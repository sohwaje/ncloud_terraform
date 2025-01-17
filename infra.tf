###Terraform을 활용한 Naver Cloud Platform Server 생성하기
variable "ncloud_zones" {
  type = list
  default = ["KR-1", "KR-2"]
}

variable "server_image_prodict_code" {
  default = "SPSW0LINUX000032"
}
variable "server_product_code" {
  default = "SPSVRSTAND000004"
}
# keypair create
resource "ncloud_login_key" "loginkey" {
  key_name = "webinar"
}

data "template_file" "user_data" {
  template = "${file("user-data.sh")}"
}
#server create
resource "ncloud_server" "server" {
  count = "2"
  name = "tf-webinar-vm-${count.index+1}"
  server_image_product_code = "${var.server_image_prodict_code}"
  server_product_code = "${var.server_product_code}"
  description = "tf-webinar-vm-${count.index+1}"
  login_key_name = "${ncloud_login_key.loginkey.key_name}"
  access_control_group_configuration_no_list = ["13054"]
  zone = "${var.ncloud_zones[count.index]}"
  user_data = "${data.template_file.user_data.rendered}"
}

### LB create
resource "ncloud_load_balancer" "lb" {
  name = "ttf_webinar_lb"
  algorithm_type = "RR"
  description = "tf_webinar_lb"

  rule_list {
        protocol_type        = "HTTP"
        load_balancer_port   = 80
        server_port          = 8080
        l7_health_check_path = "/"
      }

  rule_list {
        protocol_type        = "HTTPS"
        load_balancer_port   = 443
        server_port          = 443
        l7_health_check_path = "/"
        certificate_name     = "cert"
      }

  server_instance_no_list = ["${ncloud_server.server.*.id[0]}",
  "${ncloud_server.server.*.id[1]}"]
  internet_line_type = "PUBLC"
  network_usage_type = "PBLIP"
  region = "KR"
}

###Terraform을 활용한 Naver Cloud Platform Server 생성하기
variable “ncloud_zones” {
type = “list”
default = [“KR-1”, “KR-2”]
}

variable “server_image_prodict_code” {
default = “SPSW0LINUX000032”
}
variable “server_product_code” {
default = “SPSVRSTAND000004”
}
# keypair create
resource “ncloud_login_key” “loginkey” {
“key_name” = “webinar”
}
​
data “template_file” “user_data” {
template = “${file(“user-data.sh”)}”
}
#server create
resource “ncloud_server” “server” {
“count” = “2”
“server_name” = “tf-webinar-vm-${count.index+1}”
“server_image_product_code” = “${var.server_image_prodict_code}”
“server_product_code” = “${var.server_product_code}”
“server_description” = “tf-webinar-vm-${count.index+1}”
“login_key_name” = “${ncloud_login_key.loginkey.key_name}”
“access_control_group_configuration_no_list” = [“13054”]
“zone_code” = “${var.ncloud_zones[count.index]}”
“user_data” = “${data.template_file.user_data.rendered}”
}

### LB create
resource “ncloud_load_balancer” “lb” {
“load_balancer_name” = “ttf_webinar_lb”
“load_balancer_algorithm_type_code” = “RR”
“load_balancer_description” = “tf_webinar_lb”
“load_balancer_rule_list” = [
{
“protocol_type_code” = “HTTP”
“load_balancer_port” = 80
“server_port” = 80
“l7_health_check_path” = “/”
},
]
“server_instance_no_list” = [“${ncloud_server.server.*.id[0]}”,
“${ncloud_server.server.*.id[1]}”]
“internet_line_type_code” = “PUBLC”
“network_usage_type_code” = “PBLIP”
“region_no” = “1”
}

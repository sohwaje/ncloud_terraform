#!/bin/sh

# change date timezone into Asia/seoul
sudo ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
sudo timedatectl set-timezone Asia/Seoul

# selinux disable
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=disable/' /etc/selinux/config && sudo setenforce 0
################################################################################
# change the ssh listening port
sudo sed -i 's/^#Port 22$/Port 16215/' /etc/ssh/sshd_config
sudo sed -i 's/^#Banner none$/Banner \/etc\/issue.net/' /etc/ssh/sshd_config
# add a login banner
sudo bash -c "cat << EOF > /etc/issue.net
*******************************************************************************
*                                                                             *
*                                                                             *
*  [[[ WARNING ]]] This Machine Is ISCREAMmedia Inc's Property.               *
*                                                                             *
*  A Person Autherized By SIGONGmedia Inc Can Use This Machine.               *
*  Even If You Are Autherized, You Can Only Utilize To The Purpose.           *
*  Any Illegal Action May Results In Severe Civil And Criminal Penalties.     *
*                                                                             *
*                                                                             *
*  [[[ 경 고 ]]] 이 장비는 아이스크림미디어의 자산입니다.                     *
*  이 장비는 승인된 사용자만 접속해야합니다.                                  *
*  허가된 목적이 아닌 다른 목적으로 시스템을 사용해선 안 됩니다.              *
*  불법적인 행동에는 민형사상 법적 책임이 따릅니다.                           *
*                                                                             *
*                                                                             *
*******************************************************************************
EOF"

# change a "#PrintMotd yes" into "PrintMotd no"
sudo sed -i 's/^#PrintMotd yes$/PrintMotd no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Add a "welcome banner"
sudo curl -o /usr/bin/dynmotd https://raw.githubusercontent.com/sohwaje/Powershell_for_azure/master/extensions/motd.sh
sudo chmod +x /usr/bin/dynmotd && sudo echo "/usr/bin/dynmotd" >> /etc/profile
################################################################################
# Tunning Kernel parameter values
sudo swapoff -a
sudo sed -e '/swap/ s/^#*/#/' -i /etc/fstab

sudo bash -c "cat << EOF > /etc/sysctl.conf
vm.swappiness=0
net.ipv4.ip_forward=1
fs.file-max=10000000
net.core.somaxconn=65535
net.core.netdev_max_backlog=16777216
net.core.rmem_max=134217728
net.core.wmem_max=67108864
net.core.rmem_default=67108864
net.core.wmem_default=67108864
net.core.optmem_max=67108864
net.ipv4.ip_local_port_range=1024 65535
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_max_syn_backlog=16777216
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_mem=134217728 134217728 134217728
net.ipv4.tcp_rmem=10240 87380 134217728
net.ipv4.tcp_wmem=10240 87380 134217728
net.ipv4.tcp_fin_timeout=10
net.ipv4.tcp_max_orphans=262144
net.ipv4.tcp_synack_retries=5
net.ipv4.tcp_syn_retries=5
net.ipv4.tcp_keepalive_time=60
net.ipv4.tcp_keepalive_probes=3
net.ipv4.tcp_keepalive_intvl=10
net.ipv4.tcp_sack=1
net.ipv4.tcp_timestamps=1
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.udp_rmem_min=65536
net.ipv4.udp_wmem_min=65536
net.unix.max_dgram_qlen=100
vm.dirty_ratio=40
vm.dirty_background_ratio=10
vm.max_map_count=262144
net.ipv4.tcp_fack=1
kernel.msgmnb=65536
kernel.msgmax=65536
vm.overcommit_memory=1
EOF"
sudo /sbin/sysctl -p /etc/sysctl.conf

# filedescriptor
sudo bash -c "cat << EOF > /etc/security/limits.conf
*          soft    nproc     unlimited
*          hard    nproc     unlimited
*          soft    nofile    65536
*          hard    nofile    65536
EOF"
sudo bash -c "cat << EOF > /etc/security/limits.d/20-nproc.conf
*          soft    nproc     unlimited
*          hard    nproc     unlimited
root       soft    nproc     unlimited
root       hard    nproc     unlimited
EOF"

# customize "login-prompt"
sudo echo "export PS1=\`hostname\`'-\$LOGNAME \$PWD>'" >> /etc/profile
sudo echo "export PS1=\"[\$LOGNAME@\`hostname\`:\$PWD]\"" >> /root/.bashrc
################################################################################

# update system, install software and add yum repository
sudo yum update -y
yum -y install yum-plugin-priorities \
epel-release centos-release-scl-rh \
centos-release-scl \
http://rpms.famillecollet.com/enterprise/remi-release-7.rpm \
java-1.8.0-openjdk \
java-1.8.0-openjdk-devel \
git \
httpd \
python3 \
python3-devel
sudo yum groupinstall -y "Development Tools"

# install nodejs, npm
curl -sL https://rpm.nodesource.com/setup_12.x | sudo bash -
sudo yum install -y nodejs

# install a docker
sudo curl -s https://get.docker.com | sudo sh && systemctl start docker && systemctl enable docker
sudo groupadd docker
sudo usermod -aG docker azureuser

# install a docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# install python3 pip
sudo curl https://bootstrap.pypa.io/get-pip.py | python

# install and import python3 psutil
sudo python3 -m pip install -U psutil

# fluentd docker image pull
docker pull fluent/fluentd:v0.12-debian

# Install a bashtop(resource monitoring)
sudo git clone https://github.com/aristocratos/bpytop.git && cd bpytop;sudo make install
sudo ln -s /usr/local/bin/bpytop /usr/bin/

# sudo sed -i 's/^Listen 80$/Listen 38080/' /etc/httpd/conf/httpd.conf
sudo sed -i 's/Listen 38080/Listen 80/' /etc/httpd/conf/httpd.conf
sudo echo "Test-Page" > /var/www/html/index.html
sudo systemctl start httpd
sudo systemctl enable httpd

# for monitoring resource install and excute netdata
docker run -d --name=netdata \
  -p 19999:19999 \
  -v netdatalib:/var/lib/netdata \
  -v netdatacache:/var/cache/netdata \
  -v /etc/passwd:/host/etc/passwd:ro \
  -v /etc/group:/host/etc/group:ro \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -v /etc/os-release:/host/etc/os-release:ro \
  --restart unless-stopped \
  --cap-add SYS_PTRACE \
  --security-opt apparmor=unconfined \
  netdata/netdata

# install prometheus node-exporter
sudo wget -P \
  /tmp/ https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz; \
  cd /tmp; \
  sudo tar xvfz node_exporter-1.0.1.linux-amd64.tar.gz; \
  sudo cp /tmp/node_exporter-1.0.1.linux-amd64/node_exporter /usr/local/bin; \
  sudo rm -rf /tmp/node_exporter*

# add systemctl service
sudo bash -c "cat << EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=root
Group=root
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF"

# start node_exporter
sudo systemctl daemon-reload && sudo systemctl start node_exporter && sudo systemctl enable node_exporter

# prometheus reload
# sudo curl -X POST http://10.1.12.6:9090/-/reload

# Tomcat configuration
## 변수 설정
SOURCE_DIR="webapps"
CATALINA_HOME_NAME="apache-tomcat-7.0.90"
CATALINA_BASE_NAME="gneerbank"

# Install tomcat7
cd ~; \
wget https://archive.apache.org/dist/tomcat/tomcat-7/v7.0.90/bin/"${CATALINA_HOME_NAME}".tar.gz; \
  tar xvfz "${CATALINA_HOME_NAME}".tar.gz; \
  cp -ar "${CATALINA_HOME_NAME}" "${CATALINA_BASE_NAME}"; \
  rm -f "${CATALINA_HOME_NAME}".tar.gz

# 톰캣 환경 변수 설정
echo "export CATALINA_BASE=${HOME}/${CATALINA_BASE_NAME}" >> ~/"${CATALINA_HOME_NAME}"/bin/setenv.sh
echo "export CATALINA_HOME=${HOME}/${CATALINA_HOME_NAME}" >> ~/"${CATALINA_HOME_NAME}"/bin/setenv.sh

echo '''export DATE=`date +%Y%m%d%H%M%S`
#[2] TOMCAT Port & values
# Tomcat Port 설정
export PORT_OFFSET=0
export HTTP_PORT=$(expr 8080 + $PORT_OFFSET)
export AJP_PORT=$(expr 8009 + $PORT_OFFSET)
export SSL_PORT=$(expr 8443 + $PORT_OFFSET)
export SHUTDOWN_PORT=$(expr 8005 + $PORT_OFFSET)

# Tomcat Threads 설정
export JAVA_OPTS="$JAVA_OPTS -DmaxThreads=300"
export JAVA_OPTS="$JAVA_OPTS -DminSpareThreads=50"
export JAVA_OPTS="$JAVA_OPTS -DacceptCount=10"
export JAVA_OPTS="$JAVA_OPTS -DmaxKeepAliveRequests=-1"
export JAVA_OPTS="$JAVA_OPTS -DconnectionTimeout=30000"

#[4] Directory Setup #####
export SERVER_NAME=gneerbank
export JAVA_OPTS="$JAVA_OPTS -Dserver=gneerbank"
export JAVA_HOME="/etc/alternatives/jre_1.8.0_openjdk"
export LOG_HOME=$CATALINA_BASE/logs
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CATALINA_HOME/lib
# export SCOUTER_AGENT_DIR="/home/sigongweb/work/agent.java"

#[5] JVM Options : Memory
export JAVA_OPTS="$JAVA_OPTS -Xms4096m"
export JAVA_OPTS="$JAVA_OPTS -Xmx4096m"
export JAVA_OPTS="$JAVA_OPTS -XX:NewSize=256m"
export JAVA_OPTS="$JAVA_OPTS -Xss512k"

#[6] Parallel GC OPTIONS ###
export JAVA_OPTS="$JAVA_OPTS -XX:+UseParallelOldGC "
export JAVA_OPTS="$JAVA_OPTS -Dfile.encoding=\"utf-8\""

#[7] JVM Option GCi log, Stack Trace, Dump
export JAVA_OPTS="$JAVA_OPTS -verbose:gc"
export JAVA_OPTS="$JAVA_OPTS -XX:+PrintGCTimeStamps"
export JAVA_OPTS="$JAVA_OPTS -XX:+PrintGCDetails "
export JAVA_OPTS="$JAVA_OPTS -Xloggc:$LOG_HOME/gclog/gc_$DATE.log"
export JAVA_OPTS="$JAVA_OPTS -XX:+HeapDumpOnOutOfMemoryError"
export JAVA_OPTS="$JAVA_OPTS -XX:HeapDumpPath=$LOG_HOME/gclog/java_pid.hprof"
export JAVA_OPTS="$JAVA_OPTS -XX:+DisableExplicitGC"
export JAVA_OPTS="$JAVA_OPTS -Djava.security.egd=file:/dev/./urandom"
export JAVA_OPTS="$JAVA_OPTS -Djava.awt.headless=true"

export JAVA_OPTS="$JAVA_OPTS -Dhttp.port=$HTTP_PORT"
export JAVA_OPTS="$JAVA_OPTS -Dajp.port=$AJP_PORT"
export JAVA_OPTS="$JAVA_OPTS -Dssl.port=$SSL_PORT"
export JAVA_OPTS="$JAVA_OPTS -Dshutdown.port=$SHUTDOWN_PORT"
export JAVA_OPTS="$JAVA_OPTS -Djava.library.path=$CATALINA_HOME/lib/"
export JAVA_OPTS
echo "================================================"
echo "JAVA_HOME=$JAVA_HOME"
echo "CATALINA_HOME=$CATALINA_HOME"
echo "SERVER_HOME=$CATALINA_BASE"
echo "HTTP_PORT=$HTTP_PORT"
echo "SSL_PORT=$SSL_PORT"
echo "AJP_PORT=$AJP_PORT"
echo "SHUTDOWN_PORT=$SHUTDOWN_PORT"
echo "================================================"
''' >> ~/"${CATALINA_BASE_NAME}"/bin/setenv.sh
chmod +x ~/"${CATALINA_BASE_NAME}"/bin/setenv.sh

# server.xml 복사
rm -f ~/"${CATALINA_BASE_NAME}"/conf/server.xml
wget -P \
  ~/"${CATALINA_BASE_NAME}"/conf https://raw.githubusercontent.com/sohwaje/ncloud_terraform/master/server.xml

# tomcat database 설정
mkdir -p ~/"${SOURCE_DIR}"/"${CATALINA_BASE_NAME}"; \
  mkdir -p ~/"${CATALINA_BASE_NAME}"/conf/Catalina/localhost; \
#   echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
#   <!-- 1. 소스 경로 -->
# <Context path=\"\" docBase="${HOME}"/"${SOURCE_DIR}"/"${CATALINA_BASE_NAME}"/ reloadable=\"false\"
#          privileged=\"true\" antiResourceLocking=\"false\" antiJARLocking=\"false\">
# <!-- 2. DB 정보 -->
#     <Resource name=\"jdbc/gneerbankDS\" auth=\"Container\"
#               type=\"javax.sql.DataSource\"
#               driverClassName=\"com.mysql.jdbc.Driver\"
#               validationQuery=\"SELECT 1\"
#               validationInterval=\"30000\"
#               url=""
#               username=\"gneerbank\"
#               password=\"gneerbank\"
#               maxActive=\"100\" maxIdle=\"50\" initialSize=\"30\" maxWait=\"-1\"/>
# </Context>" > ~/"${CATALINA_BASE_NAME}"/conf/Catalina/localhost/ROOT.xml

SOURCE_DIR=webapps
CATALINA_HOME_NAME=apache-tomcat-7.0.90
CATALINA_BASE_NAME=gneerbank

# Install tomcat7
cd ~; \
wget https://archive.apache.org/dist/tomcat/tomcat-7/v7.0.90/bin/"${CATALINA_HOME_NAME}".tar.gz; \
  tar xvfz "${CATALINA_HOME_NAME}".tar.gz; \
  cp -ar "${CATALINA_HOME_NAME}" "${CATALINA_BASE_NAME}"; \
  rm -f "${CATALINA_HOME_NAME}".tar.gz

# 톰캣 환경 변수 설정
echo "export CATALINA_BASE=$HOME/$CATALINA_BASE_NAME" >> "$HOME/$CATALINA_BASE_NAME/bin/setenv.sh"
echo "export CATALINA_HOME=$HOME/$CATALINA_HOME_NAME" >> "$HOME/$CATALINA_BASE_NAME/bin/setenv.sh"

echo '''export DATE=`date +%Y%m%d%H%M%S`
#[2] TOMCAT Port & values
# Tomcat Port 설정
export PORT_OFFSET=0
export HTTP_PORT=$(expr 8080 + $PORT_OFFSET)
export AJP_PORT=$(expr 8009 + $PORT_OFFSET)
export SSL_PORT=$(expr 8443 + $PORT_OFFSET)
export SHUTDOWN_PORT=$(expr 8005 + $PORT_OFFSET)

# Tomcat Threads 설정
export JAVA_OPTS="$JAVA_OPTS -DmaxThreads=300"
export JAVA_OPTS="$JAVA_OPTS -DminSpareThreads=50"
export JAVA_OPTS="$JAVA_OPTS -DacceptCount=10"
export JAVA_OPTS="$JAVA_OPTS -DmaxKeepAliveRequests=-1"
export JAVA_OPTS="$JAVA_OPTS -DconnectionTimeout=30000"

#[4] Directory Setup #####
export SERVER_NAME=gneerbank
export JAVA_OPTS="$JAVA_OPTS -Dserver=gneerbank"
export JAVA_HOME="/etc/alternatives/jre_1.8.0_openjdk"
export LOG_HOME=$CATALINA_BASE/logs
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CATALINA_HOME/lib
# export SCOUTER_AGENT_DIR="/home/sigongweb/work/agent.java"

#[5] JVM Options : Memory
export JAVA_OPTS="$JAVA_OPTS -Xms4096m"
export JAVA_OPTS="$JAVA_OPTS -Xmx4096m"
export JAVA_OPTS="$JAVA_OPTS -XX:NewSize=256m"
export JAVA_OPTS="$JAVA_OPTS -Xss512k"

#[6] Parallel GC OPTIONS ###
export JAVA_OPTS="$JAVA_OPTS -XX:+UseParallelOldGC "
export JAVA_OPTS="$JAVA_OPTS -Dfile.encoding=\"utf-8\""

#[7] JVM Option GCi log, Stack Trace, Dump
export JAVA_OPTS="$JAVA_OPTS -verbose:gc"
export JAVA_OPTS="$JAVA_OPTS -XX:+PrintGCTimeStamps"
export JAVA_OPTS="$JAVA_OPTS -XX:+PrintGCDetails "
export JAVA_OPTS="$JAVA_OPTS -Xloggc:$LOG_HOME/gclog/gc_$DATE.log"
export JAVA_OPTS="$JAVA_OPTS -XX:+HeapDumpOnOutOfMemoryError"
export JAVA_OPTS="$JAVA_OPTS -XX:HeapDumpPath=$LOG_HOME/gclog/java_pid.hprof"
export JAVA_OPTS="$JAVA_OPTS -XX:+DisableExplicitGC"
export JAVA_OPTS="$JAVA_OPTS -Djava.security.egd=file:/dev/./urandom"
export JAVA_OPTS="$JAVA_OPTS -Djava.awt.headless=true"

export JAVA_OPTS="$JAVA_OPTS -Dhttp.port=$HTTP_PORT"
export JAVA_OPTS="$JAVA_OPTS -Dajp.port=$AJP_PORT"
export JAVA_OPTS="$JAVA_OPTS -Dssl.port=$SSL_PORT"
export JAVA_OPTS="$JAVA_OPTS -Dshutdown.port=$SHUTDOWN_PORT"
export JAVA_OPTS="$JAVA_OPTS -Djava.library.path=$CATALINA_HOME/lib/"
export JAVA_OPTS
echo "================================================"
echo "JAVA_HOME=$JAVA_HOME"
echo "CATALINA_HOME=$CATALINA_HOME"
echo "SERVER_HOME=$CATALINA_BASE"
echo "HTTP_PORT=$HTTP_PORT"
echo "SSL_PORT=$SSL_PORT"
echo "AJP_PORT=$AJP_PORT"
echo "SHUTDOWN_PORT=$SHUTDOWN_PORT"
echo "================================================"
''' >> ~/"${CATALINA_BASE_NAME}"/bin/setenv.sh
chmod +x ~/"${CATALINA_BASE_NAME}"/bin/setenv.sh

# server.xml 복사
rm -f ~/"${CATALINA_BASE_NAME}"/conf/server.xml
wget -P \
  ~/"${CATALINA_BASE_NAME}"/conf https://raw.githubusercontent.com/sohwaje/ncloud_terraform/master/server.xml

# tomcat database 설정
mkdir -p ~/"${SOURCE_DIR}"/"${CATALINA_BASE_NAME}"; \
  mkdir -p ~/"${CATALINA_BASE_NAME}"/conf/Catalina/localhost; \
  echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
  <!-- 1. 소스 경로 -->
<Context path=\"\" docBase="\"${HOME}"/"${SOURCE_DIR}"/"${CATALINA_BASE_NAME}"\" reloadable=\"false\"
         privileged=\"true\" antiResourceLocking=\"false\" antiJARLocking=\"false\">
<!-- 2. DB 정보 -->
    <Resource name=\"jdbc/elLetterMDS\" auth=\"Container\"
              type=\"javax.sql.DataSource\"
              driverClassName=\"com.mysql.jdbc.Driver\"
              validationQuery=\"SELECT 1\"
              validationInterval=\"30000\"
              url=\"jdbc:mysql://10.1.3.4:3306/hiclass_stage_db?useUnicode=true&amp;characterEncoding=UTF-8&amp;characterSetResults=UTF-8&amp;useSSL=true&amp;serverTimezone=Asia/Seoul\"
              username=\"class_user_stage\"
              password=\"class@1904\"
              maxActive=\"100\" maxIdle=\"50\" initialSize=\"30\" maxWait=\"-1\"/>
</Context>" > ~/"${CATALINA_BASE_NAME}"/conf/Catalina/localhost/ROOT.xml

# gclog 디렉토리 생성
mkdir -p ~/"${CATALINA_BASE_NAME}"/logs/gclog

# mysql-connector 복사
wget -P ~/"${CATALINA_HOME_NAME}"/lib https://github.com/sohwaje/ncloud_terraform/blob/master/mysql-connector-java-8.0.21.tar.gz
tar xvfz ~/"${CATALINA_HOME_NAME}"/lib/mysql-connector-java-8.0.21.tar.gz

# tomcat start
"${CATALINA_BASE_NAME}"/bin/startup.sh

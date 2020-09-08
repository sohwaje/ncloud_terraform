#!/bin/sh
#[1] TOMCAT V7에 최적화
export DATE=`date +%Y%m%d%H%M%S`

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

#[3] JMX monitoring
#export JAVA_OPTS="$JAVA_OPTS -Djava.rmi.server.hostname=$IPADDRESS" #Service IP Address
#export JAVA_OPTS="$JAVA_OPTS -Dcom.sun.management.jmxremote=true"
#export JAVA_OPTS="$JAVA_OPTS -Dcom.sun.management.jmxremote.port=18888"
#export JAVA_OPTS="$JAVA_OPTS -Dcom.sun.management.jmxremote.rmi.port=18888"
#export JAVA_OPTS="$JAVA_OPTS -Dcom.sun.management.jmxremote.ssl=false"
#export JAVA_OPTS="$JAVA_OPTS -Dcom.sun.management.jmxremote.authenticate=true"
#export JAVA_OPTS="$JAVA_OPTS -Dcom.sun.management.jmxremote.access.file=$CATALINA_BASE/conf/jmxremote.access"
#export JAVA_OPTS="$JAVA_OPTS -Dcom.sun.management.jmxremote.password.file=$CATALINA_BASE/conf/jmxremote.password"


#[4] Directory Setup #####
export SERVER_NAME=eletter
export JAVA_OPTS="$JAVA_OPTS -Dserver=eletter"
export CATALINA_HOME="/home/sigongweb/tomcat7"
export CATALINA_BASE="/home/sigongweb/eletter_tomcat7"
export JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.232.b09-0.el7_7.x86_64"
export LOG_HOME=$CATALINA_BASE/logs
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CATALINA_HOME/lib
export SCOUTER_AGENT_DIR="/home/sigongweb/work/agent.java"

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

#[8] Scouter
# export JAVA_OPTS="$JAVA_OPTS -javaagent:${SCOUTER_AGENT_DIR}/scouter.agent.jar"
# export JAVA_OPTS="$JAVA_OPTS -Dscouter.config=${SCOUTER_AGENT_DIR}/conf/eletter.conf"

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

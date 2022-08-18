#!/bin/bash
#脚本功能： 用于jboss的启动、重启和停止
#编写人： wwu
#文件名称： jboss_op.sh 
#-----------------------------------
#使用方法: 
#    sh jboss_op.sh start --启动jboss
#    sh jboss_op.sh stop  --停止jboss
#    sh jboss_op.sh restart --重启jboss

source /etc/profile
JBOSS_BIN="/opt/earth/jboss/bin"

if [ ! -d $JBOSS_BIN ]; then 
    echo "找不到JBoss安装目录($JBOSS_BIN)"
    exit 1
fi

#获取服务器是否有dockr启动的jboss进程
get_docker_jboss_pid(){
    jboss_pid=$(docker ps |grep jboss  | awk '{ print $1 }')
    if [ ! -z "${jboss_pid}" ]; then
        echo -n $(docker inspect -f {{.State.Pid}} $jboss_pid ) | tr ' ' '|'
    fi
}

get_pid () {
   #排除掉docker启动的jboss进程
   if [ ! -z $(get_docker_jboss_pid) ]; then
        pid=$(ps -ef | grep jboss-modules.jar | grep -Ev 'grep|jboos_op|'$(get_docker_jboss_pid)'' | awk '{ print $2 }')
   else
        pid=$(ps -ef | grep jboss-modules.jar | grep -Ev 'grep|jboos_op' | awk '{ print $2 }')
   fi
   echo -n $pid
}

start_jboss() {
    cd $JBOSS_BIN
    nohup ./standalone.sh 1>/dev/null 2>&1 &
    if [ $? -eq 0 ]; then
        sleep 2
        echo -n "JBoss启动成功,进程号:$(get_pid)" 
    else
        echo -n "JBoss启动失败"
        exit 1
    fi
}

stop_jboss() {
    cd $JBOSS_BIN
    kill -9 $(get_pid) 1>/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -n "JBoss已停止" 
    else
        echo -n "JBoss停止失败"
        exit 1
    fi
}

case "$1" in
    "start")
        if [ ! -z "$(get_pid)" ]; then
            echo "JBoss进程已启动"
        else
            start_jboss
        fi
    ;;
    "restart")
        if [ ! -z "$(get_pid)" ]; then
            stop_jboss 1>/dev/null 2>&1
            sleep 2
            start_jboss
        else
            start_jboss
        fi
    ;;
    "stop")
        if [ ! -z "$(get_pid)" ]; then
            stop_jboss
        else
            echo "JBoss进程已停止"
        fi
    ;;
    *) echo "请输入如下参数: start|stop|restart"
esac

exit 0
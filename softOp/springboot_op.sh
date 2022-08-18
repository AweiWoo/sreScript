#!/bin/bash
#脚本功能： 用于springboot的启动、重启和停止
#编写人： wwu
#文件名称： springboot_op.sh 
#-----------------------------------
#使用方法: 
#    sh springboot_op.sh start --启动springboot
#    sh springboot_op.sh stop  --停止springboot
#    sh springboot_op.sh restart --重启springboot

source /etc/profile
SPRINGBOOT_BIN=$1

if [ ! -d $SPRINGBOOT_BIN ]; then 
    echo "找不到Springboot安装目录($SPRINGBOOT_BIN)"
    exit 1
fi

get_pid() {
    pid_num=$(ps -ef | grep spring | grep -v grep | grep -v springboot_op | awk '{ print $2 }')
    echo $pid_num
}

start_springboot() {
    cd $SPRINGBOOT_BIN
    nohup sh startup.sh > /dev/null 2>&1 &
    if [ $? -eq 0 ]; then
        sleep 2
        echo -n "Springboot启动成功,进程号:" $(get_pid)
    else
        echo -n "Springboot启动失败"
        exit 1
    fi
}

stop_springboot() {
    cd $SPRINGBOOT_BIN
    sh shutdown.sh > /dev/null 2>&1 &
    if [ $? -eq 0 ]; then
        echo -n "Springboot已停止" 
    else
        echo -n "Springboot停止失败"
        exit 1
    fi
}

case "$2" in
    "start")
        if [ ! -z "$(get_pid)" ]; then
            echo "Springboot进程已启动"
        else
            start_springboot
        fi
    ;;
    "restart")
        if [ ! -z "$(get_pid)" ]; then
            stop_springboot 1>/dev/null 2>&1
	        sleep 2
            start_springboot
        else
            start_springboot
        fi
    ;;
    "stop")
        if [ ! -z "$(get_pid)" ]; then
            stop_springboot
        else
            echo "Springboot进程已停止"
        fi
    ;;
    *) echo "请输入如下参数: start|stop|restart"
esac

exit 0

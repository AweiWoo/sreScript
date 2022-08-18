#!/bin/bash
#脚本功能： 用于hornetq的启动、重启和停止
#编写人： wwu
#文件名称： hornetq_op.sh 
#-----------------------------------
#使用方法: 
#    sh hornetq_op.sh start --启动hornetq
#    sh hornetq_op.sh stop  --停止hornetq
#    sh hornetq_op.sh restart --重启hornetq

source /etc/profile
HORNETQ_BIN="/opt/earth/hornetq-2.4.0.Final/bin"

if [ ! -d $HORNETQ_BIN ]; then 
    echo "找不到Hornetq安装目录($HORNETQ_BIN)"
    exit 1
fi


get_pid() {
    pid_num=$(ps -ef | grep hornetq | grep -v grep | grep -v hornetq_op | awk '{ print $2 }')
    echo $pid_num
}

start_hornetq() {
    cd $HORNETQ_BIN
    nohup sh run.sh > /dev/null 2>&1 &
    if [ $? -eq 0 ]; then
        sleep 2
        echo "Hornetq启动成功,进程号:" $(get_pid)
    else
        echo "Hornetq启动失败"
        exit 1
    fi
}

stop_hornetq() {
    cd $HORNETQ_BIN
    sh stop.sh 
    if [ $? -eq 0 ]; then
        echo "Hornetq已停止" 
    else
        echo "Hornetq停止失败"
        exit 1
    fi
}

case "$1" in
    "start")
        if [ ! -z "$(get_pid)" ]; then
            echo "Hornetq进程已启动"
        else
            start_hornetq
        fi
    ;;
    "restart")
        if [ ! -z "$(get_pid)" ]; then
            stop_hornetq 1>/dev/null 2>&1
	        sleep 2
            start_hornetq
        else
            start_hornetq
        fi
    ;;
    "stop")
        if [ ! -z "$(get_pid)" ]; then
            stop_hornetq
        else
            echo "Hornetq进程已停止"
        fi
    ;;
    *) echo "请输入如下参数: start|stop|restart"
esac

exit 0

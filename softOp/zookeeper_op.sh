#!/bin/bash
#脚本功能： 用于zookeeper的启动、重启和停止
#编写人： wwu
#文件名称： zookeeper_op.sh 
#-----------------------------------
#使用方法: 
#    sh zookeeper_op.sh start --启动zookeeper
#    sh zookeeper_op.sh stop  --停止zookeeper
#    sh zookeeper_op.sh restart --重启zookeeper

source /etc/profile
ZOOKEEPER_BIN="/opt/earth/zookeeper/bin"

if [ ! -d $ZOOKEEPER_BIN ]; then 
    echo "找不到Zookeeper安装目录($ZOOKEEPER_BIN)"
    exit 1
fi


get_pid() {
    pid_num=$(ps -ef | grep zookeeper | grep -v grep | grep -v zookeeper_op | awk '{ print $2 }')
    echo $pid_num
}

cd $ZOOKEEPER_BIN

case "$1" in
    "start")
        if [ ! -z "$(get_pid)" ]; then
            echo "Zookeeper进程已启动"
        else
            ./zkServer.sh start > /dev/null 2>&1
            if [ $? -eq 0 ]; then 
                echo -n "Zookeeper进程启动成功, 进程号: $(get_pid)"
            else
                echo "未知错误"
                exit 1
            fi
        fi
    ;;
    "restart")
        if [ ! -z "$(get_pid)" ]; then
            ./zkServer.sh restart > /dev/null 2>&1
        else
            ./zkServer.sh start > /dev/null 2>&1
        fi
        if [ $? -eq 0 ]; then 
            echo -n "Zookeeper进程重启成功, 进程号: $(get_pid)"
        else
            echo "未知错误"
            exit 1
        fi
    ;;
    "stop")
        if [ ! -z "$(get_pid)" ]; then
            ./zkServer.sh stop > /dev/null 2>&1
            if [ $? -eq 0 ]; then 
                echo "Zookeeper停止成功"
            else
                echo "未知错误"
                exit 1
            fi
        else
            echo "ZooKeeper进程已停止"
        fi
    ;;
    *) echo "请输入如下参数: start|stop|restart"
esac

exit 0

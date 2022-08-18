#!/bin/bash
#脚本功能： 用于redis的启动、重启和停止
#编写人： wwu
#文件名称： redis_op.sh 
#-----------------------------------
#使用方法: 
#    sh redis_op.sh start --启动redis
#    sh redis_op.sh stop  --停止redis
#    sh redis_op.sh restart --重启redis

source /etc/profile
REDIS_BIN="/usr/local/bin"
REDIS_CONF="/etc/redis.conf"

if [ ! -f $REDIS_BIN/redis-server ]; then 
    echo "找不到Redis安装目录($REDIS_BIN/redis-server)"
    exit 1
fi

if [ ! -f $REDIS_CONF ]; then
    echo "找不到Redis配置文件($REDIS_CONF)"
    exit 1
fi

get_pid() {
    pid_num=$(ps -ef | grep redis | grep -v grep | grep -v redis_op | awk '{ print $2 }')
    echo $pid_num
}

start_redis() {
    $REDIS_BIN/redis-server $REDIS_CONF
    if [ $? -eq 0 ]; then
        echo "Redis启动成功,进程号:" $(get_pid)
    else
        echo "Redis启动失败"
        exit 1
    fi
}

stop_redis() {
    $REDIS_BIN/redis-cli shutdown
    if [ $? -eq 0 ]; then
        echo "Redis已停止" 
    else
        echo "Redis停止失败"
        exit 1
    fi
}

case "$1" in
    "start")
        if [ ! -z "$(get_pid)" ]; then
            echo "Redis进程已启动"
        else
            start_redis
        fi
    ;;
    "restart")
        if [ ! -z "$(get_pid)" ]; then
            stop_redis 1>/dev/null 2>&1
            start_redis
        else
            start_redis
        fi
    ;;
    "stop")
        if [ ! -z "$(get_pid)" ]; then
            stop_redis
        else
            echo "Redis进程已停止"
        fi
    ;;
    *) echo "请输入如下参数: start|stop|restart"
esac

exit 0



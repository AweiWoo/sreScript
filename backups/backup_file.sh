#!/bin/bash
#功能：使用tar命令备份文件到本地目录
#auth: wwu
#-------------------------------------
#创建定时任务每天晚上23点执行备份
#0 23 * * * /opt/script/backup_file.sh 
#-------------------------------------

#需要备份的目录
src_path=$1
#备份的位置
backup_path=$2
#备份文件的名称
backup_name=$3
#日志路径
log_path=$4

#tar备份
tar_file() 
{
   cd "${src_path}" || exit
   tar -czf  "${backup_path}""${backup_name}".tar.gz ./*
}

#日志输出
wlog()
{
   message=$1
   #开始tar打包备份，注意后面可以添加--exclude参数，排除不需要备份的文件
   echo -e "$(date +%D" "%T)" "${message}" >> "${log_path}"
}

main() 
{
   wlog ' [info] start backup'
   if tar_file; then
   #if [ $? -eq 0 ]; then
       wlog ' [info] backup successful'
   else
       wlog ' [error] backup failed'
   fi
}

main
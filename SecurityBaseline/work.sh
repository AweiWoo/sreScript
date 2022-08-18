#!/bin/bash
#脚本功能：用户linux系统的安全加固工作
#auth: wwu

log_dir=/tmp/security.log

if [ -f $log_dir ];then
   echo "" > $log_dir
fi

#限制系统无用的默认帐号登录
unless_account()
{
    userlist=(daemon bin sys adm uucp nuucp lpd imnadm ipsec ldap lp nobody snapp invscout)
    for user in ${userlist[@]}
    do
       if [ $(egrep "^${user}:" /etc/passwd | wc -l) -eq 1 ];then
          usermod -s /sbin/nologin ${user} >/dev/null 2>&1 &
          echo  $(egrep "^${user}" /etc/passwd) >> $log_dir
       else
          echo -e ${user} "不存在" >> $log_dir
       fi
    done
}

#禁止使用SSH远程root登陆，配置文件：/etc/ssh/sshd_config
forbid_ssh_rootlogin()
{
   sed -ri '/^\s*PermitRootLogin\s+.+/d' /etc/ssh/sshd_config
   echo "PermitRootLogin no" >> /etc/ssh/sshd_config 
}

#密码过期策略,配置文件：/etc/login.defs
#PASS_MAX_DAYS 90（可选） #密码最长使用天数90天
#PASS_MIN_DAYS 1  #密码最短使用天数
#PASS_WARN_AGE 28   #密码到期提前提醒天数
#PASS_MIN_LEN 8  #密码最小长度为8
passwd_policy()
{
   PASS_MAX_DAYS=9999
   PASS_MIN_DAYS=30
   PASS_WARN_AGE=30
   PASS_MIN_LEN=8
   egrep -q "^\s*PASS_MAX_DAYS\s+\S*(\s*#.*)?\s*$" /etc/login.defs && \
   sed -ri "s/^(\s*)PASS_MAX_DAYS\s+\S*(\s*#.*)?\s*$/\PASS_MAX_DAYS   $PASS_MAX_DAYS/" /etc/login.defs || \
   echo "PASS_MAX_DAYS   $PASS_MAX_DAYS" >> /etc/login.defs
   egrep -q "^\s*PASS_MIN_DAYS\s+\S*(\s*#.*)?\s*$" /etc/login.defs && \
   sed -ri "s/^(\s*)PASS_MIN_DAYS\s+\S*(\s*#.*)?\s*$/\PASS_MIN_DAYS   $PASS_MIN_DAYS/" /etc/login.defs || \
   echo "PASS_MIN_DAYS   $PASS_MIN_DAYS" >> /etc/login.defs
   egrep -q "^\s*PASS_WARN_AGE\s+\S*(\s*#.*)?\s*$" /etc/login.defs && \
   sed -ri "s/^(\s*)PASS_WARN_AGE\s+\S*(\s*#.*)?\s*$/\PASS_WARN_AGE   $PASS_WARN_AGE/" /etc/login.defs || \
   echo "PASS_WARN_AGE   $PASS_WARN_AGE" >> /etc/login.defs
   egrep -q "^\s*PASS_MIN_LEN\s+\S*(\s*#.*)?\s*$" /etc/login.defs && \
   sed -ri "s/^(\s*)PASS_MIN_LEN\s+\S*(\s*#.*)?\s*$/\PASS_MIN_LEN     $PASS_MIN_LEN/" /etc/login.defs || \
   echo "PASS_MIN_LEN   $PASS_MIN_LEN" >> /etc/login.defs
}

#登陆安全,配置文件：/etc/pam.d/system-auth
#设置为连续输错5次，密码帐号锁定3分钟
login_security()
{
   sed -ri "/^\s*auth\s+required\s+pam_tally2.so\s+.+(\s*#.*)?\s*$/d" /etc/pam.d/system-auth
   sed -ri "1a auth       required     pam_tally2.so deny=5 unlock_time=180 even_deny_root root_unlock_time=30" /etc/pam.d/system-auth
}

#密码复杂度：/etc/pam.d/system-auth
passwd_policy_complex()
{
   sed -ri '/password\s+required\s+\/lib64\/security\/pam_cracklib.so\s+*/d' /etc/pam.d/system-auth
   sed -r '/password\s+required\s+pam_deny*/a\password    required      /lib64/security/pam_cracklib.so retry=3 type= minlen=8 difok=3' /etc/pam.d/system-auth
}

#检查空口令用户
check_nopwd_user()
{
   result=$(awk -F: 'length($2)==0 {print $1}' /etc/shadow)
   if [ "$result" != '' ];then
      echo "！！！存在空口令用户: "${result}"" >> $log_dir
      return 1
   else
      echo "没有空口令用户" >> $log_dir
   fi
}

#用户登陆超时,配置文件：/etc/profile
login_timeout()
{
   TMOUT=300
   egrep -q "^\s*(export|)\s*TMOUT\S\w+.*$" /etc/profile && sed -ri "s/^\s*(export|)\s*TMOUT.\S\w+.*$/export TMOUT=$TMOUT/" /etc/profile || echo "export TMOUT=$TMOUT" >> /etc/profile
   egrep -q "^\s*.*ClientAliveInterval\s\w+.*$" /etc/ssh/sshd_config && sed -ri "s/^\s*.*ClientAliveInterval\s\w+.*$/ClientAliveInterval $TMOUT/" /etc/ssh/sshd_config || echo "ClientAliveInterval $TMOUT " >> /etc/ssh/sshd_config
}

#操作历史记录并添加时间戳
history_record()
{
   history_num=30
   egrep -q "^\s*HISTSIZE\s*\W+[0-9].+$" /etc/profile && \
      sed -ri "s/^\s*HISTSIZE\W+[0-9].+$/HISTSIZE=$history_num/" /etc/profile  || echo "HISTSIZE=$history_num" >> /etc/profile
   egrep -q "^\s*HISTTIMEFORMAT\s*\S+.+$" /etc/profile && \
      sed -ri "s/^\s*HISTTIMEFORMAT\s*\S+.+$/HISTTIMEFORMAT='%F %T | '/" /etc/profile || \
      echo "HISTTIMEFORMAT='%F %T | '" >> /etc/profile
   egrep -q "^\s*export\s*HISTTIMEFORMAT.*$" /etc/profile || echo "export HISTTIMEFORMAT" >> /etc/profile
   source /etc/profile
}

#备份安全加固涉及到的配置文件
backup_config_file()
{
   file_list=(/etc/profile /etc/ssh/sshd_config /etc/pam.d/system-auth  /etc/login.defs)
   for file in ${file_list[@]}
   do
      if [ ! -f ${file_list}.cbh ];then
         cp ${file_list} ${file_list}.cbh
         echo "cp ${file_list} ${file_list}.cbh" >> $log_dir
      else
         echo "${file_list}.cbh 备份已存在" >> $log_dir
      fi
   done
}

#加固结果
op_result()
{
   if [ $? -eq 0 ];then 
      echo "**结果：Succeed**" >> $log_dir
   else 
      echo "**结果：Faild**" >> $log_dir
   fi
}

main()
{
   declare -A oplist
   oplist["backup_config_file"]="备份配置文件"
   oplist["unless_account"]="限制系统无用的默认帐号登录"
   oplist["forbid_ssh_rootlogin"]="限制ssh远程root登陆"
   oplist["passwd_policy"]="密码策略设置"
   oplist["passwd_policy_complex"]="密码复杂度"
   oplist["login_security"]="登陆安全策略设置"
   oplist["check_nopwd_user"]="检查空口令用户"
   oplist["login_timeout"]="设置用户远程登陆超时"
   oplist["history_record"]="设置历史命令记录"

   functions=(backup_config_file unless_account forbid_ssh_rootlogin passwd_policy passwd_policy_complex \
            login_security check_nopwd_user login_timeout history_record)
   
   if [ "$pd" == "no_root_ssh" ];then
      functions=(backup_config_file unless_account passwd_policy passwd_policy_complex \
            login_security check_nopwd_user login_timeout history_record)
   fi

   n=1
   echo -e "----------------开始安全加固工作--------------------------\n" >> $log_dir
   for((i=0;i<${#functions[@]};i++))
   {
      key=${functions[$i]}
      echo -e $n".${oplist["$key"]}"  >> $log_dir
      let n++
      $($key)
      op_result
      echo -e "-----------------------------------------------------\n" >> $log_dir
   }
   echo -e "----------------安全加固工作完成--------------------------\n" >> $log_dir
}

#如果带了“no_root_ssh”参数，则表示不执行“限制ssh远程root登陆”的操作，此操作存在一定风险
pd=$1
main

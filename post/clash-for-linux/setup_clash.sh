#!/bin/bash 

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

arch=$(arch)
if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
   arch="amd64"
elif [[ $arch == "i686" || $arch == "i386" ]]; then
   arch="386"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
   arch="arm64"
else
   arch="amd64"
   echo -e "${red}检测架构失败，将使用默认架构: ${arch}${plain}"
   read
fi

pre_setup () {
   echo -e "${yellow}订阅链接获取方法参考: blog.mebi.me/post/clash-for-linux${plain}"
   read -p "请输入米白云clash订阅链接: " sublink
   apt --version > /dev/null 2>&1
   [ $? -eq 0 ] && tool="apt" 
   yum --version > /dev/null 2>&1
   [ $? -eq 0 ] && tool="yum"
   [ ! -n "$tool" ] && exit 1
   sudo $tool install -y gzip wget
   sudo mkdir -p /etc/clash
   sudo touch /etc/clash/.sublink
   sudo chmod 666 /etc/clash/.sublink
}

install_clash () {
   clash_version=$(curl -Ls "https://api.github.com/repos/Dreamacro/clash/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
   if [[ ! -n "$last_version" ]]; then
       clash_version="v1.7.1"
   fi
   sudo wget --no-check-certificate -O /usr/local/clash.gz https://hub.fastgit.org/Dreamacro/clash/releases/download/${clash_version}/clash-linux-${arch}-${clash_version}.gz
   if [[ $? -ne 0 ]]; then
       echo -e "${red}下载 clash 失败，请检查你的网络状况，或稍后再试${plain}"
       exit 1
   fi
  sudo rm /usr/local/clash
  sudo gzip -d /usr/local/clash.gz
  sudo chmod +x /usr/local/clash 
}

download_mmdb () {
   sudo wget -O /etc/clash/Country.mmdb "https://cdn.jsdelivr.net/gh/alecthw/mmdb_china_ip_list@release/Country.mmdb" 
}

import_sublink () {
    sudo wget -O /etc/clash/config.yaml "$sublink&new=1" > /dev/null 2>&1
    sudo echo "$sublink" > /etc/clash/.sublink
    echo -e "${green}订阅导入成功！${plain}"
}

update_sublink () {
    sublink=`cat /etc/clash/.sublink`
    if [ ! -n $sublink ]; then
        echo -e "${red}订阅链接不存在，请重新导入订阅链接!${plain}" 
        exit 1
    fi 
    sudo wget -O /etc/clash/config.yaml "$sublink&new=1" > /dev/null 2>&1
    echo -e "${green}手动订阅更新成功！重启clash后生效。${plain}"
}

modify_sublink () {
    echo -e "${yellow}订阅链接获取方法参考: blog.mebi.me/post/clash-for-linux${plain}"
    read -p "输入你最新的订阅链接: " sublink
    sudo wget -O /etc/clash/config.yaml "$sublink&new=1" > /dev/null 2>&1
    sudo echo "$sublink" > /etc/clash/.sublink
    echo -e "${green}订阅链接修改成功！重启clash后生效。${plain}"
}

run_clash () {
    setsid /usr/local/clash -d /etc/clash >> /dev/null 2>&1 &
    ps -ef | grep "clash -d" | grep -v grep >> /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${green}clash启动成功！打开 clash.razord.top 进行节点选择(非必需)${plain}"
    else
        echo -e "${red}启动失败！${plain}"
    fi
}

status_clash () {
    status="${red}未运行${plain}"
    clash_info=`ps -ef | grep "clash -d" | grep -v grep`
    if [ $? -eq 0 ]; then
        status="${yellow}运行中...${plain}"
    fi
}

stop_clash () {
    clash_info=`ps -ef | grep "clash -d" | grep -v grep`
    if [ $? -eq 0 ]; then
        clash_pid=`echo "$clash_info" | tr -s " " | cut -d " " -f2`
        kill -9 "$clash_pid"
    fi
    echo -e "${green}停止成功！${plain}"
}

restart_clash () {
    clash_info=`ps -ef | grep "clash -d" | grep -v grep`
    if [ $? -eq 0 ]; then
        clash_pid=`echo "$clash_info" | tr -s " " | cut -d " " -f2`
        kill -9 "$clash_pid"
    fi
    setsid /usr/local/clash -d /etc/clash >> /dev/null 2>&1 &
    ps -ef | grep "clash -d" | grep -v grep > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${green}重启成功！${plain}"
    else
        echo -e "${red}重启失败！${plain}"
    fi
}

setup_crontab () {
    crontab -l > /tmp/crontab.bak
    echo "0 3 * * * bash $PWD/$0 update_sublink" >> /tmp/crontab.bak
    crontab /tmp/crontab.bak
}

if [ $# -gt 0 ]; then
    case $1 in
	"update_sublink")
        update_sublink
        restart_clash
	exit 0
	;;
        *)
        ;;
    esac
fi

while true
do

clear
echo "米白云 Linux版 Clash 使用脚本"
echo "-------------------------------"
echo "1、安装"
echo "2、运行"
echo "3、停止"
echo "4、重启"
echo "5、命令行代理(临时)"
echo "6、命令行代理(永久)"
echo "7、更新订阅链接"
echo "8、修改订阅链接"
echo "0、退出脚本"
echo "-------------------------------"
status_clash
echo -e "Clash运行状态：$status"
echo "-------------------------------"

read -p "请选择你要的操作: " choise_num
case $choise_num in
    0)
    exit 0
    ;;
    1)
    pre_setup
    install_clash
    download_mmdb
    import_sublink
    setup_crontab
    echo -e "${green}安装成功！clash可以开始运行${plain}"
    read -p "回车退出 "
    continue
    ;;
    2)
    run_clash
    read -p "回车退出 "
    continue
    ;;
    3)
    stop_clash   
    read -p "回车退出 "
    continue
    ;;
    4)
    restart_clash
    read -p "回车退出 "
    continue
    ;;
    5)
    echo "请复制并执行下面两条命令(参考blog.mebi.me/post/clash-for-linux)："
    echo -e "${red}export http_proxy='http://127.0.0.1:7890'${plain}"
    echo -e "${red}export https_proxy='http://127.0.0.1:7890'${plain}"
    break
    ;;
    6)
    echo "请复制并执行下面三条命令(参考blog.mebi.me/post/clash-for-linux)："
    echo -e "${red}echo \"export http_proxy=http://127.0.0.1:7890\" >> /etc/profile${plain}"
    echo -e "${red}echo \"export https_proxy=http://127.0.0.1:7890\" >> /etc/profile${plain}"
    echo -e "${red}export /etc/profile${plain}"
    break
    ;;
    7)
    update_sublink
    read -p "回车退出 "
    continue
    ;;
    8)
    modify_sublink
    read -p "回车退出 "
    continue
    ;;
    *)
    exit 1
    ;;
esac
done

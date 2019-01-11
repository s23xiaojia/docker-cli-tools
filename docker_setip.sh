#!/usr/bin/env bash
#
# @Desc: docker 容器设置静态IP与宿主机同一网段通信
# @FileName: docker_setip.sh <https://github.com/s23xiaojia/docker-cli-tools.git>
# @Version: v1.0.0
# @Date: 2018/01/04
# @Author: Jia Junwei <login_532_gajun@sina.com>

cmd=$0
arg=$@
arg_num=$#

# // 打印命令使用方法
help_info() {
  echo """
  Usage: $(basename $0) <OPTION> ...

    OPTION as follows:
      --container    container name or container id
      --br           physical bridge name prepare container connect
      --ip           container ip address eg ip/prefix
      --gw           container default gateway
 
    Example:
      $(basename $0) --container test --br mybr0 --ip 192.168.1.1/24 --gw 192.168.1.254
  """
}

# // 获取参数的值   
get_params() {
  for ((i=1;i<=$arg_num/2;i++));do
    case $1 in 
     --container)
       container_name=$2
       ;;

     --br)
       bridge_name=$2
       ;;

     --ip)
       ipaddr=$2
       ;;

     --gw)
       gateway=$2
       ;;

     *)
       help_info
       exit 1
    esac
    shift 2
  done

}

# // 容器、物理桥健康状态检测
health_check(){
 
  if [[ `docker container ls -f name=$container_name -q | wc -l` -ne 1 ]];then
    echo "Error: Container $container_name is not running"   
    return 1
  fi
  brctl show $bridge_name 2>&1 | grep -q No && echo "Error: can't get info No such device $bridge_name" && return 1 || return 0
}

# // 添加veth网卡一半到容器
# // 添加veth网卡另一半到物理桥
# // 初始化容器新网卡配置

addif_to_bridge() {
  container_id=$(docker container ls -f name=$container_name -q | cut -c 1-5)  ## 容器ID
  pid=$(docker inspect -f '{{.State.Pid}}' $container_name)   ## 容器pid

  # // 设置容器的网络名称空间
  [ ! -d /var/run/netns ] && mkdir -p /var/run/netns
  find -L /var/run/netns -type l -delete
  ln -sf /proc/$pid/ns/net /var/run/netns/$container_name

  # // 生成veth网卡队并添加到容器和物理桥
  ip link add veth${container_id}.0 type veth peer name veth${container_id}.1 && true || exit 1

  #for i in {1..4};do
  #  if [ $i -eq 4 ];then echo "Exception: line[82] [NIC pair generation failed.]";exit 1;fi
  #  ip link add veth${container_id}.0 type veth peer name veth${container_id}.1
  #  if [ $? -ne 0 ];then
  #    container_id=$(docker container ls -f name=$container_name -q | cut -c 1-$[5+i])
  #  else
  #    break
  #  fi
  #done
  brctl addif $bridge_name veth${container_id}.0 && true || exit 1
  ip link set veth${container_id}.0 up && true || exit 1
  ip link set veth${container_id}.1 netns $container_name && true || exit 1

  # // 更新容器网卡配置
  #ip netns exec $container_name ip link set dev veth${container_id}.1 name eth0
  #ip netns exec $container_name ip link set eth0 up
  ip netns exec $container_name ip link set dev veth${container_id}.1 up && true || exit 1
  ip netns exec $container_name ip addr add $ipaddr dev veth${container_id}.1 && true || exit 1
  ip netns exec $container_name ip route add default via $gateway dev veth${container_id}.1 proto static metric 200 

  # // 打印网卡配置信息
  echo "container_name: $container_name"
  echo "bridge_name: $bridge_name"
  echo "ipaddr: $ipaddr"
  echo "gateway: $gateway"
}

# // 添加桥路由转发
set_ip_route() {
  iptables -t filter -L FORWARD  -nv --line | grep -wq "$bridge_name" || iptables -t filter -I FORWARD 3 -o $bridge_name -s 0.0.0.0/0 -d 0.0.0.0/0 -j ACCEPT 
  sysctl net.ipv4.ip_forward | grep -wq 0 &&  sysctl -wq net.ipv4.ip_forward=1
}

# // main 
if [[ $arg_num -ne 8 ]];then
  help_info
  exit 1
fi

get_params $arg
health_check && addif_to_bridge
set_ip_route

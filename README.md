# docker-cli-tools
@include <docker_bashrc.sh> <docker_setip.sh>

# install docker_bashrc.sh 
1. $ cd /usr/local/src
2. $ git clone https://github.com/s23xiaojia/docker-cli-tools.git 
3. $ cp ~/.bashrc ~/.bashrc.bak
4. append content from docker_bashrc.sh to ~/.bashrc.  ## Manual copy does not use command append
5. $ exec bash

# usage new docker cli commands
## View the ip address of the specified container
    $ docker-ip <container_name|container_id>  
## Display ip of all containers in the specified network
    $ docker-ipall [network_name] 
## Display the process pid of the specified container <br>
    $ docker-pid <container_name|container_id> 
## Enter or execute the specified command inside the container
    $ docker-enter <container_name|container_id> [command] 
## Display volume information for all running containers
    $ docker-volinfo

# install docker_setip.sh
1. $ cd /usr/local/src
2. $ cp docker_setip.sh /usr/local/bin/docker_setip
3. $ chmod +x /usr/local/bin/docker_setip

# usage docker_setip
## setp1. Set up the physical bridge
    $ vim /etc/sysconfig/network-scripts/ifcfg-br0  ## Physical bridge name
    DEVICE=br0
    TYPE=Bridge
    ONBOOT=yes
    BOOTPROTO=none
    NM_CONTROLLED=no
    IPADDR=192.168.123.67
    NETMASK=255.255.255.0
    GATEWAY=192.168.123.1
    DNS1=192.168.123.1
    DNS2=114.114.114.114
    ZONE=public 
    
    $ vim /etc/sysconfig/network-scripts/ifcfg-ens33  ## physical network card
    DEVICE=ens33
    TYPE=Ethernet
    BRIDGE=br0
    ONBOOT=yes
    BOOTPROTO=none
    NM_CONTROLLED=no
    ZONE=public
    
    $ systemctl stop NetworkManager.service   ### 注意需要关闭此服务，否则配置不生效
    $ systemctl disable NetworkManager
    $ systemctl restart network.service
    $ brctl stp br0 on     ### 开启二层交换机的生成树协议，防环
    $ brctl show   ### 使用brctl命令查看桥接信息，该命令由bridge-utils包提供
       
## step2. the container startup network mode must be none, specified with -net=none,examples are as follows:
    $ docker run --name b8 --network=none -itd busybox su -
## step3. cat docker_setip command help (you can also skip this） 
    $ docker_setip.sh --help

  Usage: docker_setip.sh <OPTION> ...

    OPTION as follows:
      --container    container name or container id
      --br           physical bridge name prepare container connect
      --ip           container ip address eg ip/prefix
      --gw           container default gateway
 
    Example:
      docker_setip.sh --container test --br mybr0 --ip 192.168.1.1/24 --gw 192.168.1.254
## step4. run command configure network    
    $ docker_setip.sh --container b8 --br br0 --ip 192.168.123.18/24 --gw 192.168.123.1
## step5. verify network
    $ docker-entry b8 ifconfig -a  ## View NIC configuration
    $ docker-entry b8 ping 192.168.123.1 ## Ping gateway
    $ docker-entry b8 ping www.baidu.com  ## Ping Internet


# .bashrc
# User specific aliases and functions

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

# add the content of this file to your .bashrc and you can use the command as you want
# Author:zhangzju@github
# Updated:2017-04-05

# get pid of a container
alias docker-pid="sudo docker inspect --format '{{.State.Pid}}'"

# get ip of a container
alias docker-ip="sudo docker inspect --format '{{ .NetworkSettings.IPAddress }}'"

# get the daemon process pid 
alias docker-dpid="sudo echo $(pidof dockerd)"

# check whether Docker is running, only for ubuntu16.04 or higher
alias docker-status="sudo systemctl is-active docker"

# enter to a container,the implementation refs from https://github.com/jpetazzo/nsenter/blob/master/docker-enter
function docker-enter() {
    #if [ -e $(dirname "$0")/nsenter ]; then
    #Change for centos bash running
    if [ -e $(dirname '$0')/nsenter ]; then
        # with boot2docker, nsenter is not in the PATH but it is in the same folder
        NSENTER=$(dirname "$0")/nsenter
    else
        # if nsenter has already been installed with path notified, here will be clarified
        NSENTER=$(which nsenter)
        #NSENTER=nsenter
    fi
    [ -z "$NSENTER" ] && echo "WARN Cannot find nsenter" && return

    if [ -z "$1" ]; then
        echo "Usage: `basename "$0"` CONTAINER [COMMAND [ARG]...]"
        echo ""
        echo "Enters the Docker CONTAINER and executes the specified COMMAND."
        echo "If COMMAND is not specified, runs an interactive shell in CONTAINER."
    else
        PID=$(sudo docker inspect --format "{{.State.Pid}}" "$1")
        if [ -z "$PID" ]; then
            echo "WARN Cannot find the given container"
            return
        fi
        shift

        OPTS="--target $PID --mount --uts --ipc --net --pid"

        if [ -z "$1" ]; then
            # No command given.
            # Use su to clear all host environment variables except for TERM,
            # initialize the environment variables HOME, SHELL, USER, LOGNAME, PATH,
            # and start a login shell.
            #sudo $NSENTER "$OPTS" su - root
            sudo $NSENTER --target $PID --mount --uts --ipc --net --pid su - root
        else
            # Use env to clear all host environment variables.
            #sudo $NSENTER --target $PID --mount --uts --ipc --net --pid env -i $@
            sudo $NSENTER --target $PID --mount --uts --ipc --net --pid su -l -c $@
        fi
    fi
}

# update the docker version
function docker-update(){
    if [ -e $1];then
        sudo apt-get update
        sudo apt-get upgrade -y
    elif [ "$1"="f" ];then
        sudo apt-get install apt-transport-https -y
        sudo apt-get install -y lxc-docker
    else 
        sudo apt-get update -y lxc-docker 
    fi
}

# @Desc: Display the addresses of all containers on the specified network
# @Version: 1.0.0
# @Author: jiajunwei <login_532_gajun@sina.com>
# @UpdateDate: 2019/01/03
# @Usage: shell>docker-ipall network_name 
# @Parameter: network_name 
# @Return: None
  
function docker-ipall() {
    local network=$1
    if [ -z $network ];then
        network=`docker network ls | grep -v ^NET | awk '{print $2}'`
    fi

    for net in $network;do
      echo -e "\033[32m<Network:$net,$(docker network inspect -f "{{json .IPAM.Config}}" $net | sed 's@[][{}""]@@g')>\033[0m"
      if [[ $net != "none" ]];then
        docker inspect -f '{{range .Containers }}{{if ne "null" .Name}}{{println .Name  .IPv4Address}}{{end}}{{end}}' $net | egrep -iv "^[[:space:]]*($|#)"
      else
        #arg_ip="ifconfig | grep "cast.[0-9]" | head -1 | awk '{print $2}' | sed 's@addr:@@g'"
        #arg_mask=ifconfig | grep "cast.[0-9]" | head -1 | grep -o "[mM]ask.[0-9.]\+\w" | sed 's@[mM]ask.@@'
        get_container_name="docker inspect -f '{{range .Containers }}{{if ne \"null\" .Name}}{{println .Name}}{{end}}{{end}}' $net | egrep -iv \"^[[:space:]]*($|#)\""
        container_num=$(echo $get_container_name | bash 2>/dev/null | wc -l)
        if [[ $container_num -gt 0 ]];then
          for name in `echo $get_container_name | bash`;do
            echo "$name $(docker-enter $name ip addr show | grep 'inet[[:space:]]\+' | awk '{if($NF!="lo")print $2,$NF}' | head -1)"
          done
        fi
      fi      
    done
}

# @Desc: Display volume information for all running containers
# @Version: 1.0.0
# @Author: jiajunwei <login_532_gajun@sina.com>
# @UpdateDate: 2019/01/12
# @Usage: shell>docker-volinfo 
# @Parameter: None 
# @Return: None

function docker-volinfo() {
# docker container inspect -f '{{ .Mounts}}' $(docker ps -q) | cut -c 3- | cut -d " " -f 1 | sort -u
    mnt_type_bind=()
    mnt_type_vol=()

    for name in $(docker ps  | awk '{print $NF}' | sed -n '2,$p');do
      if [[ `docker container inspect -f '{{ .Mounts}}' $name | cut -c 3- | cut -d " " -f 1` == "volume" ]];then
        mnt_type_vol=("${mnt_type_vol[*]}" "$name")
      elif [[ `docker container inspect -f '{{ .Mounts}}' $name | cut -c 3- | cut -d " " -f 1` == "bind" ]];then
        mnt_type_bind=("${mnt_type_bind[*]}" "$name")
      fi
    done

    echo "mnt_type = bind:" 
    for name in ${mnt_type_bind[*]};do echo -e -n "  - $name `docker container inspect -f '{{range .Mounts}}{{print .Source ","}}{{end}}' $name`\n";done
    echo
    echo "mnt_type = volume:"
    for name in ${mnt_type_vol[*]};do echo -e -n "  - $name `docker container inspect -f '{{range .Mounts}}{{print .Name ","}}{{end}}' $name`\n";done
}

# kill all the container which is running
alias docker-kill='docker kill $(docker ps -a -q)'

# del all the stopped container
alias docker-cleanc='docker rm $(docker ps -a -q)'

# del all the dangling images
alias docker-cleani='docker rmi $(docker images -q -f dangling=true)'

# both the effects below
alias docker-clean='dockercleanc || true && dockercleani'

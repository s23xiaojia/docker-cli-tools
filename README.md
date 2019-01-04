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
## enter or execute the specified command inside the container
    $ docker-enter <container_name|container_id> [command] 

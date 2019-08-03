# microservices-architecture
An opensource repository for all my learnings regarding microservices.

> Note: All installation and setups here are done on my Debian machine. For installation of tools on other OS you might want to check their documentations for the instructions. 

## Pre-requisites

+ Prior knowledge to the ff:
    - Virtual Machines
    - Docker
    - Basic Networking
    - Application Development
+ Change to superuser access, but please be aware of every command you run
```cli
$    sudo su
```
+ Guts

> Note : You can follow this guide without those prior knowledge but on each step or phase you have to do your research on that specific topic and this guide would just help you to narrow down the learning curve.

## Technology Used

+ Virtualbox
+ Docker
    + Docker Compose
    + Docker Swarm
    + Docker Machine
    + Docker Plugin - local-persist
+ Portainer
+ NodeJS
+ Jenkins
    + BlueOcean
+ Kibana
+ Elasticsearch
    + Filebeat
    + Metricbeat
    + Heartbeat
+ Logstash
+ Metabase

## Dependency Installation

> Note : You can browse the script file, **dependency-installation.sh** to view steps for each installation.

+ A script was already made which includes installation for the ff:
    + Virtualbox
    + Docker
    + Docker Compose
    + Docker Machine
    + Docker Plugin - local-persist

```cli
$   chmod +x dependency-installation.sh \
	&& ./dependency-installation.sh
```

## Some take notes before actual setup

+ For naming docker networks, swarms, etc. please do not use dashed lines (-), use underscores instead (_). A sample case for this is when you replicate containers, the IP for those containers might vary and for you to communicate to those container regardless of their IP is that you can use the service name of the container (stack name + service name on compose file) as host name but once you use a dashed line on those, parsing the host name would give an error. You can see implementation along the way. 

+ Never use **localhost** use **127.0.0.1** instead.

## Docker Swarm Setup

+ Initialize docker swarm
> Note : If there are more than one IP address present on your server, append **--advertise-addr \<ip-addr\>** as arg on swarm init command and replace **\<ip-addr\>** with the IP address you want to use as seen below.

```cli
$	docker swarm init
$	docker swarm init --advertise-addr <ip-addr> 
```

+ Check if swarm was created

```cli
$   docker node ls
```

> Optional : If you want to deploy lets say the database stack to another server different from the server used by the microservices stack use **docker swarm join** command, for more info check [here](https://docs.docker.com/engine/reference/commandline/swarm_join/).

## Docker Network Setup

+ Create network for microservices
> Note : On the compose file of services that need to see each other, add the created network name and add **external** property to it that is set to true. See compose files on the repo for example.

```cli
$	NETWORK_NAME=services_network \
	&& docker network create --driver=overlay ${NETWORK_NAME}
```

+ Check if network was created

```cli
$   docker network ls
```

## Portainer Setup

+ Deploy Portainer monitoring tool for docker

```cli
$	TOOLS_SETUP_DIR=tools \
	STACK_NAME=services_tools \
	&& docker stack deploy -c ./${TOOLS_SETUP_DIR}/docker-compose.portainer.yaml ${STACK_NAME}
```

+ Check if Portainer is deployed, might take some time

```cli
$   docker service ls
```

+ Once deployed access Portainer on <HOST>:9000 and setup whatever you need to. You could also check Portainer's [Documentation](https://portainer.readthedocs.io/en/stable/) for further guide. 





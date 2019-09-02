# microservices-architecture
An opensource repository for all my learnings regarding microservices.

> Note: All installation and setups here are done on my **Debian** machine. For installation of tools on other OS you might want to check their documentations for the instructions. 

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
+ ELK Stack
    + Elasticsearch
        + Filebeat
        + Metricbeat
        + Heartbeat
    + Logstash
    + Kibana
        + Application Performance Monitoring (APM) 
+ Metabase
+ NGINX

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

+ You can use this guide on servers other than **Debian** but make sure you know what you are doing.

+ For naming docker networks, swarms, etc. please do not use dashed lines (-), use underscores instead (_). A sample case for this is when you replicate containers, the IP for those containers might vary and for you to communicate to those container regardless of their IP is that you can use the service name of the container (stack name + service name on compose file) as host name but once you use a dashed line on those, parsing the host name would give an error. You can see implementation along the way. 

+ Never use **localhost** use **127.0.0.1** instead.

+ Its always better to deploy databases on different swarm node that is preferrably on a different server as well. 

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

+ Once deployed access Portainer on http://127.0.0.1:9000 and setup whatever you need to. You could also check Portainer's [Documentation](https://portainer.readthedocs.io/en/stable/) for further guide. 

## Elasticsearch, Logstash, Kibana (ELK) Stack Setup

+ Change ELASTIC_PASSWORD to your desired password for Elasticsearch, or just leave it as is for default.

+ Deploy centralized logging using ELK stack
> Note : If elasticsearch does not start you might need to run this `sysctl -w vm.max_map_count=262144` or if you want that setting to persist on reboot, open **/etc/sysctl.conf** then add **vm.max_map_count=262144** finally run `service sysctl restart` to apply changes.

```cli
$	TOOLS_SETUP_DIR=tools \
	STACK_NAME=services_tools \
	&& docker stack deploy -c ./${TOOLS_SETUP_DIR}/docker-compose.elk.yaml ${STACK_NAME}
```

+ Check if ELK stack is deployed, might take some time

```cli
$   docker service ls
```

+ Once deployed access ELK stack on http://127.0.0.1:5601 which will be your Kibana's URL and setup whatever you need to. 

### Heartbeat Uptime Monitoring Setup

+ Install Heartbeat

```cli
$   curl -L -O https://artifacts.elastic.co/downloads/beats/heartbeat/heartbeat-6.7.0-amd64.deb \
    && dpkg -i heartbeat-6.7.0-amd64.deb \
    && rm heartbeat-6.7.0-amd64.deb
```

+ Modify Heartbeat config on **/etc/heartbeat/heartbeat.yml**

```yaml
output.elasticsearch:
  hosts: ["127.0.0.1:9200"]
  username: "elastic"
  password: "changeme"
setup.kibana:
  host: "127.0.0.1:5601"
```

+ Add service URLs for heartbeat to monitor on **/etc/heartbeat/heartbeat.yml**

```yaml
heartbeat.monitors:
- type: http
  urls: ["<http://127.0.0.1:9000>"]
  schedule: "@every 10s"
```

+ Start Heartbeat service

```cli
$   heartbeat setup
$   service heartbeat-elastic start
```

+ Check if Heartbeat is working on Kibana's [Uptime Monitoring](http://127.0.0.1:5601/app/uptime#/?_g=())

### Metricbeat Setup

+ Install Metricbeat

```cli
$   curl -L -O https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-6.7.0-amd64.deb \
    && dpkg -i metricbeat-6.7.0-amd64.deb \
    && rm metricbeat-6.7.0-amd64.deb
```

+ Modify Metricbeat config on **/etc/metricbeat/metricbeat.yml**

```yaml
output.elasticsearch:
  hosts: ["127.0.0.1:9200"]
  username: "elastic"
  password: "changeme"
setup.kibana:
  host: "127.0.0.1:5601"
```

+ Start Metricbeat service

```cli
$   metricbeat setup
$   service metricbeat start
```

+ For installing Metricbeat modules check for instructions on Kibana's [Tutorial Directory](http://127.0.0.1:5601/app/kibana#/home/tutorial_directory?_g=())

### Filebeat Setup

+ Install Filebeat

```cli
$   curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-6.7.0-amd64.deb \
    && dpkg -i filebeat-6.7.0-amd64.deb \
    && rm filebeat-6.7.0-amd64.deb
```

+ Modify Filebeat config on **/etc/filebeat/filebeat.yml**, this is to enable catching of logs from Docker containers

```yaml
filebeat.inputs:
- type: docker
  containers:
    ids: 
      - "*"
output.elasticsearch:
  hosts: ["127.0.0.1:9200"]
  username: "elastic"
  password: "changeme"
setup.kibana:
  host: "127.0.0.1:5601"
```

+ Start Filebeat service

```cli
$   filebeat setup
$   service filebeat start
```

+ Check if logs are working on Kibana's [Logs](http://127.0.0.1:5601/app/infra#/logs?_g=())

+ For installing Filebeat modules check for instructions on Kibana's [Tutorial Directory](http://127.0.0.1:5601/app/kibana#/home/tutorial_directory?_g=())

### Application Performance Monitoring (APM) Setup

+ Install APM server

```cli
$   curl -L -O https://artifacts.elastic.co/downloads/apm-server/apm-server-6.7.0-amd64.deb \
    && dpkg -i apm-server-6.7.0-amd64.deb \
    && rm apm-server-6.7.0-amd64.deb
```

+ Modify APM config on **/etc/apm-server/apm-server.yml**

```yaml
output.elasticsearch:
  hosts: ["127.0.0.1:9200"]
  username: "elastic"
  password: "changeme"
```

+ Start APM server

```cli
$   service apm-server start
```

+ For setting up APM node on your app please follow instructions on Kibana's [APM Tutorial](http://127.0.0.1:5601/app/kibana#/home/tutorial/apm?_g=(time:(from:now-24h,mode:quick,to:now))&_a=).

## Jenkins Setup

+ Deploy Jenkins 
> Note : A password will be shown on jenkins container logs, use it for first time setup on jenkins. You can also save it on other location for later use.

```cli
$	TOOLS_SETUP_DIR=tools \
	STACK_NAME=services_tools \
	&& docker stack deploy -c ./${TOOLS_SETUP_DIR}/docker-compose.jenkins.yaml ${STACK_NAME}
```

+ Check if Jenkins is deployed, might take some time

```cli
$   docker service ls
```

+ Once deployed access Jenkins on http://127.0.0.1:8080, input the password shown on the container logs mentioned on previous step. Setup Jenkins accordingly and proceed to login.

### Setting Up a Bitbucket Pipeline (Optional Guide)

+ On the dashboard navigate to **Manage Jenkins>Manage Plugins** then click on **Available** tab and search for **[Bitbucket Push and Pull Request Plugin](https://wiki.jenkins.io/display/JENKINS/Bitbucket+Push+And+Pull+Request+Plugin)** and install it.

+ On your bitbucket repository nagivate to **Settings>Webhooks** then click **Add webhook**, set title to **Jenkins** and URL to **http://YOUR_JENKINS_URL/bitbucket-hook/** then adjust triggers to your likings, the default is _Repository push_.

+ After setting up on bitbucket repositry get back to jenkins and on dashboard navigate to **New Item**, set item name to **REPOSITORY_NAME** and click **Pipeline** then save. A configuration page would appear after. On the **Build Triggers** tab tick **Build with BitBucket Push and Pull Request Plugin** then add triggers similar to the triggers you set on the repository settings from the previous step. On the **Pipeline** tab set definition to **Pipeline script from SCM** and a configuration would appear below. Set SCM to **Git**, then on repository URL put the URL for cloning your repository. On the credentials select if you already have, if not click **Add>Jenkins** set values for username, password, ID and description field and click **Add** on the bottom, this would appear on the selection right after. On the branches to build set branch specifier to **origin/master**. Finally click **Save**.

+ Navigate **Back to Dashboard**, you will see your newly created pipeline.

+ Navigate to **Open Blue Ocean**, a modernized UI for jenkins would appear which contains all the pipelines created. Click on your newly created pipeline from the list, then click **Run**, this is required to initialized connection between bitbucket and jenkins through the webhook.

+ Make sure you have a **Jenkinsfile** on the repository you used, this would be the recipe for the different stages of the pipeline.

## NGINX Setup

+ On your host machine install and run NGINX using the following command.

```cli
$   apt install nginx \
    && service nginx start
```

+ Check if NGINX is running.

```cli
$   service nginx status
```

+ To setup NGINX as reverse proxy for your NodeJS application, create **\<app-name\>** file under /etc/nginx/sites-available.

```cli
$   touch /etc/nginx/sites-available/<app-name> 
```

+ Open the created file and add the following configuration.

```bash
server {
  listen 80;
  listen 443 ssl;
  server_name <app-domain>;
  
  ssl_certificate  /etc/nginx/ssl/<app-name>.crt
  ssl_certificate_key /etc/nginx/ssl/<app-name>.key

  location / {
    proxy_pass http://127.0.0.1:<app-port>;
    proxy_http_version 1.1;
    proxy_set_header X-Forwarded-For $remote_addr;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $http_host;
    proxy_cache_bypass $http_upgrade;
  }
}
```

+ Restart NGINX to apply configuration.

```cli
$   service nginx restart
```
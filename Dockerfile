FROM ubuntu:14.04
MAINTAINER Jysperm "jysperm@gmail.com"

RUN apt-get update &&\
    apt-get -y -q install mongodb nodejs npm git nginx redis-server g++ &&\
    apt-get clean &&\
    update-alternatives --install /usr/bin/node node /usr/bin/nodejs 10

RUN npm install -g coffee-script gulp bower

ADD sample/nginx.conf /etc/nginx/sites-enabled/rpadmin

EXPOSE 80
WORKDIR /rootpanel

CMD service nginx start &&\
    service mongodb start &&\
    service redis-server start &&\
    /bin/bash

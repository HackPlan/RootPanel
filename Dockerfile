FROM ubuntu:14.04
MAINTAINER Jysperm "jysperm@gmail.com"

RUN apt-get update &&\
    apt-get -y -q install mongodb nodejs npm git nginx redis-server g++ &&\
    apt-get clean &&\
    update-alternatives --install /usr/bin/node node /usr/bin/nodejs 10

RUN npm install -g coffee-script gulp bower

WORKDIR /rootpanel

ADD . ./

RUN npm install
RUN bower install --allow-root
RUN gulp build

RUN rm /etc/nginx/sites-enabled/default
RUN sed -i "s/user www-data;/user root;/g" /etc/nginx/nginx.conf

ADD sample/nginx.conf /etc/nginx/sites-enabled/rpadmin

EXPOSE 80

CMD service nginx start &&\
    service mongodb start &&\
    service redis-server start &&\
    npm start

#Debian stable
FROM debian:stable-slim

#3 args required to connect to Delphix Engine
ARG ip
ARG username
ARG password

#Update the OS and install curl
RUN apt-get update &&  apt-get -y upgrade && apt-get -y install curl
#Get jq to parse json file, and install it in / usr/bin
RUN curl -s -L https://github.com/stedolan/jq/releases/download/jq-1.4/jq-linux-x86_64 --output jq
RUN chmod +x jq
RUN cp jq /usr/bin/

#Copy Delphix scripts into the factory
COPY apis/* /usr/bin/

#!/bin/sh

########################################################################
# title:          Build Complete Project
# author:         Gary A. Stafford (https://programmaticponderings.com)
# url:            https://github.com/garystafford/sprint-music-docker
# description:    Clone and build complete Spring Music Docker project
# usage:          sh ./build_project.sh
########################################################################

# clone project
git clone -b master --single-branch \
  https://github.com/garystafford/spring-music-docker.git && \
cd spring-music-docker

# provision VirtualBox VM
docker-machine create --driver virtualbox springmusic

# set new environment
docker-machine env springmusic && \
eval "$(docker-machine env springmusic)"

# create directory to store mongo data on host
# ** assumes your project folder is 'music' **
docker volume create --name music_data

# create bridge network for project
# ** assumes your project folder is 'music' **
docker network create -d bridge music_net

# build images and orchestrate start-up of containers (in this order!)
docker-compose -p music up -d elk && sleep 15 && \
docker-compose -p music up -d mongodb && sleep 15 && \
docker-compose -p music up -d app && \
docker-compose scale app=3 && sleep 15 && \
docker-compose -p music up -d proxy

# optional: configure local DNS resolution for application URL
#echo "$(docker-machine ip springmusic)   springmusic.com" | sudo tee --append /etc/hosts

# run a simple connectivity test of application
for i in {1..10}; do curl -I $(docker-machine ip springmusic); done

#!/bin/bash


NUMBER_INSTANCES=$1
FILESHARE=$2

MOUNTPOINT="/home/username/mymountpoint"
SPITZREPO=$MOUNTPOINT

 for host in `seq 4 $((${NUMBER_INSTANCES}+3))`; do
          ( ssh 10.0.0.$host "nohup ${SPITZREPO}/cepetro-codes/build-crs-spitz.sh ${SPITZREPO}/cepetro-codes &" ) &
      done
      wait

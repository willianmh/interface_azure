#!/bin/bash


NUMBER_INSTANCES=$1
NUMBER_RROCESSORS=$2
VM_SIZE=$3
FILESHARE=$4

MOUNTPOINT="/home/username/mymountpoint"
SPITZREPO=$MOUNTPOINT

 for host in `seq 4 $((${NUMBER_INSTANCES}+3))`; do
        ( ssh 10.0.0.$host "nohup ${SPITZREPO}/cepetro-codes/run-crs-spitz.sh ${SPITZREPO}/cepetro-codes ${SPITZREPO}/data $NUMBER_INSTANCES $NUMBER_RROCESSORS $VM_SIZE "  ) &
        sleep .1
      done
      wait

#!/bin/bash


NUMBER_INSTANCES=$1
NUMBER_CORES=$2

 for host in `seq 4 $((${NUMBER_INSTANCES}+3))`; do
   scp -r /home/username/BRAMS 10.0.0.${host}:
   scp -r /home/username/bin 10.0.0.${host}:
   scp -r /home/username/meteo-only 10.0.0.${host}:
   ssh 10.0.0.${host} "ln -s /home/username/bin/brams-5.3 /home/username/meteo-only/brams"
   ssh 10.0.0.${host} "cp -r ~/mymountpoint/atmospheric ~/"
done
wait

for host in `seq 4 $((${NUMBER_INSTANCES}+3))`; do
  scp -r /home/username/brams_disable_cores.sh 10.0.0.${host}:
  ssh 10.0.0.${host} "sudo ./brams_disable_cores.sh ${NUMBER_CORES}"
done

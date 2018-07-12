#!/bin/bash

NUMBER_CORES=$1

for i in $(seq 0 $NUMBER_CORES)
do
  echo 0 > /sys/devices/system/cpu/cpu$i/online
  echo $i
done

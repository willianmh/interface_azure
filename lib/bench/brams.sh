#!/bin/bash


run_brams() {

  local BRAMSDIR=$1
  local BRAMSDIRBIN=$2
  local SAMPLEDIR=$3

  local NUMBER_INSTANCES=$4

  local VM_SIZE_FORMATTED=$5
  local TOTAL_CORES=$6

  scp -r $BRAMSDIR $SSH_ADDR:
  scp -r $BRAMSDIRBIN $SSH_ADDR:
  scp -r $SAMPLEDIR $SSH_ADDR:

  scp lib/bench/brams_dir.sh ${SSH_ADDR}:
  ssh ${SSH_ADDR} ./brams_dir.sh ${NUMBER_INSTANCES}

  scp ${LOG_DIR}/hostfile ${SSH_ADDR}:meteo-only

  echo $TOTAL_CORES > total_cores
  scp total_cores ${SSH_ADDR}:meteo-only

#   ssh ${SSH_ADDR} << EOF
#     set -x
#     cd meteo-only
#     export TMPDIR=./tmp
#     ulimit -s 65536
#     /opt/mpich3/bin/mpirun -n `cat total_cores` -f hostfile ./brams 2>&1 | tee log_brams_meteo_only.out
# EOF
#
#   scp ${SSH_ADDR}:meteo-only/log_brams_meteo_only.out $RESULTS_DIR/log_meteo_only_${VM_SIZE_FORMATTED}.out

}

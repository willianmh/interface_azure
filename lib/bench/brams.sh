#!/bin/bash


run_brams() {

  local SSH_ADDR=$1

  local BRAMSDIR=$2
  local BRAMSDIRBIN=$3
  local SAMPLEDIR=$4

  local NUMBER_INSTANCES=$5

  local VM_SIZE_FORMATTED=$6

  scp -r $BRAMSDIR $SSH_ADDR:
  scp -r $BRAMSDIRBIN $SSH_ADDR:
  scp -r $SAMPLEDIR $SSH_ADDR:

  scp bench/brams_dir.sh ${SSH_ADDR}:
  ssh ${SSH_ADDR} ./brams_dir.sh ${NUMBER_INSTANCES}


  scp ${LOG_DIR}/hostfile ${SSH_ADDR}:meteo-only

  ssh ${SSH_ADDR} << EOF
    set -x
    cd meteo-only
    export TMPDIR=./tmp
    ulimit -s 65536
    # /opt/mpich3/bin/mpirun -n 64 -f hostfile ./brams 2>&1 | tee log_brams_meteo_only.out
EOF

  scp ${SSH_ADDR}:meteo-only/log_brams_meteo_only.out $RESULTS_DIR/log_meteo_only_${VM_SIZE_FORMATTED}.out

}

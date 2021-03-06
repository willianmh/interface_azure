#!/bin/bash

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

source lib/azure_functions.sh
source lib/aux_functions.sh
source lib/bench/brams.sh


main() {

  # *******************************************************************
  # CONFIGURE ENVIROMENT
  # *******************************************************************

  is_not_empty $DEBUG \
    && set -x

  is_not_empty $VERBOSE \
    && set -x

  local BENCHMARK=${1}
  # read arguments
  local ADMIN_USERNAME=${2}
  local ADMIN_PASSWORD=${3}
  # mountpoint parameters
  local PASSMOUNT=${4}
  local DISKURL=${5}
  local DISKUSERNAME=${6}

  # azure number of machines
  local NUMBER_INSTANCES=${7}
  local VM_SIZE=${8}
  local NUMBER_PROCESSORS=${9}

  local TEMPLATE_FILE=${10}
  local IMAGE=${11}
  local LOCATION=${12}


  local VM_SIZE_FORMATTED=$(remove_special_characters $VM_SIZE )
  VM_SIZE_FORMATTED=$(to_lower_case $VM_SIZE_FORMATTED )
  # VM_SIZE_FORMATTED is something like: standarda3v2

  local BENCHMARK_FORMATTED=$(remove_special_characters $BENCHMARK)
  BENCHMARK_FORMATTED=$(to_lower_case $BENCHMARK_FORMATTED)

  local RESOURCE_GROUP=${NUMBER_INSTANCES}x${VM_SIZE_FORMATTED}

  # variables to use with a FILESHARE system. If you are running SPITZ
  # $ QUOTA (in Gib) is the size of your fileshare system
  # $ FILESHARE is the name of yout fileshare system which each vm is going to mount
  local QUOTA=15
  # manipulate file share name --> remove special characters, and to lowerCaseFy
  local FILESHARE="${BENCHMARK}${NUMBER_INSTANCES}x${VM_SIZE}"
  FILESHARE=$(remove_special_characters $FILESHARE)
  FILESHARE=$(to_lower_case $FILESHARE)
  # FILESHARE is something like : brams4xstandarda3v2


  # folders to throw outputs
  LOG_DIR="log/$BENCHMARK/${VM_SIZE}_${NUMBER_INSTANCES}"
  RESULTS_DIR="results/$BENCHMARK/${VM_SIZE}_${NUMBER_INSTANCES}"

  # create folders
  mkdir -p log
  mkdir -p results
  mkdir -p log/$BENCHMARK
  mkdir -p results/$BENCHMARK

  mkdir -p $RESULTS_DIR

  LOG_FILE="${LOG_DIR}/${VM_SIZE}_${NUMBER_INSTANCES}.log"


# *******************************************************************
# START - CONFIGURE INFRASTRUCTURE
# *******************************************************************
  init_log

  create_group $RESOURCE_GROUP $LOCATION


  # discomment if your application needs a fileshare system, like SPITZ
  # create_fileshare $FILESHARE \
  #                   $PASSMOUNT \
  #                   $DISKUSERNAME \
  #                   $QUOTA

  # If your application needs a fileshare system, add $FILESHARE as the last parameter in create_machines
  # create_machines $RESOURCE_GROUP \
  #                 $TEMPLATE_FILE \
  #                 $VM_SIZE \
  #                 $ADMINPASSWORD \
  #                 $PASSMOUNT \
  #                 $DISKURL \
  #                 $DISKUSERNAME \
  #                 $NUMBER_INSTANCES \
  #                 $IMAGE # $FILESHARE (optional)

  deploy $RESOURCE_GROUP \
         $LOCATION \
         $TEMPLATE_FILE \
         $ADMIN_USERNAME \
         $ADMIN_PASSWORD \
         $VM_SIZE \
         $IMAGE \
         $NUMBER_INSTANCES


  setup_ssh_keys $RESOURCE_GROUP
  echo $SSH_ADDR
  # discomment if application needs hostfile, like if you are running MPI
  local PATH_TO_HOSTFILE=$(generate_hostfile $NUMBER_INSTANCES)

# *******************************************************************
# BENCHMARK - running application
# *******************************************************************

  # local BRAMSDIR="/home/username/BRAMS"
  # local BRAMSDIRBIN="/home/username/bin"
  # local SAMPLEDIR="/home/username/meteo-only"
  #
  # run_brams $BRAMSDIR \
  #           $BRAMSDIRBIN \
  #           $SAMPLEDIR \
  #           $NUMBER_INSTANCES \
  #           $VM_SIZE_FORMATTED \
  #           $(($NUMBER_PROCESSORS * $NUMBER_INSTANCES))
  #
  # is_empty $DELETE \
  #   && delete_group $RESOURCE_GROUP

}

main $ARGS

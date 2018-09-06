#!/bin/bash
source lib/config.sh

init_log() {
 	mkdir -p ${LOG_DIR}
	> $LOG_FILE
	write_log "start"
 }

write_log() {
	local msg=$1
	echo "$(date) $msg" 2>&1 | tee -a ${LOG_FILE}
}

create_group() {
	local RESOURCE_GROUP=$1
	local LOCATION=$2

	write_log "Creating group ${RESOURCE_GROUP} in location ${LOCATION}"

	az group create $VERBOSE --name $RESOURCE_GROUP \
                            --location ${LOCATION}
  sleep 15

	if [ ! $? -eq 0 ]; then
		msg="Failed to create group ${RESOURCE_GROUP} exiting"
		echo "$msg"
		write_log "$msg"
	  die "$msg"
	fi
	write_log "group created"

  touch groups
  echo $RESOURCE_GROUP >> groups
}

delete_group() {
	local RESOURCE_GROUP=$1

	write_log "Deleting group ${RESOURCE_GROUP}"

	az group delete $VERBOSE --name $RESOURCE_GROUP --yes --no-wait
}

deploy() {
  local DEPLOY_NAME="deploy${RANDOM}"

  local RESOURCE_GROUP=${1}
  local LOCATION=${2}

	local TEMPLATE_FILE=${3}

  local ADMIN_USERNAME=${4}
  local ADMIN_PASSWORD=${5}

  local ADMIN_PUB_KEY="$(cat ~/.ssh/id_rsa.pub)"


	local DNS_LABEL="my${RANDOM}dnsprefix"

  local VM_SIZE=${6}
  local VM_NAME="m"
  local IMAGE=${7}

  local NUMBER_INSTANCES=${8}

  write_log "deployment $DEPLOY_NAME created, deploying $NUMBER_INSTANCES machines"

  az group deployment create $VERBOSE --name $DEPLOY_NAME \
                                        --resource-group $RESOURCE_GROUP \
                                        --template-file $TEMPLATE_FILE \
                                        --parameters adminUsername=$ADMIN_USERNAME \
                                                      adminPassword=$ADMIN_PASSWORD \
                                                      adminPublicKey="$ADMIN_PUB_KEY" \
                                                      dnsLabelPrefix=$DNS_LABEL \
                                                      vmSize=$VM_SIZE \
                                                      vmName=$VM_NAME \
                                                      imageSourceID="$IMAGE" \
                                                      numberOfInstances=$NUMBER_INSTANCES 2>&1 | tee -a $LOG_FILE

  sleep 5

  local DEPLOY_STATE=$(az group deployment show --resource-group $RESOURCE_GROUP \
                            --name $DEPLOY_NAME | \
                            grep provisioningState | \
                            sed 's/^.*://;s/[^a-zA-Z0-9]//g')

  local DEPLOY_STATE_AUX=$(grep provisioningState $LOG_FILE | sed 's/^.*://;s/[^a-zA-Z0-9]//g' )

  if [ ! "$DEPLOY_STATE_AUX" = "Succeeded" ]
  then
    echo "deploy state aux failed"
  fi

  if [ ! "$DEPLOY_STATE" = "Succeeded" ]
  then
    echo "Something goes wrong"
    write_log "Deploy failed"
    delete_group $RESOURCE_GROUP
    die "ERROR: Deployment failed"
  fi

  for i in `seq 0 $((${NUMBER_INSTANCES}-1))`
  do
    echo "ssh ${ADMIN_USERNAME}@${DNS_LABEL}${i}.${LOCATION}.cloudapp.azure.com" >> $LOG_FILE
  done

  echo "Deployment finished"
  write_log "Deploy finished"
}


create_machine() {

  local DEPLOY_NAME="${1}deploy${RANDOM}"

  local RESOURCE_GROUP=$2
	local TEMPLATE_FILE=$3
	local VM_SIZE=$4

  local ADMIN_PASSWORD=$5
  local PASSMOUNT=$6
  local DISKURL=$7
  local DISKUSERNAME=$8

  local IMAGE=$9

  local ADMIN_PUB_KEY="$(cat ~/.ssh/id_rsa.pub)"


	local VM_NAME="${1}${RESOURCE_GROUP}"
	local DNS_LABEL="my${RANDOM}dnsprefix${1}"



	write_log "creating machine $DEPLOY_NAME $VM_NAME"

  # az group deployment create --verbose --name "$DEPLOY_NAME" \
  #                             --resource-group "$RESOURCE_GROUP" \
	# 	    	                    --template-file azuredeploy_w_imageBrams.json \
  #                             --parameters vmSize="$VM_SIZE" \
  #                                           vmName="$VM_NAME" \
  #                                           dnsLabelPrefix="$DNS_LABEL" \
  #                                           adminPassword="$ADMIN_PASSWORD" \
  #                                           scriptParameterPassMount="$PASSMOUNT" \
  #                                           scriptParameterDiskUrl=$DISKURL \
  #                                           scriptParameterUsername=$DISKUSERNAME \
  #                                           adminPublicKey="$ADMIN_PUB_KEY" >> $LOG_FILE

	az group deployment create $VERBOSE --name "$DEPLOY_NAME" \
                              --resource-group "$RESOURCE_GROUP" \
		    	                    --template-file "$TEMPLATE_FILE" \
                              --parameters vmSize="$VM_SIZE" \
                                            vmName="$VM_NAME" \
                                            dnsLabelPrefix="$DNS_LABEL" \
                                            adminPassword="$ADMIN_PASSWORD" \
                                            scriptParameterPassMount="$PASSMOUNT" \
                                            scriptParameterDiskUrl=$DISKURL \
                                            scriptParameterUsername=$DISKUSERNAME \
                                            adminPublicKey="$ADMIN_PUB_KEY" \
                                            imageSourceID="$IMAGE" 2>&1 | tee

  local DEPLOY_RESULT=$(az group deployment show --name "$DEPLOY_NAME" \
                            --resource-group "$RESOURCE_GROUP")
  echo $DEPLOY_RESULT >> deploy_result

	write_log "machine $DEPLOY_NAME $VM_NAME created"
}

create_machines() {

  local RESOURCE_GROUP=${1}
  local TEMPLATE_FILE=${2}
  local VM_SIZE=${3}

  local ADMIN_PASSWORD=${4}
	local PASSMOUNT=${5}
  local DISKURL=${6}
  local DISKUSERNAME=${7}

	local NUMBER_INSTANCES=${8}

  local IMAGE=${9}

  local FILESHARE=${10}

  is_not_empty $FILESHARE \
    && DISKUSERNAME=$FILESHARE

	echo "num_instances=$NUMBER_INSTANCES"
	for (( i = 1; i <= $NUMBER_INSTANCES; i++ )); do
      create_machine $i \
                      ${RESOURCE_GROUP} \
                      ${TEMPLATE_FILE} \
                      ${VM_SIZE} \
                      ${ADMINPASSWORD} \
                      ${PASSMOUNT} \
                      ${DISKURL}${DISKUSERNAME} \
                      ${DISKUSERNAME} \
                      $IMAGE &
	done
	wait
	sleep 190

}


create_fileshare() {

  local FILESHARE=$1
  local PASSMOUNT=$2
  local DISKUSERNAME=$3
  local QUOTA=$4

  write_log "Creating storage share $FILESHARE"

  az storage share create $VERBOSE --name ${FILESHARE} \
                          --account-key ${PASSMOUNT} \
                          --account-name ${DISKUSERNAME} \
                          --quota ${QUOTA}

  sleep 15
  write_log "Storage share $FILESHARE created"

  touch fileshares
  echo $FILESHARE >> fileshares
}

mount_fileshare() {
  local MOUNTPOINT=$1

  local FILESHARE=$2

  local PASSMOUNT=${3}
  local DISKURL=${4}
  local DISKUSERNAME=${5}
  # tem coisa errada aqui
  sudo mkdir -p ${MOUNTPOINT}
  sudo mount -t cifs ${DISKURL}${FILESHARE} \
                    /home/username/${FILESHARE} \
                    -o vers=3.0,username=${DISKUSERNAME},password=${PASSMOUNT},dir_mode=0777,file_mode=0777,sec=ntlmssp
}

delete_fileshare() {
  local FILESHARE=$1
  local PASSMOUNT=$2
  local DISKUSERNAME=$3


  write_log "Deleting storage share $FILESHARE"

  az storage share delete $VERBOSE --name ${FILESHARE} \
                                    --account-name ${DISKUSERNAME} \
                                    --account-key ${PASSMOUNT}

  write_log "Storage share $FILESHARE deleted"
}

generate_hostfile() {
  local NUMBER_INSTANCES=$1

  rm ${LOG_DIR}/hostfile
  for host in `seq 4 $((${NUMBER_INSTANCES}+3))`; do
      echo "10.0.0.${host}" >> ${LOG_DIR}/hostfile
  done

  echo "$LOG_DIR/hostile"
}

setup_ssh_keys() {
  local RESOURCE_GROUP=$1


  echo $LOG_FILE > grep_ssh
  grep "ssh " ${LOG_FILE} | sed -e 's/^.*@//' >> grep_ssh

  # add access credential for all vm's
  for hostname in `grep "ssh " ${LOG_FILE} | sed -e 's/^.*@//'`; do
    # echo " Copy id from $hostname"
    ssh-keygen -R $hostname
    ssh-keygen -R `dig +short $hostname`
    ssh-keyscan -H $hostname >> ~/.ssh/known_hosts
  done

  # get the coordinator address
  SSH_ADDR=`grep "ssh " ${LOG_FILE} | tail -n 1 | sed -e 's/^.*username/username/'`

  is_empty "${SSH_ADDR}" \
    && delete_group ${RESOURCE_GROUP}

  # Create an id RSA for the coordenator
  ssh ${SSH_ADDR} "ssh-keygen -f ~/.ssh/id_rsa -t rsa -N '' "

  # copy coordinator (master) credential to all slaves
  scp ${SSH_ADDR}:.ssh/id_rsa.pub ${LOG_DIR}/id_rsa_coodinator_${RESOURCE_GROUP}.pub
  for hostname in `grep "ssh " ${LOG_FILE} | sed -e 's/^.*@//'`; do
      # echo "Put ssh key on $hostname"
      ssh-copy-id -f -i ${LOG_DIR}/id_rsa_coodinator_${RESOURCE_GROUP}.pub "username@${hostname}"
  done

  # repeat process for each vm
  ssh ${SSH_ADDR} << EOF
      set -x
      # Add all nodes to known hosts and copy the private key to all machines
      rm ~/.ssh/known_hosts
      for host in \`seq 4 $((${NUMBER_INSTANCES}+3))\`; do
          ssh-keyscan -H "10.0.0.\${host}" >> ~/.ssh/known_hosts
          scp .ssh/id_rsa .ssh/id_rsa.pub "10.0.0.\${host}":.ssh
      done
      # Copy known host that contains all machines to all machines
      for host in \`seq 4 $((${NUMBER_INSTANCES}+3))\`; do
          scp .ssh/known_hosts "10.0.0.\${host}":.ssh
      done
EOF

  echo $SSH_ADDR >> ssh_addrs
}

create_image() {
  local IMG_NAME=$1
  local IMG_RESOURCE_GROUP=$2

  local IMG_IMAGE=$3
  local LOCATION=$4

  local PACKAGES_FILE=$5

  local IMG_VM_NAME=myVM
  local IMG_USERNAME=username

  create_group $IMG_RESOURCE_GROUP $LOCATION

  az vm create $VERBOSE --resource-group $IMG_RESOURCE_GROUP \
                        --name $IMG_VM_NAME \
                        --image $IMG_IMAGE \
                        --admin-username $IMG_USERNAME \
                        --generate-ssh-keys > tmp_img_$RESOURCE_GROUP_$IMG_VM_NAME.out

  local SSH_ADDR=${IMG_USERNAME}@$( grep "publicIpAddress" tmp_img_$RESOURCE_GROUP_$IMG_VM_NAME.out | \
                    cut -c 23- | \
                    sed 's/..$//')

  local PACKAGES

  for i in $(cat $PACKAGES_FILE)
  do
    PACKAGES="$PACKAGES $i"
  done



  ssh $SSH_ADDR << EOF

  #check network connection
  local ATTEMPTS=0
  while [ $(nc -zw1 google.com 443) ] && [ "$ATTEMPTS" -lt 6 ]; do
    sleep 15
    ATTEMPTS=$((ATTEMPTS+1))
  done

  sudo apt-get update -y
  sudo apt-get -qq install -y $PACKAGES

  sudo waagent -deprovision+user -force


EOF

  # To create an image, the VM needs to be deallocated
  az vm deallocate $VERBOSE \
    --resource-group $IMG_RESOURCE_GROUP \
    --name $IMG_VM_NAME
  # Finally, set the state of the VM as generalized so the Azure platform knows the VM has been generalized. You can only create an image from a generalized VM.
  az vm generalize $VERBOSE \
    --resource-group $IMG_RESOURCE_GROUP \
    --name $IMG_VM_NAME
  # Now you can create an image of the VM
  az image create $VERBOSE \
    --resource-group $IMG_RESOURCE_GROUP \
    --name $IMG_NAME \
    --source $IMG_VM_NAME > tmp_img_create.log

  echo $(grep "id" tmp_img_create.log | head -1 | cut -c 10- | sed 's/..$//')
}

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

	az group create --name $RESOURCE_GROUP --location ${LOCATION}
  sleep 15

	if [ ! $? -eq 0 ]; then
		msg="Failed to create group ${RESOURCE_GROUP} exiting"
		echo "$msg"
		write_log "$msg"
	    exit
	fi
	write_log "group created"

  touch groups
  echo $RESOURCE_GROUP >> groups
}

delete_group() {
	local RESOURCE_GROUP=$1

	write_log "Deleting group ${RESOURCE_GROUP}"

	az group delete --name $RESOURCE_GROUP --yes --no-wait
}

create_machine() {

  local MACHINE_NAME="${1}unit${RANDOM}"

  local RESOURCE_GROUP=$2
	local TEMPLATE_FILE=$3
	local VM_SIZE=$4

  local ADMIN_PASSWORD=$5
	local PASSMOUNT=$6
  local DISKURL=$7
  local DISKUSERNAME=$8

  local ADMIN_PUB_KEY="$(cat ~/.ssh/id_rsa.pub)"


	local VM_NAME="${1}v${RESOURCE_GROUP}"
	local DNS_LABEL="${RESOURCE_GROUP}dnsprefix${1}"



	write_log "creating machine $MACHINE_NAME $VM_NAME"

	az group deployment create --name "$machine_name" \
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
                                            >> $LOG_FILE

	write_log "machine $MACHINE_NAME $VM_NAME created"
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

  local FILESHARE=${9}

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
                      ${DISKUSERNAME} &
      # create_machine "$machine_name$sufix" $resource_group $template_file $vm_size "$vm_name$sufix" "$dns_label$sufix" "$admin_password" "$password_mount" "$admin_public_key" 	&
	    sleep 20
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

  az storage share create --name ${FILESHARE} \
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

  az storage share delete --name ${FILESHARE} \
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

  # add access credential for all vm's
  for hostname in `grep "ssh " ${LOG_FILE} | sed -e 's/^.*@//' -e 's/.$//'`; do
    echo " Copy id from $hostname"
    ssh-keygen -R $hostname
    ssh-keygen -R `dig +short $hostname`
    ssh-keyscan -H $hostname >> ~/.ssh/known_hosts
  done

  # get the coordinator address
  local SSH_ADDR=`grep "ssh " ${LOG_FILE} | tail -n 1 | sed -e 's/^.*username/username/' -e 's/.$//'`

  is_empty "${SSH_ADDR}" \
    && delete_group ${RESOURCE_GROUP}

  # Create an id RSA for the coordenator
  ssh ${SSH_ADDR} "ssh-keygen -f ~/.ssh/id_rsa -t rsa -N '' "

  # copy coordinator (master) credential to all slaves
  scp ${SSH_ADDR}:.ssh/id_rsa.pub ${LOG_DIR}/id_rsa_coodinator_${RESOURCE_GROUP}.pub
  for hostname in `grep "ssh " ${LOG_FILE} | sed -e 's/^.*@//' -e 's/.$//'`; do
      echo "Put ssh key on $hostname"
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
  echo $SSH_ADDR

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

  az vm create \
  --resource-group $IMG_RESOURCE_GROUP \
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
  az vm deallocate \
    --resource-group $IMG_RESOURCE_GROUP \
    --name $IMG_VM_NAME
  # Finally, set the state of the VM as generalized so the Azure platform knows the VM has been generalized. You can only create an image from a generalized VM.
  az vm generalize \
    --resource-group $IMG_RESOURCE_GROUP \
    --name $IMG_VM_NAME
  # Now you can create an image of the VM
  az image create \
    --resource-group $IMG_RESOURCE_GROUP \
    --name $IMG_NAME \
    --source $IMG_VM_NAME > tmp_img_create.log

  echo $(grep "id" tmp_img_create.log | head -1 | cut -c 10- | sed 's/..$//')
}

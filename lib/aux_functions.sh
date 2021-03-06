die() {
    printf '%s\n' "$1" >&2
    exit 1
}

cmdline() {

  # Initialize all the option variables.
  # This ensures we are not contaminated by variables from the environment.
  local file=
  local verbose=0

  while :; do
      case $1 in
          -h|-\?|--help)
              usage    # Display a usage synopsis.
              exit 0
              ;;
          -v|--verbose)
              verbose=1  # Each -v adds 1 to verbosity.
              export VERBOSE="--verbose"
              ;;
          -x|--debug)
              export DEBUG='-x'
              set -x
              ;;
          -d|--not-delete)
              export DELETE="no"
              ;;
          -l|--location)
              if [ "$2" ]; then
                  export LOCATION=$2
                  shift
              else
                die 'ERROR: "--location" requires a non-empty option argument.'
              fi
              ;;
          -f|--file)
              if [ "$2" ]; then
                  export CONFIG_FILE=$2
                  shift
              else
                die 'ERROR: "--file" requires a non-empty option argument.'
              fi
              ;;
          -w|--overwrite)
              export FORCE="1"
            ;;
          -s|--subscription)
            if [ "$2" ]; then
              export SUBSCRIPTION=$2
              shift
            else
              die 'ERROR: "--subscription" requires a non-empty option argument.'
            fi
            ;;
          --)              # End of all options.
              shift
              break
              ;;
          -?*)
              printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
              ;;
          *)               # Default case: No more options, so break out of the loop.
              break
      esac

      shift
  done

  # if --file was provided, open it for writing, else duplicate stdout
  if [ "$file" ]; then
      exec 3> "$file"
  else
      exec 3>&1
  fi
}

usage() {
    cat << EOF
    usage: $PROGNAME [-f,--file] <PATH_TO_FILE> [options]

    Program create a cloud enviroment in Microsoft Azure.
    The information, parameters about the cluster instance  configuration and the behavior of the launcher is defined on a configure file.

    OPTIONS:
       -h --help            Configuration file containing the rules
       -f --file            File with cluster
       -v --verbose         Increase verbose log
       -d --not-delete      Dont delete the resource group. (by default the group will be deleted)
       -l --location        Location in azure
       -s --subscription    Azure subscription
       -x --debug           Increase verbose

    Examples:
       Simple run:
       $PROGNAME -f example.config

       Run and view program status:
       $PROGNAME -v -f example.config
       
EOF
}


is_empty() {
    local var=$1

    [[ -z $var ]]
}

is_not_empty() {
    local var=$1

    [[ -n $var ]]
}

is_file() {
    local file=$1

    [[ -f $file ]]
}

is_dir() {
    local dir=$1

    [[ -d $dir ]]
}

is_not_dir() {
    local dir=$1

    [[ ! -d $dir ]]
}

to_lower_case() {
  local var=$1

  echo $(sed 's/./\L&/g' <<<$var)
}

remove_special_characters() {
  local var=$1

  echo $(sed 's/[^a-zA-Z0-9]//g' <<<$var)
}

check_network_connection() {
  #check network conction
  ATTEMPTS=0
  while [ $(nc -zw1 google.com 443) ] && [ "$ATTEMPTS" -lt 6 ]; do
    echo "we have NO connectivity"
    sleep 15
    ATTEMPTS=$((ATTEMPTS+1))
  done
}

get_benchmark() {
local CONFIG_FILE=$1

  echo $(grep -w "benchmark" $CONFIG_FILE | \
                    sed 's/^.*(//' | \
                    sed 's/.$//')
}

get_location() {
local CONFIG_FILE=$1

  echo $(grep -w "location" $CONFIG_FILE | \
                    sed 's/^.*(//' | \
                    sed 's/.$//')
}

get_subscription() {
local CONFIG_FILE=$1

  echo $(grep -w "subscription" $CONFIG_FILE | \
                    sed 's/^.*(//' | \
                    sed 's/.$//')
}

get_cores() {
local CONFIG_FILE=$1

  echo $(grep -w "cores" $CONFIG_FILE | \
                    sed 's/^.*(//' | \
                    sed 's/[^a-zA-Z0-9]/ /g')
}

get_instances() {
local CONFIG_FILE=$1

  echo $(grep -w "instances" $CONFIG_FILE | \
                    sed 's/^.*(//' | \
                    sed 's/[^a-zA-Z0-9]/ /g')
}

get_adminpassword() {
local CONFIG_FILE=$1

  echo $(grep -w "adminpassword" $CONFIG_FILE | \
                    sed 's/^.*(//' | \
                    sed 's/.$//')
}

get_adminusername() {
local CONFIG_FILE=$1

  echo $(grep -w "adminusername" $CONFIG_FILE | \
                    sed 's/^.*(//' | \
                    sed 's/.$//')
}

get_passmount() {
local CONFIG_FILE=$1

  echo $(grep -w "passmount" $CONFIG_FILE | \
                    sed 's/^.*(//' | \
                    sed 's/.$//')
}

get_diskurl() {
local CONFIG_FILE=$1

  echo $(grep -w "diskurl" $CONFIG_FILE | \
                    sed 's/^.*(//' | \
                    sed 's/.$//')
}

get_diskusername() {
local CONFIG_FILE=$1

  echo $(grep -w "diskusername" $CONFIG_FILE | \
                    sed 's/^.*(//' | \
                    sed 's/.$//')
}

get_templatefile() {
  local CONFIG_FILE=$1

  echo $(grep -w "template" $CONFIG_FILE | \
                    sed 's/^.*(//' | \
                    sed 's/.$//')
}

get_vmsize() {
  local CONFIG_FILE=$1

  echo $(grep -w "vmsize" $CONFIG_FILE | \
                    sed 's/^.*(//' | \
                    sed 's/.$//')
}

get_image() {
  local CONFIG_FILE=$1

  echo $(grep -w "image" $CONFIG_FILE | \
                    sed 's/^.*(//' | \
                    sed 's/.$//')
}

get_mode() {
  local CONFIG_FILE=$1

  echo $(grep -w "mode" $CONFIG_FILE | \
                    sed 's/^.*(//' | \
                    sed 's/.$//')
}

get_role() {
  local CONFIG_FILE=$1

  echo $(grep -w "role" $CONFIG_FILE | \
                    sed 's/^.*(//' | \
                    sed 's/.$//')
}

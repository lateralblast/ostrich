#!/usr/bin/env bash

# Name:         ostrich (Old SSH Terminal Remote Interactive Console Helper)
# Version:      0.0.8
# Release:      1
# License:      CC-BA (Creative Commons By Attribution)
#               http://creativecommons.org/licenses/by/4.0/legalcode
# Group:        System
# Source:       N/A
# URL:          http://lateralblast.com.au/
# Distribution: Linux
# Vendor:       UNIX
# Packager:     Richard Spindler <richard@lateralblast.com.au>
# Description:  Shell script for connecting to devices that require old SSH ciphers

# shellcheck disable=SC2034

# Set defaults

do_verbose="false"
do_print_help="false"
do_print_version="false"
use_ssh="true"
use_scp="false"
do_strict="true"
do_debug="false"
do_dryrun="false"
do_check_docker="false"
exit_check_docker="false"
command=""
user_name=""
host_name=""

# Container name

cont_name="ostrich"

# Get command line args

cli_args="$*"

# Default SSH / SCP options

ssh_opts="-oKexAlgorithms=+diffie-hellman-group1-sha1 -oStrictHostKeyChecking=no"

# Get the script info from the script itself

app_vers=$( grep "^# Version" "$0" | awk '{print $3}' )
app_name=$( grep "^# Name" "$0" | awk '{for (i=3;i<=NF;++i) printf $i" "}' | sed 's/ $//g' )
app_pkgr=$( grep "^# Packager" "$0" | awk '{for (i=3;i<=NF;++i) printf $i" "}' )
app_help=$( grep -A1 "\-[A-Z,a-z]|" "$0" | sed "s/^\-\-//g" | sed "s/# //g" | tr -s " " )

# Print help

print_help() {
  echo "$app_name $app_vers"
  echo "$app_pkgr"
  echo ""
  echo "Usage Information:"
  echo ""
  echo "$app_help"
  return
}

# Print version

print_version () {
  echo "$app_vers"
  return
}

# Handle output

handle_output () {
  output="$1"
  type="$2"
  if [ "$do_verbose" = "true" ]; then
    case $type in
      exec)
        echo "Executing:   $output"
        ;;
      info)
        echo "Information: $output"
        ;;
      warn)
        echo "Warning:     $output"
        ;;
      *)
        echo "$output"
        ;;
    esac
  fi
  return
}

# Execute command

execute_command () {
  command="$1"
  handle_output "$command" "exec"
  if [ "$do_dryrun" = "false" ]; then
    eval "$command"
  fi
  return
}

# Check docker

check_docker () {
  handle_output "Checking docker" "info"
  test=$(which docker |grep -v found)
  if [[ ! "$test" =~ "docker" ]]; then
    handle_output "docker not installed" "warn"
    exit
  else
    handle_output "Found $test" "info"
  fi
  handle_output "Checking docker-compose" "info"
  test=$(which docker-compose |grep -v found)
  if [[ ! "$test" =~ "docker" ]]; then
    handle_output "docker-compose not installed" "warn"
    exit
  else
    handle_output "Found $test" "info"
  fi
  return
}

# If given no arguments print help

if [ "$cli_args" = "" ]; then
  print_help
  exit
fi

# If given verbose switch set verbose mode

if [[ "$cli_args" =~ "verbose" ]]; then
  do_verbose="true"
fi

# Handle command line arguments

while test $# -gt 0; do
  case $1 in
    -a|--addopts|--addoptions)
      # Additional SSH options
      ssh_opts="$ssh_opts $2"
      shift
      ;;
    -C|--check|--checkdocker)
      # Check Docker install
      do_verbose="true"
      do_check_docker="true"
      exit_check_docker="true"
      shift
      ;;
    -c|--copy|--scp)
      # Source file to copy (SCP)
      do_check_docker="true"
      use_scp="true"
      use_ssh="false"
      source_file="$2"
      shift 2
      ;;
    -d|--dest|--destination)
      # Destination file (SCP)
      do_check_docker="true"
      dest_file="$2"
      shift 2
      ;;
    -D|--debug)
      # Enable debug mode
      do_debug="true"
      shift
      ;;
    -h|--help|--usage)
      # Display help
      do_print_help="true"
      shift
      ;;
    -n|--nostrict)
      # Disable strict mode
      do_strict="false"
      shift
      ;;
    -o|--opts|--options)
      # SSH/SCP Options
      do_check_docker="true"
      ssh_opts="$2"
      shift 2
      ;;
    -r|--dryrun)
      # Dry run
      do_dryrun="true"
      shift
      ;;
    -s|--host|--hostname)
      # Specify hostname
      host_name="$2"
      shift 2
      ;;
    -t|--tag|--name)
      # Container name
      cont_name="$2"
      shift 2
      ;;
    -V|--version)
      # Display Version
      do_print_version="true"
      shift
      ;;
    -v|--verbose)
      # Enable verbose mode
      do_verbose="true"
      shift
      ;;
    -u|--user|--username)
      # Specify username
      user_name="$2"
      shift 2
      ;;
    *)
      if [[ ! "$1" =~ ^-- ]]; then
        if [[ "$1" =~ "@" ]]; then
          command="$1"
          if [[ "$1" =~ ":" ]]; then
            use_scp="true"
            use_ssh="false"
          else
            use_scp="false"
            use_ssh="true"
          fi
        else
          source_file="$1"
        fi
      fi
      shift
      ;;
  esac
done

# Print help

if [ "$do_print_help" = "true" ]; then
  print_help
  exit
fi

# Print version

if [ "$do_print_version" = "true" ]; then
  print_version
  exit
fi

# Enable strict mode

if [ "$do_strict" = "true" ]; then
  set -eu
fi

# Enable debug mode

if [ "$do_debug" = "true" ]; then
  set -x
fi

# Check user is set

if [ "$user_name" = "" ]; then
  user_name=$(whoami)
fi

# Check docker is installed

if [ "$do_check_docker" = "true" ]; then
  check_docker
fi

# Check host is set

if [ "$host_name" = "" ]; then
  if [ "$command" = "" ]; then
    handle_output "No host specified" "warn"
    exit
  fi
fi

# Check container exists

cont_test=$( docker images | awk '{print $1}' | grep "$cont_name" | wc -l | sed "s/ //g" )

if [ "$cont_test" = "0" ]; then
  if [ -f "docker-compose.yml" ]; then
    execute_command "docker-compose build"
  fi
fi
if [ "$exit_check_docker" = "true" ]; then
  exit
fi

# Strip directory name from file mapped into docker

if [ "$use_scp" = "true" ]; then
  map_file=$( basename -- "$source_file" )
fi

# Run command SSH/SCP inside docker container to connect to host

if [ "$use_scp" = "true" ]; then
  if [ "$command" = "" ]; then
    command="docker run -v $source_file:/tmp/$map_file -it $cont_name /bin/bash -c \"scp $ssh_opts /tmp/$map_file $user_name@$host_name:$dest_file\""
  else
    command="docker run -v $source_file:/tmp/$map_file -it $cont_name /bin/bash -c \"scp $ssh_opts /tmp/$map_file $command\""
  fi
else
  if [ "$command" = "" ]; then
    command="docker run -it $cont_name /bin/bash -c \"ssh $ssh_opts $user_name@$host_name\""
  else
    command="docker run -it $cont_name /bin/bash -c \"ssh $ssh_opts $command\""
  fi
fi

execute_command "$command"

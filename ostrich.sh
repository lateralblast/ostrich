#!/usr/bin/env bash

# Name:         ostrich (Old SSH Terminal Remote Interactive Console Helper)
# Version:      0.0.7
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

verbose="false"
do_print_help="false"
do_print_version="false"
use_ssh="true"
use_scp="false"
do_strict="true"
do_debug="false"

# Container name

cont_name="ostrich"

# Get command line args

args="$*"

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
  if [ "$verbose" = "true" ]; then
    case $type in
      execute)
        echo "Executing: $output"
        ;;
      *)
        echo "$output"
        ;;
    esac
  fi
  return
}

# Check docker

check_docker () {
  handle_output "Information: Checking docker"
  test=$(which docker |grep -v found)
  if [[ ! "$test" =~ "docker" ]]; then
    echo "Warning: docker not installed"
    exit
  else
    handle_output "Information: Found $test"
  fi
  handle_output "Information: Checking docker-compose"
  test=$(which docker-compose |grep -v found)
  if [[ ! "$test" =~ "docker" ]]; then
    echo "Warning: docker-compose not installed"
    exit
  else
    handle_output "Information: Found $test"
  fi
  return
}

# If given no command line arguments print usage information
# Handle when give @ in first argument

if [[ "$args" =~ "-" ]]; then
  if [ "$1" ]; then
    if [ "$2" ]; then
      if [ "$2" == "--verbose" ]; then
        test=$(echo "$1" |grep "@")
        if [ "$test" ]; then
          user_name=$(echo "$1" |cut -f1 -d@)
          host_name=$(echo "$1" |cut -f2 -d@)
        else
          user_name=$(whoami)
          host_name=$1
        fi
        user_name=$(whoami)
        host_name=$1
      else
        test=$(echo "$2" |grep ":")
        if [ "$test" ]; then
          use_ssh="false"
          use_scp="true"
          src_file="$1"
          details=$(echo "$2" |cut -f1 -d: |tr -d '\r')
          dst_file=$(echo "$2" |cut -f2 -d:)
          if [ "$dst_file" = "" ]; then
            dst_file=$src_file
          fi
          test=$(echo "$details" |grep "@")
          if [ "$test" ]; then
            user_name=$(echo "$details" |cut -f1 -d@)
            host_name=$(echo "$details" |cut -f2 -d@)
          else
            user_name=$(whoami)
            host_name=$details
          fi
        else
          echo "No destination file specified"
          exit
        fi
      fi
    else
      test=$(echo "$1" |grep "@")
      if [ "$test" ]; then
        user_name=$(echo "$1" |cut -f1 -d@)
        host_name=$(echo "$1" |cut -f2 -d@)
      else
        user_name=$(whoami)
        host_name=$1
      fi
    fi
  else
    print_help
    exit
  fi
fi

# Handle arguments

while test $# -gt 0; do
  case $args in
    -C|--check|--checkdocker)
      # Check Docker install
      verbose="true"
      do_check_docker="true"
      shift
      ;;
    -c|--copy|--scp)
      # Source file to copy (SCP)
      do_check_docker="true"
      use_scp="true"
      use_ssh="false"
      src_file="$2"
      shift 2
      ;;
    -d|--dest|--destination)
      # Destination file (SCP)
      do_check_docker="true"
      dst_file="$2"
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
      new_opts="$2"
      shift 2
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
      verbose="true"
      shift
      ;;
    -u|--user|--username)
      # Specify username
      user_name="$2"
      shift 2
      ;;
    *)
      # Display help
      do_print_help="true"
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

if [ ! "$user_name" ]; then
  user_name=$(whoami)
fi

# Check docker is installed

if [ "$do_check_docker" = "true" ]; then
  check_docker
fi

# Check host is set

if [ -z "$host_name" ]; then
  echo "No host specified"
  exit
fi

# Check container exists

test=$(docker images |awk '{print $1}' |grep "$cont_name")

if [ -z "$test" ]; then
  if [ -f "docker-compose.yml" ]; then
    docker-compose build
  fi
fi

# Handle options

if [ "$new_opts" ]; then
  ssh_opts=$new_opts
fi

# Strip directory name from file mapped into docker

if [ "$use_scp" = "true" ]; then
  map_file=$( basename -- "$src_file" )
fi

# Run command SSH/SCP inside docker container to connect to host

if [ "$use_scp" = "true" ]; then
  command="docker run -v $src_file:/tmp/$map_file -it $cont_name /bin/bash -c \"scp $ssh_opts /tmp/$map_file $user_name@$host_name:$dst_file\""
else
  command="docker run -it $cont_name /bin/bash -c \"ssh $ssh_opts $user_name@$host_name\""
fi
handle_output "$command" "execute"
eval "$command"

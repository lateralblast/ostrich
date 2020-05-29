#!/bin/bash

# Name:         ostrich (Old SSH Terminal Remote Interactive Console Helper)
# Version:      0.0.2
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

# Set defaults

verbose="false"

# Container name

name="ostrich"

# Get command line args

args=$@

# Default SSH / SCP options

opts="-oKexAlgorithms=+diffie-hellman-group1-sha1 -oStrictHostKeyChecking=no"

# Get the script info from the script itself

app_vers=$(grep "^# Version" "$0" |awk '{print $3}')
app_name=$(grep "^# Name" "$0" |awk '{for (i=3;i<=NF;++i) printf $i" "}' |sed 's/ $//g')
app_pkgr=$(grep "^# Packager" "$0" |awk '{for (i=3;i<=NF;++i) printf $i" "}')
app_help=$(grep -A1 " [A-Z,a-z])$" "$0" |sed "s/[#,\-\-]//g" |sed '/^\s*$/d')

# Print help

print_help() {
  echo "$app_name $app_vers"
  echo "$app_pkgr"
  echo ""
  echo "Usage Information:"
  echo ""
  echo "$app_help"
  echo ""
  return
}

# Print version

print_version () {
  echo "$app_vers"
  return
}

# Handle SCP and SSH

use_ssh="true"
use_scp="false"

# If given no command line arguments print usage information
# Handle when give @ in first argument

if [ `expr "$args" : "\-"` != 1 ]; then
  if [ "$1" ]; then
    if [ "$2" ]; then
      if [ "$2" == "--verbose" ]; then
        test=$(echo "$1" |grep "@")
        if [ "$test" ]; then
          user=$(echo "$1" |cut -f1 -d@)
          host=$(echo "$1" |cut -f2 -d@)
        else
          user=$(whoami)
          host=$1
        fi
        user=$(whoami)
        host=$1
      else
        test=$(echo "$2" |grep ":")
        if [ "$test" ]; then
          use_ssh="false"
          use_scp="true"
          src_file=$1
          details=$(echo "$2" |cut -f1 -d: |tr -d '\r')
          dst_file=$(echo "$2" |cut -f2 -d:)
          if [ "$dst_file" = "" ]; then
            dst_file=$src_file
          fi
          test=$(echo "$details" |grep "@")
          if [ "$test" ]; then
            user=$(echo "$details" |cut -f1 -d@)
            host=$(echo "$details" |cut -f2 -d@)
          else
            user=$(whoami)
            host=$details
          fi
        else
          echo "No destination file specified"
          exit
        fi
      fi
    else
      test=$(echo "$1" |grep "@")
      if [ "$test" ]; then
        user=$(echo "$1" |cut -f1 -d@)
        host=$(echo "$1" |cut -f2 -d@)
      else
        user=$(whoami)
        host=$1
      fi
    fi
  else
    print_help
    exit
  fi
fi

# Handle --help

if [ "$1" = "--help" ]; then
  print_help
  exit
fi

# Handle --version

if [ "$1" = "--version" ]; then
  print_version
  exit
fi

# Handle --verbose

if [ "$2" = "--verbose" ] || [ "$3" = "--verbose" ]; then
  verbose="true"
fi

# Handle arguments

if [ ! "$user" ]; then
  while getopts ":hvVu:s:o:c:d:" args ; do
    case $args in
      h)
        # Display help
        print_help
        exit
        ;;
      V)
        # Display Version
        print_version
        exit
        ;;
      c)
        # Source file to copy (SCP)
        use_scp="true"
        use_ssh="false"
        src_file=$OPTARG
        ;;
      d)
        # Destination file (SCP)
        dst_file=$OPTARG
        ;;
      v)
        # Verbose mode
        verbose="true"
        ;;
      u)
        # Username
        user=$OPTARG
        ;;
      s)
        # Hostname
        host=$OPTARG
        ;;
      o)
        # SSH/SCP Option
        new_opts=$OPTARG
        ;;
      *)
        # Display help
        print_help
        ;;
    esac
  done
fi

# Check user is set

if [ ! "$user" ]; then
  user=$(whoami)
fi

# Check host is set

if [ ! "$host" ]; then
  echo "No host specified"
  exit
fi

# Check container exists

test=$(docker images |awk '{print $1}' |grep "$name")

if [ ! "$test" ]; then
  if [ -f "docker-compose.yml" ]; then
    docker-compose build
  fi
fi

# Handle options

if [ "$new_opts" ]; then
  opts=$new_opts
fi

# Strip directory name from file mapped into docker

if [ "$use_scp" = "true" ]; then
  map_file=$(basename -- $src_file)
fi

# Call docker

if [ "$verbose" = "true" ]; then
  if [ "$use_scp" = "true" ]; then
    echo "Executing: docker run -v $src_file:/tmp/$map_file -it $name /bin/bash -c \"scp $opts /tmp/$map_file $user@$host:$dst_file\""
  else
    echo "Executing: docker run -it $name /bin/bash -c \"ssh $opts $user@$host\"" 
  fi
fi

# Run command SSH/SCP inside docker container to connect to host

if [ "$use_scp" = "true" ]; then
  docker run -v $src_file:/tmp/$map_file -it $name /bin/bash -c "scp $opts /tmp/$map_file $user@$host:$dst_file"
else
  docker run -it $name /bin/bash -c "ssh $opts $user@$host"
fi

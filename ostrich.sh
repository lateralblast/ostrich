#!/bin/bash

# Name:         ostrich (Old SSH Terminal Remote Interactive Console Helper)
# Version:      0.0.1
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

# Get the script info from the script itself

app_vers=$(grep "^# Version" "$0" |awk '{print $3}')
app_name=$(grep "^# Name" "$0" |awk '{for (i=3;i<=NF;++i) printf $i" "}' |sed 's/ $//g')
app_same=$(grep "^# Name" "$0" |awk '{print $3}')
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

# If given no command line arguments print usage information
# Handle when give @ in first argument

if [ `expr "$args" : "\-"` != 1 ]; then
  if [ "$1" ]; then
    test=$(echo "$1" |grep "@")
    if [ "$test" ]; then
      user=$(echo "$1" |cut -f1 -d@)
      host=$(echo "$1" |cut -f2 -d@)
    else
      user=$(whoami)
      host=$1
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

if [ "$1" = "--verbose" ] || [ "$2" = "--verbose" ]; then
  verbose="true"
fi

# Handle arguments

if [ ! "$user" ]; then
  while getopts ":hvVu:s:o:" args ; do
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
        # SSH Option
        opts=$OPTARG
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

if [ "$opts" ]; then
  opts="-o KexAlgorithms=diffie-hellman-group1-sha1 -o StrictHostKeyChecking=no -o $opts"
else
  opts="-o KexAlgorithms=diffie-hellman-group1-sha1 -o StrictHostKeyChecking=no"
fi

# Call docker

if [ "$verbose" = "true" ]; then
  echo "Executing: docker run -it $name /bin/bash -c \"ssh $opts $user@$host\"" 
fi

docker run -it $name /bin/bash -c "ssh $opts $user@$host"

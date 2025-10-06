#!/usr/bin/env bash

# Name:         ostrich (Old SSH Terminal Remote Interactive Console Helper)
# Version:      0.1.1
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

# Create arrays

declare -A os
declare -A script
declare -A options
declare -a options_list
declare -a actions_list

# Grab script information and put it into an associative array

script['args']="$*"
script['file']="$0"
script['name']="ostrich"
script['file']=$( realpath "${script['file']}" )
script['path']=$( dirname "${script['file']}" )
script['modulepath']="${script['path']}/modules"
script['bin']=$( basename "${script['file']}" )
script['user']=$( id -u -n )

# Function: set_defaults
#
# Set defaults

set_defaults () {
  options['verbose']="true"                                                                     # option : Verbose mode
  options["ssh"]="true"                                                                         # option : SSH mode
  options['scp']="false"                                                                        # option : SCP mode
  options['strict']="false"                                                                     # option : Strict mode
  options['oldkex']="false"                                                                     # option : Use old key exchange algorithms
  options['debug']="false"                                                                      # option : Debug mode
  options['dryrun']="false"                                                                     # option : Dryrun mode
  options['username']="${script['user']}"                                                       # option : SSH username
  options['hostname']=""                                                                        # option : Hostname to SSH to
  options['source']=""                                                                          # option : Source file
  options['command']=""                                                                         # option : Command to run via SSH
  options['docker']=""                                                                          # option : Docker command
  options['destination']=""                                                                     # option : Destination file
  options['builddir']="/tmp/${script['name']}"                                                  # option : Docker build directory
  options['dockerfile']="${options['builddir']}/Dockerfile"                                     # option : Docker file
  options['composefile']="${options['builddir']}/docker-compose.yml"                            # option : Compose file
  options['container']="${script['name']}"                                                      # option : Container name/tag
  options['sshargs']=""                                                                         # option : SSH options
  options['mapfile']=""
  options['mapdir']=""
}

# Function: print_message
#
# Print message

print_message () {
  message="$1"
  format="$2"
  if [ "${format}" = "verbose" ]; then
    echo "${message}"
  else
    if [[ "${format}" =~ warn ]]; then
      echo -e "Warning:\t${message}"
    else
      if [ "${options['verbose']}" = "true" ]; then
        if [[ "${format}" =~ ing$ ]]; then
          format="${format^}"
        else
          if [[ "${format}" =~ t$ ]]; then
            if [ "${format}" = "test" ]; then
              format="${format}ing"
            else
              format="${format^}ting"
            fi
          else
            if [[ "${format}" =~ e$ ]]; then
              if ! [[ "${format}" =~ otice ]]; then
                format="${format::-1}"
                format="${format^}ing"
              fi
            fi
          fi
        fi
        format="${format^}"
        length="${#format}"
        if [ "${length}" -lt 7 ]; then
          tabs="\t\t"
        else
          tabs="\t"
        fi
        echo -e "${format}:${tabs}${message}"
      fi
    fi
  fi
}

# Function: verbose_message
#
# Verbose message

verbose_message () {
  message="$1"
  print_message "${message}" "verbose"
}

# Function: warning_message
#
# Warning message

warning_message () {
  message="$1"
  print_message "${message}" "warn"
}

# Function: execute_message
#
#  Print command

execute_message () {
  message="$1"
  print_message "${message}" "execute"
}

# Function: notice_message
#
# Notice message

notice_message () {
  message="$1"
  verbose_message "${message}" "notice"
}

# Function: notice_message
#
# Information Message

information_message () {
  message="$1"
  verbose_message "${message}" "info"
}

# Load modules

if [ -d "${script['modulepath']}" ]; then
  modules=$( find "${script['modulepath']}" -name "*.sh" )
  for module in ${modules}; do
    if [[ "${script['args']}" =~ "verbose" ]]; then
     print_message "Module ${module}" "load"
    fi
    . "${module}"
  done
fi

# Function: execute_docker
#
# Execute docker environment

execute_docker_command () {
  if [ "${options['ssh']}" = "true" ]; then
    execute_command "docker run -it ${options['container']} /bin/bash -c \"${options['command']}\""
  else
    if [ "${options['mapdir']}" = "" ]; then
      if [ -f "${options['source']}" ]; then
        options['mapfile']=$( basename -- "${options['source']}" )
        execute_command "docker run -v ${options['source']}:${options['mapfile']} -it ${options['container']} /bin/bash -c \"scp ${options['sshargs']} ${options['mapfile']} ${options['username']}@${options['hostname']}:${options['destination']}\""
      else
        warning_message "File \"${options['source']}\""
      fi
    else
      options['mapdir']=$( dirname "${options['destination']}" )
      if ! [ -d "${options['mapdir']}" ]; then
        execute_command "mkdir -p ${options['mapdir']}"
      fi
      execute_command "docker run -v ${options['mapdir']}:${options['mapdir']} -it ${options['container']} /bin/bash -c \"scp ${options['sshargs']} ${options['username']}@${options['hostname']}:${options['source']} ${options['destination']}\""
    fi
  fi
}

# Function: execute_docker
#
# Execute docker environment

execute_docker () {
  if [ "${options['scp']}" = "true" ] || [ "${options['ssh']}" = "true" ]; then
    if [ "${options['hostname']}" = "" ]; then
      warning_message "Hostname not specified"
      do_exit
    fi
    if [ "${options['username']}" = "" ]; then
      warning_message "Username not specified"
      do_exit
    fi
  fi
}


# Function: reset_defaults
#
# Reset defaults based on command line options

reset_defaults () {
  if [ "${options['strict']}" = "false" ]; then
    options['sshargs']="-oStrictHostKeyChecking=no ${options['sshargs']}"
  fi
  if [ "${options['oldkex']}" = "true" ]; then
    options['sshargs']="-oKexAlgorithms=+diffie-hellman-group1-sha1 ${options['sshargs']}"
  fi
  if [ "${options['debug']}" = "true" ]; then
    set -x
  fi
  if [ "${options['scp']}" = "true" ]; then
    options['mapfile']=$( basename -- "${options['source']}" )
    options['docker']="docker run -v ${options['source']}:/tmp/${options['mapfile']} -it ${options['container']} /bin/bash -c \"scp ${options['sshargs']} /tmp/${options['mapfile']} ${options['username']}@${options['hostname']}:${options['destination']}\""
  else
    options['docker']="docker run -it ${options['container']} /bin/bash -c \"ssh ${options['sshargs']} ${options['username']}@${options['hostname']} ${options['command']}\""
  fi
}

# Function: do_exit
#
# Selective exit (don't exit when we're running in dryrun mode)

do_exit () {
  if [ "${options['dryrun']}" = "false" ]; then
    exit
  fi
}

# Function: execute_command
#
# Execute command

execute_command () {
  command="$1"
  privilege="$2"
  if [[ "${privilege}" =~ su ]]; then
    command="sudo sh -c \"${command}\""
  fi
  if [ "${options['verbose']}" = "true" ] || [ "${options['dryrun']}" = "true" ]; then
    execute_message "${command}"
  fi
  if [ "${options['dryrun']}" = "false" ]; then
    eval "${command}"
  fi
}

# Function: check_value
#
# check value (make sure that command line arguments that take values have values)

check_value () {
  param="$1"
  value="$2"
  if [[ ${value} =~ ^-- ]]; then
    warning_message "Value \"${value}\" for parameter \"${param}\" looks like a parameter" "verbose"
    echo ""
    if [ "${options['force']}" = "false" ]; then
      do_exit
    fi
  else
    if [ "${value}" = "" ]; then
      warning_message "No value given for parameter \"${param}\"" "verbose"
      echo ""
      if [[ "${param}" =~ option ]]; then
        print_options
      else
        if [[ "${param}" =~ action ]]; then
          print_actions
        else
          print_help
        fi
      fi
      do_exit
    fi
  fi
}

# Function: print_info
#
# Print information

print_info () {
  info="$1"
  echo ""
  echo "Usage: ${script['bin']} --action(s) [action(,action)] --option(s) [option(,option)]"
  echo ""
  if [[ ${info} =~ switch ]]; then
    echo "${info}(es):"
    echo "-----------"
  else
    echo "${info}(s):"
    echo "----------"
  fi
  while read -r line; do
    if [[ "${line}" =~ .*"# ${info}".* ]]; then
      if [[ "${info}" =~ option ]]; then
        IFS=':' read -r param desc <<< "${line}"
        IFS=']' read -r param default <<< "${param}"
        IFS='[' read -r _ param <<< "${param}"
        param="${param//\'/}"
        default="${options[${param}]}"
        if [ "${param}" = "mask" ]; then
          default="false"
        else
          if [ "${options['mask']}" = "true" ]; then
            default="${default/${script['user']}/user}"
          fi
        fi
        param="${param} (default = ${default})"
      else
        IFS='#' read -r param desc <<< "${line}"
        desc="${desc/${info} :/}"
      fi
      echo "${param}"
      echo "  ${desc}"
    fi
  done < "${script['file']}"
  echo ""
}

# Function: print_help
#
# Print help/usage insformation

print_help () {
  print_info "switch"
}

# Function print_actions
#
# Print actions

print_actions () {
  print_info "action"
}

# Function: print_options
#
# Print options

print_options () {
  print_info "option"
}

# Function: print_usage
#
# Print Usage

print_usage () {
  usage="$1"
  case $usage in
    all|full)
      print_help
      print_actions
      print_options
      ;;
    help)
      print_help
      ;;
    action*)
      print_actions
      ;;
    option*)
      print_options
      ;;
    *)
      print_help
      shift
      ;;
  esac
}

# Function: print_version
#
# Print version information

print_version () {
  script['version']=$( grep '^# Version' < "$0" | awk '{print $3}' )
  echo "${script['version']}"
}

# Function: check_shellcheck
#
# Run Shellcheck

check_shellcheck () {
  bin_test=$( command -v shellcheck | grep -c shellcheck )
  if ! [ "$bin_test" = "0" ]; then
    shellcheck "${script['file']}"
  fi
}

# Function: execute_command
#
# Execute command

execute_command () {
  command="$1"
  privilege="$2"
  if [[ "${privilege}" =~ su ]]; then
    command="sudo sh -c \"${command}\""
  fi
  if [ "${options['verbose']}" = "true" ]; then
    execute_message "${command}"
  fi
  if [ "${options['dryrun']}" = "false" ]; then
    eval "${command}"
  fi
}

# Function: check_docker
#
# Check docker

check_docker () {
  information_message "Checking docker"
  test=$( command -v docker | grep -c docker )
  if [ "${test}" -eq 0 ]; then
    warning_message "Docker not installed"
    do_exit
  fi
  information_message "Checking docker-compose"
  test=$( command -v docker-compose | grep -c docker-compose )
  if [ "${test}" -eq 0 ]; then
    warning_message "docker-compose not installed"
    do_exit
  fi
  test=$( docker images | awk '{print $1}' | grep -v REPOSITORY | grep -c "${options['container']}" )
  if [ "${test}" -eq 0 ]; then
    if ! [ -d "${options['builddir']}" ]; then
      execute_command "mkdir -p ${options['builddir']}"
    fi
    if ! [ -f "${options['composefile']}" ]; then
      tee "${options['composefile']}" << COMPOSEFILE
services:
  ${options['container']}:
    build:
      context: .
      dockerfile: Dockerfile
    image: ${options['container']}
    container_name: ${options['container']}
    entrypoint: /bin/bash
    working_dir: /root
COMPOSEFILE
    fi
    if ! [ -f "${options['dockerfile']}" ]; then
      tee "${options['dockerfile']}" << DOCKERFILE
FROM ubuntu:16.04
RUN apt-get update && apt-get install -y openssh-client
DOCKERFILE
    fi
    if [ -f "${options['composefile']}" ] && [ -f "${options['dockerfile']}" ]; then
      execute_command "cd ${options['builddir']} ; docker-compose build"
    else
      warning_message "No Docker or compose file found"
      do_exit
    fi
  fi
}

# Function: process_actions
#
# Handle actions

process_actions () {
  actions="$1"
  case $actions in
    check*)               # action : Check docker
      check_docker
      do_exit
      ;;
    shell*)               # action : Run shellcheck against script
      check_shellcheck
      ;;
    *)
      print_help
      ;;
  esac
}

# Function: process_options
#
# Handle options

process_options () {
  option="$1"
  if [[ "${option}" =~ ^no|^un|^dont ]]; then
    options["${option}"]="true"
    if [[ "${option}" =~ ^dont ]]; then
      option="${option:4}"
    else
      option="${option:2}"
    fi
    value="false"
  else
    value="true"
  fi
  options["${option}"]="${value}"
  print_message "${option} to ${value}" "set"
}

# If given no arguments print help

if [ "${script['args']}" = "" ]; then
  print_help
  exit
fi

# If given verbose switch set verbose mode

if [[ "${script['args']}" =~ verbose ]]; then
  options="true"
fi

# Set defaults

set_defaults

# Handle command line arguments

while test $# -gt 0; do
  case $1 in
    --action*)                        # switch : Action(s) to perform
      check_value "$1" "$2"
      actions_list+=("$2")
      shift 2
      ;;
    -a|--addopts|--addoptions)        # switch : Additional SSH options
      check_value "$1" "$2"
      options['sshargs']="${options['sshargs']} $2"
      shift 2
      ;;
    -C|--check|--checkdocker)         # switch : Check Docker install
      actions_list+=("checkdocker")
      shift
      ;;
    -c|--copy|--scp)                  # switch: Source file to copy (SCP)
      check_value "$1" "$2"
      actions_list+=("scp")
      options['scp']="true"
      options['ssh']="false"
      options['source']="$2"
      shift 2
      ;;
    -d|--dest|--destination)          # switch : Destination file (SCP)
      check_value "$1" "$2"
      options['destination']="$2"
      shift 2
      ;;
    -X|--dockerfile)                  # switch : Docker file
      check_value "$1" "$2"
      options['dockerfile']="$2"
      shift 2
      ;;
    -Y|--composefile)                 # switch : Docker compose file
      check_value "$1" "$2"
      options['composefile']="$2"
      shift 2
      ;;
    -D|--debug)                       # swtich : Enable debug mode
      options['debug']="true"
      shift
      ;;
    -h|--help)                        # switch : Display help
      print_help
      shift
      exit
      ;;
    -O|--oldkex)                      # switch : Enable old key exchange algorithms
      options['oldkex']="true"
      shift
      ;;
    -N|--nooldkex)                    # switch : Disable old key exchange algorithms
      options['oldkex']="false"
      shift
      ;;
    -S|--strict)                      # switch : Enable strict mode
      options['strict']="true"
      shift
      ;;
    -n|--nostrict)                    # switch : Disable strict mode
      options['strict']="false"
      shift
      ;;
    -o|--opts|--options)              # switch : SSH/SCP Options
      check_value "$1" "$2"
      options['sshargs']+="$2"
      shift 2
      ;;
    -r|--dryrun)                      # switch : Dry run
      options['dryrun']="true"
      shift
      ;;
    -s|--host|--hostname)             # switch : Specify hostname
      check_value "$1" "$2"
      options['hostname']="$2"
      shift 2
      ;;
    -t|--tag|--name)                  # switch : Container name
      check_value "$1" "$2"
      options['container']="$2"
      shift 2
      ;;
    -U|--usage)                       # switch : Usage
      check_value "$1" "$2"
      print_usage "$2"
      shift 2
      exit
      ;;
    -V|--version)                     # switch : Display Version
      print_version
      shift
      exit
      ;;
    -v|--verbose)                     # switch : Enable verbose mode
      options['verbose']="true"
      shift
      ;;
    -u|--user*)                       # switch : Specify username
      check_value "$1" "$2"
      options['username']="$2"
      shift 2
      ;;
    *)
      if [[ ! "$1" =~ ^-- ]]; then
        if [[ "$1" =~ @ ]]; then
          IFS '@' read -r options['username'] options['hostname'] <<< "$1"
          if [[ "${options['hostname']}" =~ : ]]; then
            IFS ':' read -r options['hostname'] options['source'] <<< "${options['hostname']}"
            if [ "$2" = "" ]; then
              warning_message "No destination file specified"
              do_exit
            else
              options['destination']="$2"
            fi
            options['scp']="true"
            options['ssh']="false"
            options['mapdir']=$( dirname "${options['destination']}")
#            options['command']="scp ${options['sshargs']} ${options['username']}@${options['hostname']}:${options['source']} ${options['destination']}"
          else
            options['scp']="false"
            options['ssh']="true"
            options['command']="ssh ${options['sshargs']} ${options['username']}@${options['hostname']}"
          fi
        else
          if [[ "$2" =~ : ]]; then
            options['source']="$1"
            if [[ "$2" =~ @ ]]; then
              IFS '@' read -r options['username'] options['hostname'] <<< "$2"
              IFS ':' read -r options['hostname'] options['destination'] <<< "${options['hostname']}"
            else
              IFS ':' read -r options['hostname'] options['destination'] <<< "$2"
            fi
            options['scp']="true"
            options['ssh']="false"
            options['mapfile']=$( basename -- "${options['source']}" )
            options['mapfile']="/tmp/${options['source']}"
#            options['command']="scp ${options['sshargs']} ${options['mapfile']} ${options['username']}@${options['hostname']}:${options['destination']}"
          else
            options['scp']="false"
            options['ssh']="true"
            options['hostname']="$1"
#            options['command']="ssh ${options['sshargs']} ${options['username']}@${options['hostname']}"
          fi
        fi
        execute_docker_command
        do_exit
      else
        print_help
      fi
      shift
      ;;
  esac
done

# Process options

if [ -n "${options_list[*]}" ]; then
  for list in "${options_list[@]}"; do
    if [[ "${list}" =~ "," ]]; then
      IFS="," read -r -a array <<< "${list[*]}"
      for item in "${array[@]}"; do
        process_options "${item}"
      done
    else
      process_options "${list}"
    fi
  done
fi

# Reset defaults based on switches

reset_defaults

# Process actions

if [ -n "${actions_list[*]}" ]; then
  for list in "${actions_list[@]}"; do
    if [[ "${list}" =~ "," ]]; then
      IFS="," read -r -a array <<< "${list[*]}"
      for item in "${array[@]}"; do
        process_actions "${item}"
      done
    else
      process_actions "${list}"
    fi
  done
fi

![alt tag](https://raw.githubusercontent.com/lateralblast/ostrich/master/ostrich.png)

OSTRICH
=======

Old SSH Terminal Remote Interactive Console Helper

Version: 0.1.2

Introduction
------------

New versions of SSH no longer have old ciphers compiled in as they are considered insecure.
Similarly a lot of older equipment used 768 bit host keys and later versions of SSH will not
connect to hosts with less that 1024 bit host keys.

However, sometimes we need to connect to an old piece of hardware that has older versions
of SSH that can not be upgraded.

This script provides a wrapper that:

- Creates a docker image based on Ubuntu 16.04 which has a version of SSH with older ciphers
- Runs SSH/SCP from the docker container with older cipher options

License
-------

CC BY-SA: https://creativecommons.org/licenses/by-sa/4.0/

Fund me here: https://ko-fi.com/richardatlateralblast

Status
------

This script is currently going through a refresh and clean up.

The old script can be located in the old subdirectory.


Requirements
------------

The following components are required on the deployment host and target:

- docker
- docker-compose

An example of installing docker and docker-compose on Ubuntu:

```
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
sudo apt-update
sudo apt install docker-ce
sudo apt install docker-compose
```

The script will check if the docker image ostrich exists, if not it will create it.

If for some reason this fails, there is a Docker and compose file included that can be run manaually in the directory where the Dockerfile is:

```
docker-compose build
```

Examples
--------

SSH to a host:

```
./ostrich.sh admin@192.168.10.250
```

SSH to a host:

```
./ostrich.sh --username admin --hostname 192.168.10.250
```

SCP a file to a host:

```
./ostrich.sh /tmp/blah admin@192.168.1.199:/tmp/blah
```

SCP a file to a host:

```
./ostrich.sh --username admin --hostname 192.168.1.100 --source /tmp/blah --destination /tmp/blah
```

Get usage information:

```
./ostrich.sh --help

ostrich (Old SSH Terminal Remote Interactive Console Helper) 0.0.8
Richard Spindler <richard@lateralblast.com.au>

Usage Information:

 -a|--addopts|--addoptions)
 Additional SSH options

 -C|--check|--checkdocker)
 Check Docker install

 -c|--copy|--scp)
 Source file to copy (SCP)

 -d|--dest|--destination)
 Destination file (SCP)

 -D|--debug)
 Enable debug mode

 -h|--help|--usage)
 Display help

 -n|--nostrict)
 Disable strict mode

 -o|--opts|--options)
 SSH/SCP Options

 -r|--dryrun)
 Dry run

 -s|--host|--hostname)
 Specify hostname

 -t|--tag|--name)
 Container name

 -V|--version)
 Display Version

 -v|--verbose)
 Enable verbose mode

 -u|--user|--username)
 Specify username
```

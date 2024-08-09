![alt tag](https://raw.githubusercontent.com/lateralblast/ostrich/master/ostrich.png)

OSTRICH
=======

Old SSH Terminal Remote Interactive Console Helper

Version: 0.0.8

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

This software is licensed as CC-BA (Creative Commons By Attrbution)

http://creativecommons.org/licenses/by/4.0/legalcode


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
./ostrich.sh -u admin -s 192.168.10.250
```

SCP a file to a host:

```
./ostrich.sh /tmp/blah admin@192.168.1.199:/tmp/blah
```

SCP a file to a host:

```
./ostrich.sh -u admin -s 192.168.1.100 -c /tmp/blah -d /tmp/blah
```

Get usage information:

```
./ostrich.sh -h

ostrich (Old SSH Terminal Remote Interactive Console Helper) 0.0.4
Richard Spindler <richard@lateralblast.com.au>

Usage Information:

      C)
         Check Docker install
      c)
         Source file to copy (SCP)
      d)
         Destination file (SCP)
      h)
         Display help
      o)
         SSH/SCP Option
      s)
         Hostname
      V)
         Display Version
      v)
         Verbose mode
      u)
         Username
```

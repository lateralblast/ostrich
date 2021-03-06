![alt tag](https://raw.githubusercontent.com/lateralblast/ostrich/master/ostrich.png)

OSTRICH
=======

Old SSH Terminal Remote Interactive Console Helper

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

The script will check if the docker image ostrich exists, if not it will create it.

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
ostrich (Old SSH Terminal Remote Interactive Console Helper) 0.0.2
Richard Spindler <richard@lateralblast.com.au>

Usage Information:

      h)
         Display help
      V)
         Display Version
      c)
         Source file to copy (SCP)
      d)
         Destination file (SCP)
      v)
         Verbose mode
      u)
         Username
      s)
         Hostname
      o)
         SSH/SCP Option
```

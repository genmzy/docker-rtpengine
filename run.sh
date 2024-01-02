#!/bin/sh

#yum insatll docker-ce kernel kernel-devel
echo "Checking if docker, kernel headers and iptables are installed..."

if [ -e /usr/bin/dpkg ]; then
  # host is a debian-serial linux

  if dpkg -l | grep "linux-headers-$(uname -r)"; then
    echo "linux kernel ... checked"
  else
    echo "Linux kernel headers is not installed, probably should execute: apt install linux-headers-$(uname -r)"
    exit 1;
  fi

  if dpkg -l | grep iptables; then
    echo "Iptables ... checked"
  else
    echo "Iptables should be installed"
    exit 1;
  fi

  if [ $(dpkg -l | grep docker-ce | wc -l) -lt 2 ]; then
    echo "Docker is not installed"
    exit 1;
  else
    echo "Docker ... checked"
  fi

else
  if [ -e /usr/bin/rpm ] ; then
    # host is a redhat-serial linux

    if rpm -qa | grep kernel-devel-$(uname -r); then
      echo "linux kernel ... checked"
    else
      echo "Linux kernel headers is not installed, probably should execute: yum install kernel-devel-$(uname -r)"
      exit 1;
    fi

    if rpm -qa | grep iptables; then
      echo "Iptables ... checked"
    else
      echo "Iptables should be installed"
      exit 1;
    fi

    if [ $(rpm -qa | grep docker-ce | wc -l) -lt 2 ]; then # for docker-ce and docker-ce-cli
      echo "Docker is not installed"
      exit 1;
    else
      echo "Docker ... checked"
    fi

  else
    # TODO: arch-serial linux not supported now <2023-02-09, genmzy> #
    echo "RTPEngine must run on linux! Exiting..."
    exit 1;
  fi
fi

mkdir -p /usr/local/rtpengine/log /usr/local/rtpengine/run /usr/local/rtpengine/bin
mkdir -p /data/fs_record
if [ ! -e "/usr/bin/docker-compose" ] && [ ! -e "/usr/local/bin/docker-compose" ]; then
  echo "Please install docker-compose!"
  exit 1;
fi

if [ "$1" == "-d" ]; then
  docker-compose up -d
else
  docker-compose up
fi

ansible_install.sh 

#!/bin/sh

#TODO.md

yum_makecache_retry() {

  tries=0

  until [ $tries -ge 5 ]

  do

    yum makecache && break

    let tries++

    sleep 1

  done

}



if [ "x$KITCHEN_LOG" = "xDEBUG" -o "x$OMNIBUS_ANSIBLE_LOG" = "xDEBUG" ]; then

  export PS4='(${BASH_SOURCE}:${LINENO}): - [${SHLVL},${BASH_SUBSHELL},$?] $ '

  set -x

fi



if [ ! $(which ansible-playbook) ]; then

  if [ -f /etc/centos-release ] || [ -f /etc/redhat-release ] || [ -f /etc/oracle-release ] || [ -f /etc/system-release ] || grep -q 'Amazon Linux' /etc/system-release; then



    # Install required Python libs and pip

    # Fix EPEL Metalink SSL error

    # - workaround: https://community.hpcloud.com/article/centos-63-instance-giving-cannot-retrieve-metalink-repository-epel-error

    # - SSL secure solution: Update ca-certs!!

    #   - http://stackoverflow.com/q/26734777/645491#27667111

    #   - http://serverfault.com/q/637549/77156

    #   - http://unix.stackexchange.com/a/163368/7688

    yum -y install ca-certificates nss

    yum clean all

    rm -rf /var/cache/yum

    yum_makecache_retry

    yum -y install epel-release

    # One more time with EPEL to avoid failures

    yum_makecache_retry



    yum -y install python-pip PyYAML python-jinja2 python-httplib2 python-keyczar python-paramiko git

    # If python-pip install failed and setuptools exists, try that

    if [ -z "$(which pip)" -a -z "$(which easy_install)" ]; then

      yum -y install python-setuptools

      easy_install pip

    elif [ -z "$(which pip)" -a -n "$(which easy_install)" ]; then

      easy_install pip

    fi



    # Install passlib for encrypt

    yum -y groupinstall "Development tools"

    yum -y install python-devel MySQL-python sshpass && pip install pyrax pysphere boto passlib dnspython



    # Install Ansible module dependencies

    yum -y install bzip2 file findutils git gzip hg svn sudo tar which unzip xz zip libselinux-python

    [ -n "$(yum search procps-ng)" ] && yum -y install procps-ng || yum -y install procps

  elif [ -f /etc/debian_version ] || [ grep -qi ubuntu /etc/lsb-release ] || grep -qi ubuntu /etc/os-release; then

    apt-get update

    # Install via package

     apt-get update && \

     apt-get install --no-install-recommends -y software-properties-common && \

     apt-add-repository ppa:ansible/ansible && \

     apt-get update && \

     apt-get install -y ansible



    # Install required Python libs and pip

    apt-get install -y  python-pip python-yaml python-jinja2 python-httplib2 python-paramiko python-pkg-resources

    [ -n "$( apt-cache search python-keyczar )" ] && apt-get install -y  python-keyczar

    if ! apt-get install -y git ; then

      apt-get install -y git-core

    fi

    # If python-pip install failed and setuptools exists, try that

    if [ -z "$(which pip)" -a -z "$(which easy_install)" ]; then

      apt-get -y install python-setuptools

      easy_install pip

    elif [ -z "$(which pip)" -a -n "$(which easy_install)" ]; then

      easy_install pip

    fi

    # If python-keyczar apt package does not exist, use pip

    [ -z "$( apt-cache search python-keyczar )" ] && sudo pip install python-keyczar



    # Install passlib for encrypt

    apt-get install -y build-essential

    apt-get install -y python-all-dev python-mysqldb sshpass && pip install pyrax pysphere boto passlib dnspython



    # Install Ansible module dependencies

    apt-get install -y bzip2 file findutils git gzip mercurial procps subversion sudo tar debianutils unzip xz-utils zip python-selinux



  else

    echo 'WARN: Could not detect distro or distro unsupported'

    echo 'WARN: Trying to install ansible via pip without some dependencies'

    echo 'WARN: Not all functionality of ansible may be available'

  fi



  mkdir /etc/ansible/

  echo -e '[local]\nlocalhost\n' > /etc/ansible/hosts

  pip install ansible



  if [ -f /etc/centos-release ] || [ -f /etc/redhat-release ] || [ -f /etc/oracle-release ] || [ -f /etc/system-release ] || grep -q 'Amazon Linux' /etc/system-release; then

    # Fix for pycrypto pip / yum issue

    # https://github.com/ansible/ansible/issues/276

    if  ansible --version 2>&1  | grep -q "AttributeError: 'module' object has no attribute 'HAVE_DECL_MPZ_POWM_SEC'" ; then

      echo 'WARN: Re-installing python-crypto package to workaround ansible/ansible#276'

      echo 'WARN: https://github.com/ansible/ansible/issues/276'

      pip uninstall -y pycrypto

      yum erase -y python-crypto

      yum install -y python-crypto python-paramiko

    fi

  fi



fi

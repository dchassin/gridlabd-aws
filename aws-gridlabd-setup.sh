#!/bin/bash
# 
# This script sets up an AWS host for GridLAB-D 
#

# root check
if [ $(whoami) != "root" ]; then
	echo "must be root to run this script"
	exit
fi

# system update
yum update -y
yum install git -y
yum install httpd -y
yum install php -y
yum install cmake -y 
yum groupinstall "Development Tools" -y
yum install https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm -y
yum install mysql56-server -y # for Amazon linux
if [ ! -d mysql-connector-c-6.1.9-linux-glibc2.5-x86_64 ]; then
	wget https://dev.mysql.com/get/Downloads/Connector-C/mysql-connector-c-6.1.9-linux-glibc2.5-x86_64.tar.gz
	tar xf mysql-connector-c-6.1.9-linux-glibc2.5-x86_64.tar.gz
	rm -f mysql-connector-c-6.1.9-linux-glibc2.5-x86_64.tar.gz
	cd mysql-connector-c-6.1.9-linux-glibc2.5-x86_64/
	cp -u bin/* /usr/local/bin
	cp -Ru include/* /usr/local/include
	cp -Ru lib/* /usr/local/lib
	rm -rf mysql-connector-c-6.1.9-linux-glibc2.5-x86_64
fi
yum install mysql-libs -y

cd /usr/local/src
if [ ! -d gridlabd ]; then
	git clone https://github.com/dchassin/gridlabd gridlabd
	# install xercesc
	(cd gridlabd/third_party; . install_xercesc)
	# install armadillo
	cd /usr/local/src
	wget http://sourceforge.net/projects/arma/files/armadillo-7.800.1.tar.xz
	tar xf armadillo-7.800.1.tar.xz
	rm -f armadillo-7.800.1.tar.xz
	cd armadillo-7.800.1
	cmake .
	make install
else
	cd gridlabd
	git pull origin
fi
cd /usr/local/src/gridlabd
autoreconf -isf
./customize configure
make install

# edit httpd.conf file and add index.php
if [ ! -f /etc/httpd/conf/httpd.original ]; then
	cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.original
	sed -e 's/DirectoryIndex .*/& index.php/' /etc/httpd/conf/httpd.original >/etc/httpd/conf/httpd.conf
fi

# install my web sql
# cd var/www/html
# wget http://downloads.sourceforge.net/project/mywebsql/stable/mywebsql-3.4.zip

#### this  needs to happen last ####
if [ ! -f /etc/my.original ]; then
	cp /etc/my.cnf /etc/my.original
	sed -e 's/^port=.*/#&/g;s/^socket=.*/#&/g;s/^datadir=.*/#&/g' /etc/my.original >/etc/my.cnf
fi

service mysqld restart
# Create user gridlabd_ro and gridlabd in mysql database
mysql <<-END
	CREATE USER 'gridlabd'@'localhost' IDENTIFIED BY 'gridlabd';
	GRANT ALL PRIVILEGES ON *.* TO 'gridlabd'@'localhost' WITH GRANT OPTION;
	FLUSH PRIVILEGES;
	CREATE USER 'gridlabd_ro'@'%' IDENTIFIED BY 'gridlabd';
	GRANT SELECT ON *.* TO 'gridlabd_ro'@'%';
	FLUSH PRIVILEGES;
END
# --------------------------------

#start apache service
service httpd start

if [ ! -f /etc/bashrc.original ]; then
	cp /etc/bashrc /etc/bashrc.original
	echo 'export LD_LIBRARY_PATH=/usr/local/lib' >> /etc/bashrc
fi

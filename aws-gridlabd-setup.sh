#!/bin/bash
# 
# This script sets up an AWS host for GridLAB-D running the IEEE123 feeder model in realtime
#

#elevate privileges to su
sudo su
# yum install wget -y  # install wget for redhat 7 on EC2

# yum update install git, php, apache, cmake, dev tools
#wget https://s3-us-west-1.amazonaws.com/vader-lab/gridlabd-dependencies/install-base.sh
#sh install-base.sh
yum update -y

#install base software
yum install git -y
yum install httpd -y
yum install php -y
yum install cmake -y #this is a requirement for armadillo - linear algebra library
yum groupinstall "Development Tools" -y

# MySQL Install server, connector, and libs
yum install https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm -y
yum install mysql56-server -y # for Amazon linux

#install MySql Connector
wget https://dev.mysql.com/get/Downloads/Connector-C/mysql-connector-c-6.1.9-linux-glibc2.5-x86_64.tar.gz
tar xf mysql-connector-c-6.1.9-linux-glibc2.5-x86_64.tar.gz
#rm mysql-connector-c-6.1.9-linux-glibc2.5-x86_64.tar.gz
cd mysql-connector-c-6.1.9-linux-glibc2.5-x86_64/
cp bin/* /usr/local/bin
cp -R include/* /usr/local/include
cp -R lib/* /usr/local/lib
yum install mysql-libs -y

#test MySQL Service
#service mysqld start
#service mysqld stop

#yum install mysql -y #remove this later
#copy gridlab source and install lib-xercesc
#wget https://s3-us-west-1.amazonaws.com/vader-lab/gridlabd-dependencies/install-libxercesc.sh
#sh install-libxercesc.sh
#copy gridlab source and install lib-xercesc
cd /usr/local/src
mkdir gridlabd
cd gridlabd
git clone https://github.com/dchassin/gridlab-d .
cd third_party
. install_xercesc # need to source the script for automated run.

#install armadillo - C++ linear algebra library
cd /usr/local/src
wget http://sourceforge.net/projects/arma/files/armadillo-7.800.1.tar.xz
tar xf armadillo-7.800.1.tar.xz
rm -f armadillo-7.800.1.tar.xz
cd armadillo-7.800.1
cmake .
make install

# clone IEEE123 model in www folder
cd /var/www/html
git clone https://github.com/dchassin/ieee123-aws
cp -R ieee123-aws/* .
rm -rf ieee123-aws/
mkdir data output
chmod -R 777 data output config
chown -R apache.apache .

#install gridlabd
cd /home/ec2-user/gridlabd/source
autoreconf -isf
./customize configure
make install
export PATH=/usr/local/bin:$PATH
gridlabd --validate

# edit httpd.conf file and add index.php
sed -e 's/DirectoryIndex .*/& index.php/' /etc/httpd/conf/httpd.conf >/tmp/httpd.conf
mv /tmp/httpd.conf /etc/httpd/conf/httpd.conf

# install my web sql
# cd var/www/html
# wget http://downloads.sourceforge.net/project/mywebsql/stable/mywebsql-3.4.zip

#### this  needs to happen last ####
sed -e 's/^pored -e 's/^port=.*/#&/g;s/^socket=.*/#&/g;s/^datadir=.*/#&/g' /etc/my.cnf >/tmp/my.cnf
mv /tmp/my.cnf /etc/my.cnf

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
systemctl start httpd # on RHEL 7 only

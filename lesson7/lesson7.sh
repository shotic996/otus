#!/bin/bash
#Урок 7. Управление пакетами.
yum install -y wget rpm-build rpmdevtools gcc make openssl-devel zlib-devel pcre-devel
cd /root/
wget https://nginx.org/packages/mainline/centos/8/SRPMS/nginx-1.19.9-1.el8.ngx.src.rpm
rpm -Uvh nginx-1.19.9-1.el8.ngx.src.rpm
rpmbuild -bb rpmbuild/SPECS/nginx.spec
rpm -Uvh /root/rpmbuild/RPMS/x86_64/nginx-1.19.9-1.el8.ngx.x86_64.rpm
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload
systemctl enable nginx
systemctl start nginx
mkdir /usr/share/nginx/html/repo
cp /root/rpmbuild/RPMS/x86_64/nginx-1.19.9-1.el8.ngx.x86_64.rpm /usr/share/nginx/html/repo/
wget https://downloads.percona.com/downloads/percona-distribution-mysql-ps/percona-distribution-mysql-ps-8.0.28/binary/redhat/8/x86_64/percona-orchestrator-3.2.6-2.el8.x86_64.rpm -O /usr/share/nginx/html/repo/percona-orchestrator-3.2.6-2.el8.x86_64.rpm
yum install -y createrepo
createrepo /usr/share/nginx/html/repo/
sed -i '/index  index.html index.htm;/a\        autoindex on;\' /etc/nginx/conf.d/default.conf
nginx -t
nginx -s reload
echo "[otus]" >> /etc/yum.repos.d/otus.repo
echo "name=otus-linux" >> /etc/yum.repos.d/otus.repo
echo "baseurl=http://localhost/repo" >> /etc/yum.repos.d/otus.repo
echo "gpgcheck=0" >> /etc/yum.repos.d/otus.repo
echo "enabled=1" >> /etc/yum.repos.d/otus.repo
yum repolist enabled | grep otus
yum -y install percona-orchestrator.x86_64



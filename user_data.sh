#!/bin/bash
hostname DVWA-EC2
yum install -y httpd mariadb-server mariadb php php-mysql php-gd
systemctl start mariadb httpd
systemctl enable httpd.service mariadb.service
echo -e "\\n\\nqwe123\\nqwe123\\ny\\nn\\ny\\ny\\n" | /usr/bin/mysql_secure_installation
mysql -uroot -pqwe123 -e "create database dvwa; GRANT ALL PRIVILEGES ON dvwa.* TO 'dvwa'@'localhost' IDENTIFIED BY 'qwe123'; flush privileges;"
wget https://github.com/ethicalhack3r/DVWA/archive/master.zip
unzip master.zip
mv DVWA-master/* /var/www/html/
mv DVWA-master/.htaccess /var/www/html/
cp /var/www/html/config/config.inc.php.dist /var/www/html/config/config.inc.php
sed -i "s/p@ssw0rd/qwe123/g" /var/www/html/config/config.inc.php
sed -i 's/allow_url_include = Off/allow_url_include = on/g' /etc/php.ini
chmod 777 /var/www/html/hackable/uploads
chmod 777 /var/www/html/config
chmod 666 /var/www/html/external/phpids/0.6/lib/IDS/tmp/phpids_log.txt
systemctl restart httpd.service

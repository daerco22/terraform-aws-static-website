#!/bin/bash
sudo apt-get update
sudo apt-get install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2
git clone https://github.com/daerco22/sample-static-website.git
sudo sed -i "s|<Directory /var/www/>|<Directory /sample-static-website/>|" /etc/apache2/apache2.conf
sudo bash -c 'cat /etc/apache2/sites-available/000-default.conf >> /etc/apache2/sites-available/sample-static-website.conf'
sudo sed -i "s|/var/www/html|/sample-static-website|" /etc/apache2/sites-available/sample-static-website.conf
sudo a2ensite sample-static-website.conf
sudo a2dissite 000-default.conf
sudo apache2ctl configtest
sudo systemctl reload apache2
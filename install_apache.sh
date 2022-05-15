#!/bin/bash

sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
sudo firewall-cmd — permanent — add-service=http
sudo firewall-cmd — reload
echo "Hello World from $(hostname -f)" > /var/www/html/index.html

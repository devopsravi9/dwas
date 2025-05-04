#!/bin/bash

check_root () {
  ID=$(id -u)
  if [ $ID -ne 0 ]; then
    echo "It requires root privileges run as root user"
  else
    echo "execution as root user"
  fi
}

check_status () {
  if [ $1 -eq 0 ]; then
    echo -e "===================== $2 is successfull"
  else
    echo -e "=====================$2 is failure"
    exit 1
  fi
}

check_nginx () {
  nginx -v
  if [ $? -eq 0 ]; then
    echo "nginx already installed"
  else
    apt install nginx -y
    check_status $? "install nginx"
  fi
}

IP=$1
echo $IP

check_root
check_nginx 

systemctl enable nginx
check_status $? "enable nginx"

systemctl start nginx
check_status $? "start nginx"

rm -rf /usr/share/nginx/html/*
check_status $? "remove old content"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip
check_status $? "download new content"

cd /usr/share/nginx/html
check_status $? "chnage directory"

unzip /tmp/frontend.zip
check_status $? "untar the content"

#rm /etc/nginx/default.d/expense.conf
#check_status $? "file created"

cat << EOF > /etc/nginx/conf.d/expense.conf
proxy_http_version 1.1;

location /api/ { proxy_pass http://$IP:8080/; }

location /health {
  stub_status on;
  access_log off;
}
EOF
check_status $? "content placed" 

#sed -i "s/IP/$IP/g" /etc/nginx/conf.d/expense.conf

systemctl restart nginx
check_status $? "nginx started"

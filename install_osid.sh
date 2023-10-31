#!/bin/bash

function pause(){
   read -p "$*"
}

echo "===Updating System==="
apt-get update -y
apt-get upgrade -y

echo "===Installing Required Libraries==="
apt-get install python3 python3-pip python3-cherrypy3 dcfldd -y

echo "===Setup Hostname to osid==="
bash -c "echo 'osid' > /etc/hostname"

echo "===Cloning OSID Project==="
git clone https://github.com/Snafu/osid-python3.git

mkdir -p /var/osid
mkdir -p /etc/osid/imgroot
cp -r osid-python3/* /etc/osid
rm -rf osid-python3

echo "===Installing nginx==="
apt-get install nginx -y

echo "===Configuring nginx==="
sed -i 's/hostname:port/127.0.0.1:8080/g' /etc/osid/etc/osid-nginx-proxy.conf
unlink /etc/nginx/sites-enabled/default
ln -s /etc/osid/etc/osid-nginx-proxy.conf /etc/nginx/sites-enabled/000-osid-proxy.conf

echo "===Fixing OSID Settings==="
cd /etc/osid/system
mv server.ini.sample server.ini
mv run_app.sh.sample run_app.sh

sed -i 's/localhost/127.0.0.1/g' server.ini
sed -i 's/80/8080/g' server.ini
sed -i 's/localhost/127.0.0.1/g' server.ini
sed -i 's/\/path_to_folder\/osid-python3/\/etc\/osid/g' server.ini

sed -i 's/cd \/path_to\/py-rpi-dupe/cd \/etc\/osid/g' run_app.sh
sed -i 's/hostname:port/127.0.0.1:8080/g' run_app.sh

sed -i 's/\/home\/pi\/Documents\/py-rpi-dupe/\/etc\/osid/g' osid.desktop.sample

echo "===Make Desktop Icons==="
mv osid.desktop.sample /home/*/Desktop/osid.desktop
echo "[Desktop Entry]
Name=Root File Manager
Comment=Opens up File Manager with Root Permissions
Icon=/usr/share/pixmaps/gksu-root-terminal.png
Exec=sudo pcmanfm
Type=Application
Encoding=UTF-8
Terminal=false
Categories=None;" > /home/*/Desktop/RootFileMan.desktop

echo "===Configuring Directory Permissions==="
chown www-data:www-data /etc/osid/imgroot -R
chown www-data:www-data /etc/osid/system -R
chown www-data:www-data /etc/osid/www -R

echo "===Restarting nginx==="
systemctl restart nginx

echo "===Setting up systemd==="
ln -s /etc/nginx/etc/osid.service /etc/systemd/system/osid.service
systemctl daemon-reload
systemctl enable osid.service
systemctl start osid.service

echo "===Setting up Samba==="
apt-get install samba -y

sambasettings="
[global]
workgroup = WORKGROUP
server string = Open Source Image Duplicator
map to guest = Bad User
security = user

log file = /var/log/samba/%m.log
max log size = 50

interfaces = lo eth0
guest account = www-data

dns proxy = no

[Images]
path = /etc/osid/imgroot
public = yes
only guest = yes
writable = yes"
echo "$sambasettings" > /etc/samba/smb.conf


echo "===Restart Your System==="



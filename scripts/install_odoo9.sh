#!/bin/bash

# Variablen
ODOO_USER_NAME=odoo
ODOO_USER_PWD=odoo
PG_USER_NAME=postgres
PG_USER_PWD=postgres
PG_ROLE_ODOO_NAME=odoo
PG_ROLE_ODOO_PWD=odoo
ADMIN_PASSWD='$_Foobar01$'
START_DIR=$PWD

# Zeitzone setzen
echo "Etc/UTC" > /etc/timezone

# OS auf aktuellen Stand bringen
apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y
apt-get autoremove -y

# benötigte Module installieren
apt-get install gcc unzip python2.7 python-dev python-pychart python-gnupg python-pil python-zsi python-ldap python-lxml python-dateutil libxslt1.1 libxslt1-dev libldap2-dev libsasl2-dev python-pip poppler-utils xfonts-base xfonts-75dpi xfonts-utils libxfont1 xfonts-encodings xzip xz-utils python-openpyxl python-xlrd python-decorator python-requests python-pypdf python-gevent npm nodejs node-less node-clean-css git mcrypt keychain software-properties-common python-passlib libjpeg-dev libfreetype6-dev zlib1g-dev libpng12-dev -y

# PostgreSQL installieren
apt-get install postgresql-9.5 postgresql-client postgresql-client-common postgresql-contrib-9.5 postgresql-server-dev-9.5 -y

# DB-User "odoo" anlegen
/usr/bin/sudo -u $PG_USER_NAME ./create_pg_role.sh $PG_ROLE_ODOO_NAME $PG_ROLE_ODOO_PWD

# benötigte Python-Packages installieren
easy_install --upgrade pip
pip install BeautifulSoup BeautifulSoup4 passlib pillow dateutils polib unidecode flanker simplejson enum py4j

# Node installieren
npm install -g npm
npm install -g less-plugin-clean-css
npm install -g less@1.4.2

ln -s /usr/bin/nodejs /usr/bin/node
rm /usr/bin/lessc
ln -s /usr/local/bin/lessc /usr/bin/lessc

# odoo9.conf aus Template erstellen und Parameter setzen
if [ -f odoo9.conf ]
	then rm odoo9.conf
fi

cp odoo9.conf.template odoo9.conf
sed -i s/{{admin_passwd}}/$ADMIN_PASSWD/ odoo9.conf
sed -i s/{{db_password}}/$PG_ROLE_ODOO_PWD/ odoo9.conf
sed -i s/{{db_user}}/$PG_ROLE_ODOO_NAME/ odoo9.conf

# odoo9.conf nach /etc/odoo kopieren
cd /etc
mkdir odoo
cd odoo
cp $START_DIR/odoo9.conf .

# wkhtmltopdf installieren
cd /tmp
mkdir wkhtmltopdf
cd wkhtmltopdf
wget http://download.gna.org/wkhtmltopdf/0.12/0.12.3/wkhtmltox-0.12.3_linux-generic-amd64.tar.xz
unxz wkhtmltox-0.12.3_linux-generic-amd64.tar.xz
tar xvf wkhtmltox-0.12.3_linux-generic-amd64.tar
cd wkhtmltox/bin
cp * /usr/local/bin/
cd /usr/bin
ln -s /usr/local/bin/wkhtmltopdf ./wkhtmltopdf
cd /tmp
rm -rf wkhtmltopdf

# User odoo anlegen und Passwort setzen
useradd -m -U $ODOO_USER_NAME
echo "$ODOO_USER_NAME:$ODOO_USER_PWD" | chpasswd

# Passwort für User postgres setzen
echo "$PG_USER_NAME:$PG_USER_PWD" | chpasswd

# Verzeichnis für das Logfile anlegen und Berechtigungen setzen
cd /var/log
mkdir odoo
chown odoo.odoo odoo

# Verzeichnis für odoo anlegen
cd /opt
mkdir odoo

# odoo9 aus dem Github-Repository holen
cd odoo
git clone https://github.com/odoo/odoo -b 9.0
ln -s odoo ./odoo9

# Installation der von odoo benötigten Python-Packages
cd odoo9
pip install -r requirements.txt

# Startdatei für den Service odoo9 anlegen und registrieren
cd /etc/systemd/system
cp $START_DIR/odoo9.service .
chmod 644 odoo9.service
systemctl preset odoo9.service

# odoo9 starten
service odoo9 start


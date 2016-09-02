#!/bin/bash

ROLE_ODOO_PWD=$1

cd /var/lib/postgresql

psql <<EOF
    create role odoo with password '$ROLE_ODOO_PWD';
    alter role odoo CREATEROLE;
    alter role odoo CREATEDB;
    alter role odoo CREATEUSER;
    alter role odoo LOGIN;
    \q
EOF


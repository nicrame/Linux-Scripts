#!/bin/bash

# Made for ISPConfig 3 v1.0 - 2019
#

cd /opt
mkdir -p /opt/postfixmaps
mkdir -p /opt/postfixmaps/maps
php /opt/postfixmaps/mail-maps-mx.php

# SCP files transfer
scp -C /opt/postfixmaps/maps/* postfixmaps@backupmx.mydomain.com:/home/postfixmaps/maps/

#!/bin/bash

cd /etc/postfix
openssl dhparam -out dh512.tmp 512 && mv dh512.tmp dh512.pem
openssl dhparam -out dh1024.tmp 1024 && mv dh1024.tmp dh1024.pem
openssl dhparam -out dh2048.tmp 2048 && mv dh2048.tmp dh2048.pem
chmod 644 dh512.pem dh1024.pem dh2048.pem
cp /home/postfixmaps/maps/* /etc/postfix/
systemctl restart postfix

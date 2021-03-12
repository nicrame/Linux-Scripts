#!/bin/bash

# MOTD scripts for EL
# Version 1.1
#
# This will install colorful and nice MOTD with some system information.
# MOTD is generated with scripts, that will be extracted to /etc/profile.d 
# where you may modify them to suite your needs.
# 
# I made it because i couldn't find anything like that for EL.
#
# Most of the work is done by Yannick Boetzel - yboetzel@ethz.ch
# using scripts he made and published here: https://github.com/yboetz/motd
#
# Some parts are base64 encoded here - the reason was it's much easier to
# extract such data without formatting problems with special characters from one file.
# I know it's lazy, but it is fast and very easy to do. 
# 
# More info:
# [PL/ENG] /link will be here/
#
# Feel free to contact me: marcin@marcinwilk.eu
# www.marcinwilk.eu
# Marcin Wilk
#
# License:
# 1. You use it at your own risk. Author is not responsible for any damage made with that script.
# 2. Feel free to share and modify this as you like.
#
# Changelog:
# v 1.1 - 12.03.2021
# First release, tested on CentOS 7
# v 1.0 - 11.03.2021
# Play at home, tested on RHEL 8 and CentOS 8

user=$( whoami )
# User name that run the script. No reasons to change it.
# Used only for testing.

# Installing packages that are need to make world colorful and nice!
echo "Updating system and installing EPEL repo and packages."
yum update -y
yum -y -q install dnf unzip
dnf -y -q install --nogpgcheck https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf -y -q install figlet && dnf -y -q install ruby

if [ -e /usr/local/bin/lolcat ]
then
echo "Lolcat already installed, skipping..."
else
cd /tmp
wget https://github.com/busyloop/lolcat/archive/master.zip
unzip master.zip
rm -rf master.zip
cd lolcat-master/bin
gem install lolcat
cd /tmp
rm -rf lolcast-master
fi

touch /etc/profile.d/10-banner.sh
echo '#!/bin/bash

user="$(whoami)"
echo "- -- -- ------ Audaces Fortuna Iuvat  ------ -- -- -" | lolcat -f
echo -e "Welcome \e[93m$user \e[39mat:"
' > /etc/profile.d/10-banner.sh

touch /etc/profile.d/15-name.sh
echo '#!/bin/bash

/usr/bin/env figlet "$(hostname)" | /usr/bin/env lolcat -f
' > /etc/profile.d/15-name.sh

touch /etc/profile.d/20-sysinfo.sh.b64
echo 'IyEvYmluL2Jhc2gKCiMgZ2V0IGxvYWQgYXZlcmFnZXMKSUZTPSIgIiByZWFkIExPQUQxIExPQUQ1
IExPQUQxNSA8PDwkKGNhdCAvcHJvYy9sb2FkYXZnIHwgYXdrICd7IHByaW50ICQxLCQyLCQzIH0n
KQojIGdldCBmcmVlIG1lbW9yeQpJRlM9IiAiIHJlYWQgVVNFRCBBVkFJTCBUT1RBTCA8PDwkKGZy
ZWUgLWh0bSB8IGdyZXAgIk1lbSIgfCBhd2sgeydwcmludCAkMywkNywkMid9KQojIGdldCBwcm9j
ZXNzZXMKUFJPQ0VTUz1gcHMgLWVvIHVzZXI9fHNvcnR8dW5pcSAtYyB8IGF3ayAneyBwcmludCAk
MiAiICIgJDEgfSdgClBST0NFU1NfQUxMPWBlY2hvICIkUFJPQ0VTUyJ8IGF3ayB7J3ByaW50ICQy
J30gfCBhd2sgJ3sgU1VNICs9ICQxfSBFTkQgeyBwcmludCBTVU0gfSdgClBST0NFU1NfUk9PVD1g
ZWNobyAiJFBST0NFU1MifCBncmVwIHJvb3QgfCBhd2sgeydwcmludCAkMid9YApQUk9DRVNTX1VT
RVI9YGVjaG8gIiRQUk9DRVNTInwgZ3JlcCAtdiByb290IHwgYXdrIHsncHJpbnQgJDInfSB8IGF3
ayAneyBTVU0gKz0gJDF9IEVORCB7IHByaW50IFNVTSB9J2AKIyBnZXQgcHJvY2Vzc29ycwpQUk9D
RVNTT1JfTkFNRT1gZ3JlcCAibW9kZWwgbmFtZSIgL3Byb2MvY3B1aW5mbyB8IGN1dCAtZCAnICcg
LWYzLSB8IGF3ayB7J3ByaW50ICQwJ30gfCBoZWFkIC0xYApQUk9DRVNTT1JfQ09VTlQ9YGdyZXAg
LWlvUCAncHJvY2Vzc29yXHQ6JyAvcHJvYy9jcHVpbmZvIHwgd2MgLWxgCgpXPSJcZVswOzM5bSIK
Rz0iXGVbMTszMm0iClk9IlxlWzkzbSIKaXBleHQ9JChjdXJsIC1zIGh0dHBzOi8vaXBlY2hvLm5l
dC9wbGFpbikKbmV0ZGV2PSQoaXAgLW8gbGluayBzaG93IHwgYXdrIC1GJzogJyAne3ByaW50ICQy
IiAifScgfCB0ciAtZCAnXG4nKQoKZWNobyAtZSAiCiR7V31zeXN0ZW0gaW5mbzoKJFcgIERpc3Ry
by4uLi4uLjogJFlgY2F0IC9ldGMvKnJlbGVhc2UgfCBncmVwICJQUkVUVFlfTkFNRSIgfCBjdXQg
LWQgIj0iIC1mIDItIHwgc2VkICdzLyIvL2cnYAokVyAgS2VybmVsLi4uLi4uOiAkV2B1bmFtZSAt
c3JgCgokVyAgVXB0aW1lLi4uLi4uOiAkV2B1cHRpbWUgLXBgCiRXICBMb2FkLi4uLi4uLi46ICRH
JExPQUQxJFcgKDFtKSwgJEckTE9BRDUkVyAoNW0pLCAkRyRMT0FEMTUkVyAoMTVtKQokVyAgUHJv
Y2Vzc2VzLi4uOiRXICRHJFBST0NFU1NfUk9PVCRXIChyb290KSwgJEckUFJPQ0VTU19VU0VSJFcg
KHVzZXIpLCAkRyRQUk9DRVNTX0FMTCRXICh0b3RhbCkKCiRXICBDUFUuLi4uLi4uLi46ICRXJFBS
T0NFU1NPUl9OQU1FICgkRyRQUk9DRVNTT1JfQ09VTlQkVyB2Q1BVKQokVyAgTWVtb3J5Li4uLi4u
OiAkRyRVU0VEJFcgdXNlZCwgJEckQVZBSUwkVyBhdmFpbCwgJEckVE9UQUwkVyB0b3RhbCRXCgok
VyAgTG9jYWwgSVAuLi4uOiAkV2Bob3N0bmFtZSAtSWAKJFcgIEV4dGVybmFsIElQLjogJFckaXBl
eHQKJFcgIE5ldCBkZXZpY2VzLjogJFckbmV0ZGV2Igo=' > /etc/profile.d/20-sysinfo.sh.b64
base64 --decode /etc/profile.d/20-sysinfo.sh.b64 > /etc/profile.d/20-sysinfo.sh
rm -rf /etc/profile.d/20-sysinfo.sh.b64

touch /etc/profile.d/35-diskspace.sh.b64
echo 'IyEvYmluL2Jhc2gKCiMgY29uZmlnCm1heF91c2FnZT05MApiYXJfd2lkdGg9NTAKIyBjb2xvcnMK
d2hpdGU9IlxlWzM5bSIKZ3JlZW49IlxlWzE7MzJtIgpyZWQ9IlxlWzE7MzFtIgpkaW09IlxlWzJt
Igp1bmRpbT0iXGVbMG0iCgojIGRpc2sgdXNhZ2U6IGlnbm9yZSB6ZnMsIHNxdWFzaGZzICYgdG1w
ZnMKbWFwZmlsZSAtdCBkZnMgPCA8KGRmIC1IIC14IHpmcyAteCBzcXVhc2hmcyAteCB0bXBmcyAt
eCBkZXZ0bXBmcyAteCBvdmVybGF5IC0tb3V0cHV0PXRhcmdldCxwY2VudCx1c2VkLHNpemUsYXZh
aWwgfCB0YWlsIC1uKzIpCnByaW50ZiAiXG5kaXNrIHVzYWdlOlxuIgoKZm9yIGxpbmUgaW4gIiR7
ZGZzW0BdfSI7IGRvCiAgICAjIGdldCBkaXNrIHVzYWdlCiAgICB1c2FnZT0kKGVjaG8gIiRsaW5l
IiB8IGF3ayAne3ByaW50ICQyfScgfCBzZWQgJ3MvJS8vJykKICAgIHVzZWRfd2lkdGg9JCgoKCR1
c2FnZSokYmFyX3dpZHRoKS8xMDApKQogICAgIyBjb2xvciBpcyBncmVlbiBpZiB1c2FnZSA8IG1h
eF91c2FnZSwgZWxzZSByZWQKICAgIGlmIFsgIiR7dXNhZ2V9IiAtZ2UgIiR7bWF4X3VzYWdlfSIg
XTsgdGhlbgogICAgICAgIGNvbG9yPSRyZWQKICAgIGVsc2UKICAgICAgICBjb2xvcj0kZ3JlZW4K
ICAgIGZpCiAgICAjIHByaW50IGdyZWVuL3JlZCBiYXIgdW50aWwgdXNlZF93aWR0aAogICAgYmFy
PSJbJHtjb2xvcn0iCiAgICBmb3IgKChpPTA7IGk8JHVzZWRfd2lkdGg7IGkrKykpOyBkbwogICAg
ICAgIGJhcis9Ij0iCiAgICBkb25lCiAgICAjIHByaW50IGRpbW1tZWQgYmFyIHVudGlsIGVuZAog
ICAgYmFyKz0iJHt3aGl0ZX0ke2RpbX0iCiAgICBmb3IgKChpPSR1c2VkX3dpZHRoOyBpPCRiYXJf
d2lkdGg7IGkrKykpOyBkbwogICAgICAgIGJhcis9Ij0iCiAgICBkb25lCiAgICBiYXIrPSIke3Vu
ZGltfV0iCiAgICAjIHByaW50IHVzYWdlIGxpbmUgJiBiYXIKICAgIGVjaG8gIiR7bGluZX0iIHwg
YXdrICd7IHByaW50ZigiJS0xNnMlKzNzLyVzIHVzZWQgb3V0IG9mICUrNHMoJXMgZnJlZSkgXG4i
LCAkMSwgJDIsICQzLCAkNCwgJDUpOyB9JyB8IHNlZCAtZSAncy9eLyAgLycKICAgIGVjaG8gLWUg
IiR7YmFyfSIgfCBzZWQgLWUgJ3MvXi8gIC8nCmRvbmUK' > /etc/profile.d/35-diskspace.sh.b64
base64 --decode /etc/profile.d/35-diskspace.sh.b64 > /etc/profile.d/35-diskspace.sh
rm -rf /etc/profile.d/35-diskspace.sh.b64

touch /etc/profile.d/40-services.sh.b64
echo 'IyEvYmluL2Jhc2gKCiMgc2V0IGNvbHVtbiB3aWR0aApDT0xVTU5TPTMKIyBjb2xvcnMKZ3JlZW49
IlxlWzE7MzJtIgpyZWQ9IlxlWzE7MzFtIgp1bmRpbT0iXGVbMG0iCgpzZXJ2aWNlcz0oIm5naW54
IiAiaHR0cGQiICJtYXJpYWRiIiAicGhwNzQtcGhwLWZwbSIgInBocDgwLXBocC1mcG0iICJwaHAt
ZnBtIiAibmFtZWQiICJzc2hkIiAic21iIiAibm1iIiAic21hcnRkIiAicG9zdGZpeCIgImRvdmVj
b3QiICJmYWlsMmJhbiIgInB1cmUtZnRwZCIgInVyYmFja3VwLXNlcnZlciIgInVyYmFja3VwY2xp
ZW50YmFja2VuZCIgImRvY2tlciIpCiMgc29ydCBzZXJ2aWNlcwpJRlM9JCdcbicgc2VydmljZXM9
KCQoc29ydCA8PDwiJHtzZXJ2aWNlc1sqXX0iKSkKdW5zZXQgSUZTCgpzZXJ2aWNlX3N0YXR1cz0o
KQojIGdldCBzdGF0dXMgb2YgYWxsIHNlcnZpY2VzCmZvciBzZXJ2aWNlIGluICIke3NlcnZpY2Vz
W0BdfSI7IGRvCiAgICBzZXJ2aWNlX3N0YXR1cys9KCQoc3lzdGVtY3RsIGlzLWFjdGl2ZSAiJHNl
cnZpY2UiKSkKZG9uZQoKb3V0PSIiCmZvciBpIGluICR7IXNlcnZpY2VzW0BdfTsgZG8KICAgICMg
Y29sb3IgZ3JlZW4gaWYgc2VydmljZSBpcyBhY3RpdmUsIGVsc2UgcmVkCiAgICBpZiBbWyAiJHtz
ZXJ2aWNlX3N0YXR1c1skaV19IiA9PSAiYWN0aXZlIiBdXTsgdGhlbgogICAgICAgIG91dCs9IiR7
c2VydmljZXNbJGldfTosJHtncmVlbn0ke3NlcnZpY2Vfc3RhdHVzWyRpXX0ke3VuZGltfSwiCiAg
ICBlbHNlCiAgICAgICAgb3V0Kz0iJHtzZXJ2aWNlc1skaV19Oiwke3JlZH0ke3NlcnZpY2Vfc3Rh
dHVzWyRpXX0ke3VuZGltfSwiCiAgICBmaQogICAgIyBpbnNlcnQgXG4gZXZlcnkgJENPTFVNTlMg
Y29sdW1uCiAgICBpZiBbICQoKCgkaSsxKSAlICRDT0xVTU5TKSkgLWVxIDAgXTsgdGhlbgogICAg
ICAgIG91dCs9IlxuIgogICAgZmkKZG9uZQpvdXQrPSJcbiIKCnByaW50ZiAiXG5zZXJ2aWNlczpc
biIKcHJpbnRmICIkb3V0IiB8IGNvbHVtbiAtdHMgJCcsJyB8IHNlZCAtZSAncy9eLyAgLycK' > /etc/profile.d/40-services.sh.b64
base64 --decode /etc/profile.d/40-services.sh.b64 > /etc/profile.d/40-services.sh
rm -rf /etc/profile.d/40-services.sh.b64

touch /etc/profile.d/60-admin.sh
echo '#!/bin/bash
system=$(hostname)
echo "
SysOP: root@$system
" | lolcat -f' > /etc/profile.d/60-admin.sh

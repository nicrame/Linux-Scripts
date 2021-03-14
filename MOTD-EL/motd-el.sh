#!/bin/bash

# #### MOTD scripts for EL
# Version 1.4  
# Testes on: CentOS 8, RHEL 8  
#
# This will install colorful and nice motd (message of the day) with some system informations.    
# MOTD is generated with scripts, that will be extracted to /etc/profile.d  
# where you may modify them to suite your needs.  
# You may call this script with administrator email as argument: ./motd-el.sh admin@email.com  
#
# Most of the work is done using scripts made and published here: https://github.com/yboetz/motd  
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
# v 1.4 - 15.03.2021  
# Add full file path for last command so it will work when sudo is used.  
# Fix for correct EPEL repo installing on EL7.  
# v 1.3 - 13.03.2021  
# Add monthly stats of fail2ban script.  
# Add docker containers list script.  
# Changed some colors to work better on white background.  
# Show more information while processing installer and system operator argument support.  
# v 1.2 - 12.03.2021  
# Small fixes.  
# v 1.1 - 12.03.2021  
# First release, tested on CentOS 7.  
# v 1.0 - 11.03.2021  
# Play at home, tested on RHEL 8 and CentOS 8.  

user=$( whoami )
# User name that run the script. No reasons to change it.
# Used only for testing.

# Installing packages that are need to make world colorful and nice!
echo -e "\e[38;5;214mMOTD for EL will make world colorful and nice!\e[39;0m"
echo ""
echo "You may call this script with administrator email as argument: ./motd-el.sh admin@email.com"
echo "Adding colors to the system started!"
echo "Updating system packages. It may take some time, be patient!"
yum update -y -q
echo "Installing unzip and dnf."
yum -y -q install dnf unzip
echo "Enabling EPEL repo."
yum -y install epel-release
echo "Installing figlet and ruby packages."
dnf -y -q install figlet && dnf -y -q install ruby

if [ -e /usr/local/bin/lolcat ]
then
echo "Lolcat already installed, skipping..."
else
echo "Installing lolcat from sources."
cd /tmp
wget https://github.com/busyloop/lolcat/archive/master.zip
unzip master.zip
rm -rf master.zip
cd lolcat-master/bin
gem install lolcat
cd /tmp
rm -rf lolcast-master
fi

echo ""
echo "Creating script files in /etc/prfile.d/."
touch /etc/profile.d/10-banner.sh
echo '#!/bin/bash

user="$(whoami)"
echo "- -- -- ------ Audaces Fortuna Iuvat  ------ -- -- -" | lolcat -f
echo -e "Welcome \e[38;5;214m$user \e[39;0mat:"
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
Rz0iXGVbMTszMm0iClk9IlxlWzM4OzU7MjE0bSIKaXBleHQ9JChjdXJsIC1zIGh0dHBzOi8vaXBl
Y2hvLm5ldC9wbGFpbikKbmV0ZGV2PSQoaXAgLW8gbGluayBzaG93IHwgYXdrIC1GJzogJyAne3By
aW50ICQyIiAifScgfCB0ciAtZCAnXG4nKQoKZWNobyAtZSAiCiR7V31zeXN0ZW0gaW5mbzoKJFcg
IERpc3Ryby4uLi4uLjogJFlgY2F0IC9ldGMvKnJlbGVhc2UgfCBncmVwICJQUkVUVFlfTkFNRSIg
fCBjdXQgLWQgIj0iIC1mIDItIHwgc2VkICdzLyIvL2cnYAokVyAgS2VybmVsLi4uLi4uOiAkV2B1
bmFtZSAtc3JgCgokVyAgVXB0aW1lLi4uLi4uOiAkV2B1cHRpbWUgLXBgCiRXICBMb2FkLi4uLi4u
Li46ICRHJExPQUQxJFcgKDFtKSwgJEckTE9BRDUkVyAoNW0pLCAkRyRMT0FEMTUkVyAoMTVtKQok
VyAgUHJvY2Vzc2VzLi4uOiRXICRHJFBST0NFU1NfUk9PVCRXIChyb290KSwgJEckUFJPQ0VTU19V
U0VSJFcgKHVzZXIpLCAkRyRQUk9DRVNTX0FMTCRXICh0b3RhbCkKCiRXICBDUFUuLi4uLi4uLi46
ICRXJFBST0NFU1NPUl9OQU1FICgkRyRQUk9DRVNTT1JfQ09VTlQkVyB2Q1BVKQokVyAgTWVtb3J5
Li4uLi4uOiAkRyRVU0VEJFcgdXNlZCwgJEckQVZBSUwkVyBhdmFpbCwgJEckVE9UQUwkVyB0b3Rh
bCRXCgokVyAgTG9jYWwgSVAuLi4uOiAkV2Bob3N0bmFtZSAtSWAKJFcgIEV4dGVybmFsIElQLjog
JFckaXBleHQKJFcgIE5ldCBkZXZpY2VzLjogJFckbmV0ZGV2Igo=' > /etc/profile.d/20-sysinfo.sh.b64
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
YXdrICd7IHByaW50ZigiJS0xNnMlKzNzLyUrNHMgdXNlZCBvdXQgb2YgJSs0cyglKzRzIGZyZWUp
IFxuIiwgJDEsICQyLCAkMywgJDQsICQ1KTsgfScgfCBzZWQgLWUgJ3MvXi8gIC8nCiAgICBlY2hv
IC1lICIke2Jhcn0iIHwgc2VkIC1lICdzL14vICAvJwpkb25lCg==' > /etc/profile.d/35-diskspace.sh.b64
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

touch /etc/profile.d/50-fail2ban.sh.b64
echo 'IyEvYmluL2Jhc2gKCmlmIFsgLWUgL3Zhci9sb2cvZmFpbDJiYW4ubG9nIF0KdGhlbgogICAgaWYg
WyAtciAvdmFyL2xvZy9mYWlsMmJhbi5sb2cgXQogICAgdGhlbgpsb2dmaWxlPScvdmFyL2xvZy9m
YWlsMmJhbi5sb2cqJwptYXBmaWxlIC10IGxpbmVzIDwgPChncmVwIC1oaW9QICcoXFtbYS16LV0r
XF0pID8oPzpyZXN0b3JlKT8gKGJhbnx1bmJhbiknICRsb2dmaWxlIHwgc29ydCB8IHVuaXEgLWMp
CmphaWxzPSgkKHByaW50ZiAtLSAnJXNcbicgIiR7bGluZXNbQF19IiB8IGdyZXAgLW9QICdcW1xL
W15cXV0rJyB8IHNvcnQgfCB1bmlxKSkKCm91dD0iIgpmb3IgamFpbCBpbiAke2phaWxzW0BdfTsg
ZG8KICAgIGJhbnM9JChwcmludGYgLS0gJyVzXG4nICIke2xpbmVzW0BdfSIgfCBncmVwIC1pUCAi
W1s6ZGlnaXQ6XV0rIFxbJGphaWxcXSBiYW4iIHwgYXdrICd7cHJpbnQgJDF9JykKICAgIHJlc3Rv
cmVzPSQocHJpbnRmIC0tICclc1xuJyAiJHtsaW5lc1tAXX0iIHwgZ3JlcCAtaVAgIltbOmRpZ2l0
Ol1dKyBcWyRqYWlsXF0gcmVzdG9yZSBiYW4iIHwgYXdrICd7cHJpbnQgJDF9JykKICAgIHVuYmFu
cz0kKHByaW50ZiAtLSAnJXNcbicgIiR7bGluZXNbQF19IiB8IGdyZXAgLWlQICJbWzpkaWdpdDpd
XSsgXFskamFpbFxdIHVuYmFuIiB8IGF3ayAne3ByaW50ICQxfScpCiAgICBiYW5zPSR7YmFuczot
MH0gIyBkZWZhdWx0IHZhbHVlCiAgICByZXN0b3Jlcz0ke3Jlc3RvcmVzOi0wfSAjIGRlZmF1bHQg
dmFsdWUKICAgIHVuYmFucz0ke3VuYmFuczotMH0gIyBkZWZhdWx0IHZhbHVlCiAgICBiYW5zPSQo
KCRiYW5zKyRyZXN0b3JlcykpCiAgICBkaWZmPSQoKCRiYW5zLSR1bmJhbnMpKQogICAgb3V0Kz0k
KHByaW50ZiAiJGphaWwsICUrM3MgYmFucywgJSszcyB1bmJhbnMsICUrM3MgYWN0aXZlIiAkYmFu
cyAkdW5iYW5zICRkaWZmKSJcbiIKZG9uZQoKcHJpbnRmICJcbmZhaWwyYmFuIHN0YXR1cyAobW9u
dGhseSk6XG4iCnByaW50ZiAiJG91dCIgfCBjb2x1bW4gLXRzICQnLCcgfCBzZWQgLWUgJ3MvXi8g
IC8nCiAgICBmaQpmaQo=' > /etc/profile.d/50-fail2ban.sh.b64
base64 --decode /etc/profile.d/50-fail2ban.sh.b64 > /etc/profile.d/50-fail2ban.sh
rm -rf /etc/profile.d/50-fail2ban.sh.b64

touch /etc/profile.d/55-docker.sh.b64
echo 'IyEvYmluL2Jhc2gKCmlmIFsgLWUgL3Vzci9iaW4vZG9ja2VyIF0KdGhlbgogICAgaWYgWyAtciAv
dmFyL3J1bi9kb2NrZXIuc29jayBdCiAgICB0aGVuCiMgc2V0IGNvbHVtbiB3aWR0aApDT0xVTU5T
PTIKIyBjb2xvcnMKZ3JlZW49IlxlWzE7MzJtIgpyZWQ9IlxlWzE7MzFtIgp1bmRpbT0iXGVbMG0i
CgptYXBmaWxlIC10IGNvbnRhaW5lcnMgPCA8KGRvY2tlciBwcyAtYSAtLWZvcm1hdCAne3suTmFt
ZXN9fVx0e3suU3RhdHVzfX0nIHwgc29ydCAtazEgfCBhd2sgJ3sgcHJpbnQgJDEsJDIgfScpCgpv
dXQ9IiIKZm9yIGkgaW4gIiR7IWNvbnRhaW5lcnNbQF19IjsgZG8KICAgIElGUz0iICIgcmVhZCBu
YW1lIHN0YXR1cyA8PDwgJHtjb250YWluZXJzW2ldfQogICAgIyBjb2xvciBncmVlbiBpZiBzZXJ2
aWNlIGlzIGFjdGl2ZSwgZWxzZSByZWQKICAgIGlmIFtbICIke3N0YXR1c30iID09ICJVcCIgXV07
IHRoZW4KICAgICAgICBvdXQrPSIke25hbWV9Oiwke2dyZWVufSR7c3RhdHVzLCx9JHt1bmRpbX0s
IgogICAgZWxzZQogICAgICAgIG91dCs9IiR7bmFtZX06LCR7cmVkfSR7c3RhdHVzLCx9JHt1bmRp
bX0sIgogICAgZmkKICAgICMgaW5zZXJ0IFxuIGV2ZXJ5ICRDT0xVTU5TIGNvbHVtbgogICAgaWYg
WyAkKCgoJGkrMSkgJSAkQ09MVU1OUykpIC1lcSAwIF07IHRoZW4KICAgICAgICBvdXQrPSJcbiIK
ICAgIGZpCmRvbmUKb3V0Kz0iXG4iCgpwcmludGYgIlxuZG9ja2VyIHN0YXR1czpcbiIKcHJpbnRm
ICIkb3V0IiB8IGNvbHVtbiAtdHMgJCcsJyB8IHNlZCAtZSAncy9eLyAgLycKICAgIGZpCmZp' > /etc/profile.d/55-docker.sh.b64
base64 --decode /etc/profile.d/55-docker.sh.b64 > /etc/profile.d/55-docker.sh
rm -rf /etc/profile.d/55-docker.sh.b64

touch /etc/profile.d/60-admin.sh
if [ $# -eq 0 ]
then
echo '#!/bin/bash

system=$(hostname)
echo "
SysOP: root@$system
" | lolcat -f' > /etc/profile.d/60-admin.sh
else
echo "#!/bin/bash" > /etc/profile.d/60-admin.sh
echo "" >> /etc/profile.d/60-admin.sh
echo "echo \"" >> /etc/profile.d/60-admin.sh
echo SysOP: $1 >> /etc/profile.d/60-admin.sh
echo "\" | lolcat -f" >> /etc/profile.d/60-admin.sh
fi

echo "Everything is ready. Have fun!" | /usr/local/bin/lolcat -f

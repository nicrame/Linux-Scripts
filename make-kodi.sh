#!/bin/bash

# KODI Standalone autostart install script for CentOS (versions 8)
# Created using CentOS 8!
# Wasn't made and never tested on different distros than CentOS!
# Version 2.2 for x86_64
#
# More info:
# [PL] https://www.marcinwilk.eu/pl/projects/htpc-on-centos-8-linux-with-kodi/
# [EMG] https://www.marcinwilk.eu/en/projects/htpc-on-centos-8-linux-with-kodi/
#
# Feel free to contact me: marcin@marcinwilk.eu
# www.marcinwilk.eu
# Marcin Wilk
#
# License:
# 1. You use it at your own risk. Author is not responsible for any damage made with that script.
# 2. Any changes of scripts must be shared with author with authorization to implement them and share.
#
# Changelog:
# v 2.3 - 19.07.2020
# Fixed some typos, finally releasing on the web.
# v 2.2 - 07.07.2020
# Add license info.
# Fixed typos, and checked on core CentOS install. Ready to release on web.
# v 2.1 - 03.07.2020
# Added Avahi with it's daemon enabled.
# v 2.0 - 26.06.2020
# Another approach using flatpak instead of compiling many libraries and kodi itself from sources.
# v 1.0 - 23.06.2020
# First release, tested on CentOS 8

user=$( whoami )
# User name that run the script. No reasons to change it.
# Used only for testing.

el5=$( cat /etc/redhat-release | grep "release 5" )
el6=$( cat /etc/redhat-release | grep "release 6" )
el7=$( cat /etc/redhat-release | grep "release 7" )
el8=$( cat /etc/redhat-release | grep "release 8" )

#Configuration

# Installing (compiling) from sources - if yes then it will try to use not tested sources and repos 
# to compile of missing libraries and kodi then.
# I strongly do not reommend changing that option. Most likely will not work!
srcins=no

# Plex Media Server install.
# You can set this to yes so Plex Media Server will be installed. You may try it for fun.
plex=no

echo -e "Welcome in \e[93mKODI Standalone autostart install script \e[39mfor CentOS."
echo -e "Version \e[91m2.2 \e[39msupporting SL/CentOS version 8."
echo ""
echo "This script will install additional software and will make changes"
echo "in system config files to autologin and start KODI after reboot."
echo ""
echo "Changes in the system:"
echo "1. Checking user that runs script and OS version."
echo "2. Disabling SELinux, add RPMFusion and EPEL repos, adding kodi user, installing some X11 packages, configuring firewall."
echo "3. IF CONFIGURED: Installing Plex, installing libraries, and compiling from sources some of them and kodi."
echo "4. Installing flatpak and kodi flatpak package."
echo "5. Configuring kodi user profile config, making OS to start with kodi user into X11 automatically."
echo ""
echo "If kodi crash, xterm terminall will be started, so You may restart it with command:"
echo "flatpak run tv.kodi.Kodi"
echo "or if you configured script to install from sources:"
echo "kodi"
echo ""
sleep 10

if [ $user != root ]
then
    echo "You must be root. Mission aborted!"
    echo "You are trying to start this script as: $user"
    exit 0
else
    echo "You are root, this is good for me..."
fi
echo "------------------- ---------- -------- ----- -"

if [ -n "$el5" ]
then
	echo "Too old CentOS version. Pleasu upgrade to CentOS 8."
	echo "Mission aborted!."
exit 0
fi

if [ -n "$el6" ]
then
	echo "Too old CentOS version. Pleasu upgrade to CentOS 8."
	echo "Mission aborted!."
	exit 0
fi

if [ -n "$el7" ]
then
	echo "Too old CentOS version. Pleasu upgrade to CentOS 8."
	echo "Mission aborted!."
	exit 0
fi

echo "This process will take some time, please be patient..."
if [ ! -f /etc/redhat-release ]
then
    echo "Your Linux distribution isn't supported by this script."
    echo "Mission aborted!"
    exit 0
fi

# Disabling SELinux problems
sed --in-place=.bak 's/^SELINUX\=enforcing/SELINUX\=permissive/g' /etc/selinux/config
dnf -y update
dnf -y install --nogpgcheck https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf -y install --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-8.noarch.rpm https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-8.noarch.rpm
dnf config-manager --enable PowerTools

useradd kodi
dnf -y groupinstall "base-x"
dnf -y install wget gdm matchbox-window-manager rsync xorg-x11-xinit-session xterm glibc-langpack-en flatpak avahi oclock xload ImageMagick
systemctl enable avahi-daemon

# Adding kodi user to some groups used for hardware acceleration
usermod kodi -a -G audio
usermod kodi -a -G video

# Setting up firewall
firewall-cmd --zone=public --add-port=32469/tcp --permanent
firewall-cmd --zone=public --add-port=32414/udp --permanent
firewall-cmd --zone=public --add-port=32413/udp --permanent
firewall-cmd --zone=public --add-port=32412/udp --permanent
firewall-cmd --zone=public --add-port=32410/udp --permanent
firewall-cmd --zone=public --add-port=32400/tcp --permanent
firewall-cmd --zone=public --add-port=12374/udp --permanent
firewall-cmd --zone=public --add-port=9090/tcp --permanent
firewall-cmd --zone=public --add-port=9090/udp --permanent
firewall-cmd --zone=public --add-port=9777/udp --permanent
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --zone=public --add-port=8324/tcp --permanent
firewall-cmd --zone=public --add-port=5353/udp --permanent
firewall-cmd --zone=public --add-port=3005/tcp --permanent
firewall-cmd --zone=public --add-port=1900/tcp --permanent
firewall-cmd --zone=public --add-port=1900/udp --permanent
firewall-cmd --zone=public --add-port=1414/tcp --permanent
firewall-cmd --zone=public --add-port=1414/udp --permanent
firewall-cmd --zone=public --add-port=1131/tcp --permanent
firewall-cmd --zone=public --add-port=1131/udp --permanent
firewall-cmd --zone=public --add-port=1308/tcp --permanent
firewall-cmd --zone=public --add-port=1308/udp --permanent
firewall-cmd --zone=public --add-port=1084/tcp --permanent
firewall-cmd --zone=public --add-port=1084/udp --permanent
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --reload
setsebool httpd_can_network_connect on -P

# Installing Plex Media Server
if [ $plex = yes ]
then
touch /etc/yum.repos.d/plex.repo
echo "[Plex]" >> /etc/yum.repos.d/plex.repo
echo "name=Plex" >> /etc/yum.repos.d/plex.repo
echo "baseurl=https://downloads.plex.tv/repo/rpm/$basearch/" >> /etc/yum.repos.d/plex.repo
echo "enabled=1" >> /etc/yum.repos.d/plex.repo
echo "gpgkey=https://downloads.plex.tv/plex-keys/PlexSign.key" >> /etc/yum.repos.d/plex.repo
echo "gpgcheck=1" >> /etc/yum.repos.d/plex.repo
echo "" >> /etc/yum.repos.d/plex.repo
dnf -y install plexmediaserver
dnf -y reinstall glibc-common
systemctl enable plexmediaserver
systemctl start plexmediaserver
else
echo "Plex Media Server installation skipping."
fi

# Installing KODI
# Configuring flatpak for kodi install
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

if [ $srcins = no ]
then
flatpak -y install flathub tv.kodi.Kodi
sudo -u kodi flatpak override --user --share=network --share=ipc --socket=x11 --socket=wayland --socket=fallback-x11 --socket=pulseaudio --socket=system-bus --socket=session-bus --device=all --device=dri --device=shm --allow=devel --allow=multiarch --allow=bluetooth --allow=canbus --filesystem=host tv.kodi.Kodi
else
cd /root
# Adding Raven REPO for QT install
touch /etc/yum.repos.d/raven.repo
echo "[raven]" >> /etc/yum.repos.d/raven.repo
echo "name=Raven packages" >> /etc/yum.repos.d/raven.repo
echo "baseurl=https://pkgs.dyn.su/el8/base/x86_64/" >> /etc/yum.repos.d/raven.repo
echo "gpgcheck=0" >> /etc/yum.repos.d/raven.repo
echo "enabled=1 " >> /etc/yum.repos.d/raven.repo
echo "" >> /etc/yum.repos.d/raven.repo
echo "[raven-extras]" >> /etc/yum.repos.d/raven.repo
echo "name=Raven extra packages" >> /etc/yum.repos.d/raven.repo
echo "baseurl=https://pkgs.dyn.su/el8/extras/x86_64/" >> /etc/yum.repos.d/raven.repo
echo "gpgcheck=0" >> /etc/yum.repos.d/raven.repo
echo "enabled=0" >> /etc/yum.repos.d/raven.repo
echo "" >> /etc/yum.repos.d/raven.repo
echo "[raven-multimedia]" >> /etc/yum.repos.d/raven.repo
echo "name=Raven multimedia packages" >> /etc/yum.repos.d/raven.repo
echo "baseurl=https://pkgs.dyn.su/el8/multimedia/x86_64/" >> /etc/yum.repos.d/raven.repo
echo "gpgcheck=0" >> /etc/yum.repos.d/raven.repo
echo "enabled=0" >> /etc/yum.repos.d/raven.repo
echo "" >> /etc/yum.repos.d/raven.repo
dnf --enablerepo=epel-testing,raven-extras,raven-multimedia
dnf -y update
dnf -y install qt-4.8.7 qt-devel-4.8.7
dnf -y install unixODBC-devel bzip2-devel cmake curl dbus-devel fmt-devel fontconfig-devel freetype-devel fribidi-devel gawk gcc gcc-c++ gettext gettext-devel giflib-devel gperf gtest java-11-openjdk-headless jre lcms2-devel libao-devel libass-devel libcap-devel libcdio-devel libcurl-devel libidn2-devel libjpeg-turbo-devel libmicrohttpd-devel libmpc-devel libnfs-devel libplist-devel libsmbclient-devel libtool libtool-ltdl-devel libudev-devel libunistring libunistring-devel libusb-devel libuuid-devel libva-devel libvdpau-devel libxml2-devel libXmu-devel libXrandr-devel libxslt-devel libXt-devel lirc-devel lzo-devel make mariadb-devel mesa-libEGL-devel mesa-libGL-devel mesa-libGLU-devel mesa-libGLw-devel mesa-libOSMesa-devel nasm openssl-devel openssl-libs patch pcre-devel pulseaudio-libs-devel python3-devel python3-pillow sqlite-devel swig taglib-devel tinyxml-devel trousers-devel uuid-devel yasm zlib-devel
dnf -y install gtk2-devel libXv-devel libXcursor-devel cups-devel firebird-devel freetds-devel libmng-devel libpq-devel tk-devel python2-numpy python2-tkinter python3-numpy python3-qt5 python3-sphinx python3-sphinx_rtd_theme python3-tkinter libimagequant-devel libwebp-devel openjpeg2-devel pixman-devel python2-devel tre-devel wavpack-devel yajl-devel libsamplerate-devel libtiff-devel libvorbis-devel mesa-libgbm-devel ninja-build libmad-devel libmms-devel libmodplug-devel libmpcdec-devel libmpeg2-devel libogg-devel librtmp-devel libXinerama-devel libXtst-devel libcrystalhd-devel libdca-devel fontpackages-devel glew-devel jasper-devel lame-devel faad2-devel flac-devel enca-devel e2fsprogs-devel boost-devel afpfs-ng-devel qt5-devel extra-cmake-modules kde-filesystem kf5-rpm-macros gtest-devel libpng12 lockdev-devel ncurses-devel platform-devel ant doxygen texlive-latex libevent-devel git make gcc glib2-devel gcc-c++ groff ghostscript alsa-lib-devel autoconf automake avahi-compat-libdns_sd-devel avahi-devel bluez-libs-devel

wget https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/30/Everything/source/tree/Packages/f/fstrcmp-0.7.D001-11.fc30.src.rpm 
rpmbuild --rebuild fstrcmp-0.7.D001-11.fc30.src.rpm
dnf -y install /root/rpmbuild/RPMS/x86_64/fstrcmp-0.7.D001-11.el8.x86_64.rpm /root/rpmbuild/RPMS/x86_64/fstrcmp-devel-0.7.D001-11.el8.x86_64.rpm

wget https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/30/Everything/source/tree/Packages/l/libbluray-1.1.0-1.fc30.src.rpm
rpmbuild --rebuild libbluray-1.1.0-1.fc30.src.rpm
dnf -y install /root/rpmbuild/RPMS/x86_64/libbluray-1.1.0-1.el8.x86_64.rpm /root/rpmbuild/RPMS/x86_64/libbluray-devel-1.1.0-1.el8.x86_64.rpm

wget http://vault.centos.org/8.1.1911/AppStream/Source/SPackages/libpng12-1.2.57-5.el8.src.rpm
rpmbuild --rebuild libpng12-1.2.57-5.el8.src.rpm
dnf -y install /root/rpmbuild/RPMS/x86_64/libpng12-devel-1.2.57-5.el8.x86_64.rpm

wget https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/30/Everything/source/tree/Packages/r/rapidjson-1.1.0-9.fc30.src.rpm
rpmbuild --rebuild rapidjson-1.1.0-9.fc30.src.rpm
dnf -y install /root/rpmbuild/RPMS/noarch/rapidjson-devel-1.1.0-9.el8.noarch.rpm /root/rpmbuild/RPMS/noarch/rapidjson-doc-1.1.0-9.el8.noarch.rpm

wget https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/30/Everything/source/tree/Packages/f/flatbuffers-1.10.0-4.fc30.src.rpm
rpmbuild --rebuild flatbuffers-1.10.0-4.fc30.src.rpm
dnf -y install /root/rpmbuild/RPMS/x86_64/flatbuffers-1.10.0-4.el8.x86_64.rpm /root/rpmbuild/RPMS/x86_64/flatbuffers-devel-1.10.0-4.el8.x86_64.rpm

wget https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/30/Everything/source/tree/Packages/a/a52dec-0.7.4-35.fc30.src.rpm
rpmbuild --rebuild a52dec-0.7.4-35.fc30.src.rpm
dnf -y install /root/rpmbuild/RPMS/x86_64/a52dec-0.7.4-35.el8.x86_64.rpm /root/rpmbuild/RPMS/x86_64/liba52-0.7.4-35.el8.x86_64.rpm  /root/rpmbuild/RPMS/x86_64/liba52-devel-0.7.4-35.el8.x86_64.rpm

wget https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/30/Everything/source/tree/Packages/c/crossguid-0-0.11.20160908gitfef89a4.fc30.src.rpm
rpmbuild --rebuild crossguid-0-0.11.20160908gitfef89a4.fc30.src.rpm
dnf -y install /root/rpmbuild/RPMS/x86_64/crossguid-0-0.11.20160908gitfef89a4.el8.x86_64.rpm /root/rpmbuild/RPMS/x86_64/crossguid-devel-0-0.11.20160908gitfef89a4.el8.x86_64.rpm

wget https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/30/Everything/source/tree/Packages/p/python-olefile-0.46-2.fc30.src.rpm
rpmbuild --rebuild python-olefile-0.46-2.fc30.src.rpm
dnf -y install /root/rpmbuild/RPMS/noarch/python2-olefile-0.46-2.el8.noarch.rpm /root/rpmbuild/RPMS/noarch/python3-olefile-0.46-2.el8.noarch.rpm

wget https://download-ib01.fedoraproject.org/pub/fedora/linux/updates/30/Everything/SRPMS/Packages/p/python-pillow-5.4.1-4.fc30.src.rpm
rpmbuild --rebuild python-pillow-5.4.1-4.fc30.src.rpm
dnf -y install /root/rpmbuild/RPMS/x86_64/python2-pillow-5.4.1-4.el8.x86_64.rpm /root/rpmbuild/RPMS/x86_64/python2-pillow-devel-5.4.1-4.el8.x86_64.rpm 
dnf -y install /root/rpmbuild/RPMS/x86_64/python2-pillow-tk-5.4.1-4.el8.x86_64.rpm /root/rpmbuild/RPMS/x86_64/python3-pillow-5.4.1-4.el8.x86_64.rpm
dnf -y install /root/rpmbuild/RPMS/x86_64/python3-pillow-devel-5.4.1-4.el8.x86_64.rpm /root/rpmbuild/RPMS/noarch/python3-pillow-doc-5.4.1-4.el8.noarch.rpm 
dnf -y install /root/rpmbuild/RPMS/x86_64/python3-pillow-tk-5.4.1-4.el8.x86_64.rpm

wget https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/30/Everything/source/tree/Packages/a/automoc-1.0-0.34.rc3.fc30.src.rpm 
rpmbuild --rebuild automoc-1.0-0.34.rc3.fc30.src.rpm
dnf -y install /root/rpmbuild/RPMS/x86_64/automoc-1.0-0.34.rc3.el8.x86_64.rpm

wget https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/30/Everything/source/tree/Packages/p/phonon-4.10.2-2.fc30.src.rpm 
rpmbuild --rebuild phonon-4.10.2-2.fc30.src.rpm 
dnf -y install /root/rpmbuild/RPMS/x86_64/phonon-4.10.2-2.el8.x86_64.rpm /root/rpmbuild/RPMS/x86_64/phonon-devel-4.10.2-2.el8.x86_64.rpm /root/rpmbuild/RPMS/x86_64/phonon-qt5-4.10.2-2.el8.x86_64.rpm /root/rpmbuild/RPMS/x86_64/phonon-qt5-devel-4.10.2-2.el8.x86_64.rpm

wget https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/30/Everything/source/tree/Packages/s/shairplay-0.9.0-12.20160101gitce80e00.fc30.src.rpm 
rpmbuild --rebuild shairplay-0.9.0-12.20160101gitce80e00.fc30.src.rpm
dnf -y install /root/rpmbuild/RPMS/x86_64/shairplay-0.9.0-12.20160101gitce80e00.el8.x86_64.rpm /root/rpmbuild/RPMS/x86_64/shairplay-libs-0.9.0-12.20160101gitce80e00.el8.x86_64.rpm /root/rpmbuild/RPMS/x86_64/shairplay-devel-0.9.0-12.20160101gitce80e00.el8.x86_64.rpm /root/rpmbuild/RPMS/x86_64/airtv-0.9.0-12.20160101gitce80e00.el8.x86_64.rpm

cd $HOME
git clone https://github.com/xbmc/xbmc kodi
cd $HOME/kodi
make -C tools/depends/target/crossguid PREFIX=/usr/local
make -C tools/depends/target/flatbuffers PREFIX=/usr/local
make -C tools/depends/target/libfmt PREFIX=/usr/local
make -C tools/depends/target/libspdlog PREFIX=/usr/local
make -C tools/depends/target/wayland-protocols PREFIX=/usr/local
make -C tools/depends/target/waylandpp PREFIX=/usr/local
mkdir $HOME/kodi-build
cd $HOME/kodi-build
cmake ../kodi -DCMAKE_INSTALL_PREFIX=/usr/local -DX11_RENDER_SYSTEM=gl
cmake --build . -- VERBOSE=1 -j$(getconf _NPROCESSORS_ONLN)
sudo make install
make -j$(getconf _NPROCESSORS_ONLN) -C tools/depends/target/binary-addons PREFIX=/usr/local
cd $HOME/kodi
make -j$(getconf _NPROCESSORS_ONLN) -C tools/depends/target/binary-addons PREFIX=/usr/local
fi

echo "Configuring login manager (GDM), adding lines for autologin kodi user."
autologin=$( cat /etc/gdm/custom.conf | grep AutomaticLoginEnable=true )
loginname=$( cat /etc/gdm/custom.conf | grep AutomaticLogin=kodi )
if [ -n "$autologin" ]
then
    echo "File is already configured for automatic login."
    echo "Current automatic login config:"
    grep AutomaticLoginEnable /etc/gdm/custom.conf
    echo ""
    echo "Check the GDM file /etc/gdm/custom.conf."
else
    echo "Adding line to /etc/gdm/custom.conf for automatic login."
    sed -i '/daemon]/aAutomaticLoginEnable=true' /etc/gdm/custom.conf
fi

if [ -n "$loginname" ]
then
    echo "File is already configured for user to autologin."
	echo "Check the GDM file /etc/gdm/custom.conf."
else
    echo "Adding line to /etc/gdm/custom.conf for login user name."
    sed -i '/AutomaticLoginEnable=true/aAutomaticLogin=kodi' /etc/gdm/custom.conf
fi

echo "Adding line to /etc/gdm/custom.conf for default X Session in EL7."
echo "And creating session file for specific user in /var/lib/AccountsService/users/kodi."
sed -i '/AutomaticLogin=kodi/aDefaultSession=xinit-compat.desktop' /etc/gdm/custom.conf
touch /var/lib/AccountsService/users/kodi
chmod 644 /var/lib/AccountsService/users/kodi
echo "[User]" >> /var/lib/AccountsService/users/kodi
echo "Language=" >> /var/lib/AccountsService/users/kodi
echo "XSession=xinit-compat" >> /var/lib/AccountsService/users/kodi
echo "SystemAccount=false" >> /var/lib/AccountsService/users/kodi
echo "Setting up graphical boot."

systemctl set-default graphical.target

echo "xset s off ; xset -dpms" > /home/kodi/.xsession
echo "exec matchbox-window-manager &" >> /home/kodi/.xsession
if [ $srcins = yes ]
then
echo "kodi" >> /home/kodi/.xsession
echo "" >> /home/kodi/.xsession
else
echo "flatpak run tv.kodi.Kodi" >> /home/kodi/.xsession
echo "" >> /home/kodi/.xsession
fi
echo "xterm" >> /home/kodi/.xsession
ln -s /home/kodi/.xsession /home/kodi/.xinitrc
chown kodi:kodi /home/kodi/.xsession
chmod 777 /home/kodi/.xsession

echo "[Desktop]" > /home/kodi/.dmrc
echo "Session=xinit-compat" >> /home/kodi/.dmrc
echo "Language=$LANG" >> /home/kodi/.dmrc
chown kodi:kodi /home/kodi/.dmrc
chmod 766 /home/kodi/.dmrc
echo "You may now restart this computer to experience Kodi."


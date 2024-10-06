This is simple solution to make backup MX server using postfix.
It will receive user account and domain informations from the primary (main) ISPConfig server.

In this directory there are script files that will be used. Here is the instruction of how to make things work.
!!! First are instructions to be made on new server that will work as backup MX !!!
I'm using fresh install of Debian Linux v12, but for other distributions it will work similar (just use correct tools for apps installing and check files location).
The things that must be alredy preconfigured are: Server connected to Internet with external IP address, domain name configured for that IP, ssh access enabled for users. All commands are made by root account.

1 - use this command for updating and installing needed packages "apt update && apt -y upgrade && apt install -y net-tools cron certbot sudo openssl wget sed" 
2 - Let's create new account that will be used for transfering data, with command "useradd -s /usr/sbin/nologin -m postfixmaps && sudo -u postfixmaps mkdir /home/postfixmaps/maps && sudo -u postfixmaps mkdir /home/postfixmaps/.ssh"
3 - make sure that command "hostname -f" will show current domain name as server hostname. If domain is backupmx.mydomain.com then "hostname -f" should show it. It it's not, fix Your /etc/hostsname file.
4 - Install and preconfigure postfix MTA with command: 
    "echo "postfix	postfix/mailname string $(hostname -f)" | debconf-set-selections && echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections && apt install -y postfix mailutils postfix-policyd-spf-python && systemctl stop postfix"
5 - Generating of certs for our domain name with command: "certbot certonly --standalone --agree-tos -d $(hostname -f)", it will ask You for email address!
6 - Link certificates for Postfix "ln -s /etc/letsencrypt/live/$(hostname -f)/fullchain.pem /etc/postfix/smtpd.cert && ln -s /etc/letsencrypt/live/$(hostname -f)/privkey.pem /etc/postfix/smtpd.key"
7 - Download script files and do some preparing: "wget https://raw.githubusercontent.com/nicrame/Linux-Scripts/refs/heads/master/ISPConfig/BackupMXServer/pf-dh.sh -P /opt/"
    "chmod +x /opt/pf-dh.sh && wget https://raw.githubusercontent.com/nicrame/Linux-Scripts/refs/heads/master/ISPConfig/BackupMXServer/main-mx.cf -P /etc/postfix/ && cp main.cf main-org.cf && cat main-mx.cf >> main.cf"
8 - Make some changes in main/master.cf with commands: "cp /etc/postfix/master.cf /etc/postfix/master-org.cf && sed -i '/maildrop/s/^/#/' /etc/postfix/master.cf && sed -i '/uucp/s/^/#/' /etc/postfix/master.cf"
    "wiersze=$(wc -l < /etc/postfix/master.cf) && pozm=$((wiersze - 8 + 1)) && sed -i "${pozm},\$ s/^/#/" /etc/postfix/master.cf"
	"echo "policyd-spf  unix  -       n       n       -       0       spawn" >> /etc/postfix/master.cf"
	"echo "  user=policyd-spf argv=/usr/bin/policyd-spf" >> /etc/postfix/master.cf"
	"sed -i '/POSTGREY_OPTS/s/^/#/' /etc/default/postgrey && echo 'POSTGREY_OPTS="--inet=127.0.0.1:10023 --delay=60"' >> /etc/default/postgrey && systemctl restart postgrey"
	"sudo -u postfixmaps touch /home/postfixmaps/.ssh/authorized_keys"
9 - Edit crontab with "crontab -e", and add this new line "05 04 * * * /opt/pf-dh.sh"
10 - Change SSH server config: "cp /etc/ssh/sshd_config /etc/ssh/sshd_config-org && sed -i 's|/usr/lib/openssh/sftp-server|internal-sftp|g' /etc/ssh/sshd_config"
    "echo "Match User postfixmaps" >> /etc/ssh/sshd_config && echo "    ForceCommand internal-sftp" >> /etc/ssh/sshd_config && echo "    AllowTcpForwarding no" >> /etc/ssh/sshd_config"
    "echo "    X11Forwarding no" >> /etc/ssh/sshd_config && echo "    PasswordAuthentication no" >> /etc/ssh/sshd_config"

!!! Now we must prepare our main server, where ISPC is running !!!
1 - Login as root, and if You do not have it, generate new SSH keys for files transfer between servers: "ssh-keygen -t rsa -b 4096". 
2 - Copy the contents of the file /root/.ssh/id_rsa.pub on main server, into file /home/postfixmaps/.ssh/authorized_keys on backup MX server.
3 - Check if that worked by connecting from main server to backup one with command "ssh 'postfixmaps@backupmx.mydomain.com'" It should ask "Are you sure you want to continue connecting" - just hit "y" and enter.
    There should be information that "This service allows sftp connections only. Connection to backupmx.mydomain.com closed."
4 - Edit crontab with "crontab -e" and add this line "00 04 * * * /opt/postfixmaps/mail-maps-mx.sh > /dev/null".
5 - Download file "wget https://raw.githubusercontent.com/nicrame/Linux-Scripts/refs/heads/master/ISPConfig/BackupMXServer/mail-maps-mx.sh -P /opt/postfixmaps/ && chmod +x /opt/postfixmaps/mail-maps-mx.sh"
6 - Edit downloaded file and change domain name in last lite, to the one You are using for Your backup server (from backupmx.mydomain.com to correct one).

!!! First run - checking is everything working correctly !!!
1 - Run on the main server "/opt/postfixmaps/mail-maps-mx.sh". The files should be generated and transfered to secondary server.
2 - Login on backup server and check if files are there "ls /home/postfixmaps/maps". There should be: relay_domains relay_domains.db  relay_recipients  relay_recipients.db.
3 - On the backup server run this command "/opt/pf-dh.sh". Now let's check postfix status with "systemctl status postfix" command.

And that's all. This method do not use direct database connection that would make things much easier, because long time ago my server didn't have DB ports opened for the Internet.
In today, it would be easier to make some wireguard tunel and use DB server this way instead. But maybe someone will like this complex and unfriendly solution :)
And one more thing - You may try server configuration with that online tool: https://mxtoolbox.com/SuperTool.aspx?action=smtp



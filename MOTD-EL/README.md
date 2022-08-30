#### MOTD for EL

This will install colorful and nice motd (message of the day) with some system informations.  
MOTD is generated with scripts, that will be extracted to /etc/profile.d 
where you may modify them to suite your needs.  
fail2ban and docker stats will not be shown if user do not have correct permissions for that.  
Here is the main install script motd-el.sh - and the source files .sh used to create it.

![motd-el](https://user-images.githubusercontent.com/5872054/111041700-d7980a80-8439-11eb-850a-f8c99ef0d6e4.png)

To install use this command:  
> sudo sh -c "wget -q https://raw.githubusercontent.com/nicrame/Linux-Scripts/master/MOTD-EL/motd-el.sh && chmod +x motd-el.sh && ./motd-el.sh"  

You may also add system administrator email address as argument, like that:  
> sudo sh -c "wget -q https://raw.githubusercontent.com/nicrame/Linux-Scripts/master/MOTD-EL/motd-el.sh && chmod +x motd-el.sh && ./motd-el.sh admin@email"  

Most of the work is done using scripts published here: https://github.com/yboetz/motd

More info:  
[PL/ENG] https://www.marcinwilk.eu/projects/motd-dla-el/

Feel free to contact me: marcin@marcinwilk.eu  
www.marcinwilk.eu  
Marcin Wilk  

License:  
1. You use it at your own risk. Author is not responsible for any damage made with that script.  
2. Feel free to share and modify this as you like.

Tested on: CentOS 7/8, RHEL 8, Fedora 33, RockyLinux 8, Debian 11  
Changelog:  
v 1.6 - 30.08.2022  
Detecting if running from cron job, and then skip any operation (so it will not mess cron logs).  
ownload script files from GitHub instead of extracting from script file.  
v 1.5 - 08.06.2022  
Add Debian 11 support.  
Ingore user locale settings that may broke output.  
v 1.4 - 15.03.2021  
Add full file path for last command so it will work when sudo is used.  
Fix for correct EPEL repo installing on EL7.  
v 1.3 - 13.03.2021  
Add monthly stats of fail2ban script.  
Add docker containers list script.  
Changed some colors to work better on white background.  
Show more information while processing installer and system operator argument support.  
v 1.2 - 13.03.2021  
Little fixes.  
v 1.1 - 12.03.2021  
First release, tested on CentOS 7.  
v 1.0 - 11.03.2021  
Play at home, tested on RHEL 8 and CentOS 8.

#### MOTD for EL

This will install colorful and nice motd (message of the day) with some system informations.  
MOTD is generated with scripts, that will be extracted to /etc/profile.d 
where you may modify them to suite your needs.  
fail2ban and docker stats will not be shown if user do not have correct permissions for that.  
Here is the main install script motd-el.sh - and the source files .sh used to create it.

![motd-el](https://user-images.githubusercontent.com/5872054/111041700-d7980a80-8439-11eb-850a-f8c99ef0d6e4.png)

To install use this command:  
> wget -q https://raw.githubusercontent.com/nicrame/Linux-Scripts/master/MOTD-EL/motd-el.sh && chmod +x motd-el.sh && ./motd-el.sh  

You may also add system administrator email address as argument, like that:  
> wget -q https://raw.githubusercontent.com/nicrame/Linux-Scripts/master/MOTD-EL/motd-el.sh && chmod +x motd-el.sh && ./motd-el.sh admin@email  

Most of the work is done using scripts published here: https://github.com/yboetz/motd

Some parts inside install script are .sh files encoded with base64. 
The reason was it's much easier to extract such data without formatting problems 
with special characters from one file.  
I know it's lazy, but it is fast and very easy to do. 

More info:  
[PL/ENG] /link will be here/

Feel free to contact me: marcin@marcinwilk.eu  
www.marcinwilk.eu  
Marcin Wilk  

License:  
1. You use it at your own risk. Author is not responsible for any damage made with that script.  
2. Feel free to share and modify this as you like.

Changelog:  
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

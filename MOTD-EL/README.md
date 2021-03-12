#### MOTD scripts for EL

This will install colorful and nice MOTD with some system information.  
MOTD is generated with scripts, that will be extracted to /etc/profile.d 
where you may modify them to suite your needs.

To install use this command:  
> wget https://raw.githubusercontent.com/nicrame/Linux-Scripts/master/MOTD-EL/motd-el.sh && chmod +x motd-el.sh && ./motd-el.sh

Here is the main install script motd-el.sh - and the source files .sh used to create it.

I made it because i couldn't find anything like that for EL.

Most of the work is done by Yannick Boetzel - yboetzel@ethz.ch  
using scripts he made and published here: https://github.com/yboetz/motd

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
v 1.1 - 12.03.2021  
First release, tested on CentOS 7  
v 1.0 - 11.03.2021  
Play at home, tested on RHEL 8 and CentOS 8

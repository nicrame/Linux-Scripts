<?php
// Original code based on beautiful help from ISPConfig 3 community: https://forum.howtoforge.com/threads/ispconfig-3-and-backup-mx-server-w-o-mysql.55764/

require '/usr/local/ispconfig/server/lib/mysql_clientdb.conf';
$link = mysqli_connect($clientdb_host, $clientdb_user, $clientdb_password, false);
if(!$link) {
    die("Database connection error: " . mysqli_connect_error());
}

require '/usr/local/ispconfig/server/lib/config.inc.php';
$db = $conf['db_database'];
mysqli_select_db($link, $db);

$result = mysqli_query($link, 'SELECT `domain` FROM `mail_domain` WHERE `active` = "y"');
create_map($result, 'domain', '/opt/postfixmaps/maps/relay_domains');

$result = mysqli_query($link, 'SELECT `email` FROM `mail_user` WHERE `disabledeliver` = "n"');
create_map($result, 'email', '/opt/postfixmaps/maps/relay_recipients');

$result = mysqli_query($link, 'SELECT `source` FROM `mail_forwarding` WHERE `active` = "y"');
create_map($result, 'source', '/opt/postfixmaps/maps/relay_recipients', 'a');

exec('/usr/sbin/postmap hash:/opt/postfixmaps/maps/relay_domains & /usr/sbin/postmap hash:/opt/postfixmaps/maps/relay_recipients');

function create_map($result, $key, $file, $type = 'w')
{
        if(mysqli_num_rows($result) == 0)return false;

        $content = '';

        while($row = mysqli_fetch_array($result))
        {
                $content .= $row[$key]."\tOK\n";
        }

        write_file($file, $content, $type);
}

function write_file($file, $content, $type = 'w')
{
        $handle = fopen($file, $type);
        fwrite($handle, $content);
        fclose($handle);

        return;
}
?>
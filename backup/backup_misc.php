<?php
/***** Settings *****/
// Server hostname
$hostname = exec('hostname');

// Folders to backup without front slash
$backuparray = array("etc", "var/spool");

// Time before removing old backups
$timearray = array("+15", "+15");

// Folder to backup to
$target = "/mnt/backup";

// Date
date_default_timezone_set("Europe/Stockholm");
$date = date("Ymd");

/***** Dropbox Settings *****/
// Passphrase to encrypt with
$dbpassphrase = "";

// Folders to backup without front slash
$dbbackuparray = array("etc", "var/spool");

// Time before removing old backups
$dbtimearray = array("+1", "+1");

// Folders to place backups in
// $dbbackuparray[0] will be placed in /misc
$dbsubfolderarray = array("/misc", "");

// Folder to backup to
$dbtarget = "/mnt/dropbox";
$dbtargetextra = "/_Backups"; // This will be appended to $dbtarget if the mounting succeeds

/***** Functions *****/
/**
 * @return true if mounted
 */
function checkMount($target)
{
    $mount = shell_exec("if grep -qs '$target' /proc/mounts; then
        echo \"1\"
    else
        echo \"0\"
    fi");
    $mount = preg_replace('~[\r\n]+~', '', $mount);

    return ($mount == "1" ? true : false);
}

/**
 * @return true if successfully mounted $target
 */
function mount($target)
{
    $mount = shell_exec("if ! mount {$target} ; then
        echo \"Failed to mount {$target}. Exiting.\"
        exit 1
    fi");
    
    return (preg_replace('~[\r\n]+~', '', $mount) == "" ? "" : $mount);
}

/**
 * Prints $output with linebreak if necessary.
 */
function output($output)
{
    echo (empty($output) ? "" : $output."\n");
}

/***** The script *****/
// Check if it's mounted
if(!checkMount($target))
{
    $mount = mount($target);
    if(!empty($mount))
    {
        echo "Failed to mount {$target}:\n";
        var_dump($mount);
        exit(1);
    }
}
if(!checkMount($dbtarget))
{
    $mount = mount($dbtarget);
    if(!empty($mount))
    {
        echo "Failed to mount {$dbtarget}:\n";
        var_dump($mount);
        exit(1);
    }
}

// Add hostname to target
$target = $target."/".$hostname;
$dbtarget = $dbtarget.$dbtargetextra."/".$hostname;

// Check array sizes
if(count($backuparray) != count($timearray))
    exit("Array sizes doesn't match.");
if(count($dbbackuparray) != count($dbtimearray) || count($dbbackuparray) != count($dbsubfolderarray))
    exit("Dropbox array sizes doesn't match.");

// Loop through array
for($i = 0; $i < count($backuparray); $i++)
{
    // Replace / with .
    $backup = str_replace("/", ".", $backuparray[$i]);
    
    // Remove old files
    output(shell_exec("find {$target}/*{$backup}* -mtime {$timearray[$i]} -exec rm {} \;"));
    
    // Create tar
    output(shell_exec("tar cvfz {$target}/{$backup}.{$date}.tar.gz -C / {$backuparray[$i]}"));
}

// Loop through dropbox array
for($i = 0; $i < count($dbbackuparray); $i++)
{
    // Replace / with .
    $backup = str_replace("/", ".", $dbbackuparray[$i]);
    
    // Remove old files
    output(shell_exec("find {$target}/*{$backup}* -mtime {$dbtimearray[$i]} -exec rm {} \;"));
    
    // Create archive
    output(shell_exec("openssl des3 -salt -k {$dbpassphrase} -in {$target}/{$backup}.{$date}.tar.gz -out {$dbtarget}{$dbsubfolderarray[$i]}/{$backup}.{$date}.tar.gz.encrypted"));
}
?>
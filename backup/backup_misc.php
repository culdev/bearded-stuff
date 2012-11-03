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

// Add hostname to target
$target = $target."/".$hostname;

// Check array sizes
if(count($backuparray) != count($timearray))
    exit("Array sizes doesn't match.");

// Loop through array
for($i = 0; $i < count($backuparray); $i++)
{
    // Replace / with .
    $backup = str_replace("/", ".", $backuparray[$i]);
    
    // Remove old files
    output(shell_exec("find {$target}/*{$backup}* -mtime {$timearray[$i]} -exec rm {} \;"));
    
    // Create tar
    output(shell_exec("tar cvfz {$target}/{$backup}.{$date}.tar.gz"));
}
?>
<?php
set_include_path(dirname(__FILE__).'/lib');
require 'lib/Net/SSH2.php';
require 'lib/Crypt/RSA.php';
require 'lib/colors.php';

// Date
date_default_timezone_set("Europe/Stockholm");
$date = date("Ymd");

// Remote Settings
$server = array(0 => "serverone");
// Directories to backup without /, it gets added later if needed
$basedir = "var/archives";
$dirs = array(0 => array("HOSTNAME-var-lib-mysql.{$date}.tar.gz")); // HOSTNAME will be replaced later
// Directories to exclude, separate with space
$dirsblacklist = array(0 => array());

// SSH Settings
$keyfile = "id_rsa";
$sshuser = "backupuser";
$tmpdir = "/tmp"; // On remote server
$nicelevel = "10"; // must be between -20 (most favorable) and +19 (least favorable)
$ionicelevel = "3"; // must be 1 (realtime) or 2 (best-effort) or 3 (idle)

// Local settings
$archivedir = "/var/backups"; // All backups will be stored here
$archivepass = "1234"; // Password for encrypted backup
$pidfile = "/tmpram/backup_dropbox_incremental.pid"; // Runtime file is saved here

$debug = false;

$colors = new Colors(); // CLI colors
$vars = array(); // temp array for error checking

/**
 * Prints $o with linebreak at the end if not empty.
 *
 * @param anything $o
 */
function out($o)
{
    echo (empty($o) ? "" : $o."\n");
}

// Check PID file
if(file_exists($pidfile))
{
    out($colors->getColoredString("{$pidfile} exists.", "yellow"));

    $content = str_replace("\n", "", file_get_contents($pidfile));

    if(file_exists("/proc/{$content}"))
        exit(out($colors->getColoredString("Process with PID {$content} is still running. Exiting.", "red")));
}

// Write PID file
$pid = getmypid();

if($debug)
    echo "Writing pid {$pid} to {$pidfile}... ";

exec("echo {$pid} > {$pidfile}");

if($debug)
    out($colors->getColoredString("Done.", "green"));

// Verify array sizes
$vars['server'] = count($server);
$vars['dirs'] = count($dirs);
$vars['dirsblacklist'] = count($dirsblacklist);

if($vars['server'] != $vars['dirs'] || $vars['server'] != $vars['dirsblacklist'] || $vars['dirs'] != $vars['dirsblacklist'])
    exit(out("Server doesn't match dirs and dirsblacklist."));

// Nicelevel
if($nicelevel < -20 || $nicelevel > 19)
    exit(out("Nicelevel must be between -20 and +19."));

// Ionicelevel
if($ionicelevel < 1 || $ionicelevel > 3)
    exit(out("Ionicelevel must be between 1 and 3."));

if(empty($archivepass))
    exit(out("Archivepass can't be empty."));

if(empty($archivedir))
    exit(out("Archivedir can't be empty."));

for($s = 0; $s < count($server); $s++)
{
    try
    {
        if($debug)
            out("Server {$server[$s]}:");

        // Setup
        $ssh = new Net_SSH2($server[$s]);
        $key = new Crypt_RSA();
        $key->loadKey(file_get_contents($keyfile));

        // Login to sever
        if(!$ssh->login($sshuser, $key))
            throw new Exception("SSH failed on server ${server[$s]}.");

        $hostname = str_replace("\n", "", $ssh->exec("hostname"));

        // Go through each folder
        for($d = 0; $d < count($dirs[$s]); $d++)
        {
            $folder = str_replace("HOSTNAME", $hostname, $dirs[$s][$d]); // replace HOSTNAME
            $folderexclude = $dirsblacklist[$s];
            if($debug)
                out("Folder: {$folder}");

            // Replace / with .
            $folderclean = str_replace("/", ".", $folder);
            $folder = $basedir.'/'.$folder;

            // Exclude folders
            $exclude = "";
            if(!empty($dirsblacklist[$s]))
            {
                $exclude .= "--exclude={";

                foreach($dirsblacklist[$s] as $e)
                    $exclude .= "\"{$e}\",";

                $exclude .= "}";
            }
            if($debug)
                out("Files to exclude: {$exclude}");

            // Filenames
            $filename = "{$folderclean}.encrypted";
            $backup = "{$tmpdir}/{$filename}";
            $target = "{$archivedir}/{$hostname}/{$filename}";
            
            // Create destination folder
            if($debug)
                echo "Creating destination folder... ";
            if(@mkdir("{$archivedir}/{$hostname}") && $debug)
                out($colors->getColoredString("Done.", "green"));
            else if($debug)
                out($colors->getColoredString("Already exists.", "yellow"));

            // Create tar
            if($debug)
                echo "Creating encrypted tar... ";

            exec("nice -n {$nicelevel} ionice -c {$ionicelevel} ssh {$sshuser}@${server[$s]} \"".
                    "nice -n {$nicelevel} ionice -c {$ionicelevel} tar chf - -C / {$folder} {$exclude} |".
                        " nice -n {$nicelevel} ionice -c {$ionicelevel} openssl des3 -salt -k \\\"{$archivepass}\\\"".
                            "\" > {$target}");

            if($debug)
                out($colors->getColoredString("Done.", "green"));

            // Calculate md5
            if($debug)
                echo "Calculating and dumping md5 sum... ";

            exec("md5sum {$target} | awk '{ print $1 }' > {$target}.md5");

            if($debug)
                out($colors->getColoredString("Done.", "green"));

            if($debug)
                out(" ");
        }
    }
    catch(Exception $e)
    {
        out("\n".$colors->getColoredString($e->getMessage(), "red"));
    }
}

// Clear pid file
if($debug)
    echo "Removing pidfile... ";

$vars['pidfile'] = unlink($pidfile);

if($debug && $vars['pidfile'])
    out($colors->getColoredString("Done.", "green"));
else if(!$vars['pidfile'])
    out($colors->getColoredString("Failed to remove PID file {$pidfile}:\n{$vars['pidfile']}", "red"));
?>
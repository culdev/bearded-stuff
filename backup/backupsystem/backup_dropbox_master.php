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
$dirs = array(0 => array("HOSTNAME-var-lib-mysql.{$date}.master.tar.gz")); // HOSTNAME will be replaced later
// Directories to exclude, separate with space
$dirsblacklist = array(0 => array());
$days = "+1"; // Amount of days to save the backups

// SSH Settings
$keyfile = "id_rsa";
$sshuser = "backupuser";
$tmpdir = "/tmp"; // On remote server
$nicelevel = "10"; // must be between -20 (most favorable) and +19 (least favorable)
$ionicelevel = "3"; // must be 1 (realtime) or 2 (best-effort) or 3 (idle)

// Local settings
$archivedir = "/var/backups"; // All backups will be stored here
$archivepass = "1234"; // Password for encrypted backup
$pidfile = "/tmpram/backup_dropbox_master.pid"; // Runtime file is saved here

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

            // Create tar
            if($debug)
                echo "Creating encrypted tar... ";

            $vars['tar'] = $ssh->exec(
                    "nice -n {$nicelevel} ionice -c {$ionicelevel} tar zchf - -C / {$folder} {$exclude} |".
                        " nice -n {$nicelevel} ionice -c {$ionicelevel} openssl des3 -salt -k \"{$archivepass}\" |".
                            " nice -n {$nicelevel} ionice -c {$ionicelevel} dd of={$backup} 2> /dev/null");

            if($debug && empty($vars['tar']))
                out($colors->getColoredString("Done.", "green"));
            else if(!empty($vars['tar']))
                out($colors->getColoredString("{$vars['tar']}"));

            // Calculate md5
            if($debug)
                echo "Calculating md5 sum... ";

            $md5 = str_replace("\n", "", $ssh->exec("md5sum {$backup} | awk '{ print $1 }'"));

            if($debug)
                out($colors->getColoredString("Done.", "green"));

            // Create destination folder
            if($debug)
                echo "Creating destination folder... ";
            if(@mkdir("{$archivedir}/{$hostname}"))
                out($colors->getColoredString("Done.", "green"));
            else if($debug)
                out($colors->getColoredString("Already exists.", "yellow"));

            if($debug)
                echo "Transferring {$backup}... ";

            // Transfer tar
            $target = "{$archivedir}/{$hostname}/{$filename}";
            exec("scp {$sshuser}@{$server[$s]}:{$backup} {$target}");

            if($debug)
                out($colors->getColoredString("Complete.", "green"));

            // Calculate destination md5
            if($debug)
                echo "Calculating md5... ";
            $md5dest = exec("md5sum {$target} | awk '{ print $1 }'");
            if($debug)
                out($colors->getColoredString("Done.", "green"));

            // Compare
            if($debug)
                out("Comparing md5 sums:\n{$md5}\n{$md5dest}");
            if($md5 != $md5dest)
                out($colors->getColoredString("Md5 sums doesn't match! Continuing anyway.", "red"));
            else if($debug)
                out($colors->getColoredString("Md5 sums match.", "green"));

            // Create md5 file
            if($debug)
                echo "Dumping md5 files... ";

            exec("echo {$md5dest} > {$target}.md5");
            exec("echo {$md5} > {$target}.md5remote");

            if($debug)
                out($colors->getColoredString("Done.", "green"));

            // Remove tmp files
            if($debug)
                echo "Removing temporary files from remote server... ";

            $vars['tmp'] = $ssh->exec("rm {$backup}");

            if($debug && empty($vars['tmp']))
                out($colors->getColoredString("Done.", "green"));
            else if(!empty($vars['tmp']))
                throw new Exception("Failed to remove {$backup} from {$server[$s]}:\n{$vars['tmp']}");

            // Remove old archives
            if($debug)
                echo "Removing old archives... ";

            exec("nice -n {$nicelevel} ionice -c {$ionicelevel} find {$archivedir}/{$hostname}/*{$folderclean}* -mtime {$days} -exec rm {} \;");

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
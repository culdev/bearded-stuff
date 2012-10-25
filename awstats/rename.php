<?php
// CLI
if(count($argv) <= 1)
    die("You must supply a directory argument, e.g php $argv[0] testfolder\n");

$dir = $argv[1];
if($handle = opendir($dir))
{
	while(false !== ($file = readdir($handle)))
	{
		if($file != "." && $file != "..")
		{
			$pathinfo = pathinfo($file);
            
            if(!strpos($file, $dir))
            {
                $newname = $pathinfo['filename'].'.'.$dir.'.'.$pathinfo['extension'];
                rename($dir.DIRECTORY_SEPARATOR.$file, $dir.DIRECTORY_SEPARATOR.$newname);
            }
		}
	}
}
?>

<?php

function DownloadAddress()
{
    return("http://prdownloads.sourceforge.net/adium/AdiumX_0.52.dmg?download");
}

function DownloadSourceAddress()
{
    return("http://prdownloads.sourceforge.net/adium/AdiumX_Source_0.52.tar.gz?download");
}

function DownloadTitle()
{
    return("Download v0.52");
}

function DownloadVersion()
{
    return("0.52");
}



/*
// Returns an HTML download link to the newest binary
//
// $searchPath: path to the binary folder
// $linkTitle: title for the download link
//
function NewestBinary($searchPath, $linkTitle)
{
	$newestTime = 0;
	$downloadDir = dir($searchPath);

	while( $file = $downloadDir->read() ){
	
		if( strstr( $file , ".dmg") && stristr( $file , "Adium") && !is_link("$searchPath/$file")){
	
			$createTime = filemtime("$searchPath/$file");
			
			if( $createTime > $newestTime ){
				$newestTime = $createTime;
				$newestFile = $file;
			}
	
		}
	
	}

	$downloadDir->close();
        
    //$changelog = "$searcHPath/downloads/ChangeLogs/ChangeLog_" . date("m-d-Y", $newestTime);
        
    //    return "<a href=\"$searchPath/$newestFile\">$linkTitle</a> " .
    //        "<a href=\"$changelog\">Changes</a><br/>".
    //        "<span class=\"date\">".date( "F d, Y" , $newestTime )."</span><br>";
    return "<a class=\"download\" href=\"$searchPath/$newestFile\" title=\"".date( "F d, Y" , $newestTime )." (".fsize("$searchPath/$newestFile").")"."\">$linkTitle</a>";
}


// Returns the size of a file in an easy to read form
//
// $file: file who's size we want
//
function fsize($file)
{ 
	$a = array("B", "KB", "MB", "GB", "TB", "PB"); 

	$pos = 0; 
	$size = filesize($file); 
	while ($size >= 1024) { 
		$size /= 1024; 
		$pos++; 
	} 

	return round($size,1)." ".$a[$pos]; 
}


// Returns an HTML list of available binary releases, sorted by date.
//
// $searchPath: path to the binary folder
// $count: number of binaries to display
//
function BinaryList ($searchPath, $count)
{
	$htmlOutput = '';
	
	// Get an array of binaries
	$downloadDir = dir($searchPath);
	$index = 0;
	while( $file = $downloadDir->read() )
	{
		if( strstr( $file , ".dmg") && strstr( $file , "Adium") && !strstr( $file, "src") && !is_link("$searchPath/$file"))
		{

			$binary['name'][$index] = $file;
			$binary['date'][$index] = filemtime("$searchPath/$file");
			$binary['size'][$index] = fsize("$searchPath/$file");
			$index++;
			
		}
	}
	$downloadDir->close();
	
	// Sort the array by date
	arsort( $binary['date'] );

	// Build a table from the array	
	while($count > 0 && list($index) = each($binary['date'])){
		
		$changelog = explode('_', $binary['name'][$index]);
		$changelog = explode('.', $changelog[1]);
		$changelog = $changelog[0];
		
		if(!$first) $htmlOutput .= '<b>';

		$htmlOutput .= '<a href="'.$searchPath.'/'.$binary['name'][$index].'" class="hidden">'.
					   '<img src="images/download3618.png" align="center" width="36" height="18" border="0">'.
					   date("F d, Y" , $binary['date'][$index]).' ('.$binary['size'][$index].')</a> (<a class="hidden" href="'.$searchPath.'/ChangeLogs/ChangeLog_'.$changelog.'">Changes</a>)<br>'."\n";

		if(!$first){
			$htmlOutput .= '</b>';
			$first = true;
		}
		
		$count--;
	}

	//
	return($htmlOutput);
}
*/
?>

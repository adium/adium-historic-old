<?php

// Returns an HTML bar of dynamic tabs
//
// $tabPath: Path to a folder of tabs (must contain an index.txt tab list file)
// $selected: ID of the currently selected tab
//
function DynamicTabs($tabPath, $selected)
{
	$tabArray = file($tabPath);
	$htmlOutput = "";
	
	foreach( $tabArray as $tab ){

		if(substr($tab, 0, 1) != "#"){ //Ignore commented lines
			
			$tabProperties = explode(", ", $tab);
			
			if( trim($tabProperties[3]) == "yes"){ //Tab visible
			
				if( trim($tabProperties[0]) == $selected ){
					$htmlOutput .= "<li><span id=\"current\">$tabProperties[2]</span></li>\n";
					
				}else{
					$htmlOutput .= "<li><a href=\"$tabProperties[1]\">$tabProperties[2]</a></li>\n";
				}

			}			

		}

	}

	return($htmlOutput);
}

// Returns an array of details for the specified page ID
// Array contains: Tab ID, file name, display name, sideBarVisible
//
// $tabPath: Path to a folder of tabs (must contain an index.txt tab list file)
// $page: ID of the desired tab
//
function detailsForPage($tabPath, $page)
{
	$tabArray = file($tabPath);
	
	foreach($tabArray as $tab){
		$tabProperties = explode(", ", $tab);

		if(trim($tabProperties[0]) == $page) break;
	}
	
	return($tabProperties);
}

?>
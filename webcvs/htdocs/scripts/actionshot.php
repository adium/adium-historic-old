<?php

function getDirList ($dirName) {
    $array = array();
    $d = dir($dirName);
    while($entry = $d->read()) { 
        if ($entry != "." && $entry != ".." && $entry != ".DS_Store") { 
            if (is_dir($dirName."/".$entry)) { 
                getDirList($dirName."/".$entry); 
            } else { 
                $array[] = $entry; 
            } 
        } 
    } 
    $d->close();
    return $array;
} 

function RandomActionShoot()
{
    $thumbsDir = "images/actionthumbs";
    $picturesDir = "images/actionshots";
    $picturesList = getDirList($picturesDir);
    
    $index = rand(0, count($picturesList)-1);
    $picture = $picturesList[$index];
    list($picWidth, $picHeight, $type, $attr) = getimagesize($picturesDir."/".$picture);
    list($thumbWidth, $thumbHeight, $type, $attr) = getimagesize($thumbsDir."/".$picture);
    
    return "<a href=\"$picturesDir/$picture\" onclick=\"window.open('$picturesDir/$picture','popup','width=$picWidth,height=$picHeight,scrollbars=yes,toolbar=no,status=yes'); return false\"><img src=\"$thumbsDir/$picture\" width=\"$thumbWidth\" height=\"$thumbHeight\" alt=\"actionshot\" /></a>";
}

function RandomActionShot($numberOfShots)
{
    $availablePics = getDirList($picturesDir);

    //Try and choose $numberOfShots pictures
    while($numberOfShots > 0){
        $picture = array_rand($availablePics);
        if(array_search($picture, $chosenPics) === false){ //Skip if already choosen
            $chosenPics[count($chosenPics)] = $picture;
        }

        $numberOfShots--;
    }
    
    //Return HTML for the choosen pictures
    $html = "";
    foreach($chosenPics as $picture){
        $html .= "<a href=\"$picturesDir/$picture\" onclick=\"window.open('$picturesDir/$picture','popup','width=$picWidth,height=$picHeight,scrollbars=yes,toolbar=no,status=yes'); return false\"><img src=\"$thumbsDir/$picture\" width=\"$thumbWidth\" height=\"$thumbHeight\" alt=\"actionshot\" /></a><br /><br />";
    }

    return($html);
}

?>








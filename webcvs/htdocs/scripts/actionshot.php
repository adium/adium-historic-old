<?php

function getDirList ($dirName) {
    $array = array();
    $d = dir($dirName);
    while($entry = $d->read()) { 
        if ($entry != "." && $entry != ".." && $entry != ".DS_Store") { 
            if (is_dir($dirName."/".$entry)) { 
                getDirList($dirName."/".$entry); 
            } else { 
            $array[] = $dirName."/".$entry; 
            } 
        } 
    } 
    $d->close();
    return $array;
} 

function RandomActionShoot()
{
    $picturesDir = "images/actionshots";
    $picturesList = getDirList($picturesDir);
    
    $index = rand(0, count($picturesList)-1);
    $picture = $picturesList[$index];
    list($originalwidth, $originalheight, $type, $attr) = getimagesize($picture);
    if ($originalwidth > 160) {
        $proportion = $originalwidth / 160;
        $width = 160;
        $height = (int) ceil($originalheight / $proportion);
    }
    
    return "<a href=\"$picture\" onclick=\"window.open('$picture','popup','width=$originalwidth,height=$originalheight,scrollbars=yes,toolbar=no,status=yes'); return false\"><img src=\"$picture\" width=\"$width\" height=\"$height\" alt=\"actionshot\" /></a>";
}

?>
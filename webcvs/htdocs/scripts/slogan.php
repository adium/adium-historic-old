<?php

// Grab a random slogan from our file
//
function RandomSlogan()
{
    $sloganArray = file("parts/slogans.txt");
    $slogan = "#";
    $tries = 0;

    while($slogan{0} == "#"){ //Ignore comments
        //Pull a random slogan
        $index = rand(0, count($sloganArray)-1);
        $slogan = $sloganArray[$index];

        //Just incase something goes very wrong (5 tries max)
        $tries = $tries + 1;
        if($tries > 5) return("");
    }

    return($slogan);
}
?>
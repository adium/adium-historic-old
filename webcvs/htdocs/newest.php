<?php
    require("scripts/binaries.php");
?>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title><?php echo DownloadTitle(); ?></title>
<link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
<meta http-equiv="refresh" content="0;url=<?php echo DownloadAddress(); ?>">
</head>
<body>
<a href="<?php echo DownloadAddress(); ?>"><?php echo DownloadAddress(); ?></a>
</body>
</html>

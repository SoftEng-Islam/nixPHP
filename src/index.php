<?php
setcookie("fav_food", "pizza", time() + (86400 * 2), "/");

session_start();

include("header.html");
?>
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>myPage</title>
    <style>
        * {
            padding: 0;
            border: none;
            outline: none;
            box-sizing: border-box;
        }

        body {
            padding: 10px;
            font-family: 'Courier New', Courier, monospace;
            background: rgb(39, 39, 39);
            color: wheat;
        }
    </style>
</head>

<body>
</body>

<?php
include("footer.html");
?>

</html>
<?php

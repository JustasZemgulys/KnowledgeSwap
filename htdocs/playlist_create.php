<?php
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "mellowde";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die("Prisijungimo klaida: " . $conn->connect_error);
}

function createPlaylist($name, $description, $imageUrl, $userId) {
    global $conn;

    // Įterpiame naują įrašą į `playlist` lentelę
    $query = "INSERT INTO playlist (name, description, imageUrl, userId) VALUES ('$name', '$description', '$imageUrl', '$userId')";

    if ($conn->query($query) === TRUE) {
        echo "Playlistas sukurtas sėkmingai.";

        // Gauti naujai sukurtą playlist'o ID
        $playlistId = $conn->insert_id;

        // Įterpiame naują įrašą į `playlistuser` lentelę
        $queryPlaylistUser = "INSERT INTO playlistuser (userRole, playlistId, userId) VALUES ('user', '$playlistId', '$userId')";

        if ($conn->query($queryPlaylistUser) === TRUE) {
            echo "Playlisto naudotojas sukurtas sėkmingai.";
        } else {
            echo "Klaida įdedant į playlistuser lentelę: " . $conn->error;
        }

        // ... galite pridėti kitus veiksmus, pvz., įkelti nuotrauką ir gauti jos URL
    } else {
        echo "Klaida įdedant į playlist lentelę: " . $conn->error;
    }
}

// Pavyzdinė užklausa su post duomenimis
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $target_dir = "images/";  // Directory where images will be stored
    $target_file = $target_dir . basename($_FILES["file"]["name"]);
    $uploadOk = 1;
    $imageFileType = strtolower(pathinfo($target_file, PATHINFO_EXTENSION));

    // Check if image file is a actual image or fake image
    if (isset($_POST["submit"])) {
        $check = getimagesize($_FILES["file"]["tmp_name"]);
        if ($check !== false) {
            echo "File is an image - " . $check["mime"] . ".";
            $uploadOk = 1;
        } else {
            echo "File is not an image.";
            $uploadOk = 0;
        }
    }

    // Check if file already exists
    if (file_exists($target_file)) {
        echo "Sorry, file already exists.";
        $uploadOk = 0;
    }

    // Check file size
    if ($_FILES["file"]["size"] > 500000) {
        echo "Sorry, your file is too large.";
        $uploadOk = 0;
    }

    // Allow certain file formats
    if ($imageFileType != "jpg" && $imageFileType != "png" && $imageFileType != "jpeg"
        && $imageFileType != "gif") {
        echo "Sorry, only JPG, JPEG, PNG & GIF files are allowed.";
        $uploadOk = 0;
    }

    // Check if $uploadOk is set to 0 by an error
    if ($uploadOk == 0) {
        echo "Sorry, your file was not uploaded.";
    } else {
        // if everything is ok, try to upload file
        if (move_uploaded_file($_FILES["file"]["tmp_name"], $target_file)) {
            echo "The file " . basename($_FILES["file"]["name"]) . " has been uploaded.";
            $name = $_POST["name"];
            $description = $_POST["description"];
            $imageUrl = "http://10.0.2.2/" . $target_file;
            $userId = $_POST["userId"];

            echo "Recieved userid: " . $userId . "\n";

            createPlaylist($name, $description, $imageUrl, $userId);
        } else {
            echo "Sorry, there was an error uploading your file.";
        }
    }
}

$conn->close();
?>

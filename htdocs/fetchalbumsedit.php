<?php
// Database connection parameters
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "mellowde"; // Replace with your actual database name

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Check if idUser is set in the request
if (isset($_GET['idUser'])) {
    $idUser = $_GET['idUser'];

    // Fetch idArtist based on idUser
    $sqlArtist = "SELECT idArtist FROM artist WHERE idUser = $idUser";
    $resultArtist = $conn->query($sqlArtist);

    if ($resultArtist->num_rows > 0) {
        $rowArtist = $resultArtist->fetch_assoc();
        $idArtist = $rowArtist['idArtist'];

        // Fetch all albums of the artist
        $sqlAlbums = "SELECT * FROM album WHERE idArtist = $idArtist";
        $resultAlbums = $conn->query($sqlAlbums);

        if ($resultAlbums->num_rows > 0) {
            // Output albums as JSON
            $albums = array();

            while ($rowAlbum = $resultAlbums->fetch_assoc()) {
                $albums[] = $rowAlbum;
            }

            echo json_encode($albums);
        } else {
            echo json_encode(array('message' => 'No albums found for the artist'));
        }
    } else {
        echo json_encode(array('message' => 'No artist found for the given user'));
    }
} else {
    echo json_encode(array('message' => 'idUser parameter is required'));
}

// Close the database connection
$conn->close();
?>

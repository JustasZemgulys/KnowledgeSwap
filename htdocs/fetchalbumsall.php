<?php
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "mellowde";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Fetch albums with artist information
$sql = "SELECT album.*, user.name as artistName
        FROM album
        INNER JOIN artist ON album.IdArtist = artist.idArtist
        INNER JOIN user ON artist.idUser = user.idUser";
$result = $conn->query($sql);

$albums = array();

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $albums[] = $row; // Store the entire row in $albums
    }
}

// Send the albums as JSON
header('Content-Type: application/json');
echo json_encode($albums);

$conn->close();
?>

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

// Assuming you have received IdAlbum from the Flutter app
$IdAlbum = $_GET['IdAlbum'];

// Fetch songs with artist names based on IdAlbum
$sql = "SELECT song.*, user.name as artistName 
        FROM song 
        JOIN artist ON song.idArtist = artist.idArtist
        JOIN user ON artist.idUser = user.idUser 
        WHERE song.idAlbum = $IdAlbum";

$result = $conn->query($sql);

$songs = array();

if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $songs[] = $row;
    }
}

// Send the songs as JSON
header('Content-Type: application/json');
echo json_encode($songs);

$conn->close();
?>

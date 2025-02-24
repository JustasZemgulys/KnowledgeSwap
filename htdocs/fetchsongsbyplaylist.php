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

// Get playlist ID from the POST request
$playlistId = $_POST['playlistId'];

// Fetch songs with artist names based on playlistId
$sql = "SELECT song.*, user.name as artistName 
        FROM song 
        JOIN artist ON song.idArtist = artist.idArtist
        JOIN user ON artist.idUser = user.idUser 
        JOIN playlistsongs ON song.idSong = playlistsongs.IdSong
        WHERE playlistsongs.IdPlaylist = $playlistId";

$result = $conn->query($sql);

$response = array();

if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $response['songs'][] = $row;
    }

    $response['songsCount'] = count($response['songs']);
} else {
    $response['songsCount'] = 0;
}

// Close the database connection
$conn->close();

// Send the response as JSON
header('Content-Type: application/json');
echo json_encode($response);
?>

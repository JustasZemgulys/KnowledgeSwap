<?php

// Assuming you have a database connection
$host = "localhost";
$username = "root";
$password = "";
$database = "mellowde";

$conn = new mysqli($host, $username, $password, $database);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Retrieve user's favorite genres (replace with your authentication mechanism)
$userId = $_GET['user_id']; // Assuming you pass the user ID from Flutter

// Fetch songs based on user's favorite genres
$sql = "SELECT s.idSong, u.name as artistName, s.title, s.coverURL, s.songURL
        FROM song s
        INNER JOIN favouritegenre fg ON s.IdGenre = fg.IdGenre
        INNER JOIN artist a ON s.IdArtist = a.IdArtist
        INNER JOIN user u ON a.idUser = u.idUser
        WHERE fg.idUser = $userId";

$result = $conn->query($sql);

$songs = [];

if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $songs[] = $row;
    }
}

echo json_encode($songs);

$conn->close();

?>

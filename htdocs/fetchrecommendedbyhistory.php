<?php
// Database connection details
$host = "localhost";
$user = "root";
$password = "";
$database = "mellowde";

// Create connection
$conn = new mysqli($host, $user, $password, $database);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Get the user ID from the request
$userID = $_GET['user_id'];

// Fetch songs that the user hasn't listened to
$query = "SELECT s.idSong, u.name as artistName, s.title, s.coverURL, s.songURL
          FROM song s
          INNER JOIN artist a ON s.IdArtist = a.IdArtist
          INNER JOIN user u ON a.idUser = u.idUser
          WHERE s.idSong NOT IN (
              SELECT idSong FROM user_history WHERE idUser = $userID
          )";

$result = $conn->query($query);

if ($result) {
    $songs = array();

    while ($row = $result->fetch_assoc()) {
        $songs[] = $row;
    }

    // Return the result as JSON
    header('Content-Type: application/json');
    echo json_encode($songs);
} else {
    // Handle the error
    http_response_code(500);
    echo "Error: " . $conn->error;
}

// Close the database connection
$conn->close();
?>
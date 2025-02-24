<?php
// Replace with your database connection details
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

// Retrieve comment data, idUser, and idSong from POST request
$commentText = $_POST['comment_text'];
$idUser = $_POST['idUser'];
$idSong = $_POST['idSong'];

// Insert the new comment into the commentSong table for the currently playing song
$sql = "INSERT INTO commentSong (commentSong, idSong, idUser) VALUES ('$commentText', '$idSong', '$idUser')";

if ($conn->query($sql) === TRUE) {
    echo "Comment inserted successfully";
} else {
    echo "Error: " . $sql . "<br>" . $conn->error;
}

$conn->close();
?>

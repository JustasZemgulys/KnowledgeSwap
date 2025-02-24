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

// Get song ID and playlist ID from the POST request
$songId = $_POST['songId'];
$playlistId = $_POST['playlistId'];

// Remove the song from the playlistsongs table
$sql = "DELETE FROM playlistsongs WHERE IdSong = '$songId' AND IdPlaylist = '$playlistId'";

if ($conn->query($sql) === TRUE) {
    $response = array('success' => true, 'message' => 'Song removed successfully');
} else {
    $response = array('success' => false, 'message' => 'Error removing song: ' . $conn->error);
}

// Close the database connection
$conn->close();

// Send the response as JSON
header('Content-Type: application/json');
echo json_encode($response);
?>

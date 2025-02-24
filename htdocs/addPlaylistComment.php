<?php
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "mellowde";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $playlistId = $_POST['playlistId'];
    $comment = $_POST['comment'];
    $userID = $_POST['userId'];
    // Add other required fields like userId if needed
    
    // Your SQL query to add a comment to the database
    $sql = "INSERT INTO commentplaylist (playlistId, commentPlaylist, userId) VALUES ('$playlistId', '$comment', '$userID');";
    
    // Execute the query
    if (mysqli_query($conn, $sql)) {
        echo json_encode(['success' => true]);
    } else {
        echo json_encode(['success' => false]);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
}
?>
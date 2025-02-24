<?php
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "mellowde";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $commentId = $_POST['commentId'];
    $newComment = $_POST['newComment'];
    
    // Your SQL query to update a comment in the database
    $sql = "UPDATE commentplaylist SET commentPlaylist = '$newComment' WHERE commentPlaylistId = '$commentId'";
    
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
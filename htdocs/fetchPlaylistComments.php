<?php
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "mellowde";

$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

    // Validate and sanitize the input
$playlistId = $_POST['playlistId'];

$sql = "SELECT cp.commentPlaylistId, cp.commentPlaylist, cp.playlistId, cp.userId
        FROM commentplaylist cp
        WHERE cp.playlistId = $playlistId";

// Get the result
$result = $conn->query($sql);

if ($result === FALSE) {
    die("Error in SQL query: " . $conn->error);
}

// Check if there are rows in the result
if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $comments[] = array(
            'commentPlaylistId' => $row['commentPlaylistId'],
            'commentPlaylist' => $row['commentPlaylist'], // Use empty string if null
            'playlistId' => $row['playlistId'],
            'userId' => $row['userId'],
        );
    }

    // Send JSON response
    echo json_encode($comments);
} else {
    // No comments found for the specified playlistId
    echo json_encode(['message' => 'No comments found for the specified playlistId']);
}

// Close the database connection
$conn->close();
?>

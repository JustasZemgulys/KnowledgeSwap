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

// Replace with the actual idSong of the currently playing song
$idSong = $_POST['idSong'];

// Fetch comments for the currently playing song from the database
$sql = "SELECT cs.idCommentSong, cs.commentSong, cs.idSong, cs.idUser, u.username
        FROM commentSong cs
        JOIN user u ON cs.idUser = u.idUser
        WHERE cs.idSong = $idSong";

$result = $conn->query($sql);

if ($result === FALSE) {
    die("Error in SQL query: " . $conn->error);
}

if ($result->num_rows > 0) {
    $comments = array();

    while ($row = $result->fetch_assoc()) {
        $comments[] = array(
            'idCommentSong' => $row['idCommentSong'],
            'commentSong' => $row['commentSong'],
            'idSong' => $row['idSong'],
            'idUser' => $row['idUser'],
            'username' => $row['username']
        );
    }

    // Return comments as JSON
    echo json_encode($comments);
} else {
    echo "No comments found for the current song";
}

$conn->close();
?>

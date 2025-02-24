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

// Retrieve comment ID from POST request
$commentId = $_POST['comment_id'];

// Delete the comment from the database
$sql = "DELETE FROM commentSong WHERE idCommentSong = $commentId";

if ($conn->query($sql) === TRUE) {
    echo "Comment deleted successfully";
} else {
    echo "Error deleting comment: " . $conn->error;
}

$conn->close();
?>

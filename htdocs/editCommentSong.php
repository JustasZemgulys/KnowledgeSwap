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

// Retrieve comment ID and edited comment text from POST request
$commentId = $_POST['comment_id'];
$editedComment = $_POST['edited_comment'];

// Update the comment in the database
$sql = "UPDATE commentSong SET commentSong = '$editedComment' WHERE idCommentSong = $commentId";

if ($conn->query($sql) === TRUE) {
    echo "Comment edited successfully";
} else {
    echo "Error editing comment: " . $conn->error;
}

$conn->close();
?>

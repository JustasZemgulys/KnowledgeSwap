<?php
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "mellowde";

$conn = new mysqli($servername, $username, $password, $dbname);

// Check if the necessary parameters are set
if (isset($_POST['commentId'], $_POST['newComment'])) {
    // Sanitize the input
    $commentId = filter_var($_POST['commentId'], FILTER_SANITIZE_NUMBER_INT);
    $newComment = filter_var($_POST['newComment'], FILTER_SANITIZE_STRING);

    // Update the comment in the database
    $sql = "UPDATE commentplaylist SET commentPlaylist = ? WHERE commentPlaylistId = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param('si', $newComment, $commentId);

    if ($stmt->execute()) {
        $response['success'] = true;
        $response['message'] = 'Comment updated successfully';
    } else {
        $response['success'] = false;
        $response['message'] = 'Failed to update comment';
    }

    // Close the statement
    $stmt->close();
} else {
    $response['success'] = false;
    $response['message'] = 'Invalid parameters';
}

// Close the database connection
$conn->close();

// Send the JSON response
header('Content-type: application/json');
echo json_encode($response);

?>
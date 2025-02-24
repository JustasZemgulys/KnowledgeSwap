<?php
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "mellowde";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die("Prisijungimo klaida: " . $conn->connect_error);
}

// Check if the required POST parameter is set
if (isset($_POST['playlistId'])) {
    $playlistId = $_POST['playlistId'];

    // Delete the corresponding row from the playlistuser table
    $deletePlaylistUserQuery = "DELETE FROM playlistuser WHERE playlistId = ?";
    $stmt = $conn->prepare($deletePlaylistUserQuery);
    $stmt->bind_param("i", $playlistId);

    if ($stmt->execute()) {
        $stmt->close();

        // Now, delete the playlist from the playlist table
        $deletePlaylistQuery = "DELETE FROM playlist WHERE playlistId = ?";
        $stmt = $conn->prepare($deletePlaylistQuery);
        $stmt->bind_param("i", $playlistId);

        if ($stmt->execute()) {
            $stmt->close();
            echo "Playlist and related user entry deleted successfully.";
        } else {
            echo "Error deleting playlist: " . $stmt->error;
        }
    } else {
        echo "Error deleting playlistuser entry: " . $stmt->error;
    }
} else {
    echo "Missing 'playlistId' parameter in the request.";
}

$conn->close();
?>

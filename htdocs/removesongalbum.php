<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $songId = isset($_POST['songId']) ? $_POST['songId'] : '';

    if (!empty($songId)) {
        $conn = new mysqli("localhost", "root", "", "mellowde");

        if ($conn->connect_error) {
            die("Connection failed: " . $conn->connect_error);
        }

        // Update the song's idAlbum to null to remove it from the album
        $query = "UPDATE song SET idAlbum = NULL WHERE idSong = $songId";

        if ($conn->query($query) === TRUE) {
            echo "Song removed from the album successfully.";
        } else {
            echo "Error removing song: " . $conn->error;
        }

        $conn->close();
    } else {
        echo "Invalid song ID.";
    }
} else {
    echo "Invalid request method.";
}
?>

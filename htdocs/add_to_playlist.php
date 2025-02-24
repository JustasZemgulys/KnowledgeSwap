<?php
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "mellowde";

$conn = new mysqli($servername, $username, $password, $dbname);

// Check if the required parameters are set
if (isset($_POST['songId']) && isset($_POST['playlistId']) && isset($_POST['userId'])) {
    $songId = $_POST['songId'];
    $playlistId = $_POST['playlistId'];
    $userId = $_POST['userId'];

    // Insert the record into the playlistsongs table
    $query = "INSERT INTO playlistsongs (IdSong, IdPlaylist, IdUser) VALUES ('$songId', '$playlistId', '$userId')"; // Assuming IdUser is a foreign key
    $result = mysqli_query($conn, $query);

    if ($result) {
        echo "Song added to playlist successfully.";
    } else {
        echo "Error: " . mysqli_error($conn);
    }
} else {
    echo "Error: Required parameters are missing.";
}
?>
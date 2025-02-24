<?php
// Database connection parameters
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

// Check if idSong and idAlbum are set in the request
if (isset($_POST['idSong']) && isset($_POST['idAlbum'])) {
    $idSong = $_POST['idSong'];
    $idAlbum = $_POST['idAlbum'];

    // Update the song with the given idSong to have the specified idAlbum
    $sql = "UPDATE song SET idAlbum = $idAlbum WHERE idSong = $idSong";

    if ($conn->query($sql) === TRUE) {
        echo "Song updated successfully";
    } else {
        // Log the error to a file
        error_log("Error updating song: " . $conn->error, 3, "error_log.txt");

        // Output the error message
        echo "Error updating song. Please check the server logs for more details.";
    }
} else {
    // Log the missing parameters error to a file
    error_log("idSong and idAlbum parameters are required", 3, "error_log.txt");

    // Output the error message
    echo "idSong and idAlbum parameters are required";
}

// Close the database connection
$conn->close();
?>

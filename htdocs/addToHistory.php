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

// Check if idUser and idSong are set in the request
if (isset($_POST['idUser']) && isset($_POST['idSong'])) {
    $idUser = $_POST['idUser'];
    $idSong = $_POST['idSong'];

    // Insert the song and user IDs into the user_history table
    $sql = "INSERT INTO user_history (idUser, idSong) VALUES ('$idUser', '$idSong')";

    if ($conn->query($sql) === TRUE) {
        echo "Song added to user's history successfully";
    } else {
        // Log the error to a file
        error_log("Error adding song to user's history: " . $conn->error, 3, "error_log.txt");

        // Output the error message
        echo "Error adding song to user's history. Please check the server logs for more details.";
    }
} else {
    // Log the missing parameters error to a file
    error_log("idUser and idSong parameters are required", 3, "error_log.txt");

    // Output the error message
    echo "idUser and idSong parameters are required";
}

// Close the database connection
$conn->close();
?>

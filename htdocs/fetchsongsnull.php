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

// Fetch songs with idAlbum set to null
$sql = "SELECT * FROM song WHERE idAlbum IS NULL";
$result = $conn->query($sql);

$songs = array();

if ($result === false) {
    // Log the MySQL error
    error_log("MySQL error: " . $conn->error);
    die("MySQL error: " . $conn->error);
}

if ($result->num_rows > 0) {
    // Fetching data from the result set
    while ($row = $result->fetch_assoc()) {
        $songs[] = $row;
    }
}

// Close the database connection
$conn->close();

// Convert the data to JSON and return it
echo json_encode($songs);
?>
<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

// Database connection details
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

// Handle POST request for user registration
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Your user registration logic here
} elseif ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Handle GET request to fetch all genres

    $genreList = array();

    $sql = "SELECT * FROM genre";
    $result = $conn->query($sql);

    if ($result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            $genreList[] = $row['name'];
        }
    }

    // Return the genre list as JSON
    echo json_encode($genreList);
}

$conn->close();
?>

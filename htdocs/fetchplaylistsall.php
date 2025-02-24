<?php

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Database connection
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "mellowde";

// Create a connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Fetch all playlists using a prepared statement
$sql = "SELECT playlistId, name, description, imageUrl, CAST(userId AS SIGNED) AS userId FROM playlist";
$stmt = $conn->prepare($sql);

if (!$stmt) {
    die("Query preparation failed: " . $conn->error);
}

$stmt->execute();

$result = $stmt->get_result();

if (!$result) {
    die("Query execution failed: " . $stmt->error);
}

if ($result->num_rows > 0) {
    // Set appropriate headers for JSON response
    header('Content-Type: application/json');

    // Convert the result to JSON and echo it
    $rows = array();
    while ($row = $result->fetch_assoc()) {
        $rows[] = $row;
    }
    echo json_encode($rows);
} else {
    echo "No playlists found"; // Return a message if no playlists are found
}

$stmt->close();
$conn->close();
?>

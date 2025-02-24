<?php
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

// Get the song ID from the request
$songId = $_POST['songId'];

// Calculate the average rating for the given song
$sqlAvgRating = "SELECT rating FROM song WHERE idSong = $songId";
$resultAvgRating = $conn->query($sqlAvgRating);

if ($resultAvgRating->num_rows > 0) {
    $row = $resultAvgRating->fetch_assoc();
    $avgRating = $row['rating'];

    // Return the average rating as a response
    echo $avgRating;
} else {
    // If no ratings found, return a default value (0 or any other value you prefer)
    echo "0";
}

$conn->close();
?>

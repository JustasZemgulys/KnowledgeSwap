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

// Get parameters from the Flutter app
$userId = $_POST['userId']; // Assuming you have a userId associated with the rating
$songId = $_POST['songId']; // Assuming you have a songId associated with the rating
$rating = $_POST['rating'];

// Check if the user has already rated the song
$sqlCheck = "SELECT * FROM rating WHERE idUser = $userId AND idSong = $songId";
$resultCheck = $conn->query($sqlCheck);

if ($resultCheck->num_rows > 0) {
    // User has already rated the song, update the existing rating
    $sqlUpdate = "UPDATE rating SET rating = $rating WHERE idUser = $userId AND idSong = $songId";
    if ($conn->query($sqlUpdate) === TRUE) {
        echo "Rating updated successfully";

        // Recalculate and update the average rating of the song
        recalculateAndUpdateSongRating($conn, $songId);

    } else {
        echo "Error updating rating: " . $conn->error;
    }
} else {
    // User has not rated the song yet, insert a new rating
    $sqlInsert = "INSERT INTO rating (idUser, idSong, rating) VALUES ($userId, $songId, $rating)";
    if ($conn->query($sqlInsert) === TRUE) {
        echo "Rating added successfully";

        // Recalculate and update the average rating of the song
        recalculateAndUpdateSongRating($conn, $songId);

    } else {
        echo "Error adding rating: " . $conn->error;
    }
}

$conn->close();

// Function to recalculate and update the average rating of the song
function recalculateAndUpdateSongRating($conn, $songId) {
    $sqlAvgRating = "SELECT AVG(rating) AS avgRating FROM rating WHERE idSong = $songId";
    $resultAvgRating = $conn->query($sqlAvgRating);

    if ($resultAvgRating->num_rows > 0) {
        $row = $resultAvgRating->fetch_assoc();
        $avgRating = $row['avgRating'];

        // Update the average rating in the song table
        $sqlUpdateSong = "UPDATE song SET rating = $avgRating WHERE idSong = $songId";
        if ($conn->query($sqlUpdateSong) === TRUE) {
            echo "Average rating updated successfully";
        } else {
            echo "Error updating average rating: " . $conn->error;
        }
    }
}
?>

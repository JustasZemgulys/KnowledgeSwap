<?php

// Connect to your database here
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "mellowde";

$yourDatabaseConnection = mysqli_connect($servername, $username, $password, $dbname);

// Check the database connection
if (!$yourDatabaseConnection) {
    die("Connection failed: " . mysqli_connect_error());
}

// Perform a query to fetch genres
$query = "SELECT idGenre, name FROM genre";
$result = mysqli_query($yourDatabaseConnection, $query);

// Check if the query was successful
if ($result) {
    $genres = array();
    while ($row = mysqli_fetch_assoc($result)) {
        $genres[] = $row;
    }
    echo json_encode($genres);
} else {
    // Handle the error and log it
    $error_message = 'Failed to fetch genres: ' . mysqli_error($yourDatabaseConnection);

    // Log the error to a file or other logging mechanism
    error_log($error_message, 3, 'error.log');

    echo json_encode(array('error' => 'Failed to fetch genres'));
}

// Close the database connection
mysqli_close($yourDatabaseConnection);

?>

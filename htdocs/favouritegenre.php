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

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $requestData = json_decode($_POST['genres'], true);
    $userId = $_POST['userId'];
    $genreNames = $requestData;

    // Create a prepared statement to insert data into the favouritegenre table
    $stmt = $conn->prepare("INSERT INTO favouritegenre (IdUser, IdGenre) VALUES (?, ?)");

    // Get genre IDs based on genre names
    $genreIds = [];
    foreach ($genreNames as $genreName) {
        // Assuming you have a table named 'genres' with columns 'idGenre' and 'Name'
        $result = $conn->query("SELECT idGenre FROM genre WHERE name = '$genreName'");
        $row = $result->fetch_assoc();
        $genreId = $row['idGenre'];
        $genreIds[] = $genreId;
    }

    // Bind parameters and execute the statement for each genre
    foreach ($genreIds as $genreId) {
        $stmt->bind_param("ii", $userId, $genreId);
        $stmt->execute();
    }

    $stmt->close();
}

$conn->close();
?>
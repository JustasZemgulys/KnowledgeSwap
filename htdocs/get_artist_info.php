<?php
// Establish a connection to your database
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "mellowde";

$conn = new mysqli($servername, $username, $password, $dbname);

// Check the connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Read the input parameters
$input_data = json_decode(file_get_contents("php://input"), true);
$userId = $input_data['userId'];

// Fetch artist information from the database
$sql = "SELECT * FROM artist WHERE idUser = $userId";
$result = $conn->query($sql);

$response = array();

if ($result->num_rows > 0) {
    // Artist information found
    $row = $result->fetch_assoc();

    $artistData = array(
        'id' => $row['idArtist'],
        'bio' => $row['bio'],
        'rating' => $row['rating'],
        // Add other fields as needed
    );

    $response['success'] = true;
    $response['artistData'] = $artistData;
} else {
    // No artist information found
    $response['success'] = false;
    $response['message'] = "Artist information not found for userId: $userId";
}

// Close the database connection
$conn->close();

// Return the JSON response
header('Content-Type: application/json');
echo json_encode($response);
?>

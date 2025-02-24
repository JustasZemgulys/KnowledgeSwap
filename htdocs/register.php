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
    // Get data from the request
    $data = json_decode(file_get_contents('php://input'), true);

    $username = $data['username'];
    $name = $data['name'];
    $email = $data['email'];
    $imageURL = "";
    $userType = $data['userType'];
    $password = $data['password'];

    // Insert user data into the database
    $insertQuery = "INSERT INTO User (username, name, email, imageURL, userType, password) VALUES ('$username', '$name', '$email', '$imageURL', '$userType', '$password')";

    if ($conn->query($insertQuery) === TRUE) {
        // Retrieve the user data after successful registration
        $selectQuery = "SELECT * FROM User WHERE username = '$username'";
        $result = $conn->query($selectQuery);

        if ($result->num_rows > 0) {
            $userData = $result->fetch_assoc();

            if ($userType === 'Creator') {
                // If user type is 'Creator', insert into the 'Artists' table
                $userId = $userData['idUser'];
                $bio = "";
                $rating = 0;
                $insertArtistQuery = "INSERT INTO artist (bio, rating, idUser) VALUES ('$bio', '$rating', '$userId')";
                $conn->query($insertArtistQuery);
            }

            $response = ['success' => true, 'message' => 'User registered successfully', 'userData' => $userData];
        } else {
            $response = ['success' => false, 'message' => 'Error retrieving user data'];
        }
    } else {
        $response = ['success' => false, 'message' => 'Error: ' . $insertQuery . '<br>' . $conn->error];
    }

    echo json_encode($response);
}

$conn->close();
?>

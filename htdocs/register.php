<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

// Database connection details
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "knowledgeswap";

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

    $name = $data['name'];
    $email = $data['email'];
    $password = $data['password'];

    // Insert user data into the database
    $insertQuery = "INSERT INTO user (name, email , password) VALUES ('$name', '$email', '$password')";

    if ($conn->query($insertQuery) === TRUE) {
        // Retrieve the user data after successful registration
        $selectQuery = "SELECT * FROM user WHERE name = '$name'";
        $result = $conn->query($selectQuery);

        if ($result->num_rows > 0) {
            $userData = $result->fetch_assoc();

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

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

// Handle POST request for user login
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get data from the request
    $data = json_decode(file_get_contents('php://input'), true);

    $username = $data['username'];
    $password = $data['password'];

    // Validate user credentials
    $validateUserQuery = "SELECT * FROM User WHERE username = '$username'";
    $validateUserResult = $conn->query($validateUserQuery);

    if ($validateUserResult->num_rows > 0) {
        // User with the given username exists
        $userRow = $validateUserResult->fetch_assoc();
        $storedPassword = $userRow['password'];

        // Compare plain text passwords directly
        if ($password === $storedPassword) {
            // Return all user data along with success message
            $response = [
                'success' => true,
                'message' => 'Login successful',
                'userData' => $userRow
            ];
        } else {
            $response = ['success' => false, 'message' => 'Invalid password'];
        }
    } else {
        // User with the given username does not exist
        $response = ['success' => false, 'message' => 'User not found'];
    }

    echo json_encode($response);
}

$conn->close();
?>

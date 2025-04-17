<?php
require_once 'db_connect.php';

$conn = getDBConnection();

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

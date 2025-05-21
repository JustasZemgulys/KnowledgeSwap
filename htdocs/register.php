<?php
require_once 'db_connect.php';

header('Content-Type: application/json'); // Ensure JSON response

$conn = getDBConnection();

// Handle POST request for user registration
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get data from the request
    $data = json_decode(file_get_contents('php://input'), true);

    // Validate required fields
    if (empty($data['name']) || empty($data['email']) || empty($data['password'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'All fields are required']);
        exit();
    }

    $name = $conn->real_escape_string($data['name']);
    $email = $conn->real_escape_string($data['email']);
    $password = $conn->real_escape_string($data['password']);

    // Validate email format
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid email format']);
        exit();
    }

    // Check if username or email already exists
    $checkQuery = "SELECT * FROM user WHERE name = '$name' OR email = '$email'";
    $result = $conn->query($checkQuery);
    
    if ($result->num_rows > 0) {
        $existing = $result->fetch_assoc();
        $field = ($existing['name'] === $name) ? 'username' : 'email';
        http_response_code(409);
        echo json_encode(['success' => false, 'message' => "$field already exists"]);
        exit();
    }

    // Insert user data into the database
    $insertQuery = "INSERT INTO user (name, email, password) VALUES ('$name', '$email', '$password')";

    if ($conn->query($insertQuery)) {
        $selectQuery = "SELECT * FROM user WHERE name = '$name'";
        $result = $conn->query($selectQuery);
        
        if ($result->num_rows > 0) {
            $userData = $result->fetch_assoc();
            http_response_code(201);
            echo json_encode([
                'success' => true, 
                'message' => 'User registered successfully', 
                'userData' => $userData
            ]);
        } else {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Error retrieving user data']);
        }
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Registration failed']);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}

$conn->close();
?>
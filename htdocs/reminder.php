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
    // Get data from the request
    $data = json_decode(file_get_contents('php://input'), true);

    $email = $conn->real_escape_string($data['email']);
    $newPassword = $conn->real_escape_string($data['newPassword']);  // Password without hashing

    // Using prepared statements to prevent SQL injection
    $stmt = $conn->prepare("SELECT * FROM user WHERE email = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        // Update the user's password
        $updateStmt = $conn->prepare("UPDATE user SET password = ? WHERE email = ?");
        $updateStmt->bind_param("ss", $newPassword, $email);
        if ($updateStmt->execute()) {
            $response = ['success' => true, 'message' => 'Password updated successfully'];
        } else {
            $response = ['success' => false, 'message' => 'Failed to update password'];
        }
        $updateStmt->close();
    } else {
        $response = ['success' => false, 'message' => 'User with provided email not found'];
    }

    echo json_encode($response);

    // Close the prepared statements and connection
    $stmt->close();
    $conn->close();
}
?>

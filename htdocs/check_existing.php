<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

// Disable error reporting
error_reporting(0);

// Database connection details
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "knowledgeswap";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die(json_encode(['success' => false, 'message' => "Connection failed: " . $conn->connect_error]));
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get data from the request
    $data = json_decode(file_get_contents('php://input'), true);

    if (json_last_error() !== JSON_ERROR_NONE) {
        die(json_encode(['success' => false, 'message' => "Invalid JSON input"]));
    }

    $name = $conn->real_escape_string($data['name']);
    $email = $conn->real_escape_string($data['email']);

    // Using prepared statements to prevent SQL injection
    $stmt = $conn->prepare("SELECT * FROM user WHERE name = ? OR email = ?");
    $stmt->bind_param("ss", $name, $email);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        // User with the same name or email already exists
        $existingUser = $result->fetch_assoc();
        $existingField = $existingUser['name'] == $name ? 'Name' : 'Email';
        $response = ['success' => false, 'message' => "$existingField already in use"];
    } else {
        $response = ['success' => true, 'message' => 'Name and email are available'];
    }

    echo json_encode($response);

    // Close the prepared statement and connection
    $stmt->close();
    $conn->close();
}
?>

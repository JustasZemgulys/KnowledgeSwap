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

    $username = $conn->real_escape_string($data['username']);
    $email = $conn->real_escape_string($data['email']);

    // Using prepared statements to prevent SQL injection
    $stmt = $conn->prepare("SELECT * FROM user WHERE username = ? OR email = ?");
    $stmt->bind_param("ss", $username, $email);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        // User with the same username or email already exists
        $existingUser = $result->fetch_assoc();
        $existingField = $existingUser['username'] == $username ? 'Username' : 'Email';
        $response = ['success' => false, 'message' => "$existingField already in use"];
    } else {
        $response = ['success' => true, 'message' => 'Username and email are available'];
    }

    echo json_encode($response);

    // Close the prepared statement and connection
    $stmt->close();
}
?>

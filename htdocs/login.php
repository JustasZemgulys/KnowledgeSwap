<?php
require_once 'db_connect.php';

$conn = getDBConnection();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get data from the request
    $data = json_decode(file_get_contents('php://input'), true);

    $username = $data['username'];
    $password = $data['password'];

    // Validate user credentials
	$validateUserQuery = "SELECT * FROM user WHERE name = '$username'";

	$stmt = $conn->prepare("SELECT * FROM user WHERE name = ?");
	$stmt->bind_param("s", $username);
	$stmt->execute();
	$validateUserResult = $stmt->get_result();

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

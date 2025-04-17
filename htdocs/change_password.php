<?php
require_once 'db_connect.php';

$conn = getDBConnection();

// Read the input data
$data = json_decode(file_get_contents("php://input"), true);

// Check if JSON was parsed correctly
if (json_last_error() !== JSON_ERROR_NONE) {
    echo json_encode(['success' => false, 'message' => 'Invalid JSON format']);
    exit();
}

// Check if email and newPassword are provided
if (isset($data['email']) && isset($data['newPassword'])) {
    $email = $data['email'];
    $newPassword = $data['newPassword'];

    // Hash the password for security
    //$hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);

    // Prepare the SQL query to check if the user exists
    $stmt = $conn->prepare("SELECT id FROM user WHERE email = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $stmt->store_result();

    // If the user exists, update the password
    if ($stmt->num_rows > 0) {
		// User found, update password
		$updateStmt = $conn->prepare("UPDATE user SET password = ? WHERE email = ?");
		$updateStmt->bind_param("ss", $newPassword, $email);
		
		if ($updateStmt->execute()) {
			echo json_encode(['success' => true, 'message' => 'Password updated successfully']);
		} else {
			echo json_encode(['success' => false, 'message' => 'Failed to update password']);
		}
	} else {
		echo json_encode(['success' => false, 'message' => 'No user found with this email']);
	}
}
$conn->close();
?>

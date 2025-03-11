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
    die(json_encode(['success' => false, 'message' => 'Connection failed: ' . $conn->connect_error]));
}

// Handle POST request for user settings update
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);

    $id = $data['id'];
    $newName = $data['newName'];
    $newEmail = $data['newEmail'];
    $newPassword = $data['newPassword'];
    $oldPassword = $data['oldPassword'];

    $updateFields = [];

    // Check if old password is provided and matches before updating
    if (!empty($oldPassword)) {
        $checkPasswordQuery = "SELECT * FROM user WHERE id = '$id' AND password = '$oldPassword'";
        $userData = $conn->query($checkPasswordQuery);

        if ($userData ->num_rows > 0) {
            // Old password matches, proceed with updates
            if (!empty($newName)) {
                $updateFields[] = "name = '$newName'";
            }

            if (!empty($newEmail)) {
                // Check if the new email is not already in use
                $checkEmailQuery = "SELECT * FROM user WHERE email = '$newEmail' AND id != '$id'";
                $emailResult = $conn->query($checkEmailQuery);

                if ($emailResult->num_rows == 0) {
                    $updateFields[] = "email = '$newEmail'";
                } else {
                    // Email is already in use
                    echo json_encode(['success' => false, 'message' => 'Email is already in use']);
                    exit();
                }
            }

            if (!empty($newPassword)) {
                $updateFields[] = "password = '$newPassword'";
            }
        } else {
            // Old password doesn't match
            echo json_encode(['success' => false, 'message' => 'Old password is incorrect']);
            exit();
        }
    } else {
        // Old password is required for updates
        echo json_encode(['success' => false, 'message' => 'Old password is required']);
        exit();
    }

    // Check if there are fields to update and proceed with the query
    if (!empty($updateFields)) {
		$updateQuery = "UPDATE user SET " . implode(', ', $updateFields) . " WHERE id = '$id'";

		if ($conn->query($updateQuery) === TRUE) {
			// Fetch updated user info
			$userQuery = "SELECT id, name, email, imageURL FROM user WHERE id = '$id'";
			$userResult = $conn->query($userQuery);

			if ($userResult->num_rows > 0) {
				$userData = $userResult->fetch_assoc();
				echo json_encode([
					'success' => true,
					'message' => 'User info updated successfully',
					'userData' => $userData // Send back updated user data
				]);
			} else {
				echo json_encode([
					'success' => false,
					'message' => 'Failed to retrieve updated user info but updated successfully'
				]);
			}
		} else {
			echo json_encode(['success' => false, 'message' => 'Error updating user info: ' . $conn->error]);
		}
	}
}

$conn->close();
?>

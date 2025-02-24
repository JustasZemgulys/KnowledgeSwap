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
    die(json_encode(['success' => false, 'message' => 'Connection failed: ' . $conn->connect_error]));
}

// Handle POST request for user settings update
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);

    $idUser = $data['idUser'];
    $newUsername = $data['newUsername'];
    $newName = $data['newName'];
    $newEmail = $data['newEmail'];
    $newPassword = $data['newPassword'];
    $oldPassword = $data['oldPassword'];

    $updateFields = [];

    // Check if old password is provided and matches before updating
    if (!empty($oldPassword)) {
        $checkPasswordQuery = "SELECT * FROM User WHERE idUser = '$idUser' AND password = '$oldPassword'";
        $passwordResult = $conn->query($checkPasswordQuery);

        if ($passwordResult->num_rows > 0) {
            // Old password matches, proceed with updates
            if (!empty($newUsername)) {
                $updateFields[] = "username = '$newUsername'";
            }

            if (!empty($newName)) {
                $updateFields[] = "name = '$newName'";
            }

            if (!empty($newEmail)) {
                // Check if the new email is not already in use
                $checkEmailQuery = "SELECT * FROM User WHERE email = '$newEmail' AND idUser != '$idUser'";
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
        $updateQuery = "UPDATE User SET " . implode(', ', $updateFields) . " WHERE idUser = '$idUser'";

        if ($conn->query($updateQuery) === TRUE) {
            // Update successful
            echo json_encode(['success' => true, 'message' => 'User info updated successfully']);
        } else {
            // Update failed
            echo json_encode(['success' => false, 'message' => 'Error updating user info: ' . $conn->error]);
        }
    }
}

$conn->close();
?>

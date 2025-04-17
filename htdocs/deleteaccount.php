<?php
require_once 'db_connect.php';

$conn = getDBConnection();

// Handle POST request for account deletion
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get data from the request
    $data = json_decode(file_get_contents('php://input'), true);

    $id = $data['id'];

    // Check if the user exists before deleting
    $checkUserQuery = "SELECT * FROM user WHERE id = $id";
    $checkUserResult = $conn->query($checkUserQuery);

    if ($checkUserResult->num_rows > 0) {
        // User exists, proceed with deletion
        $deleteUserQuery = "DELETE FROM user WHERE id = $id";
        if ($conn->query($deleteUserQuery) === TRUE) {
            $response = [
                'success' => true,
                'message' => 'Account deleted successfully',
            ];
        } else {
            $response = [
                'success' => false,
                'message' => 'Failed to delete account: ' . $conn->error,
            ];
        }
    } else {
        // User does not exist
        $response = [
            'success' => false,
            'message' => 'User not found',
        ];
    }

    echo json_encode($response);
}

$conn->close();
?>

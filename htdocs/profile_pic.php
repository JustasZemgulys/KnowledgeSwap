<?php
require_once 'db_connect.php';

$conn = getDBConnection();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get new image URL and userId from POST request
    $newImageUrl = $_POST['newImageUrl'];
    $id = $_POST['Id'];  // Assuming you have a user ID to identify the user in the database

    // Update the user's record with the new image URL
    $sql = "UPDATE user SET imageURL = ? WHERE id = ?";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("si", $newImageUrl, $id);  // 's' indicates string and 'i' indicates integer
    $result = $stmt->execute();

    if ($result) {
        echo json_encode(["success" => true, "message" => "Image URL updated successfully"]);
    } else {
        echo json_encode(["success" => false, "message" => "Failed to update image URL"]);
    }

    $stmt->close();
} else {
    echo json_encode(["success" => false, "message" => "Invalid request method"]);
}

$conn->close();
?>

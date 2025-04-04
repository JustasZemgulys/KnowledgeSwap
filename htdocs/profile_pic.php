<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
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
    die("Connection failed: " . $conn->connect_error);
}

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

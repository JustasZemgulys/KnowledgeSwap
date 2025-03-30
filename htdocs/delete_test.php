<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "knowledgeswap";

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    die(json_encode(['success' => false, 'message' => "Connection failed: " . $conn->connect_error]));
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $testId = $_POST['test_id'] ?? 0;
    $userId = $_POST['user_id'] ?? 0; // Added user_id for verification
    
    if ($testId <= 0 || $userId <= 0) {
        die(json_encode(['success' => false, 'message' => 'Invalid test ID or user ID']));
    }

    // First verify the test belongs to the user
    $verifyQuery = $conn->prepare("SELECT id FROM test WHERE id = ? AND fk_user = ?");
    $verifyQuery->bind_param("ii", $testId, $userId);
    $verifyQuery->execute();
    $verifyResult = $verifyQuery->get_result();
    
    if ($verifyResult->num_rows === 0) {
        die(json_encode(['success' => false, 'message' => 'Test not found or not owned by user']));
    }

    // Delete all questions first
    $deleteQuestions = $conn->prepare("DELETE FROM question WHERE fk_test = ?");
    $deleteQuestions->bind_param("i", $testId);
    $deleteQuestions->execute();

    // Then delete the test
    $deleteTest = $conn->prepare("DELETE FROM test WHERE id = ?");
    $deleteTest->bind_param("i", $testId);
    
    if ($deleteTest->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'Test and all questions deleted successfully'
        ]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to delete test']);
    }
}

$conn->close();
?>
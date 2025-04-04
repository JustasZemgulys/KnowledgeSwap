<?php
// Disable HTML errors - only log them
ini_set('display_errors', 0);
ini_set('log_errors', 1);
error_reporting(E_ALL);

// Set proper headers first
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Content-Type: application/json; charset=UTF-8");

// Default response structure
$response = [
    'success' => false,
    'user_vote' => 0,
    'total_score' => 0,
    'message' => ''
];

try {
    // Validate required parameters
    if (!isset($_GET['user_id'], $_GET['item_id'], $_GET['item_type'])) {
        throw new Exception("Missing required parameters");
    }

    $userId = (int)$_GET['user_id'];
    $itemId = (int)$_GET['item_id'];
    $itemType = $_GET['item_type'];

    // Validate item type
    $validTypes = ['test', 'resource', 'comment'];
    if (!in_array($itemType, $validTypes)) {
        throw new Exception("Invalid item type");
    }

    // Database connection with error handling
    $conn = new mysqli("localhost", "root", "", "knowledgeswap");
    if ($conn->connect_error) {
        throw new Exception("DB connection failed");
    }

    // 1. Get user's vote (returns 0 if none exists)
    $voteQuery = $conn->prepare("SELECT direction FROM vote WHERE fk_user=? AND fk_item=? AND fk_type=?");
    if (!$voteQuery) {
        throw new Exception("Vote query preparation failed");
    }
    
    $voteQuery->bind_param("iis", $userId, $itemId, $itemType);
    if (!$voteQuery->execute()) {
        throw new Exception("Vote query execution failed");
    }
    
    $voteResult = $voteQuery->get_result();
    $userVote = $voteResult->fetch_assoc()['direction'] ?? 0;
    $voteQuery->close();

    // 2. Get item score
    $scoreQuery = $conn->prepare("SELECT score FROM $itemType WHERE id=?");
    if (!$scoreQuery) {
        throw new Exception("Score query preparation failed");
    }
    
    $scoreQuery->bind_param("i", $itemId);
    if (!$scoreQuery->execute()) {
        throw new Exception("Score query execution failed");
    }
    
    $scoreResult = $scoreQuery->get_result();
    $totalScore = $scoreResult->fetch_assoc()['score'] ?? 0;
    $scoreQuery->close();

    $conn->close();

    // Successful response
    $response = [
        'success' => true,
        'user_vote' => (int)$userVote,
        'total_score' => (int)$totalScore
    ];

} catch (Exception $e) {
    http_response_code(500);
    $response['message'] = $e->getMessage();
}

// Ensure only JSON is output
echo json_encode($response);
exit;
?>
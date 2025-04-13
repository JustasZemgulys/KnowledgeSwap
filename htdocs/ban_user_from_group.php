<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

error_reporting(E_ALL);
ini_set('display_errors', 1);

// Handle OPTIONS request (CORS preflight)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header('HTTP/1.1 200 OK');
    exit();
}

$response = ['success' => false, 'message' => ''];

try {
    // Only process POST requests
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception("Only POST requests are accepted");
    }

    $input = file_get_contents('php://input');
    
    $data = json_decode($input, true);
    
    if ($data === null) {
        throw new Exception("Invalid JSON data");
    }
    

    if (!isset($data['group_id'], $data['user_id'])) {
        throw new Exception("Missing required parameters");
    }
    
    $groupId = (int)$data['group_id'];
    $userId = (int)$data['user_id'];
    
    $conn = new mysqli("localhost", "root", "", "knowledgeswap");
    
    if ($conn->connect_error) {
        throw new Exception("Connection failed: " . $conn->connect_error);
    }
    
    // Check if target user exists in group
    $stmt = $conn->prepare("SELECT role FROM group_member WHERE fk_group = ? AND fk_user = ?");
    $stmt->bind_param("ii", $groupId, $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        throw new Exception("User not found in group");
    }
    
    $targetRole = $result->fetch_assoc()['role'];
    
    // Check if target user is an admin (can't ban admins)
    if ($targetRole === 'admin') {
        throw new Exception("Cannot ban an admin");
    }
    
    // Update user's role to 'banned'
    $stmt = $conn->prepare("UPDATE group_member SET role = 'banned' WHERE fk_group = ? AND fk_user = ?");
    $stmt->bind_param("ii", $groupId, $userId);
    
    if (!$stmt->execute()) {
        throw new Exception("Failed to ban user: " . $stmt->error);
    }
    
    $response = [
        'success' => true,
        'message' => 'User banned successfully',
        'member_count' => getMemberCount($conn, $groupId)
    ];
    
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    $response['message'] = $e->getMessage();
}

echo json_encode($response);

function getMemberCount($conn, $groupId) {
    $stmt = $conn->prepare("SELECT COUNT(*) as count FROM group_member WHERE fk_group = ? AND role != 'banned'");
    $stmt->bind_param("i", $groupId);
    $stmt->execute();
    $result = $stmt->get_result();
    return $result->fetch_assoc()['count'];
}
?>
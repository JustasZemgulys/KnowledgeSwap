<?php
require_once 'db_connect.php';

$conn = getDBConnection();

error_reporting(E_ALL);
ini_set('display_errors', 1);

$response = ['success' => false, 'message' => ''];

try {
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['group_id'], $data['email'], $data['inviter_id'])) {
        throw new Exception("Missing required parameters");
    }
    
    $groupId = (int)$data['group_id'];
    $email = $data['email'];
    $inviterId = (int)$data['inviter_id'];
    
    // Check if inviter is admin/moderator of the group
    $stmt = $conn->prepare("SELECT role FROM group_member WHERE fk_group = ? AND fk_user = ?");
    $stmt->bind_param("ii", $groupId, $inviterId);
    $stmt->execute();
    $result = $stmt->get_result();
    $inviter = $result->fetch_assoc();
    
    if (!$inviter || ($inviter['role'] !== 'admin' && $inviter['role'] !== 'moderator')) {
        throw new Exception("You don't have permission to invite users");
    }
    
    // Find user by email
    $stmt = $conn->prepare("SELECT id FROM user WHERE email = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();
    $user = $result->fetch_assoc();
    
    if (!$user) {
        throw new Exception("User with this email not found");
    }
    
    $userId = $user['id'];
    
    // Check if user is already in the group
    $stmt = $conn->prepare("SELECT 1 FROM group_member WHERE fk_group = ? AND fk_user = ?");
    $stmt->bind_param("ii", $groupId, $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        throw new Exception("User is already a member of this group");
    }
    
    // Add user to group as regular member
    $stmt = $conn->prepare("INSERT INTO group_member (fk_group, fk_user, role) VALUES (?, ?, 'member')");
    $stmt->bind_param("ii", $groupId, $userId);
    
    if (!$stmt->execute()) {
        throw new Exception("Failed to add user to group: " . $stmt->error);
    }
    
    $response = [
        'success' => true,
        'message' => 'User added to group successfully'
    ];
    
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    $response['message'] = $e->getMessage();
}

echo json_encode($response);
?>
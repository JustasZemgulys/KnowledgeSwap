<?php
require_once 'db_connect.php';

$conn = getDBConnection();

error_reporting(E_ALL);
ini_set('display_errors', 1);

$response = ['success' => false, 'message' => ''];

try {
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['group_id'], $data['user_id'], $data['role'])) {
        throw new Exception("Missing required parameters");
    }
    
    $groupId = (int)$data['group_id'];
    $userId = (int)$data['user_id'];
    $role = $data['role'];
    
    // Check if the requesting user is an admin
    if (!isset($data['requesting_user_id'])) {
        throw new Exception("Requesting user ID is required");
    }
    
    $requestingUserId = (int)$data['requesting_user_id'];
    $stmt = $conn->prepare("SELECT role FROM group_member WHERE fk_group = ? AND fk_user = ?");
    $stmt->bind_param("ii", $groupId, $requestingUserId);
    $stmt->execute();
    $result = $stmt->get_result();
    $requester = $result->fetch_assoc();
    
    if (!$requester || $requester['role'] !== 'admin') {
        throw new Exception("Only admins can change user roles");
    }
    
    // Validate the new role
    if (!in_array($role, ['admin', 'moderator', 'member'])) {
        throw new Exception("Invalid role specified");
    }
    
    // Prevent changing the last admin's role
    if ($role !== 'admin') {
        $stmt = $conn->prepare("SELECT COUNT(*) as admin_count FROM group_member WHERE fk_group = ? AND role = 'admin'");
        $stmt->bind_param("i", $groupId);
        $stmt->execute();
        $result = $stmt->get_result();
        $adminCount = $result->fetch_assoc()['admin_count'];
        
        if ($adminCount <= 1) {
            // Check if the user being modified is an admin
            $stmt = $conn->prepare("SELECT role FROM group_member WHERE fk_group = ? AND fk_user = ?");
            $stmt->bind_param("ii", $groupId, $userId);
            $stmt->execute();
            $result = $stmt->get_result();
            $user = $result->fetch_assoc();
            
            if ($user && $user['role'] === 'admin') {
                throw new Exception("Cannot change the last admin's role");
            }
        }
    }
    
    // Update the user's role
    $stmt = $conn->prepare("UPDATE group_member SET role = ? WHERE fk_group = ? AND fk_user = ?");
    $stmt->bind_param("sii", $role, $groupId, $userId);
    
    if (!$stmt->execute()) {
        throw new Exception("Failed to update user role: " . $stmt->error);
    }
    
    $response = [
        'success' => true,
        'message' => 'User role updated successfully'
    ];
    
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    $response['message'] = $e->getMessage();
}

echo json_encode($response);
?>
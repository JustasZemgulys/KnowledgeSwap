<?php
require_once 'db_connect.php';

$conn = getDBConnection();

error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: application/json');
$response = ['success' => false, 'message' => ''];

try {
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['group_id'], $data['email'], $data['inviter_id'])) {
        $response['message'] = "Missing required parameters";
        echo json_encode($response);
        exit;
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
        $response['message'] = "You don't have permission to invite users";
        echo json_encode($response);
        exit;
    }
    
    // Find user by email
    $stmt = $conn->prepare("SELECT id FROM user WHERE email = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();
    $user = $result->fetch_assoc();
    
    if (!$user) {
        $response['message'] = "User with this email not found";
        echo json_encode($response);
        exit;
    }
    
    $userId = $user['id'];
    
    // Check if user is already in the group
    $stmt = $conn->prepare("SELECT role FROM group_member WHERE fk_group = ? AND fk_user = ?");
    $stmt->bind_param("ii", $groupId, $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $memberData = $result->fetch_assoc();
        $response['message'] = ($memberData['role'] === 'banned') 
            ? "User is banned from this group" 
            : "User is already a member of this group";
        echo json_encode($response);
        exit;
    }
    
    // Add user to group as regular member
    $stmt = $conn->prepare("INSERT INTO group_member (fk_group, fk_user, role) VALUES (?, ?, 'member')");
    $stmt->bind_param("ii", $groupId, $userId);
    
    if (!$stmt->execute()) {
        $response['message'] = "Failed to add user to group: " . $stmt->error;
        echo json_encode($response);
        exit;
    }
    
    $response = [
        'success' => true,
        'message' => 'User added to group successfully'
    ];
    
    echo json_encode($response);
    $conn->close();
    exit;
    
} catch (Exception $e) {
    $response['message'] = $e->getMessage();
    echo json_encode($response);
    exit;
}
?>
<?php
require_once 'db_connect.php';

$conn = getDBConnection();

$response = ['success' => false, 'message' => ''];

try {
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['group_id'], $data['user_id'])) {
        throw new Exception("Missing required parameters");
    }
    
    $groupId = (int)$data['group_id'];
    $userId = (int)$data['user_id'];
    
    // Simply delete the user from group_member
    $stmt = $conn->prepare("DELETE FROM group_member WHERE fk_group = ? AND fk_user = ?");
    $stmt->bind_param("ii", $groupId, $userId);
    
    if (!$stmt->execute()) {
        throw new Exception("Failed to remove user: " . $stmt->error);
    }
    
    $response = [
        'success' => true,
        'message' => 'User removed successfully',
        'member_count' => getMemberCount($conn, $groupId)
    ];
    
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    $response['message'] = $e->getMessage();
}

echo json_encode($response);

function getMemberCount($conn, $groupId) {
    $stmt = $conn->prepare("SELECT COUNT(*) as count FROM group_member WHERE fk_group = ?");
    $stmt->bind_param("i", $groupId);
    $stmt->execute();
    $result = $stmt->get_result();
    return $result->fetch_assoc()['count'];
}
?>
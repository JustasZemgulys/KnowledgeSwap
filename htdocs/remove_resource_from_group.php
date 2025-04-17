<?php
require_once 'db_connect.php';

$conn = getDBConnection();

$response = ['success' => false, 'message' => ''];

try {
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (!$data) {
        throw new Exception("Invalid input data");
    }
    
    $groupId = $data['group_id'] ?? null;
    $resourceId = $data['resource_id'] ?? null;
    $userId = $data['user_id'] ?? null;
    
    if (!$groupId || !$resourceId || !$userId) {
        throw new Exception("Missing required parameters");
    }
    
    // Check if user is admin or moderator of the group
    $stmt = $conn->prepare("
        SELECT role FROM group_member 
        WHERE fk_group = ? AND fk_user = ? AND role IN ('admin', 'moderator')
    ");
    $stmt->bind_param("ii", $groupId, $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        throw new Exception("You don't have permission to remove resources from this group");
    }
    
    // Remove the resource
    $stmt = $conn->prepare("
        DELETE FROM group_resource 
        WHERE fk_group = ? AND fk_resource = ?
    ");
    $stmt->bind_param("ii", $groupId, $resourceId);
    
    if ($stmt->execute()) {
        $response['success'] = true;
        $response['message'] = "Resource removed from group";
    } else {
        throw new Exception("Failed to remove resource: " . $stmt->error);
    }
    
    $stmt->close();
    $conn->close();
    
} catch (Exception $e) {
    $response['message'] = $e->getMessage();
    http_response_code(400);
}

echo json_encode($response);
?>
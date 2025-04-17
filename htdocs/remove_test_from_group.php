<?php
require_once 'db_connect.php';

$conn = getDBConnection();

$response = ['success' => false, 'message' => ''];

try {
    $data = json_decode(file_get_contents("php://input"), true);
    if (!$data) {
        throw new Exception("Invalid input data");
    }

    $groupId = $data['group_id'] ?? 0;
    $testId = $data['test_id'] ?? 0;
    $userId = $data['user_id'] ?? 0;

    if ($groupId <= 0 || $testId <= 0 || $userId <= 0) {
        throw new Exception("Invalid parameters");
    }

    // Check if user has permission to remove tests from this group
    $checkPermission = $conn->prepare("
        SELECT role FROM group_member 
        WHERE fk_group = ? AND fk_user = ? AND role IN ('admin', 'moderator')
    ");
    $checkPermission->bind_param("ii", $groupId, $userId);
    $checkPermission->execute();
    $permissionResult = $checkPermission->get_result();
    
    if ($permissionResult->num_rows === 0) {
        throw new Exception("You don't have permission to remove tests from this group");
    }

    // Remove the test
    $removeStmt = $conn->prepare("
        DELETE FROM group_test 
        WHERE fk_group = ? AND fk_test = ?
    ");
    $removeStmt->bind_param("ii", $groupId, $testId);
    
    if (!$removeStmt->execute()) {
        throw new Exception("Failed to remove test from group");
    }

    $response = [
        'success' => true,
        'message' => 'Test removed successfully'
    ];

    $removeStmt->close();
    $conn->close();

} catch (Exception $e) {
    http_response_code(400);
    $response = [
        'success' => false,
        'message' => $e->getMessage()
    ];
}

echo json_encode($response);
exit;
?>
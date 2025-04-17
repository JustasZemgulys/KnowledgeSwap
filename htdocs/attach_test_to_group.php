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

    // Check if user has permission to attach tests to this group
    $checkPermission = $conn->prepare("
        SELECT role FROM group_member 
        WHERE fk_group = ? AND fk_user = ? AND role IN ('admin', 'moderator')
    ");
    $checkPermission->bind_param("ii", $groupId, $userId);
    $checkPermission->execute();
    $permissionResult = $checkPermission->get_result();
    
    if ($permissionResult->num_rows === 0) {
        throw new Exception("You don't have permission to attach tests to this group");
    }

    // Check if test is already attached
    $checkExisting = $conn->prepare("
        SELECT 1 FROM group_test 
        WHERE fk_group = ? AND fk_test = ?
    ");
    $checkExisting->bind_param("ii", $groupId, $testId);
    $checkExisting->execute();
    
    if ($checkExisting->get_result()->num_rows > 0) {
        throw new Exception("This test is already attached to the group");
    }

    // Attach the test
    $attachStmt = $conn->prepare("
        INSERT INTO group_test (fk_group, fk_test)
        VALUES (?, ?)
    ");
    $attachStmt->bind_param("ii", $groupId, $testId);
    
    if (!$attachStmt->execute()) {
        throw new Exception("Failed to attach test to group");
    }

    $response = [
        'success' => true,
        'message' => 'Test attached successfully'
    ];

    $attachStmt->close();
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
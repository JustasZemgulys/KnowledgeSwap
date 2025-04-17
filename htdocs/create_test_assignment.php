<?php
require_once 'db_connect.php';

$conn = getDBConnection();

$response = ['success' => false, 'message' => ''];

try {
    $data = json_decode(file_get_contents("php://input"), true);
    if (!$data) {
        throw new Exception("Invalid input data");
    }

    $name = $data['name'] ?? '';
    $description = $data['description'] ?? '';
    $testId = $data['test_id'] ?? 0;
    $resourceId = $data['resource_id'] ?? null;
    $openDate = $data['open_date'] ?? null;
    $dueDate = $data['due_date'] ?? null;
    $groupId = $data['group_id'] ?? null;
    $creatorId = $data['creator_id'] ?? 0;
    $userIds = $data['user_ids'] ?? [];

    if (empty($name) || $testId <= 0 || $creatorId <= 0) {
        throw new Exception("Missing required fields");
    }

    $conn->begin_transaction();

    try {
        // Insert the test assignment
        $stmt = $conn->prepare("
            INSERT INTO test_assignment 
            (name, description, fk_test, fk_resource, open_date, due_date, fk_group, fk_creator)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ");
        
        $stmt->bind_param(
            "ssiissii", 
            $name, 
            $description, 
            $testId, 
            $resourceId, 
            $openDate, 
            $dueDate, 
            $groupId, 
            $creatorId
        );
        
        if (!$stmt->execute()) {
            throw new Exception("Failed to create test assignment");
        }
        
        $assignmentId = $stmt->insert_id;
        $stmt->close();

        // Assign to users
        if (!empty($userIds)) {
            $assignStmt = $conn->prepare("
                INSERT INTO test_assignment_user (fk_assignment, fk_user)
                VALUES (?, ?)
            ");
            
            foreach ($userIds as $userId) {
                $assignStmt->bind_param("ii", $assignmentId, $userId);
                if (!$assignStmt->execute()) {
                    throw new Exception("Failed to assign test to user");
                }
            }
            $assignStmt->close();
        }

        $conn->commit();
        $response = [
            'success' => true,
            'message' => 'Test assignment created successfully',
            'assignment_id' => $assignmentId
        ];
    } catch (Exception $e) {
        $conn->rollback();
        throw $e;
    }

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
<?php
require_once 'db_connect.php';

$conn = getDBConnection();

$response = ['success' => false, 'message' => ''];

try {
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['assignment_id']) || !is_numeric($data['assignment_id'])) {
        throw new Exception("Invalid assignment ID");
    }
    
    // Validate other required fields
    $requiredFields = ['name', 'test_id', 'group_id', 'creator_id'];
    foreach ($requiredFields as $field) {
        if (!isset($data[$field])) {
            throw new Exception("Missing required field: $field");
        }
    }
    
    $assignmentId = (int)$data['assignment_id'];
    $name = $data['name'];
    $description = $data['description'] ?? null;
    $testId = (int)$data['test_id'];
    $resourceId = isset($data['resource_id']) ? (int)$data['resource_id'] : null;
    $openDate = $data['open_date'] ?? null;
    $dueDate = $data['due_date'] ?? null;
    $groupId = (int)$data['group_id'];
    $creatorId = (int)$data['creator_id'];
    
    // Update the assignment
    $query = "UPDATE test_assignment SET 
        name = ?,
        description = ?,
        fk_test = ?,
        fk_resource = ?,
        open_date = ?,
        due_date = ?
        WHERE id = ? AND fk_group = ? AND fk_creator = ?";
    
    $stmt = $conn->prepare($query);
    if (!$stmt) {
        throw new Exception("Database query preparation failed");
    }
    
    $stmt->bind_param("ssiisssii", 
        $name, 
        $description, 
        $testId, 
        $resourceId, 
        $openDate, 
        $dueDate,
        $assignmentId,
        $groupId,
        $creatorId
    );
    
    if (!$stmt->execute()) {
        throw new Exception("Failed to update assignment");
    }
    
    // Update assigned users if provided
    if (isset($data['user_ids']) && is_array($data['user_ids'])) {
        // First delete existing assignments
        $deleteQuery = "DELETE FROM test_assignment_user WHERE fk_assignment = ?";
        $deleteStmt = $conn->prepare($deleteQuery);
        $deleteStmt->bind_param("i", $assignmentId);
        $deleteStmt->execute();
        $deleteStmt->close();
        
        // Insert new assignments
        $insertQuery = "INSERT INTO test_assignment_user (fk_assignment, fk_user) VALUES (?, ?)";
        $insertStmt = $conn->prepare($insertQuery);
        
        foreach ($data['user_ids'] as $userId) {
            $insertStmt->bind_param("ii", $assignmentId, $userId);
            $insertStmt->execute();
        }
        
        $insertStmt->close();
    }
    
    $response = [
        'success' => true,
        'message' => 'Assignment updated successfully',
        'assignment_id' => $assignmentId
    ];
    
    $stmt->close();
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    $response = [
        'success' => false,
        'message' => $e->getMessage()
    ];
}

echo json_encode($response);
exit;
?>
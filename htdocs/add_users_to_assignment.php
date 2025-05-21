<?php
require_once 'db_connect.php';

$conn = getDBConnection();

$response = ['success' => false, 'message' => '', 'added_count' => 0, 'preserved_count' => 0];

try {
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['assignment_id']) || !is_numeric($data['assignment_id'])) {
        throw new Exception("Invalid assignment ID");
    }
    
    if (!isset($data['user_ids']) || !is_array($data['user_ids'])) {
        throw new Exception("Invalid user IDs");
    }
    
    $assignmentId = (int)$data['assignment_id'];
    $userIds = array_map('intval', $data['user_ids']);
    $userIds = array_unique($userIds);
    
    error_log("Updating assignment $assignmentId with users: " . implode(',', $userIds));
    
    // Begin transaction
    $conn->begin_transaction();
    
    try {
        // First delete only assignments where users haven't completed the test
        $deleteQuery = "DELETE FROM test_assignment_user 
                        WHERE fk_assignment = ? 
                        AND fk_user NOT IN (
                            SELECT fk_user 
                            FROM test_assignment_user 
                            WHERE fk_assignment = ? AND completed = 1
                        )";
        
        $deleteStmt = $conn->prepare($deleteQuery);
        $deleteStmt->bind_param("ii", $assignmentId, $assignmentId);
        $deleteStmt->execute();
        $rowsDeleted = $conn->affected_rows;
        $deleteStmt->close();
        
        error_log("Deleted $rowsDeleted existing assignments (excluding completed tests)");
        
        // Get count of preserved users (those who completed the test)
        $preservedQuery = "SELECT COUNT(*) as preserved_count 
                          FROM test_assignment_user 
                          WHERE fk_assignment = ? AND completed = 1";
        $preservedStmt = $conn->prepare($preservedQuery);
        $preservedStmt->bind_param("i", $assignmentId);
        $preservedStmt->execute();
        $preservedResult = $preservedStmt->get_result();
        $preservedRow = $preservedResult->fetch_assoc();
        $response['preserved_count'] = $preservedRow['preserved_count'];
        $preservedStmt->close();
        
        // Insert new assignments if there are any users
        if (!empty($userIds)) {
            // Get existing users to avoid duplicates
            $existingQuery = "SELECT fk_user FROM test_assignment_user WHERE fk_assignment = ?";
            $existingStmt = $conn->prepare($existingQuery);
            $existingStmt->bind_param("i", $assignmentId);
            $existingStmt->execute();
            $existingResult = $existingStmt->get_result();
            
            $existingUsers = [];
            while ($row = $existingResult->fetch_assoc()) {
                $existingUsers[] = $row['fk_user'];
            }
            $existingStmt->close();
            
            $insertQuery = "INSERT INTO test_assignment_user (fk_assignment, fk_user) VALUES (?, ?)";
            $insertStmt = $conn->prepare($insertQuery);
            
            $addedCount = 0;
            foreach ($userIds as $userId) {
                // Only insert if user doesn't already exist in assignment
                if (!in_array($userId, $existingUsers)) {
                    $insertStmt->bind_param("ii", $assignmentId, $userId);
                    if ($insertStmt->execute()) {
                        $addedCount++;
                    }
                }
            }
            $insertStmt->close();
            
            $response['added_count'] = $addedCount;
            error_log("Added $addedCount new assignments");
        }
        
        // Commit transaction
        $conn->commit();
        
        $response['success'] = true;
        $response['message'] = empty($userIds) 
            ? "Users list updated successfully" 
            : "Users list updated successfully";
            
    } catch (Exception $e) {
        $conn->rollback();
        throw $e;
    }
    
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    $response['message'] = $e->getMessage();
    error_log("Error updating assignment users: " . $e->getMessage());
}

header('Content-Type: application/json');
echo json_encode($response);
exit;
?>
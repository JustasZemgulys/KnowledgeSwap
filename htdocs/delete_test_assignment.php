<?php
require_once 'db_connect.php';

$conn = getDBConnection();

$response = ['success' => false, 'message' => ''];

try {
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['assignment_id']) || !is_numeric($data['assignment_id'])) {
        throw new Exception("Invalid assignment ID");
    }
    
    $assignmentId = (int)$data['assignment_id'];
    
    // First delete user assignments
    $deleteUserAssignments = "DELETE FROM test_assignment_user WHERE fk_assignment = ?";
    $stmt1 = $conn->prepare($deleteUserAssignments);
    $stmt1->bind_param("i", $assignmentId);
    $stmt1->execute();
    $stmt1->close();
    
    // Then delete the assignment
    $deleteAssignment = "DELETE FROM test_assignment WHERE id = ?";
    $stmt2 = $conn->prepare($deleteAssignment);
    $stmt2->bind_param("i", $assignmentId);
    
    if ($stmt2->execute()) {
        $response = [
            'success' => true,
            'message' => 'Assignment deleted successfully'
        ];
    } else {
        throw new Exception("Failed to delete assignment");
    }
    
    $stmt2->close();
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
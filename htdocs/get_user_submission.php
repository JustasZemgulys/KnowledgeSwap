<?php
require_once 'db_connect.php';

header('Content-Type: application/json');

$response = [
    'success' => false,
    'message' => '',
    'forum_item_id' => null
];

try {
    if (empty($_GET['assignment_id']) || empty($_GET['user_id'])) {
        throw new Exception('Missing required parameters');
    }

    $assignmentId = (int)$_GET['assignment_id'];
    $userId = (int)$_GET['user_id'];

    $pdo = getPDOConnection();
    
    // Get the test ID from the assignment
    $stmt = $pdo->prepare("
        SELECT fk_test FROM test_assignment WHERE id = ?
    ");
    $stmt->execute([$assignmentId]);
    $assignment = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$assignment) {
        throw new Exception('Assignment not found');
    }

    $testId = $assignment['fk_test'];
    
    // Get the most recent forum item for this user and test
    $stmt = $pdo->prepare("
        SELECT fi.id 
        FROM forum_item fi
        JOIN test_assignment_user tau ON 
            tau.fk_assignment = ? AND 
            tau.fk_user = ? AND
            tau.completed = 1
        WHERE fi.fk_test = ?
        AND fi.fk_user = ?
        ORDER BY fi.creation_date DESC
        LIMIT 1
    ");
    
    $stmt->execute([$assignmentId, $userId, $testId, $userId]);
    $result = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($result) {
        $response['success'] = true;
        $response['forum_item_id'] = (int)$result['id'];
        $response['message'] = 'Submission found';
    } else {
        $response['message'] = 'No submission found for this assignment';
    }

} catch (PDOException $e) {
    $response['message'] = 'Database error: ' . $e->getMessage();
    http_response_code(500);
} catch (Exception $e) {
    $response['message'] = $e->getMessage();
    http_response_code(400);
}

echo json_encode($response);
exit;
?>
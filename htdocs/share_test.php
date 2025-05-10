<?php
require_once 'db_connect.php';

header('Content-Type: application/json');

$response = [
    'success' => false,
    'message' => '',
    'sharedTestId' => null
];

try {
    // Get raw POST data
    $input = file_get_contents('php://input');
    if ($input === false) {
        throw new Exception('Failed to read input data');
    }

    // Parse JSON data
    $data = json_decode($input, true);
    if ($data === null && json_last_error() !== JSON_ERROR_NONE) {
        throw new Exception('Invalid JSON data: ' . json_last_error_msg());
    }

    // Validate required fields
    $requiredFields = ['title', 'original_test_id', 'fk_user'];
    foreach ($requiredFields as $field) {
        if (empty($data[$field])) {
            throw new Exception("Missing required field: $field");
        }
    }

    $pdo = getPDOConnection();
    if (!$pdo) {
        throw new Exception('Database connection failed');
    }

    $pdo->beginTransaction();

    // 1. Insert the shared test record
    $stmt = $pdo->prepare("
        INSERT INTO forum_item 
        (title, description, fk_test, fk_user, fk_group, creation_date) 
        VALUES (?, ?, ?, ?, ?, NOW())
    ");
    if (!$stmt) {
        throw new Exception('Failed to prepare SQL statement');
    }

    $success = $stmt->execute([
        $data['title'],
        $data['description'] ?? '',
        $data['original_test_id'],
        $data['fk_user'],
        $data['fk_group'] ?? null
    ]);

    if (!$success) {
        throw new Exception('Failed to insert forum item');
    }

    $sharedTestId = $pdo->lastInsertId();

    // 2. Insert the answers for each question
    if (!empty($data['answers'])) {
        $stmt = $pdo->prepare("
            INSERT INTO forum_item_answer 
            (fk_forum_item, fk_question, answer) 
            VALUES (?, ?, ?)
        ");
        
        if (!$stmt) {
            throw new Exception('Failed to prepare answer SQL statement');
        }

        foreach ($data['answers'] as $answer) {
            if (empty($answer['question_id']) || !isset($answer['answer'])) {
                continue; // Skip invalid answers
            }

            $success = $stmt->execute([
                $sharedTestId,
                $answer['question_id'],
                $answer['answer']
            ]);

            if (!$success) {
                throw new Exception('Failed to insert answer');
            }
        }
    }

    // 3. Update test assignment completion if assignment_id is provided
    if (!empty($data['assignment_id'])) {
        $updateStmt = $pdo->prepare("
            UPDATE test_assignment_user 
            SET completed = 1, 
                completion_date = NOW() 
            WHERE fk_assignment = ? 
            AND fk_user = ?
        ");
        
        if (!$updateStmt) {
            throw new Exception('Failed to prepare completion update statement');
        }

        $success = $updateStmt->execute([
            $data['assignment_id'],
            $data['fk_user']
        ]);

        if (!$success) {
            throw new Exception('Failed to update assignment completion status');
        }
    }

    $pdo->commit();

    $response['success'] = true;
    $response['message'] = 'Test shared successfully';
    $response['sharedTestId'] = $sharedTestId;

} catch (PDOException $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    $response['message'] = 'Database error: ' . $e->getMessage();
    http_response_code(500);
} catch (Exception $e) {
    $response['message'] = $e->getMessage();
    http_response_code(400);
}

echo json_encode($response);
exit;
?>
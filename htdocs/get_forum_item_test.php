<?php
require_once 'db_connect.php';

header('Content-Type: application/json');

$response = [
    'success' => false,
    'message' => '',
    'test' => null,
    'answers' => []
];

try {
    $forumItemId = isset($_GET['forum_item_id']) ? (int)$_GET['forum_item_id'] : 0;

    if ($forumItemId <= 0) {
        throw new Exception('Invalid forum item ID');
    }

    $conn = getDBConnection();

    // First get the test ID from the forum item
    $stmt = $conn->prepare("
        SELECT fk_test 
        FROM forum_item 
        WHERE id = ? AND fk_test IS NOT NULL
    ");
    $stmt->bind_param('i', $forumItemId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        throw new Exception('No test attached to this forum item');
    }

    $row = $result->fetch_assoc();
    $testId = $row['fk_test'];

    // Get test basic info
    $stmt = $conn->prepare("
        SELECT id, name, description, creation_date
        FROM test
        WHERE id = ?
    ");
    $stmt->bind_param('i', $testId);
    $stmt->execute();
    $testInfo = $stmt->get_result()->fetch_assoc();

    // Get questions for this test
    $stmt = $conn->prepare("
        SELECT 
            id as question_id,
            name as text,
            description,
            answer as correct_answer
        FROM question
        WHERE fk_test = ?
        ORDER BY id
    ");
    $stmt->bind_param('i', $testId);
    $stmt->execute();
    $questions = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);

    // Get user answers for this forum item's test
    $stmt = $conn->prepare("
        SELECT 
            fk_question as question_id,
            answer
        FROM forum_item_answer
        WHERE fk_forum_item = ?
        ORDER BY fk_question
    ");
    $stmt->bind_param('i', $forumItemId);
    $stmt->execute();
    $answers = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);

    // Format the response
    $response['test'] = [
        'id' => $testInfo['id'],
        'name' => $testInfo['name'],
        'description' => $testInfo['description'],
        'questions' => $questions
    ];
    
    $response['answers'] = $answers;
    $response['success'] = true;

} catch (Exception $e) {
    $response['message'] = $e->getMessage();
    http_response_code(400);
} finally {
    echo json_encode($response);
    if (isset($conn)) $conn->close();
    exit;
}
?>
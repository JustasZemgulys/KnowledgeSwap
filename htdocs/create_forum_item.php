<?php
require_once 'db_connect.php';

header('Content-Type: application/json');

$response = [
    'success' => false,
    'message' => '',
    'forum_item_id' => null
];

try {
    // Get raw POST data
    $input = file_get_contents('php://input');
    
    // Parse as JSON if content-type is application/json
    if (strpos($_SERVER['CONTENT_TYPE'] ?? '', 'application/json') !== false) {
        $data = json_decode($input, true);
    } else {
        // Otherwise parse as form data
        parse_str($input, $data);
    }

    if (empty($data)) {
        throw new Exception('No data received');
    }

    // Validate required fields
    if (empty($data['title']) || empty($data['user_id'])) {
        throw new Exception('Missing required fields: title and user_id are required');
    }

    $pdo = getPDOConnection();
    $pdo->beginTransaction();

    // Insert the forum item
    $stmt = $pdo->prepare("
        INSERT INTO forum_item 
        (title, description, fk_user, creation_date, score) 
        VALUES (?, ?, ?, NOW(), 0)
    ");
    $stmt->execute([
        $data['title'],
        $data['description'] ?? '',
        $data['user_id']
    ]);
    $forumItemId = $pdo->lastInsertId();

    $pdo->commit();

    $response = [
        'success' => true,
        'message' => 'Forum item created successfully',
        'forum_item_id' => $forumItemId
    ];

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
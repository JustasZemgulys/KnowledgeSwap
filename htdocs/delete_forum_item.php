<?php
require_once 'db_connect.php';

header('Content-Type: application/json');

$response = [
    'success' => false,
    'message' => ''
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
    if (empty($data['forum_item_id']) || empty($data['user_id'])) {
        throw new Exception('Missing required fields: forum_item_id and user_id are required');
    }

    $pdo = getPDOConnection();
    $pdo->beginTransaction();

    // First verify the user owns the forum item
    $checkStmt = $pdo->prepare("SELECT id FROM forum_item WHERE id = ? AND fk_user = ?");
    $checkStmt->execute([$data['forum_item_id'], $data['user_id']]);
    
    if (!$checkStmt->fetch()) {
        throw new Exception('You can only delete your own forum items');
    }

    // Delete all votes for this forum item
    $deleteVotesStmt = $pdo->prepare("DELETE FROM vote WHERE fk_item = ? AND fk_type = 'forum_item'");
    $deleteVotesStmt->execute([$data['forum_item_id']]);

    // Delete all comments for this forum item
    $deleteCommentsStmt = $pdo->prepare("DELETE FROM comment WHERE fk_item = ? AND fk_type = 'forum_item'");
    $deleteCommentsStmt->execute([$data['forum_item_id']]);

    // Finally delete the forum item itself
    $deleteItemStmt = $pdo->prepare("DELETE FROM forum_item WHERE id = ?");
    $deleteItemStmt->execute([$data['forum_item_id']]);

    $pdo->commit();

    $response = [
        'success' => true,
        'message' => 'Forum item and all associated comments deleted successfully'
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
<?php
require_once 'db_connect.php';

header('Content-Type: application/json');

$response = [
    'success' => false,
    'message' => '',
    'item' => null
];

try {
    // Validate inputs
    $itemId = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;

    if ($itemId <= 0 || $userId <= 0) {
        throw new Exception('Invalid parameters');
    }

    $conn = getDBConnection();

    // Get forum item details with creator info and vote status
    $stmt = $conn->prepare("
        SELECT 
            fi.*,
            u.name as creator_name,
            v.direction as user_vote
        FROM forum_item fi
        LEFT JOIN user u ON fi.fk_user = u.id
        LEFT JOIN vote v ON v.fk_item = fi.id AND v.fk_type = 'forum_item' AND v.fk_user = ?
        WHERE fi.id = ?
    ");
    $stmt->bind_param('ii', $userId, $itemId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        throw new Exception('Forum item not found');
    }

    $response['item'] = $result->fetch_assoc();
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
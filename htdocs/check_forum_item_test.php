<?php
require_once 'db_connect.php';

$response = ['success' => false, 'has_test' => false];

try {
    $forumItemId = isset($_GET['forum_item_id']) ? (int)$_GET['forum_item_id'] : 0;
    
    if ($forumItemId <= 0) {
        throw new Exception("Invalid forum_item_id");
    }

    $conn = getDBConnection();

    // Check if this forum item has an associated test
    $stmt = $conn->prepare("SELECT COUNT(*) as test_count FROM forum_item WHERE id = ? AND fk_test IS NOT NULL");
    $stmt->bind_param("i", $forumItemId);
    $stmt->execute();
    $result = $stmt->get_result();
    $data = $result->fetch_assoc();
    
    $response['success'] = true;
    $response['has_test'] = $data['test_count'] > 0;
} catch (Exception $e) {
    $response['message'] = $e->getMessage();
} finally {
    header('Content-Type: application/json');
    echo json_encode($response);
    if (isset($conn)) $conn->close();
}
?>
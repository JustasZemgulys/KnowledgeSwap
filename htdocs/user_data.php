<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/user_data_errors.log');

require_once 'db_connect.php';

// Initialize response array
$response = [
    'success' => false,
    'message' => 'Initial state',
    'tests' => [],
    'resources' => [],
    'forum_items' => [],
    'groups' => []
];

try {
    // Validate user ID
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
    if ($userId <= 0) {
        throw new Exception("Invalid user_id: $userId");
    }

    $conn = getDBConnection();

    // Fetch user tests
    $stmt = $conn->prepare("
        SELECT t.*, u.name as creator_name, v.direction as user_vote 
        FROM test t
        LEFT JOIN user u ON t.fk_user = u.id
        LEFT JOIN vote v ON v.fk_item = t.id AND v.fk_type = 'test' AND v.fk_user = ?
        WHERE t.fk_user = ?
        ORDER BY t.creation_date DESC
    ");
    $stmt->bind_param("ii", $userId, $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    $response['tests'] = $result->fetch_all(MYSQLI_ASSOC);
    $stmt->close();

    // Fetch user resources
    $stmt = $conn->prepare("
        SELECT r.*, u.name as creator_name, v.direction as user_vote 
        FROM resource r
        LEFT JOIN user u ON r.fk_user = u.id
        LEFT JOIN vote v ON v.fk_item = r.id AND v.fk_type = 'resource' AND v.fk_user = ?
        WHERE r.fk_user = ?
        ORDER BY r.creation_date DESC
    ");
    $stmt->bind_param("ii", $userId, $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    $response['resources'] = $result->fetch_all(MYSQLI_ASSOC);
    $stmt->close();

    // Fetch user forum items
    $stmt = $conn->prepare("
        SELECT fi.*, u.name as creator_name, v.direction as user_vote 
        FROM forum_item fi
        LEFT JOIN user u ON fi.fk_user = u.id
        LEFT JOIN vote v ON v.fk_item = fi.id AND v.fk_type = 'forum_item' AND v.fk_user = ?
        WHERE fi.fk_user = ? AND fi.fk_group IS NULL
        ORDER BY fi.creation_date DESC
    ");
    $stmt->bind_param("ii", $userId, $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    $response['forum_items'] = $result->fetch_all(MYSQLI_ASSOC);
    $stmt->close();

    // Fetch user groups
    $stmt = $conn->prepare("
        SELECT g.*, gm.role, 
               (SELECT COUNT(*) FROM group_member WHERE fk_group = g.id) as member_count,
               v.direction as user_vote
        FROM `group` g
        JOIN group_member gm ON g.id = gm.fk_group
        LEFT JOIN vote v ON v.fk_item = g.id AND v.fk_type = 'group' AND v.fk_user = ?
        WHERE gm.fk_user = ?
        ORDER BY g.creation_date DESC
    ");
    $stmt->bind_param("ii", $userId, $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    $response['groups'] = $result->fetch_all(MYSQLI_ASSOC);
    $stmt->close();

    $response['success'] = true;
    $response['message'] = 'Data fetched successfully';

} catch (Exception $e) {
    http_response_code(500);
    $response['message'] = 'Error: ' . $e->getMessage();
    $response['error'] = $conn->error ?? null;
    $response['trace'] = $e->getTraceAsString();
} finally {
    header('Content-Type: application/json');
    echo json_encode($response);
    if (isset($conn)) $conn->close();
    exit;
}
?>
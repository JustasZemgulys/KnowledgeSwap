<?php
require_once 'db_connect.php';

$response = [
    'success' => false,
    'message' => '',
    'items' => [],
    'total' => 0
];

try {
    // Validate and sanitize inputs
    $page = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
    $perPage = isset($_GET['per_page']) ? max(1, (int)$_GET['per_page']) : 10;
    $sort = isset($_GET['sort']) && $_GET['sort'] === 'asc' ? 'ASC' : 'DESC';
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
    $offset = ($page - 1) * $perPage;

    if ($userId <= 0) {
        throw new Exception("Invalid user_id");
    }

    $conn = getDBConnection();

    // Count total forum items (excluding those with fk_group)
    $countStmt = $conn->prepare("
        SELECT COUNT(*) as total 
        FROM forum_item fi
        LEFT JOIN user u ON fi.fk_user = u.id
        WHERE fi.fk_group IS NULL
    ");
    $countStmt->execute();
    $total = (int)$countStmt->get_result()->fetch_assoc()['total'];
    $countStmt->close();

    // Get paginated results with vote information (excluding items with fk_group)
    $stmt = $conn->prepare("
        SELECT 
            fi.*,
            u.name as creator_name,
            v.direction as user_vote
        FROM forum_item fi
        LEFT JOIN user u ON fi.fk_user = u.id
        LEFT JOIN vote v ON v.fk_item = fi.id AND v.fk_type = 'forum_item' AND v.fk_user = ?
        WHERE fi.fk_group IS NULL
        ORDER BY fi.creation_date $sort
        LIMIT ? OFFSET ?
    ");
    
    $stmt->bind_param('iii', $userId, $perPage, $offset);
    $stmt->execute();
    $result = $stmt->get_result();
    $items = $result->fetch_all(MYSQLI_ASSOC);
    $stmt->close();

    $response = [
        'success' => true,
        'items' => $items,
        'total' => $total
    ];

} catch (Exception $e) {
    http_response_code(500);
    $response['message'] = 'Error: ' . $e->getMessage();
} finally {
    header('Content-Type: application/json');
    echo json_encode($response);
    if (isset($conn)) $conn->close();
    exit;
}
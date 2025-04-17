<?php
require_once 'db_connect.php';

$conn = getDBConnection();

$response = ['success' => false, 'message' => ''];

try {
    // Validate user_id first
    if (!isset($_GET['user_id']) || !is_numeric($_GET['user_id'])) {
        throw new Exception("Invalid user ID");
    }
    $userId = (int)$_GET['user_id'];
    
    // Get pagination parameters
    $page = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
    $perPage = isset($_GET['per_page']) ? max(1, (int)$_GET['per_page']) : 10;
    $sort = in_array(strtoupper($_GET['sort'] ?? ''), ['ASC', 'DESC']) ? $_GET['sort'] : 'DESC';
    $offset = ($page - 1) * $perPage;

    // First get total count
    $countQuery = "SELECT COUNT(*) as total FROM test WHERE (visibility = 1 OR fk_user = ?)";
    $countStmt = $conn->prepare($countQuery);
    if (!$countStmt) {
        throw new Exception("Count query preparation failed");
    }
    
    $countStmt->bind_param("i", $userId);
    if (!$countStmt->execute()) {
        throw new Exception("Count query execution failed");
    }
    
    $total = (int)$countStmt->get_result()->fetch_assoc()['total'];
    $countStmt->close();

    // Then get paginated results
    $testQuery = "
        SELECT 
            t.id,
            t.name,
            t.description,
            t.creation_date,
            t.visibility,
            t.fk_resource,
            t.fk_user,
            t.ai_made,
            t.score,
            v.direction as user_vote,
            COUNT(q.id) as question_count
        FROM test t
        LEFT JOIN question q ON q.fk_test = t.id
        LEFT JOIN vote v ON v.fk_item = t.id AND v.fk_type = 'test' AND v.fk_user = ?
        WHERE (t.visibility = 1 OR t.fk_user = ?)
        GROUP BY t.id
        ORDER BY t.creation_date $sort
        LIMIT ? OFFSET ?
    ";

    $stmt = $conn->prepare($testQuery);
    if (!$stmt) {
        throw new Exception("Database query preparation failed");
    }
    
    $stmt->bind_param("iiii", $userId, $userId, $perPage, $offset);
    if (!$stmt->execute()) {
        throw new Exception("Query execution failed");
    }

    $result = $stmt->get_result();
    $tests = [];

    while ($row = $result->fetch_assoc()) {
        $tests[] = [
            'id' => (int)$row['id'],
            'name' => $row['name'],
            'description' => $row['description'],
            'creation_date' => $row['creation_date'],
            'has_resource' => !empty($row['fk_resource']),
            'fk_resource' => $row['fk_resource'],
            'question_count' => (int)$row['question_count'],
            'is_owner' => ($row['fk_user'] == $userId),
            'ai_made' => (bool)$row['ai_made'],
            'score' => $row['score'],
            'fk_user' => $row['fk_user'],
            'visibility' => (bool)$row['visibility'],
            'score' => (int)$row['score'],
            'user_vote' => $row['user_vote'] ? (int)$row['user_vote'] : null,
        ];
    }

    $response = [
        'success' => true,
        'tests' => $tests,
        'total' => $total
    ];

    $stmt->close();
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
<?php
require_once 'db_connect.php';

$conn = getDBConnection();

$response = ['success' => false, 'message' => '', 'tests' => []];

try {
    if (!isset($_GET['group_id']) || !is_numeric($_GET['group_id'])) {
        throw new Exception("Invalid group ID");
    }
    $groupId = (int)$_GET['group_id'];

    $query = "
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
            u.name as creator_name,
            COUNT(q.id) as question_count
        FROM group_test gt
        JOIN test t ON gt.fk_test = t.id
        LEFT JOIN user u ON t.fk_user = u.id
        LEFT JOIN question q ON q.fk_test = t.id
        WHERE gt.fk_group = ?
        GROUP BY t.id
    ";

    $stmt = $conn->prepare($query);
    if (!$stmt) {
        throw new Exception("Database query preparation failed");
    }
    
    $stmt->bind_param("i", $groupId);
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
            'creator_name' => $row['creator_name'],
            'ai_made' => (bool)$row['ai_made'],
            'score' => (int)$row['score'],
            'fk_user' => $row['fk_user'],
            'visibility' => (bool)$row['visibility']
        ];
    }

    $response = [
        'success' => true,
        'tests' => $tests
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
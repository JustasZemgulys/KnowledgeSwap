<?php
require_once 'db_connect.php';

$conn = getDBConnection();

$response = ['success' => false, 'message' => '', 'users' => []];

try {
    if (!isset($_GET['assignment_id']) || !is_numeric($_GET['assignment_id'])) {
        throw new Exception("Invalid assignment ID");
    }
    $assignmentId = (int)$_GET['assignment_id'];

    $query = "
        SELECT 
            u.id,
            u.name,
            u.email,
            u.imageURL,
            tau.assigned_date,
            tau.completed,
            tau.completion_date,
            tau.score,
			tau.comment
        FROM test_assignment_user tau
        JOIN user u ON tau.fk_user = u.id
        WHERE tau.fk_assignment = ?
        ORDER BY u.name
    ";

    $stmt = $conn->prepare($query);
    if (!$stmt) {
        throw new Exception("Database query preparation failed");
    }
    
    $stmt->bind_param("i", $assignmentId);
    if (!$stmt->execute()) {
        throw new Exception("Query execution failed");
    }

    $result = $stmt->get_result();
    $users = [];

    while ($row = $result->fetch_assoc()) {
        $users[] = [
            'id' => (int)$row['id'],
            'name' => $row['name'],
            'email' => $row['email'],
            'profile_picture' => $row['imageURL'],
            'assigned_date' => $row['assigned_date'],
            'completed' => (bool)$row['completed'],
            'completion_date' => $row['completion_date'],
            'score' => $row['score'] !== null ? (int)$row['score'] : null,
			'comment' => $row['comment'],
        ];
    }

    $response = [
        'success' => true,
        'users' => $users
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
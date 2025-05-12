<?php
require_once 'db_connect.php';

$conn = getDBConnection();

$response = ['success' => false, 'message' => '', 'assignments' => []];

try {
    if (!isset($_GET['group_id']) || !is_numeric($_GET['group_id'])) {
        throw new Exception("Invalid group ID");
    }
    $groupId = (int)$_GET['group_id'];

    $query = "
		SELECT 
			ta.id,
			ta.name,
			ta.description,
			ta.open_date,
			ta.due_date,
			ta.creation_date,
			t.id as test_id,
			t.name as test_name,
			r.id as resource_id,
			r.name as resource_name,
			r.resource_photo_link as resource_photo_link,
			r.resource_link as resource_link,
			u.id as creator_id,
			u.name as creator_name,
			COUNT(tau.fk_user) as assigned_users_count,
			CASE 
				WHEN ta.open_date IS NULL THEN 1
				WHEN ta.open_date <= NOW() THEN 1
				ELSE 0
			END as is_available
		FROM test_assignment ta
		JOIN test t ON ta.fk_test = t.id
		LEFT JOIN resource r ON ta.fk_resource = r.id
		JOIN user u ON ta.fk_creator = u.id
		LEFT JOIN test_assignment_user tau ON tau.fk_assignment = ta.id
		WHERE ta.fk_group = ?
		GROUP BY ta.id
		ORDER BY ta.open_date DESC
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
    $assignments = [];

    while ($row = $result->fetch_assoc()) {
        $assignments[] = [
            'id' => (int)$row['id'],
            'name' => $row['name'],
            'description' => $row['description'],
            'open_date' => $row['open_date'],
            'due_date' => $row['due_date'],
            'creation_date' => $row['creation_date'],
            'test' => [
                'id' => (int)$row['test_id'],
                'name' => $row['test_name']
            ],
            'resource' => $row['resource_id'] ? [
                'id' => (int)$row['resource_id'],
                'name' => $row['resource_name'],
				'resource_link' => $row['resource_link'],
				'resource_photo_link' => $row['resource_photo_link']
            ] : null,
            'creator' => [
                'id' => (int)$row['creator_id'],
                'name' => $row['creator_name']
            ],
            'assigned_users_count' => (int)$row['assigned_users_count']
        ];
    }

    $response = [
        'success' => true,
        'assignments' => $assignments
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
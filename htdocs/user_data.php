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
    'groups' => [],
    'comments' => [],
    'assignments' => []
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
			   (SELECT COUNT(*) FROM group_member WHERE fk_group = g.id AND role != 'banned') as member_count,
			   v.direction as user_vote
		FROM `group` g
		JOIN group_member gm ON g.id = gm.fk_group
		LEFT JOIN vote v ON v.fk_item = g.id AND v.fk_type = 'group' AND v.fk_user = ?
		WHERE gm.fk_user = ? AND gm.role != 'banned'
		ORDER BY g.creation_date DESC
	");
    $stmt->bind_param("ii", $userId, $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    $response['groups'] = $result->fetch_all(MYSQLI_ASSOC);
    $stmt->close();

    // Fetch user comments
    $stmt = $conn->prepare("
        SELECT c.*, 
               CASE 
                   WHEN c.fk_type = 'forum_item' THEN fi.title
                   WHEN c.fk_type = 'test' THEN t.name
                   WHEN c.fk_type = 'resource' THEN r.name
                   WHEN c.fk_type = 'group' THEN g.name
               END as parent_title,
               c.fk_type as parent_type
        FROM comment c
        LEFT JOIN forum_item fi ON c.fk_type = 'forum_item' AND c.fk_item = fi.id
        LEFT JOIN test t ON c.fk_type = 'test' AND c.fk_item = t.id
        LEFT JOIN resource r ON c.fk_type = 'resource' AND c.fk_item = r.id
        LEFT JOIN `group` g ON c.fk_type = 'group' AND c.fk_item = g.id
        WHERE c.fk_user = ?
        ORDER BY c.creation_date DESC
    ");
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    $response['comments'] = $result->fetch_all(MYSQLI_ASSOC);
    $stmt->close();

    // Fetch user assignments
	$stmt = $conn->prepare("
		SELECT 
			a.id, 
			a.name, 
			a.description,
			a.fk_test,
			a.fk_group,
			a.open_date,
			a.due_date,
			t.name as test_name,
			t.description as test_description,
			g.name as group_name,
			g.id as group_id,
			au.completed,
			au.completion_date,
			au.score,
			au.comment as user_comment,
			gm.role
		FROM test_assignment a
		JOIN test_assignment_user au ON a.id = au.fk_assignment
		JOIN test t ON a.fk_test = t.id
		LEFT JOIN `group` g ON a.fk_group = g.id
		LEFT JOIN group_member gm ON gm.fk_group = g.id AND gm.fk_user = ?
		WHERE au.fk_user = ?
		ORDER BY a.due_date ASC
	");
	$stmt->bind_param("ii", $userId, $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    $response['assignments'] = $result->fetch_all(MYSQLI_ASSOC);
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
<?php
require_once 'db_connect.php';

$conn = getDBConnection();

// Enable error reporting for debugging (remove in production)
error_reporting(E_ALL);
ini_set('display_errors', 1);

$response = [
    'success' => false,
    'message' => 'Initial error',
    'groups' => [],
    'total' => 0
];

try {
    // Get parameters with defaults
    $page = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
    $perPage = isset($_GET['per_page']) ? max(1, (int)$_GET['per_page']) : 6;
    $sort = in_array(strtoupper($_GET['sort'] ?? ''), ['ASC', 'DESC']) ? $_GET['sort'] : 'DESC';
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;

    if ($userId <= 0) {
        throw new Exception("Valid user_id is required");
    }

    // Count total groups
    $countQuery = "SELECT COUNT(*) as total FROM `group`";
    $countResult = $conn->query($countQuery);
    
    if (!$countResult) {
        throw new Exception("Count query failed: " . $conn->error);
    }

    $total = (int)$countResult->fetch_assoc()['total'];
    $countResult->close();

	$groupsQuery = "
		SELECT 
			g.id,
			g.name,
			g.description,
			g.creation_date,
			g.icon_path,
			g.visibility,
			g.score,
			COUNT(CASE WHEN gm.role != 'banned' THEN gm.id END) as member_count,
			v.direction as user_vote,
			EXISTS(
				SELECT 1 FROM group_member gm2 
				WHERE gm2.fk_group = g.id AND gm2.fk_user = ? AND gm2.role != 'banned'
			) as is_member,
			EXISTS(
				SELECT 1 FROM group_member gm3 
				WHERE gm3.fk_group = g.id AND gm3.fk_user = ? AND gm3.role = 'admin'
			) as is_owner,
			(SELECT gm4.role FROM group_member gm4 
			 WHERE gm4.fk_group = g.id AND gm4.fk_user = ?) as user_role,
			EXISTS(
				SELECT 1 FROM group_member gm5 
				WHERE gm5.fk_group = g.id AND gm5.fk_user = ? AND gm5.role = 'banned'
			) as is_banned
		FROM `group` g
		LEFT JOIN group_member gm ON gm.fk_group = g.id AND gm.role != 'banned'
		LEFT JOIN vote v ON v.fk_item = g.id AND v.fk_type = 'group' AND v.fk_user = ?
		WHERE (g.visibility = 1) OR 
			  (g.visibility = 0 AND EXISTS(
				  SELECT 1 FROM group_member gm4 
				  WHERE gm4.fk_group = g.id AND gm4.fk_user = ? AND gm4.role != 'banned'
			  ))
		GROUP BY g.id
		ORDER BY g.creation_date $sort
		LIMIT ? OFFSET ?
	";
    
    $stmt = $conn->prepare($groupsQuery);
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }

    $offset = ($page - 1) * $perPage;
    $stmt->bind_param("iiiiiiii", $userId, $userId, $userId, $userId, $userId, $userId, $perPage, $offset);
    
    if (!$stmt->execute()) {
        throw new Exception("Execute failed: " . $stmt->error);
    }

    $result = $stmt->get_result();
    $groups = [];
    
    // Modify the icon_path handling in the while loop:
	while ($row = $result->fetch_assoc()) {
		// Keep the full path including knowledgeswap/ for the proxy
		if (!empty($row['icon_path'])) {
			// Ensure path uses forward slashes
			$row['icon_path'] = str_replace('\\', '/', $row['icon_path']);
		}
		$row['is_member'] = (bool)$row['is_member'];
        $row['is_owner'] = (bool)$row['is_owner'];
		$groups[] = $row;
	}

    $stmt->close();
    $conn->close();

    $response = [
        'success' => true,
        'message' => 'Groups loaded successfully',
        'groups' => $groups,
        'total' => $total
    ];

} catch (Exception $e) {
    http_response_code(500);
    $response['message'] = "Server Error: " . $e->getMessage();
    
    // Log the error for debugging
    error_log("Group Loading Error: " . $e->getMessage());
    error_log("Stack Trace: " . $e->getTraceAsString());
}

echo json_encode($response);
?>
<?php
require_once 'db_connect.php';

$conn = getDBConnection();

// Error reporting for development
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Initialize response
$response = [
    'success' => false,
    'message' => 'Initial error',
    'group' => null
];

// Custom logging function
function log_message($message) {
    $timestamp = date('Y-m-d H:i:s');
    $logEntry = "[$timestamp] $message\n";
    file_put_contents(__DIR__ . '/debug.log', $logEntry, FILE_APPEND);
}

try {
    // Get and validate parameters
    $groupId = isset($_GET['group_id']) ? (int)$_GET['group_id'] : 0;
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;

    log_message("Received parameters - group_id: $groupId, user_id: $userId");


	$query = "
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
			 WHERE gm4.fk_group = g.id AND gm4.fk_user = ?) as user_role
		FROM `group` g
		LEFT JOIN group_member gm ON gm.fk_group = g.id AND gm.role != 'banned'
		LEFT JOIN vote v ON v.fk_item = g.id AND v.fk_type = 'group' AND v.fk_user = ?
		WHERE g.id = ?
		GROUP BY g.id
	";
    
    log_message("Preparing main group query");
    $stmt = $conn->prepare($query);
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }

    $stmt->bind_param("iiiii", $userId, $userId, $userId, $userId, $groupId);
    
    log_message("Executing main group query");
    if (!$stmt->execute()) {
        throw new Exception("Execute failed: " . $stmt->error);
    }

    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        throw new Exception("Group not found or access denied");
    }

    $group = $result->fetch_assoc();
	$group['user_role'] = $group['user_role'] ?? null;
    log_message("Main group data retrieved");
    
    // Get group members
	$membersQuery = "
		SELECT 
			u.id,
			u.name,
			u.email,
			u.imageURL as profile_picture,
			gm.role
		FROM group_member gm
		JOIN user u ON gm.fk_user = u.id
		WHERE gm.fk_group = ? AND gm.role != 'banned'
		ORDER BY 
			CASE WHEN gm.role = 'admin' THEN 0 ELSE 1 END
	";
    
    log_message("Preparing members query");
    $membersStmt = $conn->prepare($membersQuery);
    if (!$membersStmt) {
        throw new Exception("Members prepare failed: " . $conn->error);
    }
    
    $membersStmt->bind_param("i", $groupId);
    
    log_message("Executing members query");
    if (!$membersStmt->execute()) {
        throw new Exception("Members execute failed: " . $membersStmt->error);
    }
    
    $membersResult = $membersStmt->get_result();
    $members = [];
    
    while ($member = $membersResult->fetch_assoc()) {
        $members[] = $member;
    }
    log_message("Retrieved " . count($members) . " members");
	
	$bannedQuery = "
		SELECT 
			u.id,
			u.name,
			u.imageURL as profile_picture
		FROM group_member gm
		JOIN user u ON gm.fk_user = u.id
		WHERE gm.fk_group = ? AND gm.role = 'banned'
	";

	$bannedStmt = $conn->prepare($bannedQuery);
	if (!$bannedStmt) {
		throw new Exception("Banned users prepare failed: " . $conn->error);
	}

	$bannedStmt->bind_param("i", $groupId);
	if (!$bannedStmt->execute()) {
		throw new Exception("Banned users execute failed: " . $bannedStmt->error);
	}

	$bannedResult = $bannedStmt->get_result();
	$bannedUsers = [];
	while ($bannedUser = $bannedResult->fetch_assoc()) {
		$bannedUsers[] = $bannedUser;
	}

	// Add banned users to the group data
	$group['banned_users'] = $bannedUsers;
    
    // Close statements
    $stmt->close();
    $membersStmt->close();
    $conn->close();

    // Process icon path
    if (!empty($group['icon_path'])) {
        $group['icon_path'] = str_replace('\\', '/', $group['icon_path']);
    }
    
    $group['is_member'] = (bool)$group['is_member'];
    $group['is_owner'] = (bool)$group['is_owner'];
    $group['members'] = $members;

    $response = [
        'success' => true,
        'message' => 'Group details loaded successfully',
        'group' => $group
    ];

    log_message("Successfully prepared response");

} catch (Exception $e) {
    http_response_code(500);
    $response['message'] = "Server Error: " . $e->getMessage();
    log_message("ERROR: " . $e->getMessage());
}

echo json_encode($response);
?>
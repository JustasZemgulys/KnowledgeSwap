<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "knowledgeswap";

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    die(json_encode(['success' => false, 'message' => "Connection failed: " . $conn->connect_error]));
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    $groupId = $data['group_id'] ?? 0;
    $userId = $data['user_id'] ?? 0;
    
    if ($groupId <= 0 || $userId <= 0) {
        die(json_encode(['success' => false, 'message' => 'Invalid group or user ID']));
    }

    // Check if user is already a member
    $checkQuery = $conn->prepare("SELECT id FROM group_member WHERE fk_group = ? AND fk_user = ?");
    $checkQuery->bind_param("ii", $groupId, $userId);
    $checkQuery->execute();
    $checkResult = $checkQuery->get_result();
    
    if ($checkResult->num_rows > 0) {
        die(json_encode(['success' => false, 'message' => 'User is already a member of this group']));
    }

    // Add user to group with default 'member' role
    $insertQuery = $conn->prepare("INSERT INTO group_member (fk_group, fk_user, role) VALUES (?, ?, 'member')");
    $insertQuery->bind_param("ii", $groupId, $userId);
    
    if ($insertQuery->execute()) {
        // Get updated member count
        $countQuery = $conn->prepare("SELECT COUNT(*) as member_count FROM group_member WHERE fk_group = ?");
        $countQuery->bind_param("i", $groupId);
        $countQuery->execute();
        $countResult = $countQuery->get_result();
        $memberCount = $countResult->fetch_assoc()['member_count'];
        
        echo json_encode([
            'success' => true,
            'message' => 'Successfully joined the group',
            'member_count' => $memberCount
        ]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to join group']);
    }
}

$conn->close();
?>
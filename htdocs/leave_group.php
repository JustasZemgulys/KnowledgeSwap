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

    // Check if user is an admin (admins can't leave, they must delete the group)
    $checkAdminQuery = $conn->prepare("SELECT role FROM group_member WHERE fk_group = ? AND fk_user = ?");
    $checkAdminQuery->bind_param("ii", $groupId, $userId);
    $checkAdminQuery->execute();
    $adminResult = $checkAdminQuery->get_result();
    
    if ($adminResult->num_rows > 0) {
        $role = $adminResult->fetch_assoc()['role'];
        if ($role === 'admin') {
            die(json_encode(['success' => false, 'message' => 'Admins cannot leave the group. Please delete the group instead.']));
        }
    }

    // Remove user from group
    $deleteQuery = $conn->prepare("DELETE FROM group_member WHERE fk_group = ? AND fk_user = ?");
    $deleteQuery->bind_param("ii", $groupId, $userId);
    
    if ($deleteQuery->execute()) {
        // Get updated member count
        $countQuery = $conn->prepare("SELECT COUNT(*) as member_count FROM group_member WHERE fk_group = ?");
        $countQuery->bind_param("i", $groupId);
        $countQuery->execute();
        $countResult = $countQuery->get_result();
        $memberCount = $countResult->fetch_assoc()['member_count'];
        
        echo json_encode([
            'success' => true,
            'message' => 'Successfully left the group',
            'member_count' => $memberCount
        ]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to leave group']);
    }
}

$conn->close();
?>
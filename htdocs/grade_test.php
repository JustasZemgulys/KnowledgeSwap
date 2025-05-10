<?php
require_once 'db_connect.php';

$response = [
    'success' => false,
    'message' => ''
];

try {
    // Get JSON input
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Validate inputs
    $assignmentId = isset($input['assignment_id']) ? (int)$input['assignment_id'] : 0;
    $userId = isset($input['user_id']) ? (int)$input['user_id'] : 0;
    $graderId = isset($input['grader_id']) ? (int)$input['grader_id'] : 0;
    $score = isset($input['score']) ? (int)$input['score'] : null;
    $comment = isset($input['comment']) ? trim($input['comment']) : null;

    if ($assignmentId <= 0 || $userId <= 0 || $graderId <= 0 || $score === null) {
        throw new Exception("Invalid parameters. Required: assignment_id, user_id, grader_id, score");
    }

    $conn = getDBConnection();

    // Check permissions (user can only see their own grades/comments)
    $currentUserId = $graderId; // The user making the request
    
    // Check if current user is admin/moderator or the user being graded
    $stmt = $conn->prepare("
        SELECT 
            gm.role,
            CASE WHEN gm.fk_user = ? THEN 1 ELSE 0 END AS is_self
        FROM group_member gm
        JOIN test_assignment ta ON ta.fk_group = gm.fk_group
        WHERE ta.id = ? AND (gm.fk_user = ? OR gm.fk_user = ?)
    ");
    $stmt->bind_param('iiii', $userId, $assignmentId, $currentUserId, $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    $permissions = [];
    while ($row = $result->fetch_assoc()) {
        $permissions[] = $row;
    }
    $stmt->close();

    $isAdminMod = false;
    $isSelf = false;
    
    foreach ($permissions as $perm) {
        if (in_array($perm['role'], ['admin', 'moderator'])) {
            $isAdminMod = true;
        }
        if ($perm['is_self'] == 1) {
            $isSelf = true;
        }
    }

    if (!$isAdminMod && !$isSelf) {
        throw new Exception("You don't have permission to view or edit this grade");
    }

    // Check if the test is completed by the user
    $stmt = $conn->prepare("
        SELECT id FROM test_assignment_user 
        WHERE fk_assignment = ? AND fk_user = ? AND completed = 1
    ");
    $stmt->bind_param('ii', $assignmentId, $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    $assignmentUser = $result->fetch_assoc();
    $stmt->close();

    if (!$assignmentUser) {
        throw new Exception("User hasn't completed this test yet");
    }

    // Update or insert grade/comment
    $stmt = $conn->prepare("
        UPDATE test_assignment_user 
        SET score = ?, comment = ?
        WHERE id = ?
    ");
    $stmt->bind_param('isi', $score, $comment, $assignmentUser['id']);
    $stmt->execute();
    
    if ($stmt->affected_rows === 0) {
        throw new Exception("Failed to update grade");
    }
    
    $stmt->close();

    $response['success'] = true;
    $response['message'] = 'Test graded successfully';

} catch (Exception $e) {
    http_response_code(400);
    $response['message'] = $e->getMessage();
} finally {
    header('Content-Type: application/json');
    echo json_encode($response);
    if (isset($conn)) $conn->close();
    exit;
}
<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Content-Type: application/json; charset=UTF-8");

$response = ['success' => false, 'message' => ''];

try {
    // Get raw POST data
    $rawData = file_get_contents('php://input');
    $data = json_decode($rawData, true);
    
    if (json_last_error() !== JSON_ERROR_NONE) {
        // Fallback to form data if JSON decode fails
        $data = $_POST;
    }
    
    // Validate required fields
    $requiredFields = ['comment_id', 'user_id', 'text'];
    foreach ($requiredFields as $field) {
        if (!isset($data[$field])) {  // Fixed syntax error here
            throw new Exception("Missing required field: $field");
        }
    }
    
    // Validate input
    $commentId = filter_var($data['comment_id'], FILTER_VALIDATE_INT);
    $userId = filter_var($data['user_id'], FILTER_VALIDATE_INT);
    $text = trim($data['text']);
    
    if ($commentId === false || $commentId <= 0) {
        throw new Exception("Invalid comment ID");
    }
    
    if ($userId === false || $userId <= 0) {
        throw new Exception("Invalid user ID");
    }
    
    if (empty($text)) {
        throw new Exception("Comment text cannot be empty");
    }
    
    $db = new mysqli("localhost", "root", "", "knowledgeswap");
    if ($db->connect_error) {
        throw new Exception("Database connection failed");
    }
    
    // Check if comment exists and user owns it
    $stmt = $db->prepare("SELECT fk_user, is_deleted FROM comment WHERE id = ?");
    $stmt->bind_param("i", $commentId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        throw new Exception("Comment not found");
    }
    
    $comment = $result->fetch_assoc();
    
    // Check if comment is deleted
    if ($comment['is_deleted'] == 1) {
        throw new Exception("Cannot edit deleted comment");
    }
    
    // Check ownership
    if ($comment['fk_user'] != $userId) {
        throw new Exception("You can only edit your own comments");
    }
    
    // Update comment
    $stmt = $db->prepare("UPDATE comment SET text = ?, last_edit_date = NOW() WHERE id = ?");
	$stmt->bind_param("si", $text, $commentId);
    
    if ($stmt->execute()) {
        $response = [
            'success' => true,
            'message' => 'Comment updated successfully',
            'comment_id' => $commentId,
            'text' => $text
        ];
    } else {
        throw new Exception("Failed to update comment: " . $db->error);
    }
} catch (Exception $e) {
    $response['message'] = $e->getMessage();
}

if (isset($db)) $db->close();
echo json_encode($response);
?>
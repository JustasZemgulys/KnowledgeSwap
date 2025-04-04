<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Content-Type: application/json; charset=UTF-8");

$response = ['success' => false, 'message' => ''];

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception("Invalid request method");
    }
    
    $data = json_decode(file_get_contents('php://input'), true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        $data = $_POST;
    }
    
    // Validate input
    if (!isset($data['comment_id']) || !is_numeric($data['comment_id'])) {
        throw new Exception("Invalid comment ID");
    }
    
    if (!isset($data['user_id']) || !is_numeric($data['user_id'])) {
        throw new Exception("Invalid user ID");
    }
    
    $commentId = (int)$data['comment_id'];
    $userId = (int)$data['user_id'];
    
    $db = new mysqli("localhost", "root", "", "knowledgeswap");
    if ($db->connect_error) {
        throw new Exception("Database connection failed");
    }
    
    // Check if user owns the comment
    $stmt = $db->prepare("SELECT fk_user FROM comment WHERE id = ?");
    $stmt->bind_param("i", $commentId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        throw new Exception("Comment not found");
    }
    
    $comment = $result->fetch_assoc();
    if ($comment['fk_user'] != $userId) {
        throw new Exception("You can only delete your own comments");
    }
    
    // Mark as deleted
    $stmt = $db->prepare("UPDATE comment SET is_deleted = 1 WHERE id = ?");
    $stmt->bind_param("i", $commentId);
    
    if ($stmt->execute()) {
        $response = [
            'success' => true,
            'message' => 'Comment deleted successfully'
        ];
    } else {
        throw new Exception("Failed to delete comment");
    }
} catch (Exception $e) {
    $response['message'] = $e->getMessage();
}

if (isset($db)) $db->close();
echo json_encode($response);
?>
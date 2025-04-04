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
        $data = $_POST; // Fallback to form data
    }
    
    // Required fields validation
    $requiredFields = ['user_id', 'item_id', 'item_type', 'text'];
    foreach ($requiredFields as $field) {
        if (!isset($data[$field]) || empty(trim($data[$field]))) {
            throw new Exception("Missing required field: $field");
        }
    }
    
    $userId = (int)$data['user_id'];
    $itemId = (int)$data['item_id'];
    $itemType = $data['item_type'];
    $text = trim($data['text']);
    
    // Validate item type
    $validTypes = ['resource', 'test', 'group', 'answer'];
    if (!in_array($itemType, $validTypes)) {
        throw new Exception("Invalid item type");
    }
    
    $db = new mysqli("localhost", "root", "", "knowledgeswap");
    if ($db->connect_error) {
        throw new Exception("Database connection failed");
    }
    
	$parentId = isset($data['parent_id']) && $data['parent_id'] !== '' 
        ? (int)$data['parent_id'] 
        : null;

    $db = new mysqli("localhost", "root", "", "knowledgeswap");
    if ($db->connect_error) {
        throw new Exception("Database connection failed");
    }
    
    if ($parentId !== null) {
        // Check if parent comment exists
        $checkStmt = $db->prepare("SELECT id FROM comment WHERE id = ?");
        $checkStmt->bind_param("i", $parentId);
        $checkStmt->execute();
        if (!$checkStmt->get_result()->fetch_assoc()) {
            throw new Exception("Parent comment not found");
        }
    }

    // Insert comment
    if ($parentId !== null) {
        $stmt = $db->prepare("
            INSERT INTO comment (
                text, 
                creation_date, 
                fk_user, 
                fk_item, 
                fk_type,
                parent_id
            ) VALUES (?, NOW(), ?, ?, ?, ?)
        ");
        $stmt->bind_param("siisi", $text, $userId, $itemId, $itemType, $parentId);
    } else {
        $stmt = $db->prepare("
            INSERT INTO comment (
                text, 
                creation_date, 
                fk_user, 
                fk_item, 
                fk_type
            ) VALUES (?, NOW(), ?, ?, ?)
        ");
        $stmt->bind_param("siis", $text, $userId, $itemId, $itemType);
    }
    
    if ($stmt->execute()) {
        $response = [
            'success' => true,
            'message' => 'Comment posted successfully',
            'comment_id' => $stmt->insert_id
        ];
    } else {
        throw new Exception("Failed to post comment: " . $db->error);
    }
} catch (Exception $e) {
    $response['message'] = $e->getMessage();
}

if (isset($db)) $db->close();
echo json_encode($response);
?>
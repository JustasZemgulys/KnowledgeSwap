<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Content-Type: application/json; charset=UTF-8");

$response = ['success' => false, 'message' => ''];

try {
    // Validate input
    if (!isset($_GET['item_id']) || !is_numeric($_GET['item_id'])) {
        throw new Exception("Invalid item ID");
    }
    
    if (!isset($_GET['item_type']) || !in_array($_GET['item_type'], ['resource', 'test', 'group', 'answer'])) {
        throw new Exception("Invalid item type");
    }
    
    $itemId = (int)$_GET['item_id'];
    $itemType = $_GET['item_type'];
    
    $db = new mysqli("localhost", "root", "", "knowledgeswap");
    if ($db->connect_error) {
        throw new Exception("Database connection failed");
    }

    // Get all comments with user existence check
    $stmt = $db->prepare("
    SELECT 
        c.*, 
        IFNULL(u.name, '[deleted]') as name,
        IF(u.id IS NULL, 0, 1) as user_exists,
        IFNULL(u.imageURL, 'default') as user_image,
        c.creation_date != c.last_edit_date as is_edited
    FROM comment c
    LEFT JOIN user u ON c.fk_user = u.id
    WHERE c.fk_item = ? AND c.fk_type = ?
    ORDER BY c.creation_date ASC
	");
    
    $stmt->bind_param("is", $itemId, $itemType);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $comments = [];
    while ($row = $result->fetch_assoc()) {
        $comments[] = $row;
    }
    
    $response = [
        'success' => true,
        'comments' => $comments
    ];
} catch (Exception $e) {
    $response['message'] = $e->getMessage();
}

if (isset($db)) $db->close();
echo json_encode($response);
?>
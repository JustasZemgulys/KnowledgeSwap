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
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : null;
    
    $db = new mysqli("localhost", "root", "", "knowledgeswap");
    if ($db->connect_error) {
        throw new Exception("Database connection failed");
    }

    // Get all comments with user existence check and voting information
    $query = "
    SELECT 
        c.*, 
        IFNULL(u.name, '[deleted]') as name,
        IF(u.id IS NULL, 0, 1) as user_exists,
        IFNULL(u.imageURL, 'default') as user_image,
        c.creation_date != c.last_edit_date as is_edited,
        c.score,
        v.direction as user_vote
    FROM comment c
    LEFT JOIN user u ON c.fk_user = u.id
    LEFT JOIN vote v ON v.fk_item = c.id AND v.fk_type = 'comment' AND v.fk_user = ?
    WHERE c.fk_item = ? AND c.fk_type = ?
    ORDER BY c.creation_date ASC
    ";
    
    $stmt = $db->prepare($query);
    if (!$stmt) {
        throw new Exception("Query preparation failed: " . $db->error);
    }
    
    $stmt->bind_param("iis", $userId, $itemId, $itemType);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $comments = [];
    while ($row = $result->fetch_assoc()) {
        $comments[] = [
            'id' => (int)$row['id'],
            'text' => $row['text'],
            'creation_date' => $row['creation_date'],
            'last_edit_date' => $row['last_edit_date'],
            'fk_user' => (int)$row['fk_user'],
            'fk_item' => (int)$row['fk_item'],
            'fk_type' => $row['fk_type'],
            'parent_id' => $row['parent_id'] ? (int)$row['parent_id'] : null,
            'is_deleted' => (bool)$row['is_deleted'],
            'name' => $row['name'],
            'user_image' => $row['user_image'],
            'user_exists' => (bool)$row['user_exists'],
            'is_edited' => (bool)$row['is_edited'],
            'score' => (int)$row['score'],
            'user_vote' => $row['user_vote'] ? (int)$row['user_vote'] : null
        ];
    }
    
    $response = [
        'success' => true,
        'comments' => $comments
    ];
    
    $stmt->close();
} catch (Exception $e) {
    $response['message'] = $e->getMessage();
}

if (isset($db)) $db->close();
echo json_encode($response);
?>
<?php
require_once 'db_connect.php';

$db = getDBConnection();

$response = ['success' => false, 'message' => ''];

try {
    if (!isset($_GET['id']) || !is_numeric($_GET['id'])) {
        throw new Exception("Invalid item ID");
    }
    
    if (!isset($_GET['type']) || !in_array($_GET['type'], ['resource', 'test', 'group', 'answer'])) {
        throw new Exception("Invalid item type");
    }
    
    $itemId = (int)$_GET['id'];
    $itemType = $_GET['type'];

    // Get item details based on type
    switch ($itemType) {
        case 'resource':
            $stmt = $db->prepare("
                SELECT id, name, description, resource_link, resource_photo_link 
                FROM resource 
                WHERE id = ?
            ");
            break;
        case 'test':
            $stmt = $db->prepare("
                SELECT id, name, description 
                FROM test 
                WHERE id = ?
            ");
            break;
        case 'group':
            $stmt = $db->prepare("
                SELECT id, name, description 
                FROM `group` 
                WHERE id = ?
            ");
            break;
        case 'answer':
            $stmt = $db->prepare("
                SELECT id, answer, answer_link 
                FROM answer 
                WHERE id = ?
            ");
            break;
        default:
            throw new Exception("Unsupported item type");
    }
    
    $stmt->bind_param("i", $itemId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        $response = ['success' => false, 'message' => 'Item not found'];
    } else {
        $itemData = $result->fetch_assoc();
        $response = [
            'success' => true,
            'item' => $itemData
        ];
    }
} catch (Exception $e) {
    $response['message'] = $e->getMessage();
}

if (isset($db)) $db->close();
echo json_encode($response);
?>
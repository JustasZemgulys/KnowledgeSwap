<?php
require_once 'db_connect.php';

$db = getDBConnection();

$response = ['success' => false, 'message' => ''];

try {
    if (!isset($_GET['resource_id']) || !is_numeric($_GET['resource_id'])) {
        throw new Exception("Invalid resource ID");
    }
    $resourceId = (int)$_GET['resource_id'];

    // Get resource details including resource_photo_link
    $stmt = $db->prepare("SELECT id, name, resource_link, resource_photo_link FROM resource WHERE id = ?");
    $stmt->bind_param("i", $resourceId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        $response = ['success' => false, 'message' => 'Resource not found'];
    } else {
        $resourceData = $result->fetch_assoc();
        $response = [
            'success' => true,
            'resource' => [
                'id' => $resourceData['id'],
                'name' => $resourceData['name'],
                'resource_link' => $resourceData['resource_link'],
                'resource_photo_link' => $resourceData['resource_photo_link'] // Added this line
            ]
        ];
    }
} catch (Exception $e) {
    $response['message'] = $e->getMessage();
}

if (isset($db)) $db->close();
echo json_encode($response);
?>
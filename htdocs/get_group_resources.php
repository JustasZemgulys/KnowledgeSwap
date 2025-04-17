<?php
require_once 'db_connect.php';

$conn = getDBConnection();

$response = ['success' => false, 'resources' => []];

try {
    $groupId = $_GET['group_id'] ?? null;
    
    if (!$groupId) {
        throw new Exception("Missing group_id parameter");
    }
    
    $stmt = $conn->prepare("
        SELECT r.* 
        FROM resource r
        JOIN group_resource gr ON r.id = gr.fk_resource
        WHERE gr.fk_group = ?
        ORDER BY r.creation_date DESC
    ");
    $stmt->bind_param("i", $groupId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $resources = [];
    while ($row = $result->fetch_assoc()) {
        $resources[] = $row;
    }
    
    $response['success'] = true;
    $response['resources'] = $resources;
    
    $stmt->close();
    $conn->close();
    
} catch (Exception $e) {
    $response['message'] = $e->getMessage();
    http_response_code(400);
}

echo json_encode($response);
?>
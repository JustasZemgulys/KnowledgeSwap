<?php
require_once 'db_connect.php';

$conn = getDBConnection();

//error_reporting(0);

$response = ['success' => false, 'message' => 'Request failed'];

try {
    // Get input data
    $input = json_decode(file_get_contents('php://input'), true);
    $resourceId = isset($input['resource_id']) ? (int)$input['resource_id'] : 0;
    
    if ($resourceId <= 0) {
        throw new Exception("Invalid resource ID");
    }

    // First get the icon path from the database
    $stmt = $conn->prepare("SELECT resource_photo_link FROM resource WHERE id = ?");
    $stmt->bind_param("i", $resourceId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        throw new Exception("Resource not found");
    }
    
    $resource = $result->fetch_assoc();
    $stmt->close();

    // Delete the icon file if it exists
    $iconDeleted = false;
    if (!empty($resource['resource_photo_link']) && file_exists($resource['resource_photo_link'])) {
        if (unlink($resource['resource_photo_link'])) {
            $iconDeleted = true;
        } else {
            throw new Exception("Failed to delete icon file");
        }
    }

    // Update the database to remove the icon reference
    $stmt = $conn->prepare("UPDATE resource SET resource_photo_link = NULL WHERE id = ?");
    $stmt->bind_param("i", $resourceId);
    
    if (!$stmt->execute()) {
        throw new Exception("Failed to update database record: " . $stmt->error);
    }
    
    $stmt->close();

    $response = [
        'success' => true,
        'message' => 'Icon deleted successfully',
        'icon_deleted' => $iconDeleted
    ];

} catch (Exception $e) {
    $response['message'] = $e->getMessage();
} finally {
    if (isset($conn)) $conn->close();
    echo json_encode($response);
}
?>
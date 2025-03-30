<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

// Enable error reporting only for development
ini_set('display_errors', 0);
error_reporting(0);

$response = ['success' => false, 'message' => 'Request failed'];

try {
    // Validate request method
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception("Only POST requests allowed");
    }

    // Database connection
    $conn = new mysqli("localhost", "root", "", "knowledgeswap");
    if ($conn->connect_error) {
        throw new Exception("DB connection failed");
    }

    // Get POST data
    $resourceId = (int)($_POST['resource_id'] ?? 0);
    if ($resourceId <= 0) throw new Exception("Invalid resource ID");

    // Get existing paths
    $stmt = $conn->prepare("SELECT resource_link, resource_photo_link FROM resource WHERE id = ?");
    $stmt->bind_param("i", $resourceId);
    $stmt->execute();
    $result = $stmt->get_result();
    if ($result->num_rows === 0) throw new Exception("Resource not found");
    $resource = $result->fetch_assoc();

    // Process file uploads
    $resourceDir = "knowledgeswap/resources/";
    $iconDir = "knowledgeswap/icons/";
    
    // Create directories if needed
    if (!file_exists($resourceDir)) mkdir($resourceDir, 0777, true);
    if (!file_exists($iconDir)) mkdir($iconDir, 0777, true);

    // Handle resource file
    $newResourcePath = $resource['resource_link'];
    if (isset($_FILES['resource_file']['error']) && $_FILES['resource_file']['error'] === UPLOAD_ERR_OK) {
        $file = $_FILES['resource_file'];
        $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
        if (!in_array($ext, ['pdf','jpg','jpeg','png'])) throw new Exception("Invalid file type");
        
        $newFilename = uniqid().'.'.$ext;
        $newPath = $resourceDir.$newFilename;
        
        if (!move_uploaded_file($file['tmp_name'], $newPath)) {
            throw new Exception("Failed to save resource");
        }
        
        // Delete old file
        if (!empty($resource['resource_link']) && file_exists($resource['resource_link'])) {
            unlink($resource['resource_link']);
        }
        
        $newResourcePath = $newPath;
    }

    // Handle icon file
    $newIconPath = $resource['resource_photo_link'];
    if (isset($_FILES['icon_file']['error']) && $_FILES['icon_file']['error'] === UPLOAD_ERR_OK) {
        $icon = $_FILES['icon_file'];
        $ext = strtolower(pathinfo($icon['name'], PATHINFO_EXTENSION));
        if (!in_array($ext, ['jpg','jpeg','png'])) throw new Exception("Invalid icon type");
        
        $newIconName = uniqid().'.'.$ext;
        $newIcon = $iconDir.$newIconName;
        
        if (!move_uploaded_file($icon['tmp_name'], $newIcon)) {
            throw new Exception("Failed to save icon");
        }
        
        // Delete old icon
        if (!empty($resource['resource_photo_link']) && file_exists($resource['resource_photo_link'])) {
            unlink($resource['resource_photo_link']);
        }
        
        $newIconPath = $newIcon;
    }

    // Update database
    $stmt = $conn->prepare("UPDATE resource SET 
        name = ?, 
        description = ?, 
        visibility = ?,
        resource_link = ?,
        resource_photo_link = ?
        WHERE id = ?");
    
    $stmt->bind_param("ssissi", 
        $_POST['name'],
        $_POST['description'],
        $_POST['visibility'],
        $newResourcePath,
        $newIconPath,
        $resourceId
    );

    if (!$stmt->execute()) {
        throw new Exception("DB update failed: ".$conn->error);
    }

    $response = [
        'success' => true,
        'message' => 'Resource updated',
        'paths' => [
            'resource' => $newResourcePath,
            'icon' => $newIconPath
        ]
    ];

} catch (Exception $e) {
    $response['message'] = $e->getMessage();
} finally {
    if (isset($conn)) $conn->close();
    echo json_encode($response);
}
?>
<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

error_reporting(0); // Turn off error reporting in production

$response = [
    'success' => false,
    'message' => '',
    'resource_path' => '',
    'icon_path' => ''
];

try {
    // Database connection
    $conn = new mysqli("localhost", "root", "", "knowledgeswap");
    if ($conn->connect_error) {
        throw new Exception("Database connection failed");
    }

    // Validate input
    $name = trim($_POST['name'] ?? '');
    $description = trim($_POST['description'] ?? '');
    $visibility = isset($_POST['visibility']) ? (int)$_POST['visibility'] : 1;
    $fk_user = isset($_POST['fk_user']) ? (int)$_POST['fk_user'] : 0;

    if (empty($name)) {
        throw new Exception("Resource name is required");
    }

    // File handling
    if (!isset($_FILES['resource_file'])) {
        throw new Exception("Resource file is required");
    }

    $resourceFile = $_FILES['resource_file'];
    $iconFile = $_FILES['icon_file'] ?? null;

    // Create directories if they don't exist
    $resourceDir = "knowledgeswap/resources/";
    $iconDir = "knowledgeswap/icons/";

    // Create resource directory if it doesn't exist
    if (!file_exists($resourceDir)) {
        if (!mkdir($resourceDir, 0777, true)) {
            throw new Exception("Failed to create resource directory");
        }
    }

    // Create icon directory if it doesn't exist
    if (!file_exists($iconDir)) {
        if (!mkdir($iconDir, 0777, true)) {
            throw new Exception("Failed to create icon directory");
        }
    }

    // Process resource file
    $resourceExt = strtolower(pathinfo($resourceFile['name'], PATHINFO_EXTENSION));
    if (!in_array($resourceExt, ['pdf', 'jpg', 'jpeg', 'png'])) {
        throw new Exception("Invalid resource file type. Only PDF, JPG, PNG allowed");
    }

    $resourceFilename = uniqid() . '_' . basename($resourceFile['name']);
    $resourcePath = $resourceDir . $resourceFilename;
    
    if (!move_uploaded_file($resourceFile['tmp_name'], $resourcePath)) {
        throw new Exception("Failed to upload resource file");
    }

    // Process icon file if provided
    $iconPath = null;
    if ($iconFile && $iconFile['error'] == UPLOAD_ERR_OK) {
        $iconExt = strtolower(pathinfo($iconFile['name'], PATHINFO_EXTENSION));
        if (!in_array($iconExt, ['jpg', 'jpeg', 'png'])) {
            unlink($resourcePath); // Clean up resource file
            throw new Exception("Invalid icon file type. Only JPG, PNG allowed");
        }

        $iconFilename = uniqid() . '_' . basename($iconFile['name']);
        $iconPath = $iconDir . $iconFilename;
        
        if (!move_uploaded_file($iconFile['tmp_name'], $iconPath)) {
            unlink($resourcePath); // Clean up resource file
            throw new Exception("Failed to upload icon file");
        }
    }

    // Insert into database
    $creation_date = date('Y-m-d H:i:s');
    $stmt = $conn->prepare("INSERT INTO resource 
                          (name, description, resource_link, creation_date, visibility, resource_photo_link, fk_user) 
                          VALUES (?, ?, ?, ?, ?, ?, ?)");
    
    $stmt->bind_param("ssssisi", $name, $description, $resourcePath, $creation_date, $visibility, $iconPath, $fk_user);
    
    if (!$stmt->execute()) {
        unlink($resourcePath);
        if ($iconPath) unlink($iconPath);
        throw new Exception("Database error: " . $stmt->error);
    }

    $response = [
        'success' => true,
        'message' => 'Resource uploaded successfully',
        'resource_path' => $resourcePath,
        'icon_path' => $iconPath
    ];

    $stmt->close();
    $conn->close();

} catch (Exception $e) {
    $response['message'] = $e->getMessage();
}

echo json_encode($response);
?>
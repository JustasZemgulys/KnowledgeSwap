<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "knowledgeswap";

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    die(json_encode(['success' => false, 'message' => "Connection failed: " . $conn->connect_error]));
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $resourceId = $_POST['resource_id'] ?? 0;
    
    if ($resourceId <= 0) {
        die(json_encode(['success' => false, 'message' => 'Invalid resource ID']));
    }

    // First get the file paths
    $query = $conn->prepare("SELECT resource_link, resource_photo_link FROM resource WHERE id = ?");
    $query->bind_param("i", $resourceId);
    $query->execute();
    $result = $query->get_result();
    
    if ($result->num_rows === 0) {
        die(json_encode(['success' => false, 'message' => 'Resource not found']));
    }
    
    $resource = $result->fetch_assoc();
    
    // Delete the database entry
    $deleteQuery = $conn->prepare("DELETE FROM resource WHERE id = ?");
    $deleteQuery->bind_param("i", $resourceId);
    
    if ($deleteQuery->execute()) {
        // Delete the files
        $deletedFiles = [];
        $basePath = __DIR__ . '/';
        
        if (!empty($resource['resource_link'])) {
            $filePath = $basePath . ltrim($resource['resource_link'], '/');
            if (file_exists($filePath)) {
                unlink($filePath);
                $deletedFiles[] = $resource['resource_link'];
            }
        }
        
        if (!empty($resource['resource_photo_link'])) {
            $iconPath = $basePath . ltrim($resource['resource_photo_link'], '/');
            if (file_exists($iconPath)) {
                unlink($iconPath);
                $deletedFiles[] = $resource['resource_photo_link'];
            }
        }
        
        echo json_encode([
            'success' => true,
            'message' => 'Resource deleted successfully',
            'deleted_files' => $deletedFiles
        ]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to delete resource']);
    }
}

$conn->close();
?>
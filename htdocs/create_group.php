<?php
require_once 'db_connect.php';

$conn = getDBConnection();

error_reporting(0);

$response = [
    'success' => false,
    'message' => '',
    'icon_path' => ''
];

try {
    // Validate input
    $name = trim($_POST['name'] ?? '');
    $description = trim($_POST['description'] ?? '');
    $visibility = isset($_POST['visibility']) ? (int)$_POST['visibility'] : 1;
    $fk_user = $_POST['fk_user'];

    if (empty($name)) {
        throw new Exception("Group name is required");
    }

    // Process icon file if provided
    $iconPath = null;
    if (isset($_FILES['icon_file']) && $_FILES['icon_file']['error'] == UPLOAD_ERR_OK) {
        $iconFile = $_FILES['icon_file'];
        $iconExt = strtolower(pathinfo($iconFile['name'], PATHINFO_EXTENSION));
        if (!in_array($iconExt, ['jpg', 'jpeg', 'png'])) {
            throw new Exception("Invalid icon file type. Only JPG, PNG allowed");
        }

        $iconDir = "knowledgeswap/group_icons/";
        if (!file_exists($iconDir)) {
            if (!mkdir($iconDir, 0777, true)) {
                throw new Exception("Failed to create icon directory");
            }
        }

        $iconFilename = uniqid() . '_' . basename($iconFile['name']);
        $iconPath = $iconDir . $iconFilename;
        
        if (!move_uploaded_file($iconFile['tmp_name'], $iconPath)) {
            throw new Exception("Failed to upload icon file");
        }
    }

    // Insert into database
    $creation_date = date('Y-m-d H:i:s');
    $conn->begin_transaction();

    try {
        // Insert group
        $stmt = $conn->prepare("INSERT INTO `group` 
                              (name, description, creation_date, visibility, icon_path, score) 
                              VALUES (?, ?, ?, ?, ?, 0)");
        
        $stmt->bind_param("sssis", $name, $description, $creation_date, $visibility, $iconPath);
        
        if (!$stmt->execute()) {
            throw new Exception("Failed to create group: " . $stmt->error);
        }

        $group_id = $stmt->insert_id;
        $stmt->close();

        // Add creator as admin member
        $stmt = $conn->prepare("INSERT INTO group_member
                              (fk_user, fk_group, role) 
                              VALUES (?, ?, 'admin')");
        $stmt->bind_param("ii", $fk_user, $group_id);
        
        if (!$stmt->execute()) {
            throw new Exception("Failed to add creator to group: " . $stmt->error);
        }

        $conn->commit();

        $response = [
            'success' => true,
            'message' => 'Group created successfully',
            'icon_path' => $iconPath,
            'group_id' => $group_id
        ];

    } catch (Exception $e) {
        $conn->rollback();
        if ($iconPath && file_exists($iconPath)) {
            unlink($iconPath);
        }
        throw $e;
    }

    $conn->close();

} catch (Exception $e) {
    $response['message'] = $e->getMessage();
}

echo json_encode($response);
?>
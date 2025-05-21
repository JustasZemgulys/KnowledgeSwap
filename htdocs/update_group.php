<?php
require_once 'db_connect.php';

$conn = getDBConnection();

error_reporting(0);

$response = ['success' => false, 'message' => 'Request failed'];

try {
    $groupId = (int)($_POST['group_id'] ?? 0);
    if ($groupId <= 0) throw new Exception("Invalid group ID");
    
    // Properly handle remove_icon flag (can come as string '1' or true)
    $remove_icon = isset($_POST['remove_icon']) && 
                  ($_POST['remove_icon'] === '1' || $_POST['remove_icon'] === true);

    // Get existing icon path
    $stmt = $conn->prepare("SELECT icon_path FROM `group` WHERE id = ?");
    $stmt->bind_param("i", $groupId);
    $stmt->execute();
    $result = $stmt->get_result();
    if ($result->num_rows === 0) throw new Exception("Group not found");
    $group = $result->fetch_assoc();
    $stmt->close();

    // Process icon upload
    $newIconPath = $group['icon_path'];
    
    if ($remove_icon) {
        // Delete old icon if exists
        if (!empty($group['icon_path']) && file_exists($group['icon_path'])) {
            unlink($group['icon_path']);
        }
        $newIconPath = null;
    } 
    elseif (isset($_FILES['icon_file']['error']) && $_FILES['icon_file']['error'] === UPLOAD_ERR_OK) {
        $icon = $_FILES['icon_file'];
        $ext = strtolower(pathinfo($icon['name'], PATHINFO_EXTENSION));
        if (!in_array($ext, ['jpg','jpeg','png'])) throw new Exception("Invalid icon type");
        
        $iconDir = "knowledgeswap/group_icons/";
        if (!file_exists($iconDir)) {
            mkdir($iconDir, 0777, true);
        }

        $newIconName = uniqid().'.'.$ext;
        $newIcon = $iconDir.$newIconName;
        
        if (!move_uploaded_file($icon['tmp_name'], $newIcon)) {
            throw new Exception("Failed to save icon");
        }
        
        // Delete old icon if exists
        if (!empty($group['icon_path']) && file_exists($group['icon_path'])) {
            unlink($group['icon_path']);
        }
        
        $newIconPath = $newIcon;
    }

    // Update database - always include icon_path in the query
    $stmt = $conn->prepare("UPDATE `group` SET 
        name = ?, 
        description = ?, 
        visibility = ?,
        icon_path = ?
        WHERE id = ?");
    
    $stmt->bind_param("ssisi", 
        $_POST['name'],
        $_POST['description'],
        $_POST['visibility'],
        $newIconPath, // Will be NULL if removed
        $groupId
    );

    if (!$stmt->execute()) {
        throw new Exception("DB update failed: ".$conn->error);
    }

    $response = [
        'success' => true,
        'message' => 'Group updated successfully',
        'icon_path' => $newIconPath
    ];

} catch (Exception $e) {
    $response['message'] = $e->getMessage();
} finally {
    if (isset($conn)) $conn->close();
    echo json_encode($response);
}
?>
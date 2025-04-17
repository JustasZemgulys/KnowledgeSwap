<?php
require_once 'db_connect.php';

$conn = getDBConnection();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $groupId = $_POST['group_id'] ?? 0;
    
    if ($groupId <= 0) {
        die(json_encode(['success' => false, 'message' => 'Invalid group ID']));
    }

    // First get the group details including icon path
    $query = $conn->prepare("SELECT icon_path FROM `group` WHERE id = ?");
    $query->bind_param("i", $groupId);
    $query->execute();
    $result = $query->get_result();
    
    if ($result->num_rows === 0) {
        die(json_encode(['success' => false, 'message' => 'Group not found']));
    }
    
    $group = $result->fetch_assoc();
    
    // Start transaction
    $conn->begin_transaction();
    
    try {
        // First delete all members from the group
        $deleteMembers = $conn->prepare("DELETE FROM group_member WHERE fk_group = ?");
        $deleteMembers->bind_param("i", $groupId);
        $deleteMembers->execute();
        $deleteMembers->close();
        
        // Then delete the group itself
        $deleteGroup = $conn->prepare("DELETE FROM `group` WHERE id = ?");
        $deleteGroup->bind_param("i", $groupId);
        $deleteGroup->execute();
        $deleteGroup->close();
        
        // Delete the icon file if it exists
        $deletedFiles = [];
        if (!empty($group['icon_path'])) {
            $basePath = __DIR__ . '/';
            $iconPath = $basePath . ltrim($group['icon_path'], '/');
            if (file_exists($iconPath)) {
                unlink($iconPath);
                $deletedFiles[] = $group['icon_path'];
            }
        }
        
        // Commit transaction
        $conn->commit();
        
        echo json_encode([
            'success' => true,
            'message' => 'Group deleted successfully',
            'deleted_files' => $deletedFiles
        ]);
    } catch (Exception $e) {
        // Rollback transaction on error
        $conn->rollback();
        echo json_encode([
            'success' => false,
            'message' => 'Failed to delete group: ' . $e->getMessage()
        ]);
    }
}

$conn->close();
?>
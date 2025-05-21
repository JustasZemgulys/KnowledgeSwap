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
        // 1. Delete all test assignment users (results)
        $deleteAssignmentUsers = $conn->prepare("
            DELETE tau FROM test_assignment_user tau
            JOIN test_assignment ta ON tau.fk_assignment = ta.id
            WHERE ta.fk_group = ?
        ");
        $deleteAssignmentUsers->bind_param("i", $groupId);
        $deleteAssignmentUsers->execute();
        $deleteAssignmentUsers->close();

        // 2. Delete all test assignments
        $deleteAssignments = $conn->prepare("DELETE FROM test_assignment WHERE fk_group = ?");
        $deleteAssignments->bind_param("i", $groupId);
        $deleteAssignments->execute();
        $deleteAssignments->close();

        // 3. Delete all group resources (just the associations, not the actual resources)
        $deleteGroupResources = $conn->prepare("DELETE FROM group_resource WHERE fk_group = ?");
        $deleteGroupResources->bind_param("i", $groupId);
        $deleteGroupResources->execute();
        $deleteGroupResources->close();

        // 4. Delete all group tests (just the associations, not the actual tests)
        $deleteGroupTests = $conn->prepare("DELETE FROM group_test WHERE fk_group = ?");
        $deleteGroupTests->bind_param("i", $groupId);
        $deleteGroupTests->execute();
        $deleteGroupTests->close();

        // 5. Delete all group members
        $deleteMembers = $conn->prepare("DELETE FROM group_member WHERE fk_group = ?");
        $deleteMembers->bind_param("i", $groupId);
        $deleteMembers->execute();
        $deleteMembers->close();

        // 6. Delete any forum items associated with this group
        $deleteForumItems = $conn->prepare("DELETE FROM forum_item WHERE fk_group = ?");
        $deleteForumItems->bind_param("i", $groupId);
        $deleteForumItems->execute();
        $deleteForumItems->close();

        // 7. Finally delete the group itself
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
            'message' => 'Group and all related data deleted successfully',
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
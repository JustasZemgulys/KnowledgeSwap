<?php
require_once 'db_connect.php';

$conn = getDBConnection();

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
    
    // Begin transaction
    $conn->begin_transaction();
    
    try {
        // 1. First remove all group resource references
        $deleteGroupRefs = $conn->prepare("DELETE FROM group_resource WHERE fk_resource = ?");
        $deleteGroupRefs->bind_param("i", $resourceId);
        $deleteGroupRefs->execute();
        $groupRefsDeleted = $deleteGroupRefs->affected_rows;
        $deleteGroupRefs->close();

        // 2. Remove resource reference from test assignments
        $updateAssignments = $conn->prepare("UPDATE test_assignment SET fk_resource = NULL WHERE fk_resource = ?");
        $updateAssignments->bind_param("i", $resourceId);
        $updateAssignments->execute();
        $assignmentsUpdated = $updateAssignments->affected_rows;
        $updateAssignments->close();

        // 3. Remove resource reference from any tests
        $updateTests = $conn->prepare("UPDATE test SET fk_resource = NULL WHERE fk_resource = ?");
        $updateTests->bind_param("i", $resourceId);
        $updateTests->execute();
        $testsUpdated = $updateTests->affected_rows;
        $updateTests->close();
        
        // 4. Now safe to delete the main resource entry
        $deleteQuery = $conn->prepare("DELETE FROM resource WHERE id = ?");
        $deleteQuery->bind_param("i", $resourceId);
        $deleteQuery->execute();
        $resourceDeleted = $deleteQuery->affected_rows;
        $deleteQuery->close();
        
        // Commit the transaction if all operations succeeded
        $conn->commit();
        
        // Delete the files only after successful DB operations
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
            'message' => 'Resource deletion completed',
            'details' => [
                'group_references_removed' => $groupRefsDeleted,
                'test_assignments_updated' => $assignmentsUpdated,
                'tests_updated' => $testsUpdated,
                'resource_deleted' => $resourceDeleted,
                'files_deleted' => count($deletedFiles)
            ]
        ]);
        
    } catch (Exception $e) {
        // Roll back if any error occurred
        $conn->rollback();
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to delete resource: ' . $e->getMessage(),
            'error_details' => $conn->error
        ]);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}

$conn->close();
?>
<?php
require_once 'db_connect.php';

$conn = getDBConnection();

try {
    $page = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
    $perPage = isset($_GET['per_page']) ? max(1, (int)$_GET['per_page']) : 6;
    $sort = in_array(strtoupper($_GET['sort'] ?? ''), ['ASC', 'DESC']) ? $_GET['sort'] : 'DESC';
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : null;

    // Count total visible resources
    $totalQuery = "SELECT COUNT(*) as total FROM resource 
                  WHERE visibility = 1 OR (visibility = 0 AND fk_user = ?)";
    $totalStmt = $conn->prepare($totalQuery);
    if (!$totalStmt) throw new Exception("Count prepare failed: " . $conn->error);
    $totalStmt->bind_param("i", $userId);
    $totalStmt->execute();
    $totalResult = $totalStmt->get_result();
    $total = (int)$totalResult->fetch_assoc()['total'];
    $totalStmt->close();

    // Get resources with pagination and voting info
    $resourcesQuery = "
        SELECT
            r.id,
            r.name,
            r.description,
            r.creation_date,
            r.resource_photo_link,
            r.resource_link,
            r.visibility,
            r.fk_user,
            r.score,
            v.direction as user_vote
        FROM resource r
        LEFT JOIN vote v ON v.fk_item = r.id AND v.fk_type = 'resource' AND v.fk_user = ?
        WHERE r.visibility = 1 OR (r.visibility = 0 AND r.fk_user = ?)
        ORDER BY r.creation_date $sort
        LIMIT ?, ?
    ";
    
    $stmt = $conn->prepare($resourcesQuery);
    if (!$stmt) throw new Exception("Prepare failed: " . $conn->error);
    
    $offset = ($page - 1) * $perPage;
    $stmt->bind_param("iiii", $userId, $userId, $offset, $perPage);
    $stmt->execute();
    $result = $stmt->get_result();

    $resources = [];
    while ($row = $result->fetch_assoc()) {
        if (!empty($row['resource_photo_link'])) {
            $filename = basename($row['resource_photo_link']);
            $iconDir = $_SERVER['DOCUMENT_ROOT'] . '/knowledgeswap/icons/';

            $found = null;
            foreach (glob($iconDir . '*', GLOB_NOSORT) as $file) {
                if (strtolower(basename($file)) === strtolower($filename)) {
                    $found = basename($file);
                    break;
                }
            }

            $row['resource_photo_link'] = $found
                ? 'knowledgeswap/icons/' . $found
                : null;
        }
        $resources[] = $row;
    }

    $stmt->close();
    $conn->close();

    echo json_encode([
        'success' => true,
        'resources' => $resources,
        'total' => $total
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage(),
        'stack' => $e->getTraceAsString()
    ]);
}
?>
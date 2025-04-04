<?php
// Enable detailed error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "knowledgeswap";

try {
    // Get and validate parameters
    $query = isset($_GET['query']) ? trim($_GET['query']) : '';
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
    $page = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
    $perPage = isset($_GET['per_page']) ? max(1, (int)$_GET['per_page']) : 10;
    $sort = isset($_GET['sort']) && $_GET['sort'] === 'asc' ? 'ASC' : 'DESC';
    $type = isset($_GET['type']) ? $_GET['type'] : 'all';
    $offset = ($page - 1) * $perPage;

    // Create connection
    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) {
        throw new Exception("Connection failed: " . $conn->connect_error);
    }

    // Base query for resources - select specific fields with visibility check
    $resourceSql = "SELECT 
                r.id, 
                r.name, 
                r.creation_date,
                r.fk_user,
                r.visibility,
                r.resource_link,
                r.resource_photo_link,
                r.score,
                v.direction as user_vote,
                'resource' as type,
                u.name as creator_name
            FROM resource r
            LEFT JOIN user u ON r.fk_user = u.id
            LEFT JOIN vote v ON v.fk_item = r.id AND v.fk_type = 'resource' AND v.fk_user = ?
            WHERE r.name LIKE ? 
            AND (r.visibility = 1 OR r.fk_user = ?)";
    
    // Base query for tests - select specific fields with visibility check
    $testSql = "SELECT 
                t.id, 
                t.name, 
                t.creation_date,
                t.fk_user,
                t.visibility,
                t.fk_resource,
                t.score,
                v.direction as user_vote,
                'test' as type,
                u.name as creator_name
            FROM test t
            LEFT JOIN user u ON t.fk_user = u.id
            LEFT JOIN vote v ON v.fk_item = t.id AND v.fk_type = 'test' AND v.fk_user = ?
            WHERE t.name LIKE ?
            AND (t.visibility = 1 OR t.fk_user = ?)";
    
    // Count total results with visibility check
    $countSql = "";
    $searchParam = "%$query%";
    
    if ($type === 'all') {
        $countSql = "SELECT SUM(total) as total FROM (
                    (SELECT COUNT(*) as total FROM resource WHERE name LIKE ? AND (visibility = 1 OR fk_user = ?)) 
                    UNION ALL 
                    (SELECT COUNT(*) as total FROM test WHERE name LIKE ? AND (visibility = 1 OR fk_user = ?))
                 ) as count_table";
        $stmt = $conn->prepare($countSql);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        $stmt->bind_param("sisi", $searchParam, $userId, $searchParam, $userId);
    } 
    elseif ($type === 'resource') {
        $countSql = "SELECT COUNT(*) FROM resource WHERE name LIKE ? AND (visibility = 1 OR fk_user = ?)";
        $stmt = $conn->prepare($countSql);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        $stmt->bind_param("si", $searchParam, $userId);
    }
    elseif ($type === 'test') {
        $countSql = "SELECT COUNT(*) FROM test WHERE name LIKE ? AND (visibility = 1 OR fk_user = ?)";
        $stmt = $conn->prepare($countSql);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        $stmt->bind_param("si", $searchParam, $userId);
    }
    
    if (!$stmt->execute()) {
        throw new Exception("Execute failed: " . $stmt->error);
    }
    $total = $stmt->get_result()->fetch_array()[0];
    $stmt->close();

    // Get paginated results with visibility check
    $results = array();
    
    if ($type === 'all' || $type === 'resource') {
        $stmt = $conn->prepare("$resourceSql ORDER BY creation_date $sort LIMIT ?, ?");
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        $stmt->bind_param("isiii", $userId, $searchParam, $userId, $offset, $perPage);
        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        $resourceResults = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
        $results = array_merge($results, $resourceResults);
        $stmt->close();
    }
    
    if ($type === 'all' || $type === 'test') {
        $stmt = $conn->prepare("$testSql ORDER BY creation_date $sort LIMIT ?, ?");
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        $stmt->bind_param("isiii", $userId, $searchParam, $userId, $offset, $perPage);
        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }
        $testResults = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
        $results = array_merge($results, $testResults);
        $stmt->close();
    }

    // Sort combined results if showing all types
    if ($type === 'all') {
        usort($results, function($a, $b) use ($sort) {
            return $sort === 'ASC' 
                ? strtotime($a['creation_date']) - strtotime($b['creation_date'])
                : strtotime($b['creation_date']) - strtotime($a['creation_date']);
        });
        
        // Apply pagination to combined results
        $results = array_slice($results, $offset, $perPage);
    }

    $conn->close();

    echo json_encode([
        'success' => true,
        'results' => $results,
        'total' => $total
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage(),
        'trace' => $e->getTraceAsString(),
        'error' => isset($conn) ? $conn->error : null,
        'query' => isset($stmt) ? $stmt->error : null
    ]);
}
?>
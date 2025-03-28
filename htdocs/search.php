<?php
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

    // Base query for resources
    $resourceSql = "SELECT 
                r.id, 
                r.name, 
                r.creation_date,
                'resource' as type,
                u.name as creator_name
            FROM resource r
            LEFT JOIN user u ON r.fk_user = u.id
            WHERE r.name LIKE ?";
    
    // Base query for tests
    $testSql = "SELECT 
                t.id, 
                t.name, 
                t.creation_date,
                'test' as type,
                u.name as creator_name
            FROM test t
            LEFT JOIN user u ON t.fk_user = u.id
            WHERE t.name LIKE ?";
    
    // Count total results
    $countSql = "";
    $searchParam = "%$query%";
    
    if ($type === 'all') {
        $countSql = "SELECT SUM(total) as total FROM (
                    (SELECT COUNT(*) as total FROM resource WHERE name LIKE ?) 
                    UNION ALL 
                    (SELECT COUNT(*) as total FROM test WHERE name LIKE ?)
                 ) as count_table";
        $stmt = $conn->prepare($countSql);
        $stmt->bind_param("ss", $searchParam, $searchParam);
    } 
    elseif ($type === 'resource') {
        $countSql = "SELECT COUNT(*) FROM resource WHERE name LIKE ?";
        $stmt = $conn->prepare($countSql);
        $stmt->bind_param("s", $searchParam);
    }
    elseif ($type === 'test') {
        $countSql = "SELECT COUNT(*) FROM test WHERE name LIKE ?";
        $stmt = $conn->prepare($countSql);
        $stmt->bind_param("s", $searchParam);
    }
    
    $stmt->execute();
    $total = $stmt->get_result()->fetch_array()[0];
    $stmt->close();

    // Get paginated results
    $results = array();
    
    if ($type === 'all' || $type === 'resource') {
        $stmt = $conn->prepare("$resourceSql ORDER BY creation_date $sort LIMIT ?, ?");
        $stmt->bind_param("sii", $searchParam, $offset, $perPage);
        $stmt->execute();
        $resourceResults = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
        $results = array_merge($results, $resourceResults);
        $stmt->close();
    }
    
    if ($type === 'all' || $type === 'test') {
        $stmt = $conn->prepare("$testSql ORDER BY creation_date $sort LIMIT ?, ?");
        $stmt->bind_param("sii", $searchParam, $offset, $perPage);
        $stmt->execute();
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
        'trace' => $e->getTraceAsString()
    ]);
}
?>
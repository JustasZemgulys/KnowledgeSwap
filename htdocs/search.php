<?php
// Enable all error reporting and logging
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/search_errors.log');

// Initialize logging function
function log_message($message) {
    $timestamp = date('Y-m-d H:i:s');
    $logEntry = "[$timestamp] $message\n";
    file_put_contents(__DIR__ . '/search_debug.log', $logEntry, FILE_APPEND);
}

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

// Start logging
log_message("Script started");

$response = [
    'success' => false,
    'message' => 'Initial state',
    'results' => [],
    'total' => 0
];

try {
    log_message("Entering try block");
    
    $servername = "localhost";
    $username = "root";
    $password = "";
    $dbname = "knowledgeswap";
    
    log_message("Attempting database connection");
    $conn = new mysqli($servername, $username, $password, $dbname);
    
    if ($conn->connect_error) {
        throw new Exception("Database connection failed: " . $conn->connect_error);
    }
    log_message("Database connected successfully");

    // Validate and sanitize inputs
    $query = isset($_GET['query']) ? trim($conn->real_escape_string($_GET['query'])) : '';
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
    $page = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
    $perPage = isset($_GET['per_page']) ? max(1, (int)$_GET['per_page']) : 10;
    $sort = isset($_GET['sort']) && $_GET['sort'] === 'asc' ? 'ASC' : 'DESC';
    $type = isset($_GET['type']) ? $conn->real_escape_string($_GET['type']) : 'all';
    $offset = ($page - 1) * $perPage;
    $searchParam = "%$query%";

    log_message("Parameters received - Query: $query, UserID: $userId, Page: $page, Type: $type");

    if ($userId <= 0) {
        throw new Exception("Invalid user_id: $userId");
    }

    // Base queries with improved structure
    $queries = [
        'resource' => [
            'sql' => "SELECT r.*, u.name as creator_name, v.direction as user_vote, 'resource' as type
                     FROM resource r
                     LEFT JOIN user u ON r.fk_user = u.id
                     LEFT JOIN vote v ON v.fk_item = r.id AND v.fk_type = 'resource' AND v.fk_user = ?
                     WHERE r.name LIKE ? AND (r.visibility = 1 OR r.fk_user = ?)",
            'params' => ['i', 's', 'i']
        ],
        'test' => [
            'sql' => "SELECT t.*, u.name as creator_name, v.direction as user_vote, 'test' as type
                     FROM test t
                     LEFT JOIN user u ON t.fk_user = u.id
                     LEFT JOIN vote v ON v.fk_item = t.id AND v.fk_type = 'test' AND v.fk_user = ?
                     WHERE t.name LIKE ? AND (t.visibility = 1 OR t.fk_user = ?)",
            'params' => ['i', 's', 'i']
        ],
        'group' => [
			'sql' => "SELECT g.*, 
					 (SELECT name FROM user WHERE id = (
						 SELECT fk_user FROM group_member 
						 WHERE fk_group = g.id AND role = 'admin' 
						 LIMIT 1
					 )) as creator_name,
					 v.direction as user_vote, 
					 'group' as type,
					 (SELECT COUNT(*) FROM group_member WHERE fk_group = g.id) as member_count,
					 EXISTS(SELECT 1 FROM group_member WHERE fk_group = g.id AND fk_user = ?) as is_member,
					 EXISTS(SELECT 1 FROM group_member WHERE fk_group = g.id AND fk_user = ? AND role = 'admin') as is_owner
					 FROM `group` g
					 LEFT JOIN vote v ON v.fk_item = g.id AND v.fk_type = 'group' AND v.fk_user = ?
					 WHERE g.name LIKE ? 
					 AND (g.visibility = 1 OR EXISTS(
						 SELECT 1 FROM group_member 
						 WHERE fk_group = g.id AND fk_user = ?
					 ))",
			'params' => ['i', 'i', 'i', 's', 'i']
		]
    ];

    // Count queries
// Count queries - completely rewritten for MariaDB compatibility
$countQueries = [
    'all' => [
        'sql' => "SELECT 
                    (SELECT IFNULL(COUNT(*), 0) FROM resource WHERE name LIKE ? AND (visibility = 1 OR fk_user = ?)) +
                    (SELECT IFNULL(COUNT(*), 0) FROM test WHERE name LIKE ? AND (visibility = 1 OR fk_user = ?)) +
                    (SELECT IFNULL(COUNT(*), 0) FROM `group` WHERE name LIKE ? AND 
                     (visibility = 1 OR EXISTS(
                         SELECT 1 FROM group_member 
                         WHERE fk_group = `group`.id AND fk_user = ?
                     )))
                  AS total",
        'params' => ['s', 'i', 's', 'i', 's', 'i']
    ],
    'resource' => [
        'sql' => "SELECT COUNT(*) AS total 
                  FROM resource 
                  WHERE name LIKE ? 
                  AND (visibility = 1 OR fk_user = ?)",
        'params' => ['s', 'i']
    ],
    'test' => [
        'sql' => "SELECT COUNT(*) AS total 
                  FROM test 
                  WHERE name LIKE ? 
                  AND (visibility = 1 OR fk_user = ?)",
        'params' => ['s', 'i']
    ],
    'group' => [
        'sql' => "SELECT COUNT(*) AS total 
                  FROM `group` 
                  WHERE name LIKE ? 
                  AND (visibility = 1 OR EXISTS(
                      SELECT 1 FROM group_member 
                      WHERE fk_group = `group`.id AND fk_user = ?
                  ))",
        'params' => ['s', 'i']
    ]
];

    // Execute count query
    log_message("Preparing count query for type: $type");
    $countType = ($type === 'all') ? 'all' : $type;
    $countData = $countQueries[$countType];
    $countStmt = $conn->prepare($countData['sql']);
    
    if (!$countStmt) {
        throw new Exception("Count prepare failed: " . $conn->error);
    }

    // Dynamic parameter binding for count
    $countParams = [$searchParam, $userId];
    if ($countType === 'all') {
        $countParams = array_merge($countParams, [$searchParam, $userId, $searchParam, $userId]);
    }
    
    $countStmt->bind_param(implode('', $countData['params']), ...$countParams);
    
    if (!$countStmt->execute()) {
        throw new Exception("Count execute failed: " . $countStmt->error);
    }
    
    $total = (int)($countStmt->get_result()->fetch_assoc()['total_count'] ?? 0);
    $countStmt->close();
    log_message("Count query completed. Total: $total");

    // Get results
    $results = [];
    $typesToSearch = ($type === 'all') ? ['resource', 'test', 'group'] : [$type];
    
    foreach ($typesToSearch as $searchType) {
        log_message("Processing search type: $searchType");
        $data = $queries[$searchType];
        
        $sql = $data['sql'] . " ORDER BY creation_date $sort LIMIT ? OFFSET ?";
        $params = $data['params'];
        $params[] = 'i'; // For LIMIT
        $params[] = 'i'; // For OFFSET
        
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            throw new Exception("$searchType prepare failed: " . $conn->error);
        }
        
        // Build parameters dynamically
        $bindParams = [$userId, $searchParam, $userId];
        if ($searchType === 'group') {
            $bindParams = [$userId, $userId, $userId, $searchParam, $userId];
        }
        $bindParams[] = $perPage;
        $bindParams[] = $offset;
        
        $stmt->bind_param(implode('', $params), ...$bindParams);
        
        if (!$stmt->execute()) {
            throw new Exception("$searchType execute failed: " . $stmt->error);
        }
        
        $typeResults = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
        
        // Process group-specific fields
        if ($searchType === 'group') {
            foreach ($typeResults as &$group) {
                if (!empty($group['icon_path'])) {
                    $group['icon_path'] = str_replace('\\', '/', $group['icon_path']);
                }
                $group['is_member'] = (bool)$group['is_member'];
                $group['is_owner'] = (bool)$group['is_owner'];
            }
        }
        
        $results = array_merge($results, $typeResults);
        $stmt->close();
        log_message("Retrieved " . count($typeResults) . " $searchType results");
    }

    // Sort combined results if showing all types
    if ($type === 'all') {
        usort($results, function($a, $b) use ($sort) {
            return $sort === 'ASC' 
                ? strtotime($a['creation_date']) - strtotime($b['creation_date'])
                : strtotime($b['creation_date']) - strtotime($a['creation_date']);
        });
        $results = array_slice($results, $offset, $perPage);
    }

    $response = [
        'success' => true,
        'results' => $results,
        'total' => $total
    ];
    log_message("Search completed successfully");

} catch (Exception $e) {
    http_response_code(500);
    $errorMsg = "Error: " . $e->getMessage();
    $response = [
        'success' => false,
        'message' => $errorMsg,
        'error' => $conn->error ?? null,
        'trace' => $e->getTraceAsString()
    ];
    log_message($errorMsg . "\nTrace: " . $e->getTraceAsString());
} finally {
    header('Content-Type: application/json');
    echo json_encode($response);
    log_message("Script completed. Response: " . json_encode($response));
    if (isset($conn)) $conn->close();
    exit;
}
?>
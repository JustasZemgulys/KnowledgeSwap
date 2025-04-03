<?php
// Turn off all error reporting to prevent HTML output
error_reporting(0);
ini_set('display_errors', 0);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

$response = ['success' => false, 'message' => ''];

try {
    // Validate user_id first
    if (!isset($_GET['user_id']) || !is_numeric($_GET['user_id'])) {
        throw new Exception("Invalid user ID");
    }
    $userId = (int)$_GET['user_id'];
    
    $servername = "localhost";
    $username = "root";
    $password = "";
    $dbname = "knowledgeswap";

    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) {
        throw new Exception("Database connection failed");
    }

    $testQuery = "
        SELECT 
            t.id,
            t.name,
            t.description,
            t.creation_date,
            t.visibility,
            t.fk_resource,
            t.fk_user,
			t.ai_made,
            COUNT(q.id) as question_count
        FROM test t
        LEFT JOIN question q ON q.fk_test = t.id
        WHERE (t.visibility = 1 OR t.fk_user = ?)
        GROUP BY t.id
        ORDER BY t.creation_date DESC
    ";

    $stmt = $conn->prepare($testQuery);
    if (!$stmt) {
        throw new Exception("Database query preparation failed");
    }
    
    $stmt->bind_param("i", $userId);
    if (!$stmt->execute()) {
        throw new Exception("Query execution failed");
    }

    $result = $stmt->get_result();
    $tests = [];

    while ($row = $result->fetch_assoc()) {
        $tests[] = [
            'id' => (int)$row['id'],
            'name' => $row['name'],
            'description' => $row['description'],
            'creation_date' => $row['creation_date'],
            'has_resource' => !empty($row['fk_resource']),
			'fk_resource' => $row['fk_resource'],
            'question_count' => (int)$row['question_count'],
            'is_owner' => ($row['fk_user'] == $userId),
			'ai_made' => (bool)$row['ai_made'],
			'fk_user' => $row['fk_user'],
            'visibility' => (bool)$row['visibility']
        ];
    }

    $response = [
        'success' => true,
        'tests' => $tests
    ];

    $stmt->close();
    $conn->close();

} catch (Exception $e) {
    http_response_code(500);
    $response = [
        'success' => false,
        'message' => $e->getMessage()
    ];
}

// Ensure only JSON is output
echo json_encode($response);
exit;
?>
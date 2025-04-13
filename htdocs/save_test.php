<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

// Database connection
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "knowledgeswap";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die(json_encode(['success' => false, 'message' => "Connection failed: " . $conn->connect_error]));
}

// Get raw POST data
$json = file_get_contents('php://input');
$data = json_decode($json, true);

// Verify JSON decoding
if (json_last_error() !== JSON_ERROR_NONE) {
    die(json_encode([
        'success' => false, 
        'message' => 'JSON decode error: ' . json_last_error_msg(),
        'received_data' => $json
    ]));
}

// Validate required fields
if (empty($data['name']) || empty($data['questions']) || empty($data['userId'])) {
    die(json_encode([
        'success' => false, 
        'message' => 'Missing required fields',
        'received_data' => $data
    ]));
}

// Start transaction
$conn->begin_transaction();

try {
    // Insert test
    $resourceId = isset($data['fk_resource']) ? $data['fk_resource'] : null;
    $visibility = isset($data['visibility']) ? (int)$data['visibility'] : 1;
    
    $stmt = $conn->prepare("INSERT INTO test 
        (name, description, creation_date, visibility, fk_user, fk_resource) 
        VALUES (?, ?, NOW(), ?, ?, ?)");
    $stmt->bind_param("ssiii", 
        $data['name'], 
        $data['description'], 
        $visibility,
        $data['userId'],
        $resourceId);
    
    if (!$stmt->execute()) {
        throw new Exception("Test insert failed: " . $conn->error);
    }
    
    $testId = $conn->insert_id;
    $stmt->close();
    
    // Insert questions
    foreach ($data['questions'] as $question) {
        if (empty($question['title']) || empty($question['answer'])) {
            continue;
        }

        $aiMade = $question['ai_made'] ?? 0; // Convert to variable first
        
        $stmt = $conn->prepare("INSERT INTO question 
            (name, description, answer, `index`, fk_test, fk_user, creation_date, ai_made) 
            VALUES (?, ?, ?, ?, ?, ?, NOW(), ?)");
        $stmt->bind_param("sssiiii", 
            $question['title'],
            $question['description'],
            $question['answer'],
            $question['index'],
            $testId,
            $data['userId'],
            $aiMade);
            
        if (!$stmt->execute()) {
            throw new Exception("Question insert failed: " . $conn->error);
        }
        $stmt->close();
    }

    $conn->commit();
    echo json_encode(['success' => true, 'message' => 'Test saved successfully', 'testId' => $testId]);
} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
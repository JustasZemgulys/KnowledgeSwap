<?php
require_once 'db_connect.php';

// Set header first to ensure proper content type
header('Content-Type: application/json');

$conn = getDBConnection();

// Get raw POST data
$json = file_get_contents('php://input');
$data = json_decode($json, true);

// Initialize response array
$response = [
    'success' => false,
    'message' => '',
    'testId' => null
];

try {
    // Validate JSON decoding
    if (json_last_error() !== JSON_ERROR_NONE) {
        throw new Exception('Invalid JSON data received');
    }

    // Validate required fields
    if (empty($data['name']) || empty($data['questions']) || empty($data['userId'])) {
        throw new Exception('Missing required fields');
    }

    // Start transaction
    $conn->begin_transaction();

    // Prepare resource ID - handle NULL case properly
    $resourceId = !empty($data['fk_resource']) ? (int)$data['fk_resource'] : null;
    $visibility = isset($data['visibility']) ? (int)$data['visibility'] : 1;
    
    // Insert test
    $stmt = $conn->prepare("INSERT INTO test 
        (name, description, creation_date, visibility, fk_user, fk_resource) 
        VALUES (?, ?, NOW(), ?, ?, ?)");
    
    if ($resourceId === null) {
        $stmt->bind_param("ssiii", 
            $data['name'], 
            $data['description'], 
            $visibility,
            $data['userId'],
            $resourceId);
    } else {
        $stmt->bind_param("ssiii", 
            $data['name'], 
            $data['description'], 
            $visibility,
            $data['userId'],
            $resourceId);
    }
    
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

        $aiMade = isset($question['ai_made']) ? (int)$question['ai_made'] : 0;
        
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
    
    $response['success'] = true;
    $response['message'] = 'Test saved successfully';
    $response['testId'] = $testId;
    
} catch (Exception $e) {
    if (isset($conn) && $conn->in_transaction) {
        $conn->rollback();
    }
    $response['message'] = $e->getMessage();
    http_response_code(400); // Bad request
}

// Ensure no output before this
echo json_encode($response);

if (isset($conn)) {
    $conn->close();
}
exit;
?>
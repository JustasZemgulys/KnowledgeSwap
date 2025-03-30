<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

// Database connection details
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

// Handle POST request
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get data from the request
    $data = json_decode(file_get_contents('php://input'), true);

    if (json_last_error() !== JSON_ERROR_NONE) {
        die(json_encode(['success' => false, 'message' => 'Invalid JSON data']));
    }

    // Log received data
    error_log("Received data: " . print_r($data, true));

    $name = $data['name'] ?? '';
    $description = $data['description'] ?? '';
    $questions = $data['questions'] ?? [];
    $userId = $data['userId'] ?? 0;

    // Validate required fields
    if (empty($name) || empty($description) || empty($questions) || $userId <= 0) {
        die(json_encode(['success' => false, 'message' => 'Missing or invalid required fields']));
    }

    // Start transaction
    $conn->begin_transaction();

    try {
        // Insert test data into the database
        $insertTestQuery = "INSERT INTO test (name, description, creation_date, visibility, fk_user, fk_resource) 
                          VALUES (?, ?, NOW(), 1, ?, NULL)";
        
        $stmt = $conn->prepare($insertTestQuery);
        $stmt->bind_param("ssi", $name, $description, $userId);
        $stmt->execute();
        
        $testId = $conn->insert_id; // Get the ID of the newly inserted test
        $stmt->close();

        // Insert questions into the database
        foreach ($questions as $question) {
            $title = $question['title'] ?? '';
            $description = $question['description'] ?? '';
            $answer = $question['answer'] ?? '';
            $index = $question['index'] ?? 0; // Get the index, default to 0 if not provided

            if (empty($title) || empty($answer)) {
                error_log("Invalid question data: " . print_r($question, true));
                continue; // Skip invalid questions
            }

            $insertQuestionQuery = "INSERT INTO question 
                                  (name, description, creation_date, visibility, answer, `index`, fk_user, fk_test) 
                                  VALUES (?, ?, NOW(), 1, ?, ?, ?, ?)";
            
            $stmt = $conn->prepare($insertQuestionQuery);
            $stmt->bind_param("sssiis", 
                $title, 
                $description, 
                $answer, 
                $index, 
                $userId, 
                $testId);
            
            if (!$stmt->execute()) {
                throw new Exception("Error inserting question: " . $conn->error);
            }
            $stmt->close();
        }

        // Commit transaction
        $conn->commit();
        $response = ['success' => true, 'message' => 'Test and questions saved successfully'];
    } catch (Exception $e) {
        // Rollback transaction on error
        $conn->rollback();
        $response = ['success' => false, 'message' => 'Error saving test: ' . $e->getMessage()];
    }

    echo json_encode($response);
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
}

$conn->close();
?>
<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

$response = ['success' => false, 'message' => ''];

try {
    // Get input data
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input || !isset($input['testId']) || !isset($input['userId'])) {
        throw new Exception("Invalid input data");
    }

    $db = new mysqli("localhost", "root", "", "knowledgeswap");
    if ($db->connect_error) {
        throw new Exception("Database connection failed");
    }

    // Begin transaction
    $db->begin_transaction();

    try {
        // Update test info
        $stmt = $db->prepare("UPDATE test SET name = ?, description = ? WHERE id = ? AND fk_user = ?");
        $stmt->bind_param("ssii", $input['name'], $input['description'], $input['testId'], $input['userId']);
        
        if (!$stmt->execute()) {
            throw new Exception("Failed to update test");
        }

        // Process questions
        if (isset($input['questions']) && is_array($input['questions'])) {
            foreach ($input['questions'] as $question) {
                if (isset($question['id'])) {
                    // Update existing question
                    $stmt = $db->prepare("UPDATE question SET 
                        name = ?, 
                        description = ?, 
                        answer = ?,
                        `index` = ?,
                        fk_user = ?
                        WHERE id = ? AND fk_test = ?");
                    $stmt->bind_param("sssiiii", 
                        $question['title'],
                        $question['description'],
                        $question['answer'],
                        $question['index'],
                        $input['userId'], // Include user ID for existing questions too
                        $question['id'],
                        $input['testId']);
                } else {
                    // Insert new question
                    $stmt = $db->prepare("INSERT INTO question 
                        (name, description, answer, `index`, fk_test, fk_user, creation_date, visibility) 
                        VALUES (?, ?, ?, ?, ?, ?, NOW(), 1)");
                    $stmt->bind_param("sssiii", 
                        $question['title'],
                        $question['description'],
                        $question['answer'],
                        $question['index'],
                        $input['testId'],
                        $input['userId']); // Include user ID for new questions
                }
                
                if (!$stmt->execute()) {
                    throw new Exception("Failed to process questions: " . $db->error);
                }
            }
        }

        $db->commit();
        $response = ['success' => true, 'message' => 'Test updated successfully'];
    } catch (Exception $e) {
        $db->rollback();
        throw $e;
    }
} catch (Exception $e) {
    $response['message'] = $e->getMessage();
} finally {
    if (isset($db)) $db->close();
    echo json_encode($response);
}
?>
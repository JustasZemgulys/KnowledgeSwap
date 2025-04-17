<?php
require_once 'db_connect.php';

$conn = getDBConnection();

$response = ['success' => false, 'message' => ''];

function log_message($message) {
    $timestamp = date('Y-m-d H:i:s');
    $logEntry = "[$timestamp] $message\n";
    file_put_contents(__DIR__ . '/update_test_debug.log', $logEntry, FILE_APPEND);
}

log_message("Update started");

try {
    // Get and decode input
    $json = file_get_contents('php://input');
    $input = json_decode($json, true);
    
    if (json_last_error() !== JSON_ERROR_NONE) {
        throw new Exception("Invalid JSON: " . json_last_error_msg());
    }
    
    log_message("Received data: " . print_r($input, true));
    
    if (!$input || !isset($input['testId']) || !isset($input['userId'])) {
        throw new Exception("Missing required fields");
    }

    $conn->begin_transaction();

    try {
        $resourceId = isset($input['fk_resource']) ? $input['fk_resource'] : null;
		$visibility = isset($input['visibility']) ? (int)$input['visibility'] : 1; 

		// Update test with NULL handling
		if ($resourceId === null) {
			$stmt = $conn->prepare("UPDATE test SET 
				name = ?, 
				description = ?,
				fk_resource = NULL,
				visibility = ?
				WHERE id = ? AND fk_user = ?");
			$stmt->bind_param("ssiii", 
				$input['name'], 
				$input['description'],
				$visibility,            
				$input['testId'], 
				$input['userId']);
		} else {
			$stmt = $conn->prepare("UPDATE test SET 
				name = ?, 
				description = ?,
				fk_resource = ?,
				visibility = ?
				WHERE id = ? AND fk_user = ?");
			$stmt->bind_param("ssiiii", 
				$input['name'], 
				$input['description'],
				$resourceId,
				$visibility,            
				$input['testId'], 
				$input['userId']);
		}
        
        if (!$stmt->execute()) {
            throw new Exception("Test update failed: " . $conn->error);
        }
        $stmt->close();

        // Process questions
        if (isset($input['questions']) && is_array($input['questions'])) {
            foreach ($input['questions'] as $question) {
                if (isset($question['id'])) {
                    // Update existing question
                    $stmt = $conn->prepare("UPDATE question SET 
                        name = ?, 
                        description = ?, 
                        answer = ?,
                        `index` = ?,
                        ai_made = ?
                        WHERE id = ? AND fk_test = ?");
                    $aiMade = $question['ai_made'] ?? 0;
                    $stmt->bind_param("sssiiii", 
                        $question['title'],
                        $question['description'],
                        $question['answer'],
                        $question['index'],
                        $aiMade,
                        $question['id'],
                        $input['testId']);
                } else {
                    // Insert new question
                    $stmt = $conn->prepare("INSERT INTO question 
                        (name, description, answer, `index`, fk_test, fk_user, creation_date, ai_made) 
                        VALUES (?, ?, ?, ?, ?, ?, NOW(), ?)");
                    $aiMade = $question['ai_made'] ?? 0;
                    $stmt->bind_param("sssiiii", 
                        $question['title'],
                        $question['description'],
                        $question['answer'],
                        $question['index'],
                        $input['testId'],
                        $input['userId'],
                        $aiMade);
                }
                
                if (!$stmt->execute()) {
                    throw new Exception("Question operation failed: " . $conn->error);
                }
                $stmt->close();
            }
        }

        $conn->commit();
        $response = ['success' => true, 'message' => 'Test updated successfully'];
    } catch (Exception $e) {
        $conn->rollback();
        throw $e;
    }
} catch (Exception $e) {
    $response['message'] = $e->getMessage();
    log_message("Error: " . $e->getMessage());
}

if (isset($conn)) $conn->close();
header('Content-Type: application/json');
echo json_encode($response);
?>
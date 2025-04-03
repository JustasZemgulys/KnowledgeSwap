<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

$response = ['success' => false, 'message' => ''];

try {
    // Get and decode input
    $json = file_get_contents('php://input');
    $input = json_decode($json, true);
    
    if (json_last_error() !== JSON_ERROR_NONE) {
        throw new Exception("Invalid JSON: " . json_last_error_msg());
    }
    
    if (!$input || !isset($input['testId']) || !isset($input['userId'])) {
        throw new Exception("Missing required fields");
    }

    $db = new mysqli("localhost", "root", "", "knowledgeswap");
    if ($db->connect_error) {
        throw new Exception("Database connection failed");
    }

    $db->begin_transaction();

    try {
		$resourceId = isset($input['fk_resource']) ? $input['fk_resource'] : null;
		$visibility = isset($input['visibility']) ? (int)$input['visibility'] : 1; 
		
        // Update test
        $stmt = $db->prepare("UPDATE test SET 
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
		
		if (!$stmt->execute()) {
			throw new Exception("Test update failed: " . $db->error);
		}
		
		// Update resource link
		//$stmt = $db->prepare("DELETE FROM test_resource WHERE fk_test = ?");
		//$stmt->bind_param("i", $input['testId']);
		//if (!$stmt->execute()) {
		//	throw new Exception("Resource link cleanup failed: " . $db->error);
		//}
		
		//if (!empty($input['fk_resource'])) {
		//	$stmt = $db->prepare("INSERT INTO test_resource 
		//		(fk_test, fk_resource) 
		//		VALUES (?, ?)");
		//	$stmt->bind_param("ii", $input['testId'], $input['fk_resource']);
		//	if (!$stmt->execute()) {
		//		throw new Exception("Resource link failed: " . $db->error);
		//	}
		//	$stmt->close();
		//}

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
                        ai_made = ?
                        WHERE id = ? AND fk_test = ?");
                    $aiMade = $question['ai_made'] ?? 0; // Convert to variable first
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
                    $stmt = $db->prepare("INSERT INTO question 
                        (name, description, answer, `index`, fk_test, fk_user, creation_date, ai_made) 
                        VALUES (?, ?, ?, ?, ?, ?, NOW(), ?)");
                    $aiMade = $question['ai_made'] ?? 0; // Convert to variable first
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
                    throw new Exception("Question operation failed: " . $db->error);
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
}

if (isset($db)) $db->close();
echo json_encode($response);
?>
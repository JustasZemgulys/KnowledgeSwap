<?php
require_once 'db_connect.php';

try {
    // Get PDO connection
    $pdo = getPDOConnection();

    if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['id'])) {
        // Validate ID parameter
        $testId = filter_input(INPUT_GET, 'id', FILTER_VALIDATE_INT);
        if ($testId === false || $testId === null) {
            throw new Exception("Invalid test ID");
        }

        // Prepare and execute query
        $stmt = $pdo->prepare("
            SELECT id, name, description, creation_date, ai_made, visibility
            FROM test 
            WHERE id = ?
        ");
        $stmt->execute([$testId]);
        $test = $stmt->fetch();

        if ($test) {
            sendJsonResponse(['success' => true, 'test' => $test]);
        } else {
            sendJsonResponse(['success' => false, 'message' => 'Test not found'], 404);
        }
    } else {
        sendJsonResponse(['success' => false, 'message' => 'Invalid request method or missing ID'], 400);
    }
} catch (PDOException $e) {
    sendJsonResponse(['success' => false, 'message' => 'Database error: ' . $e->getMessage()], 500);
} catch (Exception $e) {
    sendJsonResponse(['success' => false, 'message' => $e->getMessage()], 400);
}
?>
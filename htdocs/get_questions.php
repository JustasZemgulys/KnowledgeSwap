<?php
require_once 'db_connect.php';

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

try {
    $pdo = getPDOConnection();

    if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['test_id'])) {
        $testId = filter_input(INPUT_GET, 'test_id', FILTER_VALIDATE_INT);
        
        if (!$testId) {
            throw new Exception("Invalid test ID");
        }

        $stmt = $pdo->prepare("
            SELECT id, name, description, answer, `index`, ai_made
            FROM question 
            WHERE fk_test = ?
            ORDER BY `index` ASC
        ");
        $stmt->execute([$testId]);
        $questions = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Ensure all fields have proper values
        $questions = array_map(function($q) {
            return [
                'id' => $q['id'] ?? null,
                'name' => $q['name'] ?? '',
                'description' => $q['description'] ?? '',
                'answer' => $q['answer'] ?? '',
                'index' => $q['index'] ?? 0,
                'ai_made' => isset($q['ai_made']) ? (int)$q['ai_made'] : 0
            ];
        }, $questions);

        echo json_encode([
            'success' => true,
            'questions' => $questions
        ], JSON_UNESCAPED_UNICODE);
        exit();
    } else {
        throw new Exception("Invalid request method or missing parameters");
    }
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false, 
        'message' => 'Database error: ' . $e->getMessage()
    ]);
} catch(Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false, 
        'message' => $e->getMessage()
    ]);
}
?>
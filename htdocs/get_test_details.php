<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "knowledgeswap";

try {
    $pdo = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['id'])) {
        $testId = $_GET['id'];
        
        $stmt = $pdo->prepare("
            SELECT id, name, description, creation_date, ai_made, visibility
            FROM test 
            WHERE id = ?
        ");
        $stmt->execute([$testId]);
        $test = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($test) {
            echo json_encode(['success' => true, 'test' => $test]);
        } else {
            echo json_encode(['success' => false, 'message' => 'Test not found']);
        }
    }
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
} catch(Exception $e) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
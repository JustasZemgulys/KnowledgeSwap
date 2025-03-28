<?php
// Add this at the very top
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Modify headers to match working script
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

error_log("===== REQUEST RECEIVED =====");

// Database configuration
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "knowledgeswap";

// Mistral API configuration
$apiKey = "nECGxBiPP3s9uHR2s09PLSsjUC7xbtwZ";
$mistralUrl = "https://api.mistral.ai/v1/chat/completions";

try {
    // Get input data - MODIFIED to handle both content types
    $input = file_get_contents('php://input');
    error_log("Raw input: " . $input);
    
    $data = json_decode($input, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        throw new Exception("Invalid JSON input: " . json_last_error_msg());
    }
    
    error_log("Decoded data: " . print_r($data, true));

    $resourceId = $data['resource_id'] ?? 0;
    $userId = $data['user_id'] ?? 0;
    $resourceName = $data['resource_name'] ?? 'Resource';

    // Validate input
    if ($resourceId <= 0 || $userId <= 0) {
        throw new Exception("Invalid input parameters");
    }

    // Create database connection
    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) {
        throw new Exception("Database connection failed: " . $conn->connect_error);
    }

    // Get resource data
    $resource = getResource($conn, $resourceId);
    error_log("Resource data: " . print_r($resource, true));
    
    // MODIFIED file path handling
    $filePath = $_SERVER['DOCUMENT_ROOT'] . '/' . ltrim($resource['resource_link'], '/');
    error_log("Attempting to access file at: " . $filePath);
    
    if (!file_exists($filePath)) {
        throw new Exception("File not found at: " . $filePath);
    }

    $textContent = extractTextFromFile($filePath);
    error_log("Extracted text length: " . strlen($textContent));
    
    // Generate test content
    $questions = generateTestQuestions($textContent, $apiKey, $mistralUrl);
    
    // Save to database
    $conn->autocommit(false);
    $testId = saveTest($conn, $resourceName, $userId, $resourceId);
    saveQuestions($conn, $questions, $testId);
    $conn->commit();

    echo json_encode([
        'success' => true, 
        'testId' => $testId,
        'generatedQuestions' => count($questions)
    ]);

} catch (Exception $e) {
    error_log("ERROR: " . $e->getMessage());
    if (isset($conn)) {
        $conn->rollback();
    }
    http_response_code(500);
    echo json_encode([
        'success' => false, 
        'error' => $e->getMessage(),
        'trace' => $e->getTraceAsString()
    ]);
}

// Database functions
function getResource($conn, $resourceId) {
    $stmt = $conn->prepare("SELECT resource_link FROM resource WHERE id = ?");
    $stmt->bind_param("i", $resourceId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        throw new Exception("Resource not found");
    }
    return $result->fetch_assoc();
}

function saveTest($conn, $name, $userId, $resourceId) {
    $stmt = $conn->prepare("INSERT INTO test (name, description, creation_date, fk_user, fk_resource) 
        VALUES (?, 'Auto-generated test', NOW(), ?, ?)");
    $stmt->bind_param("sii", $name, $userId, $resourceId);
    
    if (!$stmt->execute()) {
        throw new Exception("Failed to save test: " . $conn->error);
    }
    return $conn->insert_id;
}

function saveQuestions($conn, $questions, $testId) {
    $stmt = $conn->prepare("INSERT INTO question (name, description, answer, creation_date, fk_test) 
        VALUES (?, ?, ?, NOW(), ?)");
    
    foreach ($questions as $q) {
        $options = json_encode($q['options'] ?? []);
        $stmt->bind_param("sssi", $q['text'], $options, $q['answer'], $testId);
        
        if (!$stmt->execute()) {
            throw new Exception("Failed to save question: " . $conn->error);
        }
    }
}

// AI Generation functions
function generateTestQuestions($textContent, $apiKey, $mistralUrl) {
    $questions = [];
    $promptTemplates = [
        "Generate a multiple choice question with 4 options about: $textContent",
        "Create a true/false question based on: $textContent",
        "Generate a short answer question regarding: $textContent",
        "Create an essay question about: $textContent",
        "Generate a fill-in-the-blank question using: $textContent"
    ];

    foreach ($promptTemplates as $prompt) {
        $response = sendToMistral($prompt, $apiKey, $mistralUrl);
        $questions[] = parseQuestion($response);
    }

    if (count($questions) < 5) {
        throw new Exception("Failed to generate all questions");
    }
    return $questions;
}

function sendToMistral($prompt, $apiKey, $mistralUrl) {
    $ch = curl_init($mistralUrl);
    curl_setopt_array($ch, [
        CURLOPT_HTTPHEADER => [
            "Authorization: Bearer $apiKey",
            "Content-Type: application/json"
        ],
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode([
            "model" => "mistral-tiny",
            "messages" => [["role" => "user", "content" => $prompt]],
            "temperature" => 0.7,
            "max_tokens" => 500
        ]),
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 30
    ]);

    $response = curl_exec($ch);
    if (curl_errno($ch)) {
        throw new Exception("AI API error: " . curl_error($ch));
    }

    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    if ($httpCode !== 200) {
        throw new Exception("AI API returned status: $httpCode");
    }

    return json_decode($response, true);
}

function parseQuestion($response) {
    if (!isset($response['choices'][0]['message']['content'])) {
        throw new Exception("Invalid AI response format");
    }

    $content = $response['choices'][0]['message']['content'];
    $question = [
        'text' => '',
        'options' => [],
        'answer' => ''
    ];

    // Extract question
    if (preg_match('/Question:\s*(.+?)(\n|$)/s', $content, $matches)) {
        $question['text'] = trim($matches[1]);
    }

    // Extract options
    if (preg_match('/Options:\s*([\s\S]+?)Answer:/', $content, $matches)) {
        $question['options'] = array_map('trim', explode("\n", trim($matches[1])));
    }

    // Extract answer
    if (preg_match('/Answer:\s*(.+)/', $content, $matches)) {
        $question['answer'] = trim($matches[1]);
    }

    if (empty($question['text']) || empty($question['answer'])) {
        throw new Exception("Failed to parse valid question from AI response");
    }

    return $question;
}

/**
 * Extracts text from a file (PDF or image).
 */
function extractTextFromFile($filePath, $fileType) {
    $extractedText = "";

    // Use finfo to detect the MIME type
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $detectedMimeType = finfo_file($finfo, $filePath);
    finfo_close($finfo);

    // Override the provided $fileType with the detected MIME type
    $fileType = $detectedMimeType;

    error_log("Detected MIME type: $fileType");

    try {
        // Verify file exists
        if (!file_exists($filePath)) {
            throw new Exception("File not found: $filePath");
        }

        // PDF handling
        if ($fileType === 'application/pdf') {
            error_log("Parsing PDF file: $filePath");
            $parser = new \Smalot\PdfParser\Parser();
            $pdf = $parser->parseFile($filePath);
            $extractedText = $pdf->getText();

            if (empty($extractedText)) {
                throw new Exception("PDF parsing returned empty text. The PDF might be image-based or contain no extractable text.");
            }

            error_log("PDF text extracted successfully");
        }
        // Image handling
        elseif (in_array($fileType, ['image/jpeg', 'image/png', 'image/jpg'])) {
            error_log("Processing image file: $filePath");
            $outputFile = tempnam(sys_get_temp_dir(), 'ocr_output');

            // Use full path to Tesseract
            $tesseractPath = '"C:\\Program Files\\Tesseract-OCR\\tesseract"'; // Windows
            // $tesseractPath = '/usr/bin/tesseract'; // Linux/macOS

            $cmd = "$tesseractPath " . escapeshellarg($filePath) . " " . escapeshellarg($outputFile) . " 2>&1";
            exec($cmd, $output, $returnCode);

            if ($returnCode !== 0) {
                throw new Exception("Tesseract failed (Code $returnCode): " . implode("\n", $output));
            }

            $extractedText = file_get_contents($outputFile . '.txt');
            unlink($outputFile . '.txt');

            if (empty($extractedText)) {
                throw new Exception("OCR returned empty text");
            }
        }
        else {
            throw new Exception("Unsupported file type: $fileType");
        }
    } catch (Exception $e) {
        error_log("Extraction Error: " . $e->getMessage());
        return [
            "error" => "Text extraction failed",
            "details" => $e->getMessage()
        ];
    }

    return $extractedText;
}
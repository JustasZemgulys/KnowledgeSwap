<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

require 'vendor/autoload.php';

$apiKey = "nECGxBiPP3s9uHR2s09PLSsjUC7xbtwZ";

// Database connection
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "knowledgeswap";

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    die(json_encode(['success' => false, 'message' => "Connection failed: " . $conn->connect_error]));
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    
    $resourceId = $data['resourceId'] ?? 0;
    $userId = $data['userId'] ?? 0;
    $resourceName = $data['resourceName'] ?? '';
    $questionsConfig = $data['questions'] ?? [];

    if ($resourceId <= 0 || $userId <= 0) {
        die(json_encode(['success' => false, 'message' => 'Invalid resource or user ID']));
    }

    // Get resource file content
    $resourceQuery = $conn->prepare("SELECT resource_link FROM resource WHERE id = ?");
    $resourceQuery->bind_param("i", $resourceId);
    $resourceQuery->execute();
    $resourceResult = $resourceQuery->get_result();
    
    if ($resourceResult->num_rows === 0) {
        die(json_encode(['success' => false, 'message' => 'Resource not found']));
    }
    
    $resource = $resourceResult->fetch_assoc();
    $resourcePath = $resource['resource_link'];
    $extractedText = "";

    if (!empty($resourcePath)) {
        $filePath = __DIR__ . '/' . ltrim($resourcePath, '/');
        $fileType = mime_content_type($filePath);
        $extractionResult = extractTextFromFile($filePath, $fileType);
        if (!is_array($extractionResult)) {
            $extractedText = $extractionResult;
        }
    }

    // Generate questions based on configuration
    $questions = [];
    foreach ($questionsConfig as $config) {
        $prompt = "Generate 1 question about {$config['topic']}";
        $prompt .= " with parameters: {$config['parameters']}";
        
        if (!empty($extractedText)) {
            $prompt .= " Use the following text as reference: $extractedText";
        }

        $question = generateQuestionFromPrompt($prompt);
        if ($question) {
            $questions[] = $question;
        }
        usleep(500000); // Rate limiting
    }

    if (count($questions) < 1) {
        die(json_encode(['success' => false, 'message' => 'Failed to generate questions']));
    }
    
    // Create test
    $testName = "Test: " . substr($resourceName, 0, 50);
    $testDescription = "Generated test based on resource: " . $resourceName;
    
    $insertTestQuery = "INSERT INTO test (name, description, creation_date, visibility, fk_user, fk_resource) 
                       VALUES (?, ?, NOW(), 1, ?, ?)";
    $stmt = $conn->prepare($insertTestQuery);
    $stmt->bind_param("ssii", $testName, $testDescription, $userId, $resourceId);
    
    if ($stmt->execute()) {
        $testId = $conn->insert_id;
        
        // Insert questions
        foreach ($questions as $q) {
            $insertQuestionQuery = "INSERT INTO question (name, description, creation_date, visibility, answer, fk_user, fk_test) 
                                   VALUES (?, ?, NOW(), 1, ?, ?, ?)";
            $qStmt = $conn->prepare($insertQuestionQuery);
            $qStmt->bind_param("sssii", $q['title'], $q['description'], $q['answer'], $userId, $testId);
            $qStmt->execute();
        }
        
        echo json_encode(['success' => true, 'testId' => $testId]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to save test']);
    }
}

function generateQuestionFromPrompt($prompt) {
    global $apiKey;
    
    $prompt .= " Follow this exact format:

Question: [The question text]

**If multiple choice or true/false**, include:
Options:
A) [Option A]
B) [Option B]
C) [Option C]
D) [Option D]
Answer: [Correct answer letter and text, e.g. 'A) [Option A]']

**Important Rules:**
- For non-multiple-choice questions, only include Question and Answer
- Never include example options for non-multiple-choice questions";

    try {
        $url = "https://api.mistral.ai/v1/chat/completions";
        $inputData = [
            "model" => "mistral-tiny",
            "messages" => [
                [
                    "role" => "user",
                    "content" => $prompt
                ]
            ],
            "max_tokens" => 500,
            "temperature" => 0.7
        ];

        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER => [
                "Authorization: Bearer $apiKey",
                "Content-Type: application/json"
            ],
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => json_encode($inputData),
            CURLOPT_TIMEOUT => 30
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

        if ($httpCode !== 200) {
            error_log("API error: " . $response);
            return null;
        }

        $responseData = json_decode($response, true);
        $content = $responseData['choices'][0]['message']['content'] ?? '';

        // Parse the response
        $question = [
            'title' => '',
            'description' => '',
            'answer' => ''
        ];

        // Extract question
        if (preg_match('/Question:\s*(.+)/', $content, $matches)) {
            $question['title'] = trim($matches[1]);
        }

        // Extract options (if any)
        if (preg_match('/Options:\s*([\s\S]+?)Answer:/', $content, $matches)) {
            $question['description'] = trim($matches[1]);
        }

        // Extract answer
        if (preg_match('/Answer:\s*(.+)/', $content, $matches)) {
            $question['answer'] = trim($matches[1]);
        }

        return $question;
    } catch (Exception $e) {
        error_log("Error generating question: " . $e->getMessage());
        return null;
    } finally {
        if (isset($ch)) curl_close($ch);
    }
}

function generateQuestion($topic, $parameters, $referenceText = "") {
    global $apiKey;
    
    $prompt = "Generate 1 question about $topic";
    $prompt .= " based on following parameters: $parameters";
    $prompt .= ".";
    
    if (!empty($referenceText)) {
        $prompt .= " Use the following text as a reference: $referenceText";
    }

    $prompt .= " Follow this exact format:

Question: [The question text]

**If and ONLY if the question type is multiple choice or true or false **, include:
Options:
A) [Option A]
B) [Option B]
**Use 2 options, for true or false questions, more for multiple choice questions, eg**
C) [Option C]
D) [Option D]
Answer: [The correct answer. If the question is multiple choice, format the answer as 'A) [Option A]'. Otherwise, provide a direct answer as 'Answer'.]
**Important Rules:**
- Do NOT include the Options section for open-ended, fill-in-the-blank, or other non-multiple-choice questions.
- Never include example options (e.g., commented-out options) for non-multiple-choice questions
";

    try {
        $url = "https://api.mistral.ai/v1/chat/completions";
        $inputData = [
            "model" => "mistral-tiny",
            "messages" => [
                [
                    "role" => "user",
                    "content" => $prompt
                ]
            ],
            "max_tokens" => 500,
            "temperature" => 0.7
        ];

        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER => [
                "Authorization: Bearer $apiKey",
                "Content-Type: application/json"
            ],
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => json_encode($inputData),
            CURLOPT_TIMEOUT => 30
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

        if ($httpCode !== 200) {
            error_log("API error: " . $response);
            return null;
        }

        $responseData = json_decode($response, true);
        $content = $responseData['choices'][0]['message']['content'] ?? '';

        // Parse the response
        $question = [
            'title' => '',
            'description' => '',
            'answer' => ''
        ];

        // Extract question
        if (preg_match('/Question:\s*(.+)/', $content, $matches)) {
            $question['title'] = trim($matches[1]);
        }

        // Extract options (if any)
        if (preg_match('/Options:\s*([\s\S]+?)Answer:/', $content, $matches)) {
            $question['description'] = trim($matches[1]);
        }

        // Extract answer
        if (preg_match('/Answer:\s*(.+)/', $content, $matches)) {
            $question['answer'] = trim($matches[1]);
        }

        return $question;
    } catch (Exception $e) {
        error_log("Error generating question: " . $e->getMessage());
        return null;
    } finally {
        if (isset($ch)) curl_close($ch);
    }
}

function extractTextFromFile($filePath, $fileType) {
    $extractedText = "";

    try {
        if (!file_exists($filePath)) {
            throw new Exception("File not found: $filePath");
        }

        // PDF handling
        if ($fileType === 'application/pdf') {
            $parser = new \Smalot\PdfParser\Parser();
            $pdf = $parser->parseFile($filePath);
            $extractedText = $pdf->getText();

            if (empty($extractedText)) {
                throw new Exception("PDF parsing returned empty text");
            }
        }
        // Image handling
        elseif (in_array($fileType, ['image/jpeg', 'image/png', 'image/jpg'])) {
            $outputFile = tempnam(sys_get_temp_dir(), 'ocr_output');
            $tesseractPath = '"C:\\Program Files\\Tesseract-OCR\\tesseract"';
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
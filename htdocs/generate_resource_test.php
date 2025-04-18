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

function log_message($message) {
    $timestamp = date('Y-m-d H:i:s');
    $logEntry = "[$timestamp] $message\n";
    file_put_contents(__DIR__ . '/ai_create_debug.log', $logEntry, FILE_APPEND);
}

require_once 'db_connect.php';

$conn = getDBConnection();

$apiKey = "nECGxBiPP3s9uHR2s09PLSsjUC7xbtwZ";

try {
    $conn = getDBConnection();
    log_message("Database connection established");
} catch (Exception $e) {
    log_message("Database connection failed: " . $e->getMessage());
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    log_message("POST request received");
    
    // Get raw input and log it
    $rawInput = file_get_contents('php://input');
    log_message("Raw input received: " . substr($rawInput, 0, 1000)); // Log first 1000 chars
    
    $data = json_decode($rawInput, true);
    
    if (json_last_error() !== JSON_ERROR_NONE) {
        $error = "JSON decode error: " . json_last_error_msg() . " in input: " . substr($rawInput, 0, 500);
        log_message($error);
        die(json_encode(['success' => false, 'message' => 'Invalid JSON input']));
    }
    
    log_message("Decoded input data: " . print_r($data, true));
    
    $resourceId = $data['resourceId'] ?? 0;
    $userId = $data['userId'] ?? 0;
    $resourceName = $data['resourceName'] ?? '';
    $questionsConfig = $data['questions'] ?? [];

    log_message("Processing request for resource ID: $resourceId, user ID: $userId");

    if ($resourceId <= 0 || $userId <= 0) {
        log_message("Invalid resource or user ID received");
        die(json_encode(['success' => false, 'message' => 'Invalid resource or user ID']));
    }

    // Get resource file content
    try {
        $resourceQuery = $conn->prepare("SELECT resource_link FROM resource WHERE id = ?");
        $resourceQuery->bind_param("i", $resourceId);
        $resourceQuery->execute();
        $resourceResult = $resourceQuery->get_result();
        
        if ($resourceResult->num_rows === 0) {
            log_message("Resource not found for ID: $resourceId");
            die(json_encode(['success' => false, 'message' => 'Resource not found']));
        }
        
        $resource = $resourceResult->fetch_assoc();
        $resourcePath = $resource['resource_link'];
        log_message("Found resource path: $resourcePath");
    } catch (Exception $e) {
        log_message("Database query failed: " . $e->getMessage());
        die(json_encode(['success' => false, 'message' => 'Database error']));
    }

    $extractedText = "";
    if (!empty($resourcePath)) {
        $filePath = __DIR__ . '/' . ltrim($resourcePath, '/');
        log_message("Attempting to process file at path: $filePath");
        
        if (!file_exists($filePath)) {
            log_message("File not found at path: $filePath");
            die(json_encode(['success' => false, 'message' => 'Resource file not found']));
        }

        $fileType = mime_content_type($filePath);
        log_message("Detected file type: $fileType");
        
        $extractionResult = extractTextFromFile($filePath, $fileType);
        
        if (is_array($extractionResult)) {
            log_message("Text extraction failed: " . print_r($extractionResult, true));
        } else {
            $extractedText = $extractionResult;
            log_message("Successfully extracted text (length: " . strlen($extractedText) . ")");
        }
    }

    // Generate questions based on configuration
    $questions = [];
    log_message("Starting question generation for " . count($questionsConfig) . " questions");
    
    foreach ($questionsConfig as $index => $config) {
        log_message("Generating question #$index with config: " . print_r($config, true));
        
        $prompt = "Generate 1 question about {$config['topic']}";
        $prompt .= " with parameters: {$config['parameters']}";
        
        if (!empty($extractedText)) {
            $prompt .= " Use the following text as reference: " . substr($extractedText, 0, 100) . "...";
        }

        $question = generateQuestionFromPrompt($prompt);
        
        if ($question) {
            log_message("Generated question #$index successfully: " . print_r($question, true));
            $questions[] = [
                ...$question,
                'original_order' => $config['original_order'] ?? $index
            ];
        } else {
            log_message("Failed to generate question #$index");
        }
        
        usleep(500000);
    }

    if (count($questions) < 1) {
        log_message("No questions were generated successfully");
        die(json_encode(['success' => false, 'message' => 'Failed to generate questions']));
    }
    
    log_message("Successfully generated " . count($questions) . " questions");
    
    // Create test
    $testName = "Test: " . substr($resourceName, 0, 50);
    $testDescription = "Generated test based on resource: " . $resourceName;
    
    log_message("Creating test with name: $testName");
    
    try {
        $insertTestQuery = "INSERT INTO test (name, description, creation_date, visibility, fk_user, fk_resource, ai_made) 
                           VALUES (?, ?, NOW(), 1, ?, ?, 1)";
        $stmt = $conn->prepare($insertTestQuery);
        $stmt->bind_param("ssii", $testName, $testDescription, $userId, $resourceId);
        
        if ($stmt->execute()) {
            $testId = $conn->insert_id;
            log_message("Test created successfully with ID: $testId");
            
            // Insert questions
            $questionsInserted = 0;
			foreach ($questions as $q) {
				$insertQuestionQuery = "INSERT INTO question 
					(name, description, creation_date, answer, fk_user, fk_test, ai_made, `index`) 
					VALUES (?, ?, NOW(), ?, ?, ?, 1, ?)";
				$qStmt = $conn->prepare($insertQuestionQuery);
				$originalOrder = $q['original_order'] + 1; // Convert to 1-based index
				$qStmt->bind_param("sssiii", 
					$q['title'], 
					$q['description'], 
					$q['answer'], 
					$userId, 
					$testId,
					$originalOrder
				);
				if (!$qStmt->execute()) {
					log_message("Failed to insert question: " . $qStmt->error);
				}
				$qStmt->close();
			}
            
            log_message("Inserted $questionsInserted questions for test ID: $testId");
            
            // Clear output buffer before sending JSON
            ob_end_clean();
            echo json_encode(['success' => true, 'testId' => $testId]);
            log_message("Successfully returned response for test ID: $testId");
        } else {
            throw new Exception("Test insert failed: " . $conn->error);
        }
    } catch (Exception $e) {
        log_message("Database operation failed: " . $e->getMessage());
        ob_end_clean();
        echo json_encode(['success' => false, 'message' => 'Failed to save test']);
    }
} else {
    log_message("Invalid request method: " . $_SERVER['REQUEST_METHOD']);
    ob_end_clean();
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
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

/**
 * Extracts text from PDF files with server-side parsing and timeout protection
 */
function extractTextFromPDF($filePath) {
    try {
        log_message("Starting PDF processing for: " . basename($filePath));

        // Initialize the parser FIRST
        $parser = new \Smalot\PdfParser\Parser();
        log_message("PDF parser initialized");

        // Parse the PDF
        log_message("Attempting to parse PDF file");
        $pdf = $parser->parseFile($filePath);
        log_message("PDF parsed successfully");
        
        $text = $pdf->getText();
        log_message("Text extracted from PDF");
        
        if (empty(trim($text))) {
            throw new Exception("No text content found - possibly image-based PDF");
        }
        
        return $text;
        
    } catch (\Exception $e) {
        log_message("PDF Error: " . $e->getMessage());
        throw $e;
    }
}

/**
 * Main file text extraction handler with timeout protection
 */
function extractTextFromFile($filePath, $fileType) {
    // Set overall timeout (45 seconds)
    set_time_limit(45);
    $startTime = time();
    
    try {
        log_message("Starting file processing for: " . basename($filePath));

        if (!is_readable($filePath)) {
            throw new Exception("File not found or not readable");
        }

        // Verify MIME type
        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        $detectedMimeType = finfo_file($finfo, $filePath);
        finfo_close($finfo);
        
        log_message("Detected MIME type: $detectedMimeType");

        // Handle different file types
        switch ($detectedMimeType) {
            case 'application/pdf':
                try {
                    $text = extractTextFromPDF($filePath);
                    log_message("PDF processing completed in " . (time() - $startTime) . " seconds");
                    return $text;
                } catch (Exception $e) {
                    return [
                        "error" => "PDF processing failed",
                        "details" => $e->getMessage(),
                        "solution" => "Please upload a smaller, non-secured, text-based PDF"
                    ];
                }
                
            case 'image/jpeg':
            case 'image/png':
            case 'image/jpg':
                if ((time() - $startTime) > 30) {
                    throw new Exception("Processing taking too long");
                }
                return ocrWithCloudService($filePath, $detectedMimeType);
                
            default:
                throw new Exception("Unsupported file type: $detectedMimeType");
        }
        
    } catch (Exception $e) {
        log_message("Extraction Error after " . (time() - $startTime) . " seconds: " . $e->getMessage());
        return [
            "error" => "Text extraction failed",
            "details" => $e->getMessage(),
            "processing_time" => (time() - $startTime) . " seconds"
        ];
    }
}

/**
 * Uses OCR.space API for text extraction with proper error handling
 */
function ocrWithCloudService($filePath, $fileType) {
    $apiKey = 'K82403247488957'; // Double-check this key at ocr.space
    $url = 'https://api.ocr.space/parse/image';
    
    try {
        // 1. Verify file exists and is readable
        if (!is_readable($filePath)) {
            log_message("File not readable: $filePath");
        }

        // 2. Prepare file content with error handling
        $fileContent = file_get_contents($filePath);
        if ($fileContent === false) {
            log_message("Failed to read file contents");
        }
        
        // 3. Debug file info
        $fileInfo = [
            'size' => filesize($filePath),
            'mime' => mime_content_type($filePath),
            'base64_length' => strlen(base64_encode($fileContent))
        ];
        log_message("File debug: " . print_r($fileInfo, true));

        // 4. Use cURL instead of file_get_contents
        $ch = curl_init();
        
        $data = [
            'apikey' => $apiKey,
            'language' => 'eng',
            'isOverlayRequired' => 'false',
            'base64Image' => 'data:' . $fileType . ';base64,' . base64_encode($fileContent),
            'OCREngine' => 2,
            'filetype' => strtoupper(pathinfo($filePath, PATHINFO_EXTENSION))
        ];

        curl_setopt_array($ch, [
            CURLOPT_URL => $url,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => $data,
            CURLOPT_HTTPHEADER => ['Expect:'], // Fix for some servers
            CURLOPT_TIMEOUT => 30,
            CURLOPT_SSL_VERIFYPEER => false // Temporary for debugging
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        
        // 5. Enhanced error logging
        if (curl_errno($ch)) {
            $curlError = curl_error($ch);
            log_message("cURL Error: $curlError");
            throw new Exception("API connection failed: $curlError");
        }
        
        if ($httpCode !== 200) {
            log_message("API returned HTTP $httpCode. Response: $response");
            throw new Exception("API returned HTTP $httpCode");
        }

        $result = json_decode($response, true);
        
        if (json_last_error() !== JSON_ERROR_NONE) {
            log_message("Invalid JSON: $response");
            throw new Exception("Invalid API response format");
        }

        // 6. Parse response with debug
        log_message("Full API response: " . print_r($result, true));
        
        if (!isset($result['ParsedResults'][0]['ParsedText'])) {
            $error = $result['ErrorMessage'] ?? 'No parsed text in response';
            log_message("OCR failed: $error");
        }

        $text = trim($result['ParsedResults'][0]['ParsedText']);
        
        if (empty($text)) {
            log_message("OCR returned empty text");
        }

        return $text;
    } catch (Exception $e) {
        log_message("OCR Failed: " . $e->getMessage());
        throw new Exception("OCR processing error: " . $e->getMessage());
    } finally {
        if (isset($ch)) curl_close($ch);
    }
}
<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

require_once 'db_connect.php';

$conn = getDBConnection();

function log_message($message) {
    $timestamp = date('Y-m-d H:i:s');
    $logEntry = "[$timestamp] $message\n";
    file_put_contents(__DIR__ . '/ai_create_debug.log', $logEntry, FILE_APPEND);
}

require 'vendor/autoload.php';

$apiKey = "nECGxBiPP3s9uHR2s09PLSsjUC7xbtwZ";

// Get fields from POST data
$topic = $_POST['topic'] ?? '';
$parameters = $_POST['parameters'] ?? '';

log_message("Received topic: $topic, parameters: $parameters");

// Validate required fields
if (empty($topic) || empty($parameters)) {
    log_message("Validation failed: Missing topic or parameters");
    echo json_encode(["error" => "Missing or invalid required fields"]);
    exit;
}

// Handle file upload
$extractedText = "";
if (isset($_FILES['file'])) {
    log_message("File uploaded: " . print_r($_FILES['file'], true));
    $file = $_FILES['file'];
    $filePath = $file['tmp_name'];
    $fileType = $file['type'];

    // Extract text from the uploaded file
    $extractionResult = extractTextFromFile($filePath, $fileType);
    if (is_array($extractionResult) && isset($extractionResult['error'])) {
        log_message("Text extraction failed: " . print_r($extractionResult, true));
        echo json_encode($extractionResult);
        exit;
    }
    $extractedText = $extractionResult;

    if (empty($extractedText)) {
        log_message("Text extraction returned empty text");
        echo json_encode(["error" => "Failed to extract text from file"]);
        exit;
    }
}

// Construct the AI prompt
$prompt = "Generate 1 question about $topic";
if (!empty($parameters)) {
    $prompt .= " based on the following parameters: $parameters";
}
$prompt .= ".";
if (!empty($extractedText)) {
    $prompt .= " Use the following text as a reference: $extractedText";
}

// Add format instructions
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
    // Mistral API configuration
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

    log_message("Sending request to Mistral API with prompt: $prompt");

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

    log_message("API Response Code: $httpCode");
    log_message("API Response: $response");

    if (curl_errno($ch)) {
        throw new Exception("CURL error: " . curl_error($ch));
    }

    $responseData = json_decode($response, true);

    if ($httpCode !== 200) {
        throw new Exception("API error: " . ($responseData['message'] ?? 'Unknown error'));
    }

    // Extract the correct response content
    if (isset($responseData['choices'][0]['message']['content'])) {
        echo json_encode([
            "success" => true,
            "full_response" => $responseData
        ]);
    } else {
        throw new Exception("Unexpected response format");
    }
} catch (Exception $e) {
    log_message("API Error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        "error" => "Failed to generate questions",
        "details" => $e->getMessage()
    ]);
} finally {
    if (isset($ch)) curl_close($ch);
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


?>
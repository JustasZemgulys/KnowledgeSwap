<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

require 'vendor/autoload.php'; // Ensure Composer autoload is included

$apiKey = "nECGxBiPP3s9uHR2s09PLSsjUC7xbtwZ"; // Your Mistral API key

// Get fields from POST data
$topic = $_POST['topic'] ?? '';
$parameters = $_POST['parameters'] ?? '';

error_log("Received topic: $topic, parameters: $parameters");

// Validate required fields
if (empty($topic) || empty($parameters)) {
    error_log("Validation failed: Missing topic or parameters");
    echo json_encode(["error" => "Missing or invalid required fields"]);
    exit;
}

// Handle file upload
$extractedText = "";
if (isset($_FILES['file'])) {
    error_log("File uploaded: " . print_r($_FILES['file'], true));
    $file = $_FILES['file'];
    $filePath = $file['tmp_name'];
    $fileType = $file['type'];

    // Extract text from the uploaded file
    $extractionResult = extractTextFromFile($filePath, $fileType);
    if (is_array($extractionResult) && isset($extractionResult['error'])) {
        error_log("Text extraction failed: " . print_r($extractionResult, true));
        echo json_encode($extractionResult);
        exit;
    }
    $extractedText = $extractionResult;

    if (empty($extractedText)) {
        error_log("Text extraction returned empty text");
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

    error_log("Sending request to Mistral API with prompt: $prompt");

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

    error_log("API Response Code: $httpCode");
    error_log("API Response: $response");

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
    error_log("API Error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        "error" => "Failed to generate questions",
        "details" => $e->getMessage()
    ]);
} finally {
    if (isset($ch)) curl_close($ch);
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
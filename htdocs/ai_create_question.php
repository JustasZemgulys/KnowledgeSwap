<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

require 'vendor/autoload.php';

$apiKey = "nECGxBiPP3s9uHR2s09PLSsjUC7xbtwZ";

// Get fields from POST data (not JSON)
$topic = $_POST['topic'] ?? '';
$questionAmount = isset($_POST['question_amount']) ? (int)$_POST['question_amount'] : 0;

// Validate required fields
if (empty($topic) || $questionAmount <= 0) {
    echo json_encode(["error" => "Missing or invalid required fields"]);
    exit;
}

// Handle file upload
$extractedText = "";
if (isset($_FILES['file'])) {
    $file = $_FILES['file'];
    $filePath = $file['tmp_name'];
    $fileType = $file['type'];

    $extractionResult = extractTextFromFile($filePath, $fileType);
	if (is_array($extractionResult) && isset($extractionResult['error'])) {
		echo json_encode($extractionResult);
		exit;
	}
	$extractedText = $extractionResult;

    if (empty($extractedText)) {
        echo json_encode(["error" => "Failed to extract text from file"]);
        exit;
    }
}
//Returns just the extracted text
//echo json_encode(["extracted_text" => $extractedText]);
//exit;

// Use the extracted text as part of the AI prompt
$prompt = "Generate $questionAmount multiple choice questions about $topic based on the following text: $extractedText";

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
        "max_tokens" => 150,  // Increased from 1 to allow meaningful response
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
        CURLOPT_TIMEOUT => 30  // Added timeout
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    
    if (curl_errno($ch)) {
        throw new Exception("CURL error: " . curl_error($ch));
    }

    $responseData = json_decode($response, true);
    
    if ($httpCode !== 200) {
        throw new Exception("API error: " . ($responseData['message'] ?? 'Unknown error'));
    }

    // Extract the correct response content
    if (isset($responseData['choices'][0]['message']['content'])) {
        $questions = $responseData['choices'][0]['message']['content'];
        echo json_encode([
            "success" => true,
            "questions" => $questions,
            "full_response" => $responseData  // Optional: include for debugging
        ]);
    } else {
        throw new Exception("Unexpected response format");
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "error" => "Failed to generate questions",
        "details" => $e->getMessage(),
        "request_data" => $inputData ?? null  // Helps with debugging
    ]);
} finally {
    if (isset($ch)) curl_close($ch);
}

function extractTextFromFile($filePath, $fileType) {
    $extractedText = "";

    // Use finfo to detect the MIME type
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $detectedMimeType = finfo_file($finfo, $filePath);
    finfo_close($finfo);

    // Override the provided $fileType with the detected MIME type
    $fileType = $detectedMimeType;

    try {
        // Verify file exists
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
        return json_encode([
            "error" => "Text extraction failed",
            "details" => $e->getMessage()
        ]);
    }

    return $extractedText;
}
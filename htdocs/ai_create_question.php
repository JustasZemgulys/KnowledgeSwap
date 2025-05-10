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
$topic = trim($_POST['topic'] ?? '');
$parameters = trim($_POST['parameters'] ?? '');
$useResourceText = isset($_POST['use_resource']) && $_POST['use_resource'] == '1';

log_message("Received topic: $topic, parameters: $parameters, useResource: $useResourceText");

// Validate required fields
if (empty($topic)) {
    echo "Missing Topic";
    exit;
}

// Handle file upload and text extraction if resource should be used
$extractedText = "";
if ($useResourceText && isset($_FILES['file'])) {
    log_message("Processing attached resource for text extraction");
    $file = $_FILES['file'];
    $filePath = $file['tmp_name'];
    $fileType = $file['type'];

    $extractionResult = extractTextFromFile($filePath, $fileType);
    if (is_array($extractionResult)) {
        echo "Failed to extract text from resource";
        exit;
    }
    $extractedText = trim($extractionResult);

    if (empty($extractedText)) {
        echo "Resource text extraction returned empty content";
        exit;
    }
}

// Construct the AI prompt with strict format requirements
$prompt = <<<PROMPT
Generate exactly 1 high-quality question about {$topic} that strictly follows these rules:

# CORE REQUIREMENTS
1. [TITLE] - Full question text
   - Example: [TITLE]What is PHP's main advantage?[/TITLE]
   - Must end with closing tag: [/TITLE]

2. [DESCRIPTION] - Mandatory explanation of the question.
   - It should explain what the question is about.
   - It should explain how it relates to the resource content.
   - Format: [DESCRIPTION]This question examines the main reason for PHP's popularity as a server-side language. The answer will be taken directly from the section discussing PHP's advantages in the resource text.[/DESCRIPTION]
   - Must end with closing tag: [/DESCRIPTION]
   
3. QUESTION TYPES:
   - If creating MULTIPLE-CHOICE:
     a) Include 2-4 [OPTION] tags
	 b) Each option MUST end with [/OPTION]
     c) [ANSWER] must exactly match one option (e.g., "A) Correct choice")
	 - Example:
   [OPTION]A) Easy deployment[/OPTION]
   [OPTION]B) Strong typing[/OPTION]
   - If creating OPEN-ENDED:
     * [ANSWER] must be self-contained and complete
     * [DESCRIPTION] field is not required, can be totally left empty.
   
4. [ANSWER] - Complete answer with:
   a) The correct response
   b) Context paragraph from resource (when available)
   - Format: [ANSWER]Correct answer\n[/ANSWER]\n[CONTEXT]Relevant excerpt[...][/CONTEXT]
   - Must end with closing tag: [/ANSWER]

PROMPT;
// Add parameters if provided
if (!empty($parameters)) {
    $prompt .= "\n\n# MANDATORY PARAMETERS\nThis question MUST satisfy ALL of these requirements:\n{$parameters}";
}
// Add resource-specific instructions if applicable
if (!empty($extractedText)) {
    $prompt .= <<<RESOURCE

# STRICT TOPIC-RESOURCE VALIDATION:
- FIRST verify the resource text is actually about {$topic}
- If the resource contains NO relevant information about {$topic}, return:
  [FAILURE]Failed to create question: The resource does not contain any information about {$topic}[/FAILURE]
- Only proceed with question generation if the resource clearly relates to {$topic}

# REFERENCE TEXT TO USE:
{$extractedText}
RESOURCE;
} else {
    $prompt .= "\n\n# GENERAL KNOWLEDGE QUESTION RULES:\n- Draw from established facts about {$topic}\n- Provide clear, concise answers. Do not include CONTEXT section for this question it does not need it";
}

// Final formatting requirements
$prompt .= <<<FORMAT

# STRICT FORMATTING RULES:
1. QUESTION TYPES:
   - If creating MULTIPLE-CHOICE:
     a) Include 2-4 [OPTION] tags
	 b) Each option MUST end with [/OPTION]
     c) [ANSWER] must exactly match one option (e.g., "A) Correct choice")
	 - Example:
   [OPTION]A) Easy deployment[/OPTION]
   [OPTION]B) Strong typing[/OPTION]
   - If creating OPEN-ENDED:
     * [ANSWER] must be self-contained and complete
     * [DESCRIPTION] field is not required, can be totally left empty.

2. FAILURE CASES:
	- If impossible to create valid question, return:
		[FAILURE]Reason why[/FAILURE]
	- If impossible to create question with that topic and resouce return:
		[FAILURE]Failed create question with that topic and resouce[/FAILURE]

# EXAMPLE (Resource-Based Multiple-Choice):
[TITLE]How does PHP handle type conversion?[/TITLE]
[DESCRIPTION]PHP automatically converts between types in most contexts. This differs from strict-typed languages where explicit conversion is needed. The correct answer shows this automatic behavior, while incorrect options describe manual conversion or type errors.[/DESCRIPTION]
[OPTION]A) Requires explicit casting[/OPTION]
[OPTION]B) Automatically converts types[/OPTION]
[OPTION]C) Always throws type errors[/OPTION]
[OPTION]D) Only converts strings to numbers[/OPTION]
[ANSWER]B) Automatically converts types[/ANSWER]
[CONTEXT]"PHP automatically converts types based on context - strings become numbers in arithmetic operations [...]"[/CONTEXT]

# EXAMPLE (General Knowledge Open-Ended):
[TITLE]What year was PHP created?[/TITLE]
[DESCRIPTION]Tests knowledge of PHP's history and development timeline. PHP was created before many modern web technologies and pioneered server-side scripting for the web.[/DESCRIPTION]
[ANSWER]1995[/ANSWER]
FORMAT;


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
        "max_tokens" => 1000,
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
        CURLOPT_TIMEOUT => 45
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

    // Extract the response content
	$aiResponse = $responseData['choices'][0]['message']['content'] ?? '';
	log_message("AI Response Content: $aiResponse");

	// In the validation section, replace with this version:

	// Extract and normalize the response
	$aiResponse = $responseData['choices'][0]['message']['content'] ?? '';
	$aiResponse = preg_replace('/\r\n|\r/', "\n", trim($aiResponse));

	// Check for failure case first
	if (preg_match('/\[FAILURE\](.*?)\[\/FAILURE\]/s', $aiResponse, $failureMatches)) {
		echo json_encode([
			'success' => false,
			'error' => trim($failureMatches[1]),
			'content' => $aiResponse
		]);
		exit;
	}

	// Parse all components with more flexible matching
	$components = [
		'title' => null,
		'description' => null,
		'answer' => null,
		'context' => null,
		'options' => []
	];

	// Use a more robust parsing approach
	$sections = [
		'title' => '/\[TITLE\](.*?)\[\/TITLE\]/s',
		'description' => '/\[DESCRIPTION\](.*?)\[\/DESCRIPTION\]/s',
		'answer' => '/\[ANSWER\](.*?)(?:\[\/ANSWER\]|$)/s',
		'context' => '/\[CONTEXT\](.*?)\[\/CONTEXT\]/s',
		'options' => '/\[OPTION\](.*?)\[\/OPTION\]/s'
	];

	foreach ($sections as $key => $pattern) {
		if ($key === 'options') {
			if (preg_match_all($pattern, $aiResponse, $matches)) {
				$components[$key] = array_map('trim', $matches[1]);
			}
		} else {
			if (preg_match($pattern, $aiResponse, $matches)) {
				$components[$key] = trim($matches[1]);
			}
		}
	}

	// Debug log the parsed components
	log_message("Parsed components: " . print_r($components, true));

	// Validate required fields
	if (empty($components['title']) || empty($components['answer']) || empty($components['description'])) {
		$missing = [];
		empty($components['title']) && $missing[] = "TITLE";
		empty($components['answer']) && $missing[] = "ANSWER";
		empty($components['description']) && $missing[] = "DESCRIPTION";
		
		echo "AI failed to provide required components: " . implode(", ", $missing);
		exit;
	}


	// For resource-based questions, ensure context exists
	if (!empty($extractedText) && empty($components['context'])) {
		echo "Resource-based questions require [CONTEXT] with supporting text";
		exit;
	}

	// Build the description with options if they exist
	$description = $components['description'] ?? '';
	if (!empty($components['options'])) {
		$description .= (empty($description) ? "" : "\n\n") . "Options:\n";
		foreach ($components['options'] as $option) {
			$description .= "• " . trim($option) . "\n";
		}
	}

	// Build the answer with context if it exists
	$answer = $components['answer'];
	if (!empty($components['context'])) {
		$answer .= "\n\nContext:\n" . $components['context'];
	}

	// Debug log the final output
	log_message("Final description: " . $description);
	log_message("Final answer: " . $answer);

	// Return the combined fields
	$formattedResponse = "[TITLE]{$components['title']}[/TITLE]\n" .
						 "[DESCRIPTION]{$description}[/DESCRIPTION]\n" .
						 "[ANSWER]{$answer}[/ANSWER]";

	echo $formattedResponse;
	
} catch (Exception $e) {
    log_message("API Error: " . $e->getMessage());
    echo "Processing error: {$e->getMessage()}";
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
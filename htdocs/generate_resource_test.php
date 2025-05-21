<?php
while (ob_get_level()) ob_end_clean();
ob_start();
header('Content-Type: application/json');
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

require_once 'db_connect.php';
require 'vendor/autoload.php';

$conn = getDBConnection();

$apiKey = "nECGxBiPP3s9uHR2s09PLSsjUC7xbtwZ";

function log_message($message) {
    $timestamp = date('Y-m-d H:i:s');
    $logEntry = "[$timestamp] $message\n";
    file_put_contents(__DIR__ . '/generate_test_debug.log', $logEntry, FILE_APPEND);
}

// Get database connection
$conn = getDBConnection();
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
		
		// If extraction failed (returned an array with error info)
		if (is_array($extractionResult)) {
			log_message("Text extraction failed - aborting");
			die(json_encode([
				'success' => false,
				'error' => $extractionResult['error'],
				'details' => $extractionResult['details'],
				'solution' => $extractionResult['solution']
			]));
		}
		
		$extractedText = $extractionResult;
	}
	log_message("Text extracted:");
	log_message($extractedText);

    // Generate questions with retry logic
    $questions = [];
    foreach ($questionsConfig as $index => $config) {
        $questionGenerated = false;
        $attempts = 0;
        $maxAttempts = 10;
        
        while (!$questionGenerated && $attempts < $maxAttempts) {
            $attempts++;
            log_message("Attempt $attempts for question {$config['topic']}");
            
            $question = generateQuestionWithRetry(
                $config['topic'], 
                $config['parameters'], 
                $extractedText,
                $attempts
            );
            
            if ($question) {
                $questions[] = [
                    ...$question,
                    'original_order' => $config['original_order'] ?? $index
                ];
                $questionGenerated = true;
                log_message("Successfully generated question after $attempts attempts");
            } else {
                log_message("Failed attempt $attempts for question {$config['topic']}");
                usleep(500000 * $attempts); // Exponential backoff
            }
        }
        
        if (!$questionGenerated) {
			die(json_encode([
				'success' => false, 
				'message' => "Failed to generate question after $maxAttempts attempts: {$config['topic']}",
				'failedQuestion' => $config['topic']
			]));
		}
    }

    if (count($questions) < 1) {
        die(json_encode(['success' => false, 'message' => 'Failed to generate questions']));
    }
    
	log_message("Creating test");
    // Create test
    $testName = "Test: " . substr($resourceName, 0, 50);
    $testDescription = "Generated test based on resource: " . $resourceName;
    
    $insertTestQuery = "INSERT INTO test (name, description, creation_date, visibility, fk_user, fk_resource, ai_made) 
                       VALUES (?, ?, NOW(), 0, ?, ?, 1)";
    $stmt = $conn->prepare($insertTestQuery);
    $stmt->bind_param("ssii", $testName, $testDescription, $userId, $resourceId);
    
	log_message("Inserted questions");
    if ($stmt->execute()) {
        $testId = $conn->insert_id;
        
        // Insert questions
        foreach ($questions as $q) {
			$insertQuestionQuery = "INSERT INTO question 
				(name, description, creation_date, answer, fk_user, fk_test, ai_made, `index`) 
				VALUES (?, ?, NOW(), ?, ?, ?, 1, ?)";
			
			try {
				$qStmt = $conn->prepare($insertQuestionQuery);
				if ($qStmt === false) {
					throw new Exception("Prepare failed: " . $conn->error);
				}
				
				$originalOrder = $q['original_order'] + 1;
				
				$bindResult = $qStmt->bind_param("sssiii", 
					$q['title'], 
					$q['description'], 
					$q['answer'], 
					$userId, 
					$testId,
					$originalOrder
				);
				if ($bindResult === false) {
					throw new Exception("Bind failed: " . $qStmt->error);
				}
				
				$executeResult = $qStmt->execute();
				if ($executeResult === false) {
					throw new Exception("Execute failed: " . $qStmt->error);
				}
				
			} catch (Exception $e) {
				log_message("QUESTION INSERT ERROR: " . $e->getMessage());
				continue;
			}
		}
		
        log_message("Success");
		ob_end_clean();
        echo json_encode(['success' => true, 'testId' => $testId]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to save test']);
    }
}

function generateQuestionWithRetry($topic, $parameters, $referenceText = "", $attempt = 1) {
    global $apiKey;
    
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
        $prompt .= "# MANDATORY PARAMETERS\nThis question MUST satisfy ALL of these requirements:\n{$parameters}\n\n";
    }
    
    // Add resource-specific instructions if applicable
    if (!empty($referenceText)) {
        $prompt .= <<<PROMPT
# STRICT TOPIC-RESOURCE VALIDATION:
- FIRST verify the resource text is actually about {$topic}
- If the resource contains NO relevant information about {$topic}, return:
  [FAILURE]Failed to create question: The resource does not contain any information about {$topic}[/FAILURE]
- Only proceed with question generation if the resource clearly relates to {$topic}

# REFERENCE TEXT TO USE:
{$referenceText}

PROMPT;
    }

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

2. OUTPUT FORMAT:
[TITLE]Question text here[/TITLE]
[DESCRIPTION]Optional description or options here[/DESCRIPTION]
[ANSWER]Correct answer here[/ANSWER]
[CONTEXT]Optional supporting context from resource[/CONTEXT]

FORMAT;

    try {
        $url = "https://api.mistral.ai/v1/chat/completions";
        $inputData = [
            "model" => $attempt > 2 ? "mistral-small" : "mistral-tiny", // Upgrade model after 2 attempts
            "messages" => [
                [
                    "role" => "user",
                    "content" => $prompt
                ]
            ],
            "max_tokens" => 1000,
            "temperature" => min(0.7 + ($attempt * 0.1), 0.9) // Slightly increase temperature with each attempt
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
            CURLOPT_TIMEOUT => 30 + ($attempt * 5) // Increase timeout with each attempt
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

        if ($httpCode !== 200) {
            log_message("API error ($httpCode) on attempt $attempt: " . $response);
            return null;
        }

        $responseData = json_decode($response, true);
        $aiResponse = $responseData['choices'][0]['message']['content'] ?? '';
        $aiResponse = preg_replace('/\r\n|\r/', "\n", trim($aiResponse));
		
		log_message("Topic $topic");
		log_message("Params $parameters)");
		log_message("Full AI response (attempt $attempt):\n" . $aiResponse);
		log_message("Structured response data:\n" . print_r($responseData, true));
		
        // Check for failure case first
        if (preg_match('/\[FAILURE\](.*?)\[\/FAILURE\]/s', $aiResponse, $failureMatches)) {
            log_message("AI reported failure on attempt $attempt: " . trim($failureMatches[1]));
            return null;
        }
		
		// Enhanced validation for all closing tags
		$requiredTags = [
			'title' => ['[/TITLE]', 'Missing [/TITLE] closing tag'],
			'description' => ['[/DESCRIPTION]', 'Missing [/DESCRIPTION] closing tag'],
			'answer' => ['[/ANSWER]', 'Missing [/ANSWER] closing tag'],
			'context' => ['[/CONTEXT]', 'Missing [/CONTEXT] closing tag (optional if no context)']
		];

		foreach ($requiredTags as $key => [$closingTag, $errorMsg]) {
			if ($key !== 'context' && !str_contains($aiResponse, $closingTag)) {
				log_message("$errorMsg in attempt $attempt");
				return null;
			}
			// For context, only validate if context exists
			if ($key === 'context' && str_contains($aiResponse, '[CONTEXT]') && !str_contains($aiResponse, '[/CONTEXT]')) {
				log_message($errorMsg . " when context exists");
				return null;
			}
		}

		// Special validation for multiple-choice options
		if (str_contains($aiResponse, '[OPTION]')) {
			// Extract all complete [OPTION]...[/OPTION] blocks first
			preg_match_all('/\[OPTION\](.*?)\[\/OPTION\]/s', $aiResponse, $optionMatches);
			
			// Check if we found any complete option blocks
			if (empty($optionMatches[0])) {
				log_message("Found [OPTION] tags but no complete options in attempt $attempt");
				return null;
			}
			
			// Now check for any orphaned [OPTION] tags without closing tags
			$totalOptionTags = substr_count($aiResponse, '[OPTION]');
			$totalClosingTags = substr_count($aiResponse, '[/OPTION]');
			
			if ($totalOptionTags !== $totalClosingTags) {
				log_message("Mismatched [OPTION] tags (found $totalOptionTags opening but $totalClosingTags closing) in attempt $attempt");
				return null;
			}
			
			// Store the valid options
			$components['options'] = array_map('trim', $optionMatches[1]);
		}

		// Validate answer section specifically
		if (str_contains($aiResponse, '[ANSWER]') && !str_contains($aiResponse, '[/ANSWER]')) {
			log_message("Invalid answer section - missing closing [/ANSWER] tag in attempt $attempt");
			return null;
		}

		// Additional check for answer content format
		if (isset($components['answer']) && !str_ends_with(trim($components['answer']), '[/ANSWER]')) {
			log_message("Answer content doesn't end with [/ANSWER] tag in attempt $attempt");
			return null;
		}

        // Parse components
        $components = [
            'title' => null,
            'description' => null,
            'answer' => null,
            'context' => null,
            'options' => []
        ];

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

        // Validate required fields
        if (empty($components['title']) || empty($components['answer']) || empty($components['description'])) {
            log_message("Missing required fields in attempt $attempt response");
            return null;
        }

        // For resource-based questions, ensure context exists
        if (!empty($referenceText) && empty($components['context'])) {
            log_message("Missing context in resource-based question attempt $attempt");
            return null;
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

        return [
            'title' => $components['title'],
            'description' => $description,
            'answer' => $answer,
			'FULL' => $responseData
        ];
    } catch (Exception $e) {
        log_message("Error in attempt $attempt: " . $e->getMessage());
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
        
        // Method 1: Try pdftotext first (fastest)
        if (function_exists('shell_exec') && shell_exec('which pdftotext')) {
            $text = extractWithPdftotext($filePath);
            if (!empty(trim($text))) return $text;
        }
        
        // Method 2: Try PHP parser
        $text = extractWithPHPParser($filePath);
        if (!empty(trim($text))) return $text;
        
        // Method 3: Try OCR as last resort
        return extractWithOCR($filePath);
        
    } catch (Exception $e) {
        log_message("PDF Extraction Error: " . $e->getMessage());
        return [
            "error" => "PDF text extraction failed",
            "details" => $e->getMessage(),
            "solution" => "This appears to be an image-based PDF. Try uploading a text-based PDF or a clear image file."
        ];
    }
}

/**
 * Method 1: Extract using pdftotext command-line tool
 */
function extractWithPdftotext($filePath) {
    $tempFile = tempnam(sys_get_temp_dir(), 'pdftext');
    $command = sprintf(
        'pdftotext -layout -nopgbrk "%s" "%s" 2>&1',
        escapeshellarg($filePath),
        escapeshellarg($tempFile)
    );
    
    shell_exec($command);
    
    if (!file_exists($tempFile)) {
        throw new Exception("pdftotext failed to create output file");
    }
    
    $text = file_get_contents($tempFile);
    unlink($tempFile);
    
    return $text;
}

/**
 * Method 2: Extract using PHP PDF parser
 */
function extractWithPHPParser($filePath) {
    $parser = new \Smalot\PdfParser\Parser([
        'retainImageContent' => false
    ]);
    
    $pdf = $parser->parseFile($filePath);
    $text = $pdf->getText();
    
    // Clean up text
    $text = preg_replace('/\s+/', ' ', $text);
    return trim($text);
}

/**
 * Method 3: Extract using OCR (for image-based PDFs)
 */
function extractWithOCR($filePath) {
    log_message("Attempting OCR for image-based PDF");
    
    // Convert PDF to image first
    $imageFile = convertPdfToImage($filePath);
    if (!$imageFile) {
        throw new Exception("PDF to image conversion failed");
    }
    
    // Use OCR on the image
    return ocrWithCloudService($imageFile, 'image/png');
}

/**
 * Convert PDF to image for OCR processing
 */
function convertPdfToImage($pdfPath) {
    if (!extension_loaded('imagick')) {
        throw new Exception("ImageMagick not available for PDF conversion");
    }
    
    try {
        $imagick = new Imagick();
        $imagick->setResolution(300, 300);
        $imagick->readImage($pdfPath . '[0]'); // First page only
        $imagick->setImageFormat('png');
        
        $tempImage = tempnam(sys_get_temp_dir(), 'pdfimg') . '.png';
        $imagick->writeImage($tempImage);
        $imagick->clear();
        
        return $tempImage;
    } catch (Exception $e) {
        throw new Exception("PDF to image conversion failed: " . $e->getMessage());
    }
}

/**
 * Main file text extraction handler with timeout protection
 */
function extractTextFromFile($filePath, $fileType) {
    set_time_limit(45);
    $startTime = time();
    
    try {
        log_message("Starting file processing for: " . basename($filePath));

        if (!is_readable($filePath)) {
            throw new Exception("File not found or not readable");
        }

        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        $detectedMimeType = finfo_file($finfo, $filePath);
        finfo_close($finfo);
        
        log_message("Detected MIME type: $detectedMimeType");

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
    $apiKey = 'K82403247488957';
    $url = 'https://api.ocr.space/parse/image';
    
    try {
        if (!is_readable($filePath)) {
            log_message("File not readable: $filePath");
            throw new Exception("File not readable");
        }

        $fileContent = file_get_contents($filePath);
        if ($fileContent === false) {
            log_message("Failed to read file contents");
            throw new Exception("Failed to read file");
        }
        
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
            CURLOPT_HTTPHEADER => ['Expect:'],
            CURLOPT_TIMEOUT => 30,
            CURLOPT_SSL_VERIFYPEER => false
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        
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

        log_message("Full API response: " . print_r($result, true));
        
        if (!isset($result['ParsedResults'][0]['ParsedText'])) {
            $error = $result['ErrorMessage'] ?? 'No parsed text in response';
            log_message("OCR failed: $error");
            throw new Exception($error);
        }

        $text = trim($result['ParsedResults'][0]['ParsedText']);
        
        if (empty($text)) {
            log_message("OCR returned empty text");
            throw new Exception("OCR returned empty text");
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
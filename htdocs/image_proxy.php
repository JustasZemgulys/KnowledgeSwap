<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Access-Control-Allow-Origin: *');

// Get and sanitize the path
$requestedPath = isset($_GET['path']) ? urldecode($_GET['path']) : '';
$requestedPath = ltrim($requestedPath, '/'); // Remove leading slashes

// Validate path
if (empty($requestedPath)) {
    http_response_code(400);
    exit(json_encode(['error' => 'No file path specified']));
}

// Security checks
if (strpos($requestedPath, '..') !== false) {
    http_response_code(403);
    exit(json_encode(['error' => 'Directory traversal not allowed']));
}

// PORTABLE PATH SOLUTION - works on any server
$baseDir = $_SERVER['DOCUMENT_ROOT'] . '/';
$fullPath = $baseDir . str_replace('/', DIRECTORY_SEPARATOR, $requestedPath);

// Debug output (check your PHP error log)
error_log("Attempting to serve: " . $fullPath);

// Check file exists
if (!file_exists($fullPath)) {
    http_response_code(404);
    error_log("File not found: " . $fullPath);
    exit(json_encode(['error' => 'File not found at: ' . $fullPath]));
}

// Set content type based on file extension
$extensionMap = [
    'jpg'  => 'image/jpeg',
    'jpeg' => 'image/jpeg',
    'png'  => 'image/png',
    'gif'  => 'image/gif',
    'webp' => 'image/webp',
    'pdf'  => 'application/pdf'
];

$ext = strtolower(pathinfo($fullPath, PATHINFO_EXTENSION));

if (!isset($extensionMap[$ext])) {
    http_response_code(415);
    exit(json_encode(['error' => 'Unsupported file type']));
}

// Serve the file with appropriate headers
header('Content-Type: ' . $extensionMap[$ext]);
header('Content-Length: ' . filesize($fullPath));
header('Content-Disposition: inline; filename="' . basename($fullPath) . '"');
readfile($fullPath);
?>
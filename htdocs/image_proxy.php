<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Get and sanitize the path
$requestedPath = isset($_GET['path']) ? urldecode($_GET['path']) : '';
$requestedPath = ltrim($requestedPath, '/'); // Remove leading slashes

// Validate path
if (empty($requestedPath)) {
    http_response_code(400);
    echo json_encode(['error' => 'No file path specified']);
    exit;
}

// Security checks
if (strpos($requestedPath, '..') !== false) {
    http_response_code(403);
    echo json_encode(['error' => 'Directory traversal not allowed']);
    exit;
}

$baseDir = $_SERVER['DOCUMENT_ROOT'] . '/';
$fullPath = $baseDir . str_replace('/', DIRECTORY_SEPARATOR, $requestedPath);

// Check file exists
if (!file_exists($fullPath)) {
    http_response_code(404);
    echo json_encode(['error' => 'File not found', 'path' => $fullPath]);
    exit;
}

// Set content type based on file extension
$extensionMap = [
    'jpg'  => 'image/jpeg',
    'jpeg' => 'image/jpeg',
    'png'  => 'image/png',
    'gif'  => 'image/gif',
    'webp' => 'image/webp'
];

$ext = strtolower(pathinfo($fullPath, PATHINFO_EXTENSION));

if (!isset($extensionMap[$ext])) {
    http_response_code(415);
    echo json_encode(['error' => 'Unsupported file type']);
    exit;
}

// Serve the file with appropriate headers
header('Content-Type: ' . $extensionMap[$ext]);
header('Content-Length: ' . filesize($fullPath));
readfile($fullPath);
?>
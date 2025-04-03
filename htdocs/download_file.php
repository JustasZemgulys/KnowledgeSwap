<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/octet-stream");

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

// Set appropriate headers for download
header('Content-Description: File Transfer');
header('Content-Disposition: attachment; filename="'.basename($fullPath).'"');
header('Content-Length: ' . filesize($fullPath));
readfile($fullPath);
exit;
?>
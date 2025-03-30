<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "knowledgeswap";

try {
    $page = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
    $perPage = isset($_GET['per_page']) ? max(1, (int)$_GET['per_page']) : 6;
    $sort = in_array(strtoupper($_GET['sort'] ?? ''), ['ASC', 'DESC']) ? $_GET['sort'] : 'DESC';
    $offset = ($page - 1) * $perPage;

    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) {
        throw new Exception("Database connection failed: " . $conn->connect_error);
    }

    $totalResult = $conn->query("SELECT COUNT(*) as total FROM resource");
    if (!$totalResult) throw new Exception("Count query failed: " . $conn->error);
    $total = (int)$totalResult->fetch_assoc()['total'];

    $stmt = $conn->prepare("
        SELECT
            id,
            name,
            description,
            creation_date,
            resource_photo_link,
			resource_link,
			fk_user
        FROM resource
        ORDER BY creation_date $sort
        LIMIT ?, ?
    ");
    if (!$stmt) throw new Exception("Prepare failed: " . $conn->error);
    $stmt->bind_param("ii", $offset, $perPage);
    $stmt->execute();
    $result = $stmt->get_result();

    $resources = [];
    while ($row = $result->fetch_assoc()) {
        if (!empty($row['resource_photo_link'])) {
            $filename = basename($row['resource_photo_link']);
            $iconDir = $_SERVER['DOCUMENT_ROOT'] . '/knowledgeswap/icons/';

            $found = null;
            foreach (glob($iconDir . '*', GLOB_NOSORT) as $file) {
                if (strtolower(basename($file)) === strtolower($filename)) {
                    $found = basename($file);
                    break;
                }
            }

            $row['resource_photo_link'] = $found
                ? 'knowledgeswap/icons/' . $found
                : null;
        }
        $resources[] = $row;
    }

    $stmt->close();
    $conn->close();

    echo json_encode([
        'success' => true,
        'resources' => $resources,
        'total' => $total
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage(),
        'stack' => $e->getTraceAsString()
    ]);
}
?>

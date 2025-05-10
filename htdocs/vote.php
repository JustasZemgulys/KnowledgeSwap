<?php
require_once 'db_connect.php';

$conn = getDBConnection();

$response = ['success' => false, 'message' => ''];

try {
    // Get input data (works with both POST and JSON)
    $input = file_get_contents('php://input');
    if (strpos($_SERVER['CONTENT_TYPE'] ?? '', 'application/json') !== false) {
        $data = json_decode($input, true);
    } else {
        parse_str($input, $data);
    }

    // Validate input
    $requiredFields = ['direction', 'fk_user', 'fk_item', 'fk_type'];
    foreach ($requiredFields as $field) {
        if (!isset($data[$field])) {
            throw new Exception("Missing required field: $field");
        }
    }

    $direction = (int)$data['direction'];
    $userId = (int)$data['fk_user'];
    $itemId = (int)$data['fk_item'];
    $itemType = $data['fk_type'];

    if (!in_array($direction, [1, -1])) {
        throw new Exception("Invalid vote direction");
    }

    if (!in_array($itemType, ['test', 'resource', 'comment', 'group', 'forum_item'])) {
        throw new Exception("Invalid item type");
    }

    // Start transaction
    $conn->begin_transaction();

    try {
        // Check for existing vote
        $checkQuery = "SELECT id, direction FROM vote 
                       WHERE fk_user = ? AND fk_item = ? AND fk_type = ?";
        $stmt = $conn->prepare($checkQuery);
        $stmt->bind_param("iis", $userId, $itemId, $itemType);
        $stmt->execute();
        $result = $stmt->get_result();
        $existingVote = $result->fetch_assoc();
        $stmt->close();

        $voteChange = $direction;
        $voteId = null;

        if ($existingVote) {
            // User is changing or removing their vote
            $voteId = $existingVote['id'];
            if ($existingVote['direction'] == $direction) {
                // User is removing their vote
                $voteChange = -$direction;
                $deleteQuery = "DELETE FROM vote WHERE id = ?";
                $stmt = $conn->prepare($deleteQuery);
                $stmt->bind_param("i", $voteId);
                $stmt->execute();
                $stmt->close();
            } else {
                // User is changing their vote
                $voteChange = 2 * $direction; // Remove old vote (-1) and add new (+1) = net +2
                $updateQuery = "UPDATE vote SET direction = ? WHERE id = ?";
                $stmt = $conn->prepare($updateQuery);
                $stmt->bind_param("ii", $direction, $voteId);
                $stmt->execute();
                $stmt->close();
            }
        } else {
            // New vote
            $insertQuery = "INSERT INTO vote (direction, fk_user, fk_item, fk_type) 
                           VALUES (?, ?, ?, ?)";
            $stmt = $conn->prepare($insertQuery);
            $stmt->bind_param("iiis", $direction, $userId, $itemId, $itemType);
            $stmt->execute();
            $voteId = $stmt->insert_id;
            $stmt->close();
        }

        // Update the item's score
        $tableName = $itemType === 'forum_item' ? 'forum_item' : $itemType;
        $updateScoreQuery = "UPDATE `$tableName` SET score = score + ? WHERE id = ?";
        $stmt = $conn->prepare($updateScoreQuery);
        $stmt->bind_param("ii", $voteChange, $itemId);
        $stmt->execute();
        $stmt->close();

        // Get the new score
        $getScoreQuery = "SELECT score FROM `$tableName` WHERE id = ?";
        $stmt = $conn->prepare($getScoreQuery);
        $stmt->bind_param("i", $itemId);
        $stmt->execute();
        $result = $stmt->get_result();
        $newScore = $result->fetch_assoc()['score'];
        $stmt->close();

        $conn->commit();

        $response = [
            'success' => true,
            'new_score' => $newScore,
            'user_vote' => $existingVote && $existingVote['direction'] == $direction ? null : $direction,
        ];

    } catch (Exception $e) {
        $conn->rollback();
        throw $e;
    }

    $conn->close();

} catch (Exception $e) {
    http_response_code(500);
    $response = [
        'success' => false,
        'message' => $e->getMessage()
    ];
}

header('Content-Type: application/json');
echo json_encode($response);
exit;
?>
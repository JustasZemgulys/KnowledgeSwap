<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

$response = ['success' => false, 'message' => ''];

try {
    // Validate input
    $requiredFields = ['direction', 'fk_user', 'fk_item', 'fk_type'];
    foreach ($requiredFields as $field) {
        if (!isset($_POST[$field])) {
            throw new Exception("Missing required field: $field");
        }
    }

    $direction = (int)$_POST['direction'];
    $userId = (int)$_POST['fk_user'];
    $itemId = (int)$_POST['fk_item'];
    $itemType = $_POST['fk_type'];

    if (!in_array($direction, [1, -1])) {
        throw new Exception("Invalid vote direction");
    }

    if (!in_array($itemType, ['test', 'resource', 'comment', 'group'])) {
        throw new Exception("Invalid item type");
    }

    $servername = "localhost";
    $username = "root";
    $password = "";
    $dbname = "knowledgeswap";

    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) {
        throw new Exception("Database connection failed");
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
        $tableName = $itemType;
        $updateScoreQuery = "UPDATE `$tableName` SET score = score + ? WHERE id = ?";
        $stmt = $conn->prepare($updateScoreQuery);
        $stmt->bind_param("ii", $voteChange, $itemId);
        $stmt->execute();
        $stmt->close();

        // Update user points if this is a test or resource
        /*if (in_array($itemType, ['test', 'resource'])) {
            $pointsChange = $voteChange * ($itemType === 'test' ? 2 : 1); // Tests give more points
            
            // First, get the owner's user ID
            $ownerIdQuery = "SELECT fk_user FROM $tableName WHERE id = ?";
            $stmt = $conn->prepare($ownerIdQuery);
            $stmt->bind_param("i", $itemId);
            $stmt->execute();
            $result = $stmt->get_result();
            $ownerRow = $result->fetch_assoc();
            $ownerId = $ownerRow['fk_user'];
            $stmt->close();

            // Then update the owner's points
            $updateUserQuery = "UPDATE user SET 
                               points = points + ?,
                               points_in_24h = points_in_24h + ?,
                               points_in_week = points_in_week + ?,
                               points_in_month = points_in_month + ?
                               WHERE id = ?";
            $stmt = $conn->prepare($updateUserQuery);
            $stmt->bind_param("iiiii", $pointsChange, $pointsChange, $pointsChange, $pointsChange, $ownerId);
            $stmt->execute();
            $stmt->close();
        }*/

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

echo json_encode($response);
exit;
?>
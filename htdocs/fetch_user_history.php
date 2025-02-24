<?php
// Database connection parameters
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "mellowde"; // Make sure to replace with your actual database name

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$response = []; // Initialize an empty array for the response

try {
    if (isset($_POST['userId'])) {
        $userId = $_POST['userId'];
        
        $sql = "SELECT s.idSong, s.title, s.coverURL, s.songURL, uh.play_date
			FROM user_history AS uh 
			JOIN song AS s ON uh.idSong = s.idSong 
			WHERE uh.idUser = $userId 
			ORDER BY uh.play_date DESC";

        $result = $conn->query($sql);

        if ($result && $result->num_rows > 0) {
            while ($row = $result->fetch_assoc()) {
                $response[] = $row;
            }
        } else {
            $response['message'] = "No songs found for this user.";
        }
    } else {
        $response['error'] = "userId parameter is required.";
    }
    
    header('Content-Type: application/json');
    echo json_encode($response);
    
} catch (Exception $e) {
    $errorResponse = ['error' => 'An error occurred while fetching user history.', 'details' => $e->getMessage()];
    header('Content-Type: application/json');
    echo json_encode($errorResponse);
}

// Close the database connection
$conn->close();
?>

<?php

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "mellowde";

$conn = mysqli_connect($servername, $username, $password, $dbname);

if (!$conn) {
    die("Connection failed: " . mysqli_connect_error());
}

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $idSong = $_POST['idSong'];

    $query = "DELETE FROM song WHERE idSong = $idSong";
    $result = mysqli_query($conn, $query);

    if ($result) {
        echo json_encode(['success' => true, 'message' => 'Song removed successfully']);
    } else {
        $errorMessage = 'Failed to remove song: ' . mysqli_error($conn);
        error_log($errorMessage);
        echo json_encode(['success' => false, 'message' => $errorMessage]);
    }
} else {
    $errorMessage = 'Invalid request method';
    error_log($errorMessage);
    echo json_encode(['success' => false, 'message' => $errorMessage]);
}

mysqli_close($conn);

?>
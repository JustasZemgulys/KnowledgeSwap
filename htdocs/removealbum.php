<?php
header('Content-Type: application/json');

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "mellowde";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$albumId = $_POST['albumId'];

// Delete album from the database
$sqlDeleteAlbum = "DELETE FROM album WHERE idAlbum = ?";
$stmtDeleteAlbum = $conn->prepare($sqlDeleteAlbum);
$stmtDeleteAlbum->bind_param("i", $albumId);

if ($stmtDeleteAlbum->execute()) {
    echo json_encode(["status" => "success", "message" => "Album removed successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => "Error removing album"]);
}

$stmtDeleteAlbum->close();
$conn->close();
?>
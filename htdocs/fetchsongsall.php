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

$sql = "SELECT song.*, user.name AS artistName FROM song
        INNER JOIN artist ON song.idArtist = artist.idArtist
        INNER JOIN user ON artist.idUser = user.idUser";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    $songs = array();

    while ($row = $result->fetch_assoc()) {
        $songs[] = $row;
    }

    echo json_encode(["success" => true, "songs" => $songs]);
} else {
    echo json_encode(["success" => false, "message" => "No songs found"]);
}

$conn->close();
?>
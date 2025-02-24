<?php
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $idAlbum = isset($_GET['idAlbum']) ? $_GET['idAlbum'] : '';

    if (!empty($idAlbum)) {
        $conn = new mysqli("localhost", "root", "", "mellowde");

        if ($conn->connect_error) {
            die("Connection failed: " . $conn->connect_error);
        }

        $query = "SELECT * FROM song WHERE idAlbum = $idAlbum";
        $result = $conn->query($query);

        $songs = array();

        while ($row = $result->fetch_assoc()) {
            $songs[] = $row;
        }

        header('Content-Type: application/json');
        echo json_encode($songs);

        $conn->close();
    } else {
        echo "Invalid album ID.";
    }
} else {
    echo "Invalid request method.";
}
?>
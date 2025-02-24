<?php
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "mellowde";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die("Prisijungimo klaida: " . $conn->connect_error);
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $userId = $_POST["userId"];

    $query = "SELECT * FROM playlist WHERE userId = '$userId'";
    $result = $conn->query($query);

    if ($result->num_rows > 0) {
        $playlists = array();

        while ($row = $result->fetch_assoc()) {
            $playlist = array(
                "idPlaylist" => $row["playlistId"],
                "name" => $row["name"],
                "description" => $row["description"],
                "coverURL" => $row["imageUrl"],
                "userId" => $row["userId"]
            );

            $playlists[] = $playlist;
        }

        echo json_encode($playlists);
    } else {
        echo "Gauti playlistai yra tušti.";
    }
} else {
    echo "Neteisinga užklausa.";
}

$conn->close();
?>

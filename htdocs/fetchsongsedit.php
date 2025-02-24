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
    $idUser = $_POST['idUser'];

    $query = "SELECT idArtist FROM artist WHERE idUser = $idUser";
    $result = mysqli_query($conn, $query);

    if ($result) {
        $row = mysqli_fetch_assoc($result);
        $idArtist = $row['idArtist'];

        $querySongs = "SELECT idSong, title, coverURL FROM song WHERE idArtist = $idArtist";
        $resultSongs = mysqli_query($conn, $querySongs);

        if ($resultSongs) {
            $songs = array();
            while ($rowSong = mysqli_fetch_assoc($resultSongs)) {
                $songs[] = $rowSong;
            }

            echo json_encode(['success' => true, 'songs' => $songs]);
        } else {
            $errorMessage = 'Failed to fetch songs: ' . mysqli_error($conn);
            error_log($errorMessage);
            echo json_encode(['success' => false, 'message' => $errorMessage]);
        }
    } else {
        $errorMessage = 'Failed to fetch idArtist: ' . mysqli_error($conn);
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

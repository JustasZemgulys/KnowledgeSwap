<?php
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "mellowde";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die("Prisijungimo klaida: " . $conn->connect_error);
}

// Funkcija gauti dainas iš playlist lentelės
function getSongsFromPlaylist($playlistId) {
    global $conn;

    $query = "SELECT * FROM song
              JOIN queue ON song.idSong = queue.songId
              WHERE queue.playlistId = '$playlistId'";

    $result = $conn->query($query);

    if ($result->num_rows > 0) {
        $songs = array();
        while ($row = $result->fetch_assoc()) {
            $songs[] = $row;
        }
        return $songs;
    } else {
        return array();
    }
}

// Pavyzdinė užklausa gauti dainas iš playlist lentelės
$playlistId = 1; // Pakeiskite į jūsų pageidaujamą playlist'o ID
$songs = getSongsFromPlaylist($playlistId);

// Spausdiname gautas dainas
foreach ($songs as $song) {
    echo "Dainos pavadinimas: " . $song['title'] . "<br>";
    // Pridėkite kitus laukus, kuriuos norite atvaizduoti
    // TODO: pasidaryt kad rodytu tiktai tai ko reikia pacios dainos
}

$conn->close();
?>

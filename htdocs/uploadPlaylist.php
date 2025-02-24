<?php
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "mellowde";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die("Prisijungimo klaida: " . $conn->connect_error);
}

function createPlaylist($name, $description, $imageUrl, $userId) {
    global $conn;

    $query = "INSERT INTO playlist (name, description, imageUrl, userId) VALUES ('$name', '$description', '$imageUrl', '$userId')";

    if ($conn->query($query) === TRUE) {
        echo json_encode(['status' => 'success', 'message' => 'Playlistas sukurtas sėkmingai.']);
        // Gauti naujai sukurtą playlist'o ID
        $playlistId = $conn->insert_id;

        // Įterpiame naują įrašą į `playlistuser` lentelę
        $queryPlaylistUser = "INSERT INTO playlistuser (userRole, playlistId, userId) VALUES ('user', '$playlistId', '$userId')";

        if ($conn->query($queryPlaylistUser) === TRUE) {
            echo "Playlisto naudotojas sukurtas sėkmingai.";
        } else {
            echo "Klaida įdedant į playlistuser lentelę: " . $conn->error;
        }
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Klaida įdedant į playlist lentelę: ' . $conn->error]);
    }
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    if (isset($_POST['name']) && isset($_POST['description'])) {
        $target_dir = "images/";
        $target_file = $target_dir . basename($_FILES["file"]["name"]);
        $uploadOk = 1;
        $imageFileType = strtolower(pathinfo($target_file, PATHINFO_EXTENSION));

        if (file_exists($target_file)) {
            echo json_encode(['status' => 'error', 'message' => 'Failas jau egzistuoja.']);
            $uploadOk = 0;
        }

        if ($_FILES["file"]["size"] > 500000) {
            echo json_encode(['status' => 'error', 'message' => 'Failo dydis per didelis.']);
            $uploadOk = 0;
        }

        if ($imageFileType != "jpg" && $imageFileType != "png" && $imageFileType != "jpeg" && $imageFileType != "gif") {
            echo json_encode(['status' => 'error', 'message' => 'Leidžiami tik JPG, JPEG, PNG ir GIF failų tipai.']);
            $uploadOk = 0;
        }

        if ($uploadOk == 0) {
            echo json_encode(['status' => 'error', 'message' => 'Jūsų failas nebuvo įkeltas.']);
        } else {
            if (move_uploaded_file($_FILES["file"]["tmp_name"], $target_file)) {
                $name = $_POST["name"];
                $description = $_POST["description"];
                $imageUrl = "http://10.0.2.2/" . $target_file;
                $userId = 52;

                createPlaylist($name, $description, $imageUrl, $userId);
                echo json_encode(['status' => 'success', 'message' => 'Failas ' . basename($_FILES["file"]["name"]) . ' buvo įkeltas.']);
            } else {
                echo json_encode(['status' => 'error', 'message' => 'Įvyko klaida įkeliant failą.']);
            }
        }
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Trūksta reikiamų POST duomenų.']);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Netinkamas užklausos metodas.']);
}

echo json_encode(['status' => 'debug', 'received_data' => $_POST]);

$conn->close();
?>

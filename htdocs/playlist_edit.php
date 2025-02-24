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
    $playlistId = $_POST["playlistId"];
    $name = isset($_POST["name"]) ? $_POST["name"] : null;
    $description = isset($_POST["description"]) ? $_POST["description"] : null;

    // Check if a file was uploaded
    if (!empty($_FILES["file"]["name"])) {
        $target_dir = "images/";
        $target_file = $target_dir . basename($_FILES["file"]["name"]);
        $uploadOk = 1;
        $imageFileType = strtolower(pathinfo($target_file, PATHINFO_EXTENSION));

        // Check if the file already exists
        $counter = 1;
        while (file_exists($target_file)) {
            $filename = pathinfo($_FILES["file"]["name"], PATHINFO_FILENAME);
            $target_file = $target_dir . $filename . "_$counter." . $imageFileType;
            $counter++;
        }

        // Copy the file to the target directory
        if (copy($_FILES["file"]["tmp_name"], $target_file)) {
            $imageUrl = "http://10.0.2.2/" . $target_file;

            // Debugging statements
            echo "Image moved successfully to: $target_file\n";
            echo "Full URL: $imageUrl\n";
        } else {
            echo "Klaida perkopijuojant paveiksliuką.";
            exit;
        }
    } else {
        // No new image selected, fetch the existing playlist information
        $selectQuery = "SELECT name, description, imageUrl FROM playlist WHERE playlistId = ?";
        $stmt = $conn->prepare($selectQuery);
        $stmt->bind_param("i", $playlistId);
        $stmt->execute();
        $stmt->bind_result($existingName, $existingDescription, $existingImageUrl);
        $stmt->fetch();
        $stmt->close();

        // Use the existing values if the corresponding fields are not filled in the request
        $name = $name ?: $existingName;
        $description = $description ?: $existingDescription;
        $imageUrl = $existingImageUrl;
    }

    // Update playlist information using prepared statements
    $updateQuery = "UPDATE playlist
                    SET name = ?, description = ?, imageUrl = ?
                    WHERE playlistId = ?";

    $stmt = $conn->prepare($updateQuery);
    $stmt->bind_param("sssi", $name, $description, $imageUrl, $playlistId);

    if ($stmt->execute()) {
        echo "Playlist atnaujintas sėkmingai.";
    } else {
        echo "Klaida: " . $stmt->error;
    }

    $stmt->close();
}

$conn->close();
?>

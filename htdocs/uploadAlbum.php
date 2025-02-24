<?php
$target_dir = "images/";  // Directory where images will be stored
$target_file = $target_dir . basename($_FILES["file"]["name"]);
$uploadOk = 1;
$imageFileType = strtolower(pathinfo($target_file, PATHINFO_EXTENSION));

// ... (rest of the existing code)

// Check if $uploadOk is set to 0 by an error
if ($uploadOk == 0) {
    echo "Sorry, your file was not uploaded.";
} else {
    // if everything is ok, try to upload file
    if (move_uploaded_file($_FILES["file"]["tmp_name"], $target_file)) {
        echo "The file " . basename($_FILES["file"]["name"]) . " has been uploaded.";

        // Insert into MySQL database
        $servername = "localhost";
        $username = "root";
        $password = "";
        $dbname = "mellowde";

        $conn = new mysqli($servername, $username, $password, $dbname);

        if ($conn->connect_error) {
            die("Connection failed: " . $conn->connect_error);
        }

        $title = $_POST['name'];
        $imageURL = "http://10.0.2.2/" . $target_file;
        $idUser = $_POST['idUser'];

        $sqlRetrieveArtist = "SELECT idArtist FROM artist WHERE idUser = '$idUser'";
        $resultRetrieveArtist = $conn->query($sqlRetrieveArtist);

        if ($resultRetrieveArtist->num_rows > 0) {
            $row = $resultRetrieveArtist->fetch_assoc();
            $idArtist = $row['idArtist'];

            $createdAt = date("Y-m-d h:i:sa");

            $sql = "INSERT INTO album (title, coverURL, idArtist, createdAt) VALUES ('$title', '$imageURL', '$idArtist', '$createdAt')";

            if ($conn->query($sql) === TRUE) {
                $idAlbum = $conn->insert_id;  // Get the auto-generated idAlbum
                echo json_encode(['status' => 'success', 'idAlbum' => $idAlbum]);
            } else {
                error_log("Error: " . $sql . "\n" . $conn->error);
                echo "Error: " . $sql . "<br>" . $conn->error;
            }
        } else {
            error_log("Error retrieving idArtist for idUser: " . $idUser);
            echo "Error retrieving idArtist.";
        }

        $conn->close();
    } else {
        error_log("Error uploading file: " . $target_file);
        echo "Sorry, there was an error uploading your file.";
    }
}
?>

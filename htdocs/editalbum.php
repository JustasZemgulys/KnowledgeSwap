<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $idAlbum = isset($_POST['idAlbum']) ? $_POST['idAlbum'] : '';
    $name = isset($_POST['name']) ? $_POST['name'] : '';

    // Check if cover image is uploaded
    if (isset($_FILES['coverURL']) && !empty($_FILES['coverURL']['name'])) {
        $targetDir = "images/";
        $targetFile = $targetDir . basename($_FILES['coverURL']['name']);
        $uploadOk = 1;
        $imageFileType = strtolower(pathinfo($targetFile, PATHINFO_EXTENSION));

        // Allow certain file formats
        if ($imageFileType != "jpg" && $imageFileType != "png" && $imageFileType != "jpeg"
            && $imageFileType != "gif") {
            echo "Sorry, only JPG, JPEG, PNG & GIF files are allowed.";
            $uploadOk = 0;
        }

        // Check if $uploadOk is set to 0 by an error
        if ($uploadOk == 0) {
            echo "Sorry, your file was not uploaded.";
        } else {
            // if everything is ok, try to upload file
            if (move_uploaded_file($_FILES['coverURL']['tmp_name'], $targetFile)) {
                $imagelink = "http://10.0.2.2/" . $targetFile;
            } else {
                echo "Sorry, there was an error uploading your file.";
                exit;
            }
        }
    }

    // Update the database only if there's a name or coverURL
    if (!empty($name) || isset($imagelink)) {
        $conn = new mysqli("localhost", "root", "", "mellowde");

        if ($conn->connect_error) {
            die("Connection failed: " . $conn->connect_error);
        }

        // Update the album details in the database
        if (!empty($name)) {
            $nameQuery = "UPDATE album SET title = '$name' WHERE idAlbum = $idAlbum";

            if ($conn->query($nameQuery) !== TRUE) {
                echo "Error updating album name: " . $conn->error;
                $conn->close();
                exit;
            }
        }

        if (isset($imagelink)) {
            $coverQuery = "UPDATE album SET coverURL = '$imagelink' WHERE idAlbum = $idAlbum";

            if ($conn->query($coverQuery) !== TRUE) {
                echo "Error updating coverURL: " . $conn->error;
                $conn->close();
                exit;
            }
        }

        echo "Album details updated successfully.";
        $conn->close();
    } else {
        echo "No changes detected.";
    }
} else {
    echo "Invalid request method.";
}
?>

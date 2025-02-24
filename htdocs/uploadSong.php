<?php

// Define upload directories
$imageUploadDir = "images/";
$audioUploadDir = "songs/";

// Check if the form is submitted
if ($_SERVER["REQUEST_METHOD"] === "POST") {

    // Check if files are uploaded successfully
    if (isset($_FILES["imageFile"]) && isset($_FILES["audioFile"])) {

        // Handle image file upload
        $imageTmpPath = $_FILES["imageFile"]["tmp_name"];
        $imageName = $_FILES["imageFile"]["name"];
        $imagePath = $imageUploadDir . $imageName;

        if (move_uploaded_file($imageTmpPath, $imagePath)) {
            echo "Image file uploaded successfully.\n";
        } else {
            $error = error_get_last();
            echo "Error uploading image file: " . $error['message'] . "\n";
        }

        // Handle audio file upload
        $audioTmpPath = $_FILES["audioFile"]["tmp_name"];
        $audioName = $_FILES["audioFile"]["name"];
        $audioPath = $audioUploadDir . $audioName;

        if (move_uploaded_file($audioTmpPath, $audioPath)) {
            echo "Audio file uploaded successfully.\n";

            // Insert entry into the database
            $servername = "localhost";
            $username = "root";
            $password = "";
            $dbname = "mellowde";

            // Create connection
            $conn = new mysqli($servername, $username, $password, $dbname);

            // Check connection
            if ($conn->connect_error) {
                die("Connection failed: " . $conn->connect_error);
            }

            // Get other form data (modify these based on your form)
            $songName = $_POST["songName"];
            $bio = $_POST["bio"];
            $idUser = $_POST["idUser"]; // Retrieve idUser from the request
            $idGenre = $_POST["genreId"];
            $rating = 0;
            $songURL = "http://10.0.2.2/" . $audioPath;
            $coverURL = "http://10.0.2.2/" . $imagePath;

            // Fetch idArtist based on idUser
            $sqlFetchIdArtist = "SELECT idArtist FROM artist WHERE idUser = '$idUser'";
            $result = $conn->query($sqlFetchIdArtist);

            if ($result->num_rows > 0) {
                $row = $result->fetch_assoc();
                $idArtist = $row["idArtist"];

                // SQL query to insert data
                $sql = "INSERT INTO song (title, bio, idArtist, coverURL, songURL, idGenre, rating) 
                        VALUES ('$songName', '$bio', '$idArtist', '$coverURL', '$songURL', '$idGenre', '$rating')";

                if ($conn->query($sql) === TRUE) {
                    echo "Record inserted successfully.\n";
                } else {
                    echo "Error inserting record: " . $conn->error;
                }
            } else {
                echo "No matching artist found for the given idUser.\n";
            }

            $conn->close();
        } else {
            $error = error_get_last();
            echo "Error uploading audio file: " . $error['message'] . "\n";
        }

    } else {
        echo "Files not received.\n";
    }

} else {
    echo "Invalid request method.\n";
}

?>

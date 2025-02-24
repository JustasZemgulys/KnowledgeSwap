<?php
header('Content-Type: application/json');

// Define upload directories
$imageUploadDir = "images/";
$audioUploadDir = "songs/";

// Check if the form is submitted
if ($_SERVER["REQUEST_METHOD"] === "POST") {

    // Check if songId is provided
    if (isset($_POST["idSong"])) {

        // Get song details from the form
        $songId = $_POST["idSong"];
        $songName = $_POST["songName"];
        $bio = $_POST["bio"];
        $genreId = $_POST["genreId"];

        // Update song data in the database
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

        $sqlUpdate = "UPDATE song SET title = ?, bio = ?, IdGenre = ? WHERE idSong = ?";
        $stmtUpdate = $conn->prepare($sqlUpdate);
        $stmtUpdate->bind_param("ssii", $songName, $bio, $genreId, $songId);

        if ($stmtUpdate->execute()) {
            // Song data updated successfully

            // Check if cover picture is provided
            if (isset($_FILES["coverPicture"])) {
                $coverPictureTmpPath = $_FILES["coverPicture"]["tmp_name"];
                $coverPictureName = basename($_FILES["coverPicture"]["name"]);
                $coverPicturePath = $imageUploadDir . $coverPictureName;
                $coverURL = "http://10.0.2.2/" . $coverPicturePath;

                // Save new cover picture
                if (move_uploaded_file($coverPictureTmpPath, $coverPicturePath)) {
                    // Update cover picture path in the database
                    $sqlCoverUpdate = "UPDATE song SET coverURL = ? WHERE idSong = ?";
                    $stmtCoverUpdate = $conn->prepare($sqlCoverUpdate);
                    $stmtCoverUpdate->bind_param("si", $coverURL, $songId);
                    $stmtCoverUpdate->execute();
                    $stmtCoverUpdate->close();
                }
            }

            // Check if audio file is provided
            if (isset($_FILES["audioFile"])) {
                $audioTmpPath = $_FILES["audioFile"]["tmp_name"];
                $audioName = basename($_FILES["audioFile"]["name"]);
                $audioPath = $audioUploadDir . $audioName;
                $songURL = "http://10.0.2.2/" . $audioPath;

                // Save new audio file
                if (move_uploaded_file($audioTmpPath, $audioPath)) {
                    // Update audio file path in the database
                    $sqlAudioUpdate = "UPDATE song SET songURL = ? WHERE idSong = ?";
                    $stmtAudioUpdate = $conn->prepare($sqlAudioUpdate);
                    $stmtAudioUpdate->bind_param("si", $songURL, $songId);
                    $stmtAudioUpdate->execute();
                    $stmtAudioUpdate->close();
                }
            }

            echo json_encode(["status" => "success", "message" => "Song updated successfully"]);
        } else {
            echo json_encode(["status" => "error", "message" => "Error updating song"]);
        }

        $stmtUpdate->close();
        $conn->close();

    } else {
        echo json_encode(["status" => "error", "message" => "Song ID not provided"]);
    }

} else {
    echo json_encode(["status" => "error", "message" => "Invalid request method"]);
}
?>

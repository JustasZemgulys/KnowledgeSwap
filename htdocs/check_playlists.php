<?php
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "mellowde";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die("Prisijungimo klaida: " . $conn->connect_error);
}

// Tikrina, ar yra sukurtų playlistų
$query = "SELECT COUNT(*) AS count FROM playlist";

$result = $conn->query($query);

if ($result->num_rows > 0) {
    $row = $result->fetch_assoc();
    $count = $row["count"];
    
    // Grąžiname rezultatą į Flutter aplikaciją
    echo $count > 0 ? 'true' : 'false';
} else {
    echo "0 results";
}

$conn->close();
?>

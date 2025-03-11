<?php
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require 'vendor/autoload.php'; // Include Composer's autoloader

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

$mail = new PHPMailer(true);

try {
    // Get data from the request
    $data = json_decode(file_get_contents('php://input'), true);

    // Check if email is set and valid
    if (isset($data['email']) && filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
        $recipientEmail = $data['email'];
        $verificationCode = rand(100000, 999999); // Generate a random verification code

        // Server settings
        $mail->isSMTP();
        $mail->Host = 'smtp.gmail.com'; // Set the SMTP server to send through
        $mail->SMTPAuth = true;
        $mail->Username = 'KnowledgeSwapOfficial@gmail.com'; // SMTP username
        $mail->Password = 'oklc xxul ytag vyav'; // SMTP password
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
        $mail->Port = 587;

        // Recipients
        $mail->setFrom('KnowledgeSwapOfficial@gmail.com', 'KnowledgeSwap');
        $mail->addAddress($recipientEmail);

        // Content
        $mail->isHTML(true);
        $mail->Subject = 'Password reminder';
        $mail->Body    = "<h1>Verification Code to change password</h1><p>Your verification code is: $verificationCode</p>";

        // Send email
        $mail->send();

        // Return verification code as a string
        echo json_encode(['success' => true, 'verificationCode' => strval($verificationCode)]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Invalid email address']);
    }
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => 'Mailer Error: ' . $mail->ErrorInfo]);
}

?>

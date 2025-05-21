<?php
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require 'vendor/autoload.php';

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

$mail = new PHPMailer(true);

try {
    // Get JSON input
    $json = file_get_contents('php://input');
    if ($json === false) {
        throw new Exception("Failed to read input data");
    }
    
    $data = json_decode($json, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        throw new Exception("Invalid JSON data");
    }

    // Validate email
    if (!isset($data['email']) || !filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
        throw new Exception("Invalid email address");
    }

    $recipientEmail = $data['email'];
    $verificationCode = strval(rand(100000, 999999)); // 6-digit code as string

    // SMTP Configuration
    $mail->isSMTP();
    $mail->Host = 'smtp.gmail.com';
    $mail->SMTPAuth = true;
    $mail->Username = 'KnowledgeSwapOfficial@gmail.com';
    $mail->Password = 'oklc xxul ytag vyav';
    $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
    $mail->Port = 587;

    // Email content
    $mail->setFrom('KnowledgeSwapOfficial@gmail.com', 'KnowledgeSwap');
    $mail->addAddress($recipientEmail);
    $mail->isHTML(true);
    $mail->Subject = 'Password Reset Verification Code';
    $mail->Body = "
        <h1>Password Reset Request</h1>
        <p>Your verification code is: <strong>$verificationCode</strong></p>
        <p>This code will expire in 10 minutes.</p>
    ";

    // Send email
    if (!$mail->send()) {
        throw new Exception("Failed to send email");
    }

    // Return success response
    echo json_encode([
        'success' => true,
        'verificationCode' => $verificationCode,
        'message' => 'Verification code sent successfully'
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
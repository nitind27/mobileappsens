<?php
declare(strict_types=1);

namespace FieldPilot\Controllers;

use FieldPilot\Services\FileUploadService;
use FieldPilot\Services\AuditLogger;
use PDO;
use Exception;

class CommunicationController extends BaseController {
    /**
     * Get chat conversation messages between current user and contact
     */
    public function getMessages(array $params, ?array $user): void {
        $contactUserId = (int)($params['user_id'] ?? $this->getQuery('user_id', 0));
        $myUserId = (int)$user['id'];

        if (!$contactUserId) {
            $this->error('Contact user ID required', 400);
        }

        // Mark unread messages as read
        $this->db->prepare("
            UPDATE chat_messages 
            SET is_read = 1, read_at = NOW() 
            WHERE sender_id = ? AND receiver_id = ? AND is_read = 0
        ")->execute([$contactUserId, $myUserId]);

        $stmt = $this->db->prepare("
            SELECT m.*, 
                   s.full_name as sender_name, s.avatar_url as sender_avatar,
                   r.full_name as receiver_name, r.avatar_url as receiver_avatar
            FROM chat_messages m
            JOIN users s ON m.sender_id = s.id
            JOIN users r ON m.receiver_id = r.id
            WHERE (m.sender_id = ? AND m.receiver_id = ?) 
               OR (m.sender_id = ? AND m.receiver_id = ?)
            ORDER BY m.created_at ASC
        ");
        $stmt->execute([$myUserId, $contactUserId, $contactUserId, $myUserId]);
        $messages = $stmt->fetchAll();

        $this->json(['messages' => $messages], 200, 'Messages loaded');
    }

    /**
     * Send a text, voice note, or media message
     */
    public function sendMessage(array $params, ?array $user): void {
        $body = $this->getBody();
        $receiverId = (int)($body['receiver_id'] ?? 0);
        $messageType = $body['message_type'] ?? 'text';
        $content = $body['content'] ?? null;
        $mediaUrl = $body['media_url'] ?? null;
        $durationSeconds = (int)($body['duration_seconds'] ?? 0);

        if (!$receiverId) {
            $this->error('Receiver ID is required', 422);
        }

        // Handle audio voice note upload
        if (isset($_FILES['audio']) && $_FILES['audio']['error'] === UPLOAD_ERR_OK) {
            try {
                $uploadResult = FileUploadService::handleUpload($_FILES['audio'], 'audio');
                $mediaUrl = $uploadResult['relative_path'];
                $messageType = 'audio';
            } catch (Exception $e) {
                $this->error('Audio file upload failed: ' . $e->getMessage(), 400);
            }
        }

        if (empty($content) && empty($mediaUrl)) {
            $this->error('Message cannot be empty', 400);
        }

        $stmt = $this->db->prepare("
            INSERT INTO chat_messages 
            (sender_id, receiver_id, message_type, content, media_url, duration_seconds, is_read, created_at)
            VALUES (?, ?, ?, ?, ?, ?, 0, NOW())
        ");
        $stmt->execute([(int)$user['id'], $receiverId, $messageType, $content, $mediaUrl, $durationSeconds]);
        $msgId = (int)$this->db->lastInsertId();

        $this->json([
            'message_id' => $msgId,
            'media_url' => $mediaUrl,
            'created_at' => date('Y-m-d H:i:s')
        ], 201, 'Message sent');
    }

    /**
     * Initiate Voice or Video call session
     */
    public function initiateCall(array $params, ?array $user): void {
        $body = $this->getBody();
        $receiverId = (int)($body['receiver_id'] ?? 0);
        $callType = $body['call_type'] ?? 'audio'; // 'audio' or 'video'
        $sdpOffer = $body['sdp_offer'] ?? null;

        if (!$receiverId) {
            $this->error('Receiver ID is required', 422);
        }

        $channelName = 'call_' . uniqid('', true);

        $stmt = $this->db->prepare("
            INSERT INTO call_sessions 
            (caller_id, receiver_id, call_type, status, channel_name, sdp_offer, created_at)
            VALUES (?, ?, ?, 'ringing', ?, ?, NOW())
        ");
        $stmt->execute([(int)$user['id'], $receiverId, $callType, $channelName, $sdpOffer]);
        $callId = (int)$this->db->lastInsertId();

        AuditLogger::log((int)$user['id'], 'CALL_INITIATED', 'call_sessions', $callId, null, [
            'type' => $callType,
            'receiver_id' => $receiverId
        ]);

        $this->json([
            'call_id' => $callId,
            'channel_name' => $channelName,
            'status' => 'ringing'
        ], 201, 'Call initiated');
    }

    /**
     * Answer / reject / end call session
     */
    public function respondCall(array $params, ?array $user): void {
        $callId = (int)($params['id'] ?? 0);
        $body = $this->getBody();
        $action = $body['action'] ?? 'accept'; // 'accept', 'reject', 'end'
        $sdpAnswer = $body['sdp_answer'] ?? null;

        $stmt = $this->db->prepare("SELECT * FROM call_sessions WHERE id = ?");
        $stmt->execute([$callId]);
        $call = $stmt->fetch();

        if (!$call) {
            $this->error('Call session not found', 404);
        }

        if ($action === 'accept') {
            $update = $this->db->prepare("
                UPDATE call_sessions 
                SET status = 'accepted', sdp_answer = ?, start_time = NOW() 
                WHERE id = ?
            ");
            $update->execute([$sdpAnswer, $callId]);
            $msg = 'Call accepted';
        } elseif ($action === 'reject') {
            $update = $this->db->prepare("UPDATE call_sessions SET status = 'rejected', end_time = NOW() WHERE id = ?");
            $update->execute([$callId]);
            $msg = 'Call rejected';
        } else {
            // End call
            $startTime = !empty($call['start_time']) ? strtotime($call['start_time']) : time();
            $duration = max(0, time() - $startTime);
            $update = $this->db->prepare("
                UPDATE call_sessions 
                SET status = 'ended', end_time = NOW(), duration_seconds = ? 
                WHERE id = ?
            ");
            $update->execute([$duration, $callId]);
            $msg = 'Call ended';
        }

        $this->json(['status' => $action], 200, $msg);
    }
}

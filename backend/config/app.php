<?php
declare(strict_types=1);

namespace FieldPilot\Config;

class AppConfig {
    public static function getBaseUrl(): string {
        $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? "https://" : "http://";
        $host = $_SERVER['HTTP_HOST'] ?? 'localhost:8000';
        return $protocol . $host;
    }

    public static function getUploadDir(): string {
        return dirname(__DIR__) . '/uploads';
    }

    public static function allowedUploadMimes(): array {
        return [
            'image/jpeg' => 'jpg',
            'image/png' => 'png',
            'image/webp' => 'webp',
            'audio/mpeg' => 'mp3',
            'audio/wav' => 'wav',
            'audio/ogg' => 'ogg',
            'audio/m4a' => 'm4a',
            'audio/mp4' => 'mp4',
            'application/pdf' => 'pdf'
        ];
    }
}

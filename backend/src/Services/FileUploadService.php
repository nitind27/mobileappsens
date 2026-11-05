<?php
declare(strict_types=1);

namespace FieldPilot\Services;

use FieldPilot\Config\AppConfig;
use Exception;

class FileUploadService {
    public static function handleUpload(array $file, string $subfolder = 'receipts'): array {
        if (!isset($file['error']) || is_array($file['error'])) {
            throw new Exception('Invalid file parameters.');
        }

        switch ($file['error']) {
            case UPLOAD_ERR_OK:
                break;
            case UPLOAD_ERR_NO_FILE:
                throw new Exception('No file was uploaded.');
            case UPLOAD_ERR_INI_SIZE:
            case UPLOAD_ERR_FORM_SIZE:
                throw new Exception('File exceeded upload size limit.');
            default:
                throw new Exception('Unknown upload error.');
        }

        if ($file['size'] > 15 * 1024 * 1024) { // 15MB limit
            throw new Exception('File size must not exceed 15MB.');
        }

        // Validate MIME type securely
        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        $mime = finfo_file($finfo, $file['tmp_name']);
        finfo_close($finfo);

        $allowedMimes = AppConfig::allowedUploadMimes();
        if (!array_key_exists($mime, $allowedMimes)) {
            throw new Exception('Unsupported file format: ' . $mime);
        }

        $extension = $allowedMimes[$mime];
        $targetDir = AppConfig::getUploadDir() . '/' . $subfolder;
        if (!is_dir($targetDir)) {
            mkdir($targetDir, 0755, true);
        }

        $uniqueName = sprintf('%s_%s.%s', uniqid('fp_', true), bin2hex(random_bytes(4)), $extension);
        $targetPath = $targetDir . '/' . $uniqueName;

        if (!move_uploaded_file($file['tmp_name'], $targetPath)) {
            throw new Exception('Failed to move uploaded file to destination.');
        }

        return [
            'file_name' => $file['name'],
            'relative_path' => 'uploads/' . $subfolder . '/' . $uniqueName,
            'full_url' => AppConfig::getBaseUrl() . '/uploads/' . $subfolder . '/' . $uniqueName,
            'file_type' => $mime,
            'file_size' => $file['size']
        ];
    }

    public static function handleBase64Upload(string $base64Data, string $subfolder = 'signatures', string $ext = 'png'): array {
        if (preg_match('/^data:image\/(\w+);base64,/', $base64Data, $type)) {
            $base64Data = substr($base64Data, strpos($base64Data, ',') + 1);
            $ext = strtolower($type[1]);
        }

        $data = base64_decode($base64Data);
        if ($data === false) {
            throw new Exception('Invalid base64 payload.');
        }

        $targetDir = AppConfig::getUploadDir() . '/' . $subfolder;
        if (!is_dir($targetDir)) {
            mkdir($targetDir, 0755, true);
        }

        $uniqueName = sprintf('%s_%s.%s', uniqid('fp_sign_', true), bin2hex(random_bytes(4)), $ext);
        $targetPath = $targetDir . '/' . $uniqueName;

        if (file_put_contents($targetPath, $data) === false) {
            throw new Exception('Failed to write image data.');
        }

        return [
            'file_name' => $uniqueName,
            'relative_path' => 'uploads/' . $subfolder . '/' . $uniqueName,
            'full_url' => AppConfig::getBaseUrl() . '/uploads/' . $subfolder . '/' . $uniqueName,
            'file_type' => 'image/' . $ext,
            'file_size' => strlen($data)
        ];
    }
}

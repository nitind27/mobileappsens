<?php
declare(strict_types=1);

namespace FieldPilot\Config;

class JWTConfig {
    public static function getSecret(): string {
        return getenv('JWT_SECRET') ?: 'FieldPilot_Super_Secure_JWT_Secret_Key_2026_xyz!#$';
    }

    public static function getIssuer(): string {
        return getenv('JWT_ISSUER') ?: 'fieldpilot.com';
    }

    public static function getExpirySeconds(): int {
        return 86400 * 7; // 7 days token validity
    }
}

<?php
// Standalone PHP Development Server Router
// Usage: php -S localhost:8000 backend/server.php

$uri = urldecode(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH));

// Serve static uploaded files directly if they exist
if ($uri !== '/' && file_exists(__DIR__ . $uri)) {
    return false;
}

// Redirect all other API requests to public/index.php
require __DIR__ . '/public/index.php';

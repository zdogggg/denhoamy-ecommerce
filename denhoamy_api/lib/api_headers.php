<?php
// =====================================================
// API response headers - lib/api_headers.php
// =====================================================
// Sets version headers on every response. URL routing /v1/ reserved for future.

define('APP_START_TIME', microtime(true));
define('API_VERSION', 'v1');

function setVersionHeaders()
{
    header('X-API-Version: ' . API_VERSION);
    header('X-Powered-By: DenHoaMy API');
}

setVersionHeaders();

<?php
declare(strict_types=1);

function loadDbConfig(): array
{
    $config = [
        'host' => getenv('DB_HOST') ?: '127.0.0.1',
        'port' => getenv('DB_PORT') ?: '3306',
        'dbname' => getenv('DB_NAME') ?: 'dry_goods_db',
        'username' => getenv('DB_USERNAME') ?: 'root',
        'password' => getenv('DB_PASSWORD') ?: '',
        'charset' => getenv('DB_CHARSET') ?: 'utf8mb4',
    ];

    $localConfigFile = __DIR__ . '/db.local.php';
    if (file_exists($localConfigFile)) {
        $localConfig = require $localConfigFile;
        if (is_array($localConfig)) {
            $config = array_replace($config, $localConfig);
        }
    }

    return $config;
}

return loadDbConfig();

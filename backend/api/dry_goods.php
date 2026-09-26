<?php
declare(strict_types=1);

// Never show PHP warnings/errors to users: they can reveal file paths or SQL
// details. Errors still go to the server's error log for debugging.
ini_set('display_errors', '0');
ini_set('log_errors', '1');
error_reporting(E_ALL);

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-HTTP-Method-Override');
header('Access-Control-Max-Age: 86400');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

function jsonResponse(int $statusCode, bool $success, string $message, $data = null, array $errors = []): void
{
    http_response_code($statusCode);

    $payload = [
        'success' => $success,
        'message' => $message,
    ];

    if ($data !== null) {
        $payload['data'] = $data;
    }

    if (!empty($errors)) {
        $payload['errors'] = $errors;
    }

    echo json_encode($payload, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
    exit;
}

function readJsonBody(): array
{
    $rawBody = file_get_contents('php://input');
    if ($rawBody === false || trim($rawBody) === '') {
        return [];
    }

    $decoded = json_decode($rawBody, true);
    if (!is_array($decoded)) {
        return [];
    }

    return $decoded;
}

function normalizeMethod(): string
{
    $method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');

    if ($method === 'POST' && !empty($_SERVER['HTTP_X_HTTP_METHOD_OVERRIDE'])) {
        $override = strtoupper(trim((string) $_SERVER['HTTP_X_HTTP_METHOD_OVERRIDE']));
        if (in_array($override, ['PUT', 'DELETE'], true)) {
            return $override;
        }
    }

    return $method;
}

function validateDryGoodFields(array $input, bool $isUpdate = false): array
{
    $errors = [];

    $requiredTextFields = ['product_name', 'category', 'unit'];
    foreach ($requiredTextFields as $field) {
        if (!isset($input[$field]) || trim((string) $input[$field]) === '') {
            $errors[$field] = 'This field is required.';
        }
    }

    if (array_key_exists('quantity', $input)) {
        if (!is_numeric($input['quantity']) || (float) $input['quantity'] < 0) {
            $errors['quantity'] = 'Quantity must be a number greater than or equal to 0.';
        }
    } elseif (!$isUpdate) {
        $errors['quantity'] = 'Quantity is required.';
    }

    if (array_key_exists('price', $input)) {
        if (!is_numeric($input['price']) || (float) $input['price'] < 0) {
            $errors['price'] = 'Price must be a number greater than or equal to 0.';
        }
    } elseif (!$isUpdate) {
        $errors['price'] = 'Price is required.';
    }

    return $errors;
}

try {
    $dbConfig = require __DIR__ . '/../config/db.php';

    $dsn = sprintf(
        'mysql:host=%s;port=%s;dbname=%s;charset=%s',
        $dbConfig['host'],
        $dbConfig['port'],
        $dbConfig['dbname'],
        $dbConfig['charset']
    );

    $pdo = new PDO(
        $dsn,
        $dbConfig['username'],
        $dbConfig['password'],
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]
    );
} catch (Throwable $e) {
    jsonResponse(500, false, 'Database connection failed.', null, [
        'database' => 'Unable to connect to the database right now.',
    ]);
}

$requestMethod = normalizeMethod();

try {
    switch ($requestMethod) {
        case 'GET':
            if (isset($_GET['id'])) {
                $id = filter_input(INPUT_GET, 'id', FILTER_VALIDATE_INT);
                if ($id === false || $id === null || $id <= 0) {
                    jsonResponse(400, false, 'Invalid product id.', null, [
                        'id' => 'Product id must be a positive integer.',
                    ]);
                }

                $stmt = $pdo->prepare('SELECT * FROM dry_goods WHERE id = :id LIMIT 1');
                $stmt->execute([':id' => $id]);
                $product = $stmt->fetch();

                if (!$product) {
                    jsonResponse(404, false, 'Product not found.', null, [
                        'id' => 'No product found with that id.',
                    ]);
                }

                jsonResponse(200, true, 'Product retrieved successfully.', $product);
            }

            $stmt = $pdo->prepare('SELECT * FROM dry_goods ORDER BY created_at DESC, id DESC');
            $stmt->execute();
            $products = $stmt->fetchAll();
            jsonResponse(200, true, 'Products retrieved successfully.', $products);

        case 'POST':
            $input = readJsonBody();
            if (empty($input)) {
                jsonResponse(400, false, 'Request body is required.', null, [
                    'body' => 'JSON body is missing or invalid.',
                ]);
            }

            $errors = validateDryGoodFields($input, false);
            if (!empty($errors)) {
                jsonResponse(422, false, 'Please correct the highlighted fields.', null, $errors);
            }

            $stmt = $pdo->prepare(
                'INSERT INTO dry_goods (product_name, category, quantity, unit, price, supplier, description)
                 VALUES (:product_name, :category, :quantity, :unit, :price, :supplier, :description)'
            );

            $stmt->execute([
                ':product_name' => trim((string) $input['product_name']),
                ':category' => trim((string) $input['category']),
                ':quantity' => (float) $input['quantity'],
                ':unit' => trim((string) $input['unit']),
                ':price' => (float) $input['price'],
                ':supplier' => isset($input['supplier']) && trim((string) $input['supplier']) !== '' ? trim((string) $input['supplier']) : null,
                ':description' => isset($input['description']) && trim((string) $input['description']) !== '' ? trim((string) $input['description']) : null,
            ]);

            $newId = (int) $pdo->lastInsertId();
            $newStmt = $pdo->prepare('SELECT * FROM dry_goods WHERE id = :id LIMIT 1');
            $newStmt->execute([':id' => $newId]);
            $newProduct = $newStmt->fetch();

            jsonResponse(201, true, 'Product created successfully.', $newProduct);

        case 'PUT':
            $id = filter_input(INPUT_GET, 'id', FILTER_VALIDATE_INT);
            if ($id === false || $id === null || $id <= 0) {
                jsonResponse(400, false, 'Invalid product id.', null, [
                    'id' => 'Product id must be a positive integer.',
                ]);
            }

            $input = readJsonBody();
            if (empty($input)) {
                jsonResponse(400, false, 'Request body is required.', null, [
                    'body' => 'JSON body is missing or invalid.',
                ]);
            }

            $errors = validateDryGoodFields($input, true);
            if (!empty($errors)) {
                jsonResponse(422, false, 'Please correct the highlighted fields.', null, $errors);
            }

            $checkStmt = $pdo->prepare('SELECT id FROM dry_goods WHERE id = :id LIMIT 1');
            $checkStmt->execute([':id' => $id]);
            if (!$checkStmt->fetch()) {
                jsonResponse(404, false, 'Product not found.', null, [
                    'id' => 'No product found with that id.',
                ]);
            }

            $stmt = $pdo->prepare(
                'UPDATE dry_goods
                 SET product_name = :product_name,
                     category = :category,
                     quantity = :quantity,
                     unit = :unit,
                     price = :price,
                     supplier = :supplier,
                     description = :description
                 WHERE id = :id'
            );

            $stmt->execute([
                ':product_name' => trim((string) $input['product_name']),
                ':category' => trim((string) $input['category']),
                ':quantity' => (float) $input['quantity'],
                ':unit' => trim((string) $input['unit']),
                ':price' => (float) $input['price'],
                ':supplier' => isset($input['supplier']) && trim((string) $input['supplier']) !== '' ? trim((string) $input['supplier']) : null,
                ':description' => isset($input['description']) && trim((string) $input['description']) !== '' ? trim((string) $input['description']) : null,
                ':id' => $id,
            ]);

            $updatedStmt = $pdo->prepare('SELECT * FROM dry_goods WHERE id = :id LIMIT 1');
            $updatedStmt->execute([':id' => $id]);
            $updatedProduct = $updatedStmt->fetch();

            jsonResponse(200, true, 'Product updated successfully.', $updatedProduct);

        case 'DELETE':
            $id = filter_input(INPUT_GET, 'id', FILTER_VALIDATE_INT);
            if ($id === false || $id === null || $id <= 0) {
                jsonResponse(400, false, 'Invalid product id.', null, [
                    'id' => 'Product id must be a positive integer.',
                ]);
            }

            $checkStmt = $pdo->prepare('SELECT id FROM dry_goods WHERE id = :id LIMIT 1');
            $checkStmt->execute([':id' => $id]);
            if (!$checkStmt->fetch()) {
                jsonResponse(404, false, 'Product not found.', null, [
                    'id' => 'No product found with that id.',
                ]);
            }

            $stmt = $pdo->prepare('DELETE FROM dry_goods WHERE id = :id');
            $stmt->execute([':id' => $id]);

            jsonResponse(200, true, 'Product deleted successfully.', ['id' => $id]);

        default:
            jsonResponse(405, false, 'Method not allowed.', null, [
                'method' => 'Unsupported HTTP method.',
            ]);
    }
} catch (PDOException $e) {
    jsonResponse(500, false, 'Something went wrong while processing your request.', null, [
        'database' => 'Unable to complete the database operation.',
    ]);
} catch (Throwable $e) {
    jsonResponse(500, false, 'Something went wrong while processing your request.', null, [
        'server' => 'An internal server error occurred.',
    ]);
}

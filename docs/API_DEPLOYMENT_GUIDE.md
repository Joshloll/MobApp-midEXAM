# API Deployment Guide

## Scope
This guide covers the local XAMPP setup and production deployment for the Dry Goods Inventory API in `backend/api/dry_goods.php`. It also explains the required file layout, environment variables, and how to test all 5 API endpoints with a browser, Postman/Thunder Client, and `curl`.

## 1) Local XAMPP setup

### Step 1: Start Apache and MySQL
1. Open XAMPP Control Panel.
2. Start `Apache` and `MySQL`.
3. Confirm both are running without errors.

How to verify:
- Open `http://localhost` in your browser.
- Open `http://localhost/phpmyadmin`.
- If both open, your local web server and database server are working.

### Step 2: Create the database
1. Open `http://localhost/phpmyadmin`.
2. Click `New` and create a database named `dry_goods_db`.
3. Import the file: `database/dry_goods.sql`.

How to verify:
- In phpMyAdmin, open the `dry_goods_db` database.
- Confirm the `dry_goods` table exists.
- Run: `SELECT COUNT(*) FROM dry_goods;`
- Expected output: `15` rows.

### Step 3: Place the API in the local web root
Use a folder inside the XAMPP web root. On Windows, the default folder is usually:

`C:/xampp/htdocs/`

Place the project like this:

```text
C:/xampp/htdocs/MobApp-midEXAM/
├── backend/
│   ├── api/
│   └── config/
├── database/
└── ...
```

How to verify:
- Run the URL below in a browser:
- `http://localhost/MobApp-midEXAM/backend/api/dry_goods.php`
- Expected result: a JSON response with the list of products.

### Step 4: Configure database credentials
Copy the example file:

```bash
copy backend\config\db.local.example.php backend\config\db.local.php
```

Then edit `backend/config/db.local.php` with your local MySQL credentials, for example:

```php
<?php
return [
    'host' => '127.0.0.1',
    'port' => '3306',
    'dbname' => 'dry_goods_db',
    'username' => 'root',
    'password' => '',
    'charset' => 'utf8mb4',
];
```

How to verify:
- Visit the API URL again.
- Expected result: JSON with `success: true` and a `data` array.

## 2) Production path and file layout

Use this structure on the VPS:

```text
/var/www/MobApp-midEXAM/
├── backend/
│   ├── api/
│   └── config/
├── database/
└── ...
```

You usually configure the Apache/Nginx site to point to this folder, then configure your domain to point to the VPS IP address.

How to verify:
- Run `ls -l /var/www/MobApp-midEXAM` on the server.
- Confirm the folders exist.
- Confirm the PHP files are readable by the web server user.

## 3) Environment variables and credentials
The PHP config reads values from environment variables first, then falls back to `backend/config/db.local.php`.

Example `.env` values:

```env
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=dry_goods_db
DB_USERNAME=dry_goods_user
DB_PASSWORD=CHANGE_ME
DB_CHARSET=utf8mb4
```

Important:
- Do not commit real passwords.
- Keep the `.env` file only on the server.
- Use `db.local.php` only for local development, and keep it out of Git.

How to verify:
- Run:

```bash
php -r "var_export(getenv('DB_NAME'));"
```

- Expected output: `dry_goods_db` if the environment variable is set.

## 4) API endpoints

Base URL for local testing:

```text
http://localhost/MobApp-midEXAM/backend/api/dry_goods.php
```

### GET all products
```bash
curl -i http://localhost/MobApp-midEXAM/backend/api/dry_goods.php
```

Expected response:

```json
{
  "success": true,
  "message": "Products retrieved successfully.",
  "data": [
    {
      "id": 1,
      "product_name": "Premium Rice (5kg)",
      "category": "Rice",
      "quantity": "8.50",
      "unit": "bag",
      "price": "245.00",
      "supplier": "Metro Food Supply",
      "description": "Premium quality rice packaged in a 5 kg bag for daily family use."
    }
  ]
}
```

How to verify:
- Confirm status code is `200`.
- Confirm `Content-Type` is `application/json; charset=utf-8`.

### GET one product
```bash
curl -i "http://localhost/MobApp-midEXAM/backend/api/dry_goods.php?id=1"
```

Expected result:
- `200` when the record exists.
- `404` when the record is missing.

How to verify:
- Check the HTTP status code and response body.

### POST create product
```bash
curl -i -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "Brown Rice",
    "category": "Rice",
    "quantity": 12.5,
    "unit": "bag",
    "price": 255.00,
    "supplier": "Local Farmers Co.",
    "description": "Healthy brown rice for everyday meals."
  }' \
  "http://localhost/MobApp-midEXAM/backend/api/dry_goods.php"
```

Expected response:

```json
{
  "success": true,
  "message": "Product created successfully.",
  "data": {
    "id": 16,
    "product_name": "Brown Rice",
    "category": "Rice",
    "quantity": "12.50",
    "unit": "bag",
    "price": "255.00",
    "supplier": "Local Farmers Co.",
    "description": "Healthy brown rice for everyday meals."
  }
}
```

How to verify:
- Confirm status code is `201`.
- Confirm the new record appears in phpMyAdmin.

### PUT update product
```bash
curl -i -X PUT \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "Brown Rice",
    "category": "Rice",
    "quantity": 14.00,
    "unit": "bag",
    "price": 260.00,
    "supplier": "Local Farmers Co.",
    "description": "Updated brown rice stock value."
  }' \
  "http://localhost/MobApp-midEXAM/backend/api/dry_goods.php?id=16"
```

Expected result:
- `200` with updated record data.

How to verify:
- Retrieve the product again and inspect the new value.

### DELETE product
```bash
curl -i -X DELETE "http://localhost/MobApp-midEXAM/backend/api/dry_goods.php?id=16"
```

Expected result:
- `200` when the record exists.
- `404` when it does not.

How to verify:
- Confirm the record is removed from phpMyAdmin.

## 5) Method override support
Some servers or proxies block `PUT` and `DELETE`. The API supports this fallback:

```bash
curl -i -X POST \
  -H "Content-Type: application/json" \
  -H "X-HTTP-Method-Override: PUT" \
  -d '{
    "product_name": "Updated Rice",
    "category": "Rice",
    "quantity": 20,
    "unit": "bag",
    "price": 270.00,
    "supplier": "Supplier A",
    "description": "This was sent with an override header."
  }' \
  "http://localhost/MobApp-midEXAM/backend/api/dry_goods.php?id=1"
```

Why this is needed:
- Some shared hosting and gateways do not allow real `PUT` or `DELETE` requests from browsers or some clients.
- The server reads `X-HTTP-Method-Override` and treats it as the actual method.

How to verify:
- Confirm the request updates the record even though the HTTP method used was `POST`.

## 6) Browser testing
Open these URLs directly in the browser:

- List all: `http://localhost/MobApp-midEXAM/backend/api/dry_goods.php`
- One item: `http://localhost/MobApp-midEXAM/backend/api/dry_goods.php?id=1`

For create/edit/delete, use Postman, Thunder Client, or `curl` because browsers do not make raw `PUT` and `DELETE` requests easily.

How to verify:
- The browser displays a valid JSON document for `GET` requests.

## 7) CORS explanation
Basic CORS headers are included so the API can be tested from a browser if needed:

```php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-HTTP-Method-Override');
```

This is only needed when a browser page calls the API from another origin. In a normal Flutter app running on the same local app or same domain, it is usually not required, but the headers are harmless and useful for browser testing.

How to verify:
- Open the browser developer tools network tab.
- If you call the API from a browser-based client, check if the response includes `Access-Control-Allow-*` headers.

## 8) Production deployment checklist
1. Upload the project files to the VPS.
2. Install Apache or Nginx and PHP 8.
3. Install `pdo_mysql`, `mbstring`, and `json` extensions.
4. Import the SQL file into MariaDB/MySQL.
5. Create a least-privilege database user.
6. Set environment variables or a server-side config file.
7. Ensure the web root points to the API folder.
8. Enable HTTPS with Let's Encrypt.
9. Update the Flutter app to use the HTTPS domain.

How to verify:
- Test the live URL from another device using:

```bash
curl -i https://YOURNAME.duckdns.org/api/dry_goods.php
```

Expected result: a successful JSON response from the live server.

## 9) Common error expected responses
- `400`: malformed or missing request body, bad ID format
- `404`: product id not found
- `405`: unsupported method
- `422`: validation error
- `500`: server or database error

Example validation error response:

```json
{
  "success": false,
  "message": "Please correct the highlighted fields.",
  "errors": {
    "quantity": "Quantity must be a number greater than or equal to 0."
  }
}
```

How to verify:
- Send invalid data and confirm the API returns `422` with a proper error envelope.

## 10) Final local test command set
Use this quick set to confirm the API works:

```bash
curl -i http://localhost/MobApp-midEXAM/backend/api/dry_goods.php
curl -i "http://localhost/MobApp-midEXAM/backend/api/dry_goods.php?id=1"
curl -i -X POST -H "Content-Type: application/json" -d '{"product_name":"Test Product","category":"Rice","quantity":10,"unit":"kg","price":150}' "http://localhost/MobApp-midEXAM/backend/api/dry_goods.php"
curl -i -X PUT -H "Content-Type: application/json" -d '{"product_name":"Test Product","category":"Rice","quantity":12,"unit":"kg","price":160}' "http://localhost/MobApp-midEXAM/backend/api/dry_goods.php?id=1"
curl -i -X DELETE "http://localhost/MobApp-midEXAM/backend/api/dry_goods.php?id=1"
```

How to verify:
- Each command should return a valid JSON envelope and the correct HTTP status code.
- If any command fails, verify Apache is running, the database exists, and `db.local.php` matches the local credentials.

CREATE DATABASE IF NOT EXISTS dry_goods_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE dry_goods_db;

DROP TABLE IF EXISTS dry_goods;

CREATE TABLE dry_goods (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    quantity DECIMAL(10,2) NOT NULL DEFAULT 0,
    unit VARCHAR(20) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    supplier VARCHAR(100) NULL,
    description TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO dry_goods (product_name, category, quantity, unit, price, supplier, description) VALUES
('Premium Rice (5kg)', 'Rice', 8.50, 'bag', 245.00, 'Metro Food Supply', 'Premium quality rice packaged in a 5 kg bag for daily family use.'),
('White Sugar', 'Sugar', 12.00, 'kg', 68.50, 'City Grain Traders', 'Fine white sugar for household and baking needs.'),
('All-Purpose Flour', 'Flour', 9.25, 'kg', 75.00, 'Bahay Pasalubong', 'Soft wheat flour for bread, cakes, and pastries.'),
('Instant Noodles', 'Noodles', 26.00, 'pack', 18.50, 'Island Market Co.', 'Convenient instant noodles for quick meals.'),
('Arabica Coffee Beans', 'Coffee', 15.50, 'kg', 420.00, 'Mountain Brew Supply', 'Roasted Arabica beans with a smooth, balanced flavor.'),
('Pasta Elbow', 'Pasta', 20.00, 'pack', 32.00, 'Golden Harvest Foods', 'Elbow pasta suitable for soups, salads, and baked dishes.'),
('Butter Cookies', 'Biscuits', 31.00, 'box', 52.00, 'Sweet Crumb Foods', 'Crunchy butter cookies packed in retail boxes.'),
('Canned Sardines', 'Canned Goods', 17.00, 'can', 25.00, 'Coastal Food Mart', 'Ready-to-eat sardines in tomato sauce.'),
('Canned Tuna', 'Canned Goods', 7.50, 'can', 39.00, 'Harbor Fresh Foods', 'High-protein tuna canned for quick meals and sandwiches.'),
('Corned Beef', 'Canned Goods', 9.00, 'can', 95.00, 'Prime Pantry Goods', 'Fully cooked corned beef ideal for breakfast or lunch.'),
('Whole Wheat Pasta', 'Pasta', 11.75, 'pack', 44.50, 'Healthy Grain Depot', 'Whole wheat pasta with more fiber and a nutty taste.'),
('Brown Sugar', 'Sugar', 6.25, 'kg', 72.00, 'South Valley Supply', 'Mildly sweet brown sugar often used for desserts and drinks.'),
('Premium Jasmine Rice', 'Rice', 14.00, 'sack', 1180.00, 'Luzon Rice Traders', 'Aromatic jasmine rice suitable for special family meals.'),
('Lucky Me Pancit Canton', 'Noodles', 5.00, 'pack', 21.00, 'Metro Food Supply', 'Popular stir-fry noodles for busy households.'),
('Tomato Sauce', 'Canned Goods', 22.00, 'bottle', 58.00, 'Bayan Food Distributors', 'Classic tomato sauce for pasta, stews, and sauces.');

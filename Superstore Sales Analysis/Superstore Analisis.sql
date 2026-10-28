
-- ============================================================
-- PROJECT : SUPERSTORE SALES ANALYSIS
-- TOOL    : GOOGLE BIGQUERY
-- DATASET : superstore-512822.superstore.penjualan
-- ============================================================


-- ============================================================
-- 1. DATA EXPLORATION
-- ============================================================

-- 1.1 Menampilkan Sampel Data
SELECT *
FROM `superstore-512822.superstore.penjualan`
LIMIT 30;


-- 1.2 Memeriksa Jumlah Data dan Periode Penjualan
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT `Order ID`) AS total_transactions,
    MIN(`Order Date`) AS first_order_date,
    MAX(`Order Date`) AS last_order_date
FROM `superstore-512822.superstore.penjualan`;


-- ============================================================
-- 2. DATA QUALITY CHECK
-- ============================================================

-- 2.1 Memeriksa Data Kosong
SELECT
    COUNTIF(`Order ID` IS NULL) AS missing_order_id,
    COUNTIF(`Order Date` IS NULL) AS missing_order_date,
    COUNTIF(`Customer ID` IS NULL) AS missing_customer_id,
    COUNTIF(`Product ID` IS NULL) AS missing_product_id,
    COUNTIF(Category IS NULL) AS missing_category,
    COUNTIF(`Sub-Category` IS NULL) AS missing_sub_category,
    COUNTIF(Sales IS NULL) AS missing_sales,
    COUNTIF(Quantity IS NULL) AS missing_quantity,
    COUNTIF(Discount IS NULL) AS missing_discount,
    COUNTIF(Profit IS NULL) AS missing_profit
FROM `superstore-512822.superstore.penjualan`;


-- 2.2 Memeriksa Baris Duplikat
SELECT
    *,
    COUNT(*) AS duplicate_count
FROM `superstore-512822.superstore.penjualan`
GROUP BY ALL
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- ============================================================
-- 3. SALES PERFORMANCE ANALYSIS
-- ============================================================

-- 3.1 Ringkasan KPI Utama
SELECT
    COUNT(DISTINCT `Order ID`) AS total_transactions,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND(AVG(Discount), 4) AS average_discount
FROM `superstore-512822.superstore.penjualan`;


-- 3.2 Tren Penjualan dan Profit Bulanan
SELECT
    DATE_TRUNC(`Order Date`, MONTH) AS month,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit
FROM `superstore-512822.superstore.penjualan`
GROUP BY month
ORDER BY month;


-- 3.3 Kinerja Penjualan Berdasarkan Kategori dan Subkategori
SELECT
    Category AS category,
    `Sub-Category` AS sub_category,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit
FROM `superstore-512822.superstore.penjualan`
GROUP BY category, sub_category
ORDER BY total_sales DESC;


-- 3.4 Kinerja Penjualan Berdasarkan Wilayah
SELECT
    Region AS region,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit
FROM `superstore-512822.superstore.penjualan`
GROUP BY region
ORDER BY total_sales DESC;


-- 3.5 Kinerja Penjualan Berdasarkan Segmen Pelanggan
SELECT
    Segment AS segment,
    COUNT(DISTINCT `Order ID`) AS total_transactions,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit
FROM `superstore-512822.superstore.penjualan`
GROUP BY segment
ORDER BY total_profit DESC;


-- 3.6 Top 5 Kota Berdasarkan Profit
SELECT
    City AS city,
    ROUND(SUM(Profit), 2) AS total_profit
FROM `superstore-512822.superstore.penjualan`
GROUP BY city
ORDER BY total_profit DESC
LIMIT 5;


-- ============================================================
-- 4. PROFITABILITY ANALYSIS
-- ============================================================

-- 4.1 Top 10 Produk dengan Profit Terendah
SELECT
    `Product Name` AS product_name,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit
FROM `superstore-512822.superstore.penjualan`
GROUP BY product_name
HAVING SUM(Profit) < 0
ORDER BY total_profit ASC
LIMIT 10;


-- 4.2 Top 5 Produk Paling Menguntungkan
SELECT
    `Product Name` AS product_name,
    Category AS category,
    `Sub-Category` AS sub_category,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit
FROM `superstore-512822.superstore.penjualan`
GROUP BY product_name, category, sub_category
ORDER BY total_profit DESC
LIMIT 5;


-- 4.3 Analisis Diskon terhadap Profit
SELECT
    Discount AS discount,
    COUNT(*) AS total_rows,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND(AVG(Profit), 2) AS average_profit_per_row,
    ROUND(
        SAFE_DIVIDE(SUM(Profit), SUM(Sales)) * 100,
        2
    ) AS profit_margin_percentage
FROM `superstore-512822.superstore.penjualan`
GROUP BY discount
ORDER BY discount;


-- 4.4 Menghitung Jumlah Pesanan dengan Profit Negatif
WITH order_profit AS (
    SELECT
        `Order ID` AS order_id,
        SUM(Profit) AS total_profit
    FROM `superstore-512822.superstore.penjualan`
    WHERE `Order ID` IS NOT NULL
    GROUP BY order_id
)
SELECT
    COUNTIF(total_profit < 0) AS loss_making_orders
FROM order_profit;


-- ============================================================
-- 5. INVESTIGATING THE LOWEST-PROFIT MONTH
-- ============================================================

-- 5.1 Menemukan Bulan dengan Profit Terendah
WITH monthly_profit AS (
    SELECT
        DATE_TRUNC(`Order Date`, MONTH) AS month,
        SUM(Profit) AS total_profit
    FROM `superstore-512822.superstore.penjualan`
    GROUP BY month
)
SELECT
    month,
    ROUND(total_profit, 2) AS total_profit
FROM monthly_profit
ORDER BY total_profit ASC
LIMIT 1;


-- 5.2 Menemukan Wilayah dengan Profit Terendah
-- pada Bulan dengan Profit Terendah
WITH monthly_profit AS (
    SELECT
        DATE_TRUNC(`Order Date`, MONTH) AS month,
        SUM(Profit) AS total_profit
    FROM `superstore-512822.superstore.penjualan`
    GROUP BY month
),
lowest_month AS (
    SELECT month
    FROM monthly_profit
    ORDER BY total_profit ASC
    LIMIT 1
)
SELECT
    p.Region AS region,
    ROUND(SUM(p.Profit), 2) AS total_profit
FROM `superstore-512822.superstore.penjualan` AS p
JOIN lowest_month AS m
    ON DATE_TRUNC(p.`Order Date`, MONTH) = m.month
GROUP BY region
ORDER BY total_profit ASC
LIMIT 1;


-- 5.3 Menemukan Produk dengan Profit Terendah
-- pada Bulan dan Wilayah Terpilih
WITH monthly_profit AS (
    SELECT
        DATE_TRUNC(`Order Date`, MONTH) AS month,
        SUM(Profit) AS total_profit
    FROM `superstore-512822.superstore.penjualan`
    GROUP BY month
),
lowest_month AS (
    SELECT month
    FROM monthly_profit
    ORDER BY total_profit ASC
    LIMIT 1
),
regional_profit AS (
    SELECT
        p.Region AS region,
        SUM(p.Profit) AS total_profit
    FROM `superstore-512822.superstore.penjualan` AS p
    JOIN lowest_month AS m
        ON DATE_TRUNC(p.`Order Date`, MONTH) = m.month
    GROUP BY region
),
lowest_region AS (
    SELECT region
    FROM regional_profit
    ORDER BY total_profit ASC
    LIMIT 1
)
SELECT
    p.`Product Name` AS product_name,
    ROUND(SUM(p.Profit), 2) AS total_profit
FROM `superstore-512822.superstore.penjualan` AS p
JOIN lowest_month AS m
    ON DATE_TRUNC(p.`Order Date`, MONTH) = m.month
JOIN lowest_region AS r
    ON p.Region = r.region
GROUP BY product_name
ORDER BY total_profit ASC
LIMIT 1;


-- ============================================================
-- 6. CREATE VIEW FOR LOOKER STUDIO
-- ============================================================

CREATE OR REPLACE VIEW
    `superstore-512822.superstore.penjualan_looker` AS
SELECT
    `Row ID` AS row_id,
    `Order ID` AS order_id,
    `Order Date` AS order_date,
    `Ship Date` AS ship_date,
    `Ship Mode` AS ship_mode,
    `Customer ID` AS customer_id,
    `Customer Name` AS customer_name,
    Segment AS segment,
    Country AS country,
    City AS city,
    State AS state,
    `Postal Code` AS postal_code,
    Region AS region,
    `Product ID` AS product_id,
    Category AS category,
    `Sub-Category` AS sub_category,
    `Product Name` AS product_name,
    Sales AS sales,
    Quantity AS quantity,
    Discount AS discount,
    Profit AS profit
FROM `superstore-512822.superstore.penjualan`;

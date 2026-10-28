
-- =========================================================
-- PROJECT: COFFEE SHOP SALES ANALYSIS
-- TOOL: GOOGLE BIGQUERY
-- =========================================================


-- =========================================================
-- 1. DATA EXPLORATION
-- =========================================================

-- 1.1 Melihat Sampel Data
SELECT *
FROM `coffee-sales-512521.coffee_sales.transaksi`
LIMIT 10;


-- 1.2 Memeriksa Jumlah Baris dan Periode Data
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT transaction_id) AS unique_transactions,
    MIN(transaction_date) AS first_transaction_date,
    MAX(transaction_date) AS last_transaction_date
FROM `coffee-sales-512521.coffee_sales.transaksi`;


-- =========================================================
-- 2. DATA QUALITY CHECK
-- =========================================================

-- 2.1 Memeriksa Data Kosong
SELECT
    COUNTIF(transaction_id IS NULL) AS missing_transaction_id,
    COUNTIF(transaction_date IS NULL) AS missing_transaction_date,
    COUNTIF(transaction_time IS NULL) AS missing_transaction_time,
    COUNTIF(transaction_qty IS NULL) AS missing_transaction_qty,
    COUNTIF(store_id IS NULL) AS missing_store_id,
    COUNTIF(store_location IS NULL) AS missing_store_location,
    COUNTIF(product_id IS NULL) AS missing_product_id,
    COUNTIF(unit_price IS NULL) AS missing_unit_price,
    COUNTIF(product_category IS NULL) AS missing_product_category,
    COUNTIF(product_type IS NULL) AS missing_product_type,
    COUNTIF(product_detail IS NULL) AS missing_product_detail
FROM `coffee-sales-512521.coffee_sales.transaksi`;


-- 2.2 Memeriksa Baris Duplikat
SELECT
    *,
    COUNT(*) AS duplicate_count
FROM `coffee-sales-512521.coffee_sales.transaksi`
GROUP BY ALL
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- =========================================================
-- 3. SALES PERFORMANCE ANALYSIS
-- =========================================================

-- 3.1 Tren Pendapatan Bulanan
SELECT
    DATE_TRUNC(transaction_date, MONTH) AS month,
    SUM(transaction_qty * unit_price) AS revenue
FROM `coffee-sales-512521.coffee_sales.transaksi`
GROUP BY month
ORDER BY month;


-- 3.2 Tren Pendapatan Harian
SELECT
    transaction_date,
    SUM(transaction_qty * unit_price) AS revenue
FROM `coffee-sales-512521.coffee_sales.transaksi`
GROUP BY transaction_date
ORDER BY transaction_date;


-- 3.3 Kinerja Penjualan per Lokasi Toko
SELECT
    store_location,
    SUM(transaction_qty) AS quantity_sold,
    SUM(transaction_qty * unit_price) AS revenue
FROM `coffee-sales-512521.coffee_sales.transaksi`
GROUP BY store_location
ORDER BY revenue DESC;


-- 3.4 Top 5 Kategori Produk Berdasarkan Pendapatan
SELECT
    product_category,
    SUM(transaction_qty) AS quantity_sold,
    SUM(transaction_qty * unit_price) AS revenue
FROM `coffee-sales-512521.coffee_sales.transaksi`
GROUP BY product_category
ORDER BY revenue DESC
LIMIT 5;


-- 3.5 Top 5 Tipe Produk Berdasarkan Pendapatan
SELECT
    product_type,
    SUM(transaction_qty) AS quantity_sold,
    SUM(transaction_qty * unit_price) AS revenue
FROM `coffee-sales-512521.coffee_sales.transaksi`
GROUP BY product_type
ORDER BY revenue DESC
LIMIT 5;


-- 3.6 Top 10 Produk Berdasarkan Pendapatan
SELECT
    product_detail,
    SUM(transaction_qty) AS quantity_sold,
    SUM(transaction_qty * unit_price) AS revenue
FROM `coffee-sales-512521.coffee_sales.transaksi`
GROUP BY product_detail
ORDER BY revenue DESC
LIMIT 10;


-- 3.7 Top 5 Produk Terlaris Berdasarkan Kuantitas
SELECT
    product_detail,
    SUM(transaction_qty) AS quantity_sold
FROM `coffee-sales-512521.coffee_sales.transaksi`
GROUP BY product_detail
ORDER BY quantity_sold DESC
LIMIT 5;


-- 3.8 Top 5 Produk Terlaris dalam Kategori Coffee
SELECT
    product_detail,
    SUM(transaction_qty) AS quantity_sold,
    SUM(transaction_qty * unit_price) AS revenue
FROM `coffee-sales-512521.coffee_sales.transaksi`
WHERE product_category = 'Coffee'
GROUP BY product_detail
ORDER BY quantity_sold DESC
LIMIT 5;


-- 3.9 Waktu Transaksi Tersibuk
SELECT
    EXTRACT(HOUR FROM transaction_time) AS transaction_hour,
    COUNT(DISTINCT transaction_id) AS total_transactions
FROM `coffee-sales-512521.coffee_sales.transaksi`
GROUP BY transaction_hour
ORDER BY total_transactions DESC;


-- 3.10 Hari dengan Transaksi Terbanyak
SELECT
    FORMAT_DATE('%A', transaction_date) AS day_name,
    COUNT(DISTINCT transaction_id) AS total_transactions
FROM `coffee-sales-512521.coffee_sales.transaksi`
GROUP BY EXTRACT(DAYOFWEEK FROM transaction_date), day_name
ORDER BY EXTRACT(DAYOFWEEK FROM transaction_date);


-- =========================================================
-- 4. KEY PERFORMANCE INDICATORS (KPI)
-- =========================================================

-- 4.1 Ringkasan KPI Penjualan
SELECT
    SUM(transaction_qty * unit_price) AS total_revenue,
    COUNT(DISTINCT transaction_id) AS total_transactions,
    SUM(transaction_qty) AS quantity_sold,
    COUNT(DISTINCT product_id) AS total_products
FROM `coffee-sales-512521.coffee_sales.transaksi`;


-- 4.2 Rata-rata Nilai per Transaksi
WITH revenue_per_transaction AS (
    SELECT
        transaction_id,
        SUM(transaction_qty * unit_price) AS transaction_revenue
    FROM `coffee-sales-512521.coffee_sales.transaksi`
    WHERE transaction_id IS NOT NULL
    GROUP BY transaction_id
)
SELECT
    COUNT(*) AS total_transactions,
    ROUND(AVG(transaction_revenue), 2) AS average_transaction_value
FROM revenue_per_transaction;


-- 4.3 Tren Pendapatan Bulanan per Kategori
SELECT
    DATE_TRUNC(transaction_date, MONTH) AS month,
    product_category,
    SUM(transaction_qty * unit_price) AS revenue
FROM `coffee-sales-512521.coffee_sales.transaksi`
GROUP BY month, product_category
ORDER BY month, revenue DESC;


-- 4.4 Kontribusi Pendapatan per Kategori
WITH category_revenue AS (
    SELECT
        product_category,
        SUM(transaction_qty * unit_price) AS revenue
    FROM `coffee-sales-512521.coffee_sales.transaksi`
    GROUP BY product_category
)
SELECT
    product_category,
    revenue,
    ROUND(
        SAFE_DIVIDE(revenue, SUM(revenue) OVER ()) * 100,
        2
    ) AS revenue_percentage
FROM category_revenue
ORDER BY revenue DESC;

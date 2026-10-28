# mengambil kolom order id dari table orders di dataset toko_peralatan_dapur

select order_id
from `toko_peralatan_dapur.orders`;

#No 1
#menghitung total dan rata-rata shipping fee
select
  SUM(shipping_fee) as total_shipping_fee,
  AVG(shipping_fee) as rata_rata_shipping_fee
from `toko_peralatan_dapur.orders`
where extract(year FROM sales_date) = 2025;

#No 2
#5 produk dengan unit terjual terbanyak dari pesanan yang completed vs top 5 produk berdasarkan revenue
# - Top 5 Produk by Unit Terjual
select product_name,
  SUM(quantity) as total_unit
  from `toko_peralatan_dapur.orders`
  where status_clean='complete'
  group by product_name
  order by total_unit DESC
limit 5;

# - Top 5 Produk by Total Revenue
select product_name,
  SUM(total_sales) as total_revenue
  from `toko_peralatan_dapur.orders`
  where status_clean='complete'
  group by product_name
  order by total_revenue DESC
limit 5;

#No 3
#Jumlah pesanan dan total revenue completed selama Q4 (Oktober-Desember) 2025
select
count(distinct order_id) as jumlah_pesanan,
sum(total_sales) as total_revenue
from `toko_peralatan_dapur.orders`
where status_clean='complete' and sales_date between '2025-10-01' and '2025-12-31';

#No 4
# Kota Mana yang rata-rata ongkosnya paling Mahas
# Kota Mana yang rata-rata paling murah
# Selisih ongkos paling mahal dengan ongkos paling mahal
with city_shipping as (
  select
  city_clean,AVG(shipping_fee) as rata_rata_shipping_fee
  from `toko_peralatan_dapur.orders`
  where city_clean is not null
  group by city_clean
)
select
  (select city_clean from city_shipping order by rata_rata_shipping_fee desc limit 1) as max_avg_shipping_fee,
  (select max(rata_rata_shipping_fee) from city_shipping) as max_shipping_fee,
  (select city_clean from city_shipping order by rata_rata_shipping_fee asc limit 1) as min_avg_shipping_fee,
  (select min(rata_rata_shipping_fee) from city_shipping) as min_shipping_fee,
  (select max(rata_rata_shipping_fee)-min(rata_rata_shipping_fee) from city_shipping) as shipping_diffrence;

#No 5
# Besar uang dari status refund & persen terhadap gross sales setahun
select
 sum(case when status_clean='refund' then total_sales else 0 end) as total_refund,
 sum(total_sales) as gross_sales,
 round(
  sum(case when status_clean='refund' then total_sales else 0 end)
  / sum(total_sales) * 100,2
 ) as persen_refund
from `toko_peralatan_dapur.orders`;

#No 6
# 5 Top Product dengan avg qty tertinggi,dgn syarat min 50% completed
select product_name,
count(distinct order_id) as jumlah_pesanan,
avg(quantity) as rata_rata_quantity
from `toko_peralatan_dapur.orders`
where status_clean='complete'
group by product_name
having count(distinct order_id) >= 50
order by rata_rata_quantity desc
limit 5;

#No 7
#dari 3 kategori, bulan apa yang memiliki revenue completed paling tinggi
with per_bulan as (
  select
    category_clean,
    format_date('%Y-%m', sales_date) as bulan,
    sum(total_sales) as revenue
  from `toko_peralatan_dapur.orders`
  where status_clean ='complete'
  group by category_clean, bulan
),
ranked as (
  select *,
   row_number() over (partition by category_clean order by revenue desc) as rv
  from per_bulan
)
select category_clean, bulan ,revenue
from ranked
where rv=1;

# No 8
#dari 57 product, banyak product yang menyumbang kan 80% dari total revenue completed
with revenue_per_product as (
  select product_name, sum(total_sales) as revenue
  from `toko_peralatan_dapur.orders`
  where status_clean='complete'
  group by product_name
),
cum as (
  select
  product_name, revenue,
  sum(revenue) over (order by revenue desc) as cum_revenue,
  sum(revenue) over () as total_revenue,
  row_number() over (order by revenue desc) as rank_product
  from revenue_per_product
)
select min(rank_product) as jumlah_penduduk_80_persen
from cum
where cum_revenue >=0.8 * total_revenue;

#No 9
WITH pelanggan_valid AS (
  SELECT customer_name_clean
  FROM `toko_peralatan_dapur.orders`
  WHERE status_clean= 'complete'
  GROUP BY customer_name_clean
  HAVING COUNT (DISTINCT order_id) > 5
),
tanggal_urut AS (
SELECT
  t.customer_name_clean,
  t.sales_date,
  LAG(t.sales_date) OVER (PARTITION BY t.customer_name_clean ORDER BY t.sales_date) AS tanggal_sebelumnya
FROM `toko_peralatan_dapur.orders` t
JOIN pelanggan_valid p ON t.customer_name_clean = p.customer_name_clean
WHERE t.status_clean= 'complete'
),
jeda AS (
SELECT customer_name_clean,
AVG(DATE_DIFF(sales_date, tanggal_sebelumnya, DAY)) AS avg_jeda_hari
FROM tanggal_urut
WHERE tanggal_sebelumnya IS NOT NULL
GROUP BY customer_name_clean
)
SELECT
(SELECT AVG(avg_jeda_hari) FROM jeda) AS rata_rata_jeda_keseluruhan,
(SELECT customer_name_clean FROM jeda ORDER BY avg_jeda_hari ASC LIMIT 1) AS pelanggan_jeda_tersingkat, (SELECT MIN(avg_jeda_hari) FROM jeda) AS jeda_tersingkat_hari;

#No 10
WITH per_produk AS (
    SELECT
        product_name,
        COUNTIF(status_clean = 'refund') AS jumlah_refund,
        COUNT(*) AS total_pesanan,
        SUM(CASE
                WHEN status_clean = 'refund' THEN total_sales
                ELSE 0
            END) AS revenue_refund,
        SAFE_DIVIDE(
            COUNTIF(status_clean = 'refund'),
            COUNT(*)
        ) AS refund_rate
    FROM `toko_peralatan_dapur.orders`
    GROUP BY product_name
)

SELECT
    product_name,
    refund_rate,
    revenue_refund,
    revenue_refund *
    GREATEST(refund_rate - 0.05, 0) / refund_rate
        AS potensi_revenue_terselamatkan
FROM per_produk
ORDER BY refund_rate DESC
LIMIT 1;


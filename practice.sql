--Rank films by total rental revenue within each category.
WITH film_revenue AS (
    SELECT
        c.category_id,
        c.name AS category_name,
        f.film_id,
        f.title,
        SUM(p.amount) AS total_revenue
    FROM film f
    JOIN film_category fc
        ON f.film_id = fc.film_id
    JOIN category c
        ON fc.category_id = c.category_id
    JOIN inventory i
        ON f.film_id = i.film_id
    JOIN rental r
        ON i.inventory_id = r.inventory_id
    JOIN payment p
        ON r.rental_id = p.rental_id
    GROUP BY
        c.category_id,
        c.name,
        f.film_id,
        f.title
)
SELECT
    category_id,
    category_name,
    film_id,
    title,
    total_revenue,
    RANK() OVER (
        PARTITION BY category_id
        ORDER BY total_revenue DESC
    ) AS revenue_rank
FROM film_revenue
ORDER BY category_name, revenue_rank;

--Q2.Find the top 3 customers per city based on total rental amount
WITH customer_revenue AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        ct.city_id,
        ct.city,
        SUM(p.amount) AS total_rental_amount
    FROM customer c
    JOIN address ad
        ON c.address_id = ad.address_id
    JOIN city ct
        ON ad.city_id = ct.city_id
    JOIN payment p
        ON c.customer_id = p.customer_id
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name,
        ct.city_id,
        ct.city
),
ranked_customers AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY city
            ORDER BY total_rental_amount DESC
        ) AS city_rank
    FROM customer_revenue
)
SELECT
    customer_id,
    first_name,
    last_name,
    city,
    total_rental_amount,
    city_rank
FROM ranked_customers
WHERE city_rank <= 3
ORDER BY city, city_rank;

--Q3.For each customer, show their first and last rental date using window functions
-- Q3: For each customer, show their first and last rental date using window functions

SELECT DISTINCT
    c.customer_id,
    c.first_name,
    c.last_name,
    MIN(r.rental_date) OVER (PARTITION BY c.customer_id) AS first_rental_date,
    MAX(r.rental_date) OVER (PARTITION BY c.customer_id) AS last_rental_date
FROM customer c
JOIN rental r
    ON c.customer_id = r.customer_id
ORDER BY c.customer_id;


--Q4.Find customers who rented more films than the average customer.
select 
c.customer_id,
c.first_name,
c.last_name,
count(r.rental_id) as total
from customer c
join rental r on c.customer_id=r.customer_id
group by c.customer_id,c.first_name,c.last_name
having count(rental_id)>(select avg(total_rent) from (select(count(rental_id)) as total_rent 
from rental r join customer c on r.customer_id=c.customer_id group by c.customer_id,c.first_name,c.last_name) sub)ORDER BY
total desc;

-- Q4: Find customers who rented more films than the average customer

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(r.rental_id) AS total_rentals
FROM customer c
JOIN rental r
    ON c.customer_id = r.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
HAVING COUNT(r.rental_id) >
(
    SELECT AVG(customer_rentals)
    FROM (
        SELECT COUNT(*) AS customer_rentals
        FROM rental
        GROUP BY customer_id
    ) sub
)
ORDER BY total_rentals DESC;

--Q5.Find films whose rental revenue is above category average.


with film_revenue as(
    SELECT
        c.category_id,
        c.name AS category_name,
        f.film_id,
        f.title,
        SUM(p.amount) AS total_revenue
    FROM film f
    JOIN film_category fc
        ON f.film_id = fc.film_id
    JOIN category c
        ON fc.category_id = c.category_id
    JOIN inventory i
        ON f.film_id = i.film_id
    JOIN rental r
        ON i.inventory_id = r.inventory_id
    JOIN payment p
        ON r.rental_id = p.rental_id
    GROUP BY
        c.category_id,
        c.name,
        f.film_id,
        f.title
)
SELECT
    category_name,
    film_id,
    title,
    total_revenue
FROM (
    SELECT
     *,
        AVG(total_revenue) OVER (
            PARTITION BY category_id
        ) AS category_avg_revenue
    FROM film_revenue
) t
WHERE total_revenue > category_avg_revenue
ORDER BY category_name, total_revenue DESC;

--QFind customers who have rented all available categories.
select c.customer_id,
c.first_name,
c.last_name,
count(DISTINCT cg.name) as total_cat
from customer c
join rental r on c.customer_id=r.customer_id
join inventory i on r.inventory_id=i.inventory_id
join film_category fc on i.film_id=fc.film_id
join category cg on fc.category_id=cg.category_id
group by c.customer_id,c.first_name,c.last_name
having count(DISTINCT cg.name)=(select count(DISTINCT cg.name) from category cg);

---**WINDOW FUNCTION**
SELECT customer_id, SUM(amount)
FROM payment
GROUP BY customer_id;
/* When we do group by it is reducing the 
rows means it is actually redcuing the individula payment row*/

--1.Row No
--Number each payment made by each customer
select 
customer_id,
payment_id,
amount,
ROW_NUMBER()over(partition by customer_id
order by payment_id) as Rn
from payment;
/* This query is giving us the each payment made by each customer which are order according to the payment_id
and since it is partition by customer_id we will get the all payments of evry customer and we will the unique row number*/

--Find the latest payment per customer

WITH ranked_payments AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY payment_date DESC
           ) AS rn
    FROM payment
)
SELECT *
FROM ranked_payments
WHERE rn = 1;

WITH max_payment AS (
    SELECT
        customer_id,
        MAX(payment_date) AS latest_payment
    FROM payment
    GROUP BY customer_id
)
SELECT p.*
FROM payment p
JOIN max_payment m
ON p.customer_id = m.customer_id
AND p.payment_date = m.latest_payment;

--Find top 3 customers per city by total payment.
with top_customers as(
    select 
    c.customer_id,
    ct.city,
    sum(p.amount) as total_amt
    from customer c
    join address a on c.address_id=a.address_id
    join city ct on a.city_id=ct.city_id
    join payment p on c.customer_id=p.customer_id
    group by c.customer_id,ct.city
),
ranked as(
SELECT
*,
DENSE_RANK()over(
    PARTITION BY city
    ORDER BY total_amt desc
) as rn
from top_customers
)

select * FROM
ranked where rn<=3;

--RANK
--Rank customers by total payment.
select 
customer_id,
sum(amount) as total_amt,
RANK()over(order by sum(amount) desc) as RANK
from payment
group by customer_id;
--------
with custom as(
    select customer_id,
    sum(amount) as total_amt
    from payment
    group by customer_id
),
rank as(
    select *,
    Rank()over(order by total_amt) as rn
    from custom
)
select * from rank;

----
--Rank films by rental count within category.
with rental_count as(
    select cg.name as cname,
    f.title,
    count(r.rental_id) as rent_cnt
    from category cg join
    film_category fc on cg.category_id=fc.category_id
    join film f on fc.film_id=f.film_id
    join inventory i on fc.film_id=i.film_id
    join rental r on i.inventory_id=r.inventory_id
    group by cg.name,f.title
),
ranked as (
    select *,
    RANK()OVER(PARTITION BY cname  order by rent_cnt desc) as rn
    from rental_count
)
select * from ranked;

--Find top revenue film per category.
with top_revenue as(
    select 
    f.title,
    cg.name as cname,
    sum(p.amount) as total_amt
    from film f join film_category fc
    on f.film_id=fc.film_id
    join category cg on fc.category_id=cg.category_id
    join inventory i on f.film_id=i.film_id
    join rental r on i.inventory_id=r.inventory_id
    join payment p on r.rental_id=p.rental_id
    group by cg.category_id,cg.name,f.film_id,f.title
),
ranked as (
    select *,
    Rank()over(PARTITION BY cname order by total_amt desc) as rn
    from top_revenue
)
select * from ranked 
where rn=1;


/*FUNCTION 3: DENSE_RANK()
 Difference from RANK

No gaps in ranking*/

--Rank customers by payment (no gaps).
with custom as(
    select customer_id,
    sum(amount) as total_amt
    from payment
    group by customer_id
),
rank as(
    select *,
    DENSE_RANK()over(order by total_amt desc) as rn
    from custom
)
select * from rank;

---Top 3 revenue customers without skipping ranks.
--since here we are not foced for uniquness we can use dense rank

WITH ranked AS (
    SELECT
        customer_id,
        SUM(amount) AS total_amount,
        DENSE_RANK() OVER (ORDER BY SUM(amount) DESC) AS drnk
    FROM payment
    GROUP BY customer_id
)
SELECT *
FROM ranked
WHERE drnk <= 3;

--Rank categories by revenue without gaps.
with ranked_categories as(
    select cg.name as cname,
    sum(p.amount)as total_amt
    from category cg JOIN
    film_category fc on cg.category_id=fc.category_id
    join inventory i on fc.film_id=i.film_id
    join rental r on i.inventory_id=r.inventory_id
    join payment p on r.rental_id=p.rental_id
    group by cg.name,cg.category_id

),
ranked as(
    select *,
    DENSE_RANK()over(order by total_amt desc) as rn
    from ranked_categories
)
select * from ranked;

--Running total revenue.
SELECT
    payment_date,
    amount,
    SUM(amount) OVER (ORDER BY payment_date) AS running_total
FROM payment;

--Customer-wise total shown on every row.
with cust_wise_total as(
    select c.first_name,c.last_name,
    c.customer_id,sum(p.amount) as total_amt
    from customer c join payment p
    on c.customer_id=p.customer_id
    group by c.customer_id
)
select * from cust_wise_total;

SELECT
    customer_id,
    amount,
    SUM(amount) OVER (PARTITION BY customer_id) AS customer_total
FROM payment;

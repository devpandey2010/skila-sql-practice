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

--Q.Find actors who have never appeared in a rented film.

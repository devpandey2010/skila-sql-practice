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

------------

--LEAD()

--Access previous row
--Previous payment amount per customer.
select customer_id,
payment_date,
amount,
LAG(amount)over(PARTITION BY customer_id order by payment_date) as prev_amt
from payment;

--Difference between current and previous payment.
select *,
amount-LAG(amount)over(PARTITION BY customer_id order by payment_date) as diff
from payment;

--Days gap between rentals per customer.
with dated_diff as(
    select
    customer_id,
    rental_date,
    Lag(rental_date)OVER(PARTITION BY customer_id order by rental_date) as previous_date
FROM rental
)
select *,DATEDIFF(rental_date,previous_date)as gap from dated_diff;

SELECT
    customer_id,
    rental_date,
    CAST(
        julianday(rental_date) -
        julianday(
            LAG(rental_date) OVER (
                PARTITION BY customer_id
                ORDER BY rental_date
            )
        ) AS INTEGER
    ) AS gap_days
FROM rental;


--Q.Top 3 films per category
with film_name as(
    select 
    cg.name as cname,
    cg.category_id,
    f.film_id,
    f.title,
    sum(p.amount) as amt
    from film f join film_category fc on f.film_id=fc.film_id
    join category cg on fc.category_id=cg.category_id
    join inventory i on fc.film_id=i.film_id
    join rental r on i.inventory_id=r.inventory_id
    join payment p on r.rental_id=p.rental_id
    group by cg.category_id,cg.name,f.film_id,f.title

),
 Ranked as
 (
    select *,
    ROW_NUMBER()OVER(PARTITION BY cname order by amt desc) as rn
    from film_name
 )
 select * from Ranked where rn<=3;

 --Q.Revenue contribution per category
 with contribution as(
    select 
    cg.category_id,
    cg.name as cname,
    sum(p.amount) as amt
    from category cg join film_category fc on cg.category_id=fc.category_id
    join inventory i on fc.film_id= i.film_id
    join rental r on i.inventory_id=r.inventory_id
    join payment p on r.rental_id=p.rental_id
    group by cg.category_id,cg.name
 ),
 Ranked as(
    select *,
    round(
    amt*100/sum(amt) over (),2) as rn
    from contribution
 )
 select * from ranked;

--Customer spending vs average
with customer_rent as 
(
    select c.customer_id as cid,
    c.first_name,
    c.last_name,
    sum(p.amount) as total_amt
    from customer c join payment p on c.customer_id=p.customer_id
    group by c.customer_id,c.first_name,c.last_name
),
Ranked as(
    select *,
    AVG(total_amt) over() as overall_avg
    from customer_rent
)
select *,
case
    when total_amt>overall_avg then "Above Average"
    when total_amt<overall_avg then "Below average"
    else "Average"
end as spending_category
from Ranked;

--Gap between rentals 
select customer_id,rental_date,
Lag(rental_date)over(partition by customer_id order by rental_date) as prev_day,
cast(
julianday(rental_date)-julianday(prev_day)as INTEGER) as
gap_days
from rental;

--Rank customers per store
WITH customer_spending AS (
    SELECT 
        c.store_id,
        c.customer_id,
        c.first_name,
        c.last_name,
        SUM(p.amount) AS total_spent
    FROM customer c
    JOIN payment p 
        ON c.customer_id = p.customer_id
    GROUP BY 
        c.store_id, 
        c.customer_id, 
        c.first_name, 
        c.last_name
)
SELECT *,
       RANK() OVER (
           PARTITION BY store_id 
           ORDER BY total_spent DESC
       ) AS store_rank
FROM customer_spending;


--Monthly running revenue

--Repeat rental detection

--Top actor by revenue
with top_revenue as(
    select a.actor_id,
    a.first_name,
    a.last_name,
    sum(p.amount) as amt 
    from actor a join film_actor fa on a.actor_id=fa.actor_id
    join inventory i on fa.film_id=i.film_id
    join rental r on i.inventory_id=r.inventory_id
    join payment p on r.rental_id=p.rental_id
    group by a.actor_id,a.first_name,a.last_name
),
Ranked as(
    select *,
    DENSE_RANK() over(order by amt desc) as rn
    from top_revenue
)
select * from Ranked where rn=1;
--Customer churn signal using LEAD

--Rank categories by store revenue
with rank_categories AS(
    select cg.category_id,
    cg.name,
    s.store_id,
    sum(p.amount) as amt
    from category cg join film_category fc on cg.category_id=fc.category_id
    join inventory i on fc.film_id=i.film_id
    join rental r on i.inventory_id=r.inventory_id
    join payment p on r.rental_id=p.rental_id
    join staff st on p.staff_id=st.staff_id
    join store s on st.store_id=s.store_id
    group by cg.category_id,cg.name,s.store_id
),
Ranked as(
    select *,
    DENSE_RANK() over(PARTITION BY store_id ORDER BY amt desc) as Rn
    from rank_categories
)
select * from Ranked;

--Revenue contribution % per category per store
WITH category_store_revenue AS (
    SELECT 
        s.store_id,
        cg.category_id,
        cg.name AS category_name,
        SUM(p.amount) AS category_revenue
    FROM category cg
    JOIN film_category fc ON cg.category_id = fc.category_id
    JOIN inventory i ON fc.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    JOIN payment p ON r.rental_id = p.rental_id
    JOIN staff st ON p.staff_id = st.staff_id
    JOIN store s ON st.store_id = s.store_id
    GROUP BY 
        s.store_id,
        cg.category_id,
        cg.name
),
final AS (
    SELECT *,
           SUM(category_revenue) OVER (PARTITION BY store_id) AS store_total_revenue
    FROM category_store_revenue
)
SELECT 
    store_id,
    category_id,
    category_name,
    category_revenue,
    ROUND(
        category_revenue * 100.0 / store_total_revenue, 2
    ) AS revenue_contribution_pct
FROM final
ORDER BY store_id, revenue_contribution_pct DESC;

--Top 80% revenue categories per store
WITH category_store_revenue AS (
    SELECT 
        s.store_id,
        cg.category_id,
        cg.name AS category_name,
        SUM(p.amount) AS category_revenue
    FROM category cg
    JOIN film_category fc ON cg.category_id = fc.category_id
    JOIN inventory i ON fc.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    JOIN payment p ON r.rental_id = p.rental_id
    JOIN staff st ON p.staff_id = st.staff_id
    JOIN store s ON st.store_id = s.store_id
    GROUP BY 
        s.store_id,
        cg.category_id,
        cg.name
),
final AS (
    SELECT *,
           SUM(category_revenue) OVER (PARTITION BY store_id) AS store_total_revenue
    FROM category_store_revenue
),
percentages as(
select * ,
Round(category_revenue * 100.0 / store_total_revenue, 2
    ) AS revenue_contribution_pct
FROM final
),
cumulative as(
    select *,
    sum(revenue_contribution_pct) over(partition by store_id order by revenue_contribution_pct desc)as cumulative_pct
    from percentages
)
select * from cumulative where cumulative_pct<=80;

--Customers with increasing spending trend
/* Give the customer whose spending trend is increasing*/
with trend AS(
    select c.customer_id,
    c.first_name,
    c.last_name,
    p.amount as amt
    from customer c join payment p on c.customer_id=p.customer_id
    group by c.customer_id,c.first_name,c.last_name
),
Revenue AS(
    select *,
    coalesce(Lag(amt)over(PARTITION BY customer_id),0)as prev_revenue
    from trend
),
Differences AS(
    select *,
    (
        prev_revenue-amt
    ) as diff
    from revenue
)
select *
from differences
where 
Not EXISTS(select 1
from differences where diff<0);

WITH ordered_payments AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        p.payment_date,
        p.amount,
        LAG(p.amount) OVER (
            PARTITION BY c.customer_id
            ORDER BY p.payment_date
        ) AS prev_amount
    FROM customer c
    JOIN payment p 
        ON c.customer_id = p.customer_id
),
diffs AS (
    SELECT *,
           amount - prev_amount AS diff
    FROM ordered_payments
)
SELECT DISTINCT
    customer_id,
    first_name,
    last_name
FROM diffs d
WHERE prev_amount IS NOT NULL
GROUP BY customer_id, first_name, last_name
HAVING MIN(diff) > 0;


--For each category, find the film contributing highest % of category revenue.
--Here we have to do three task 
--1.We have to find total revenue of each category....2.we have to find % contribution of each for their corresponding category
--3.We have to rank films on basis of % contribution then filter out te top film for each category

--Task 1
with payment_detail AS(
select c.category_id,c.name,f.film_id,f.title,sum(p.amount) as film_sum from category c join film_category fc 
on c.category_id=fc.category_id join film f on fc.film_id=f.film_id join 
inventory i on f.film_id=i.film_id join rental r on i.inventory_id=r.inventory_id
join payment p on r.rental_id=p.rental_id group by  c.category_id,c.name,f.film_id,f.title
),
revenue_contribution AS
(
    select *, film_sum*100/sum(film_sum)over(partition by category_id)as film_contribution from payment_detail
),
Ranked AS(
    select *,ROW_NUMBER() over(PARTITION BY category_id order by film_contribution desc) as rn from revenue_contribution
)
select * from ranked where rn=1;


--Find actors whose films generate more revenue than the average actor revenue.
 select a.actor_id,a.first_name,a.last_name,sum(p.amount) from actor a join film_actor fa on a.actor_id=fa.actor_id
    join inventory i on fa.film_id=i.film_id join rental r on i.inventory_id=r.inventory_id join payment p on
    r.rental_id=p.payment_id group by a.actor_id,a.first_name,a.last_name;
with actor_revenue AS(
    select a.actor_id,a.first_name,a.last_name,sum(p.amount) as total_revenue_per_actor from actor a join film_actor fa on a.actor_id=fa.actor_id
    join inventory i on fa.film_id=i.film_id join rental r on i.inventory_id=r.inventory_id join payment p on
    r.rental_id=p.payment_id group by a.actor_id,a.first_name,a.last_name)

    select * from actor_revenue where total_revenue_per_actor>(select avg(total_revenue_per_actor) from actor_revenue);

--Find customers whose average rental amount is higher than overall average.
/* Steps to solve
1.Go to every customer find out the average of each customer
2.Find the overall average of rental amount
3.List all the customer who have greater rental avg than overall avg

--------
--------

CORE CONCEPT--Aggregate functions inside HAVING work per group, not globally.
------
-------
*/
with customer_payment as(
Select
c.customer_id,
c.first_name,
c.last_name,
avg(p.amount) as cust_payment
from customer c
join rental r on c.customer_id=r.customer_id
join payment p on r.rental_id=p.rental_id
group by c.customer_id,c.first_name,c.last_name
)
select * from customer_payment
where cust_payment>
(
    select avg(amount) from payment 
)
order by cust_payment desc;

--Identify customers whose rental frequency increased over time.
/*This is a Question of TREND (INcreasing TREND) which is associated with time
The CORE LOGIC of Trend-Type Questions (MEMORIZE THIS)

To identify a trend, you must compare a current value with a previous value over time.

Everything else is just implementation.

🧠 Universal Trend-Solving Framework (Step-by-Step)

Whenever you see words like:

increasing

decreasing

growth

decline

trend

change over time

Follow this exact checklist:

✅ Step 1: Choose the ENTITY

Ask:

“Trend of WHAT?”

Examples:

Customer

Product

Film

Category

This becomes:

PARTITION BY entity_id

✅ Step 2: Choose the TIME ORDER

Ask:

“What defines time?”

Examples:

Date

Month

Year

Sequence number

This becomes:

ORDER BY time_column

✅ Step 3: Decide the METRIC

Ask:

“What value is changing?”

Examples:

Rental count

Revenue

Average amount

Gap between events

This is:

metric

✅ Step 4: Access the PREVIOUS VALUE

This is the heart of trend analysis.

Tool:

LAG(metric)


Now you can compare:

current_value  vs  previous_value

✅ Step 5: Define the TREND CONDITION

Ask:

“What does increasing mean here?”

Examples:

current > previous → increasing

current < previous → decreasing

gap_days < prev_gap_days → more frequent

✅ Step 6: Decide the QUALIFIER

Ask:

“How strong should the trend be?”

Options:

At least once

Consistent increase

Average increase

Latest period only

This controls:

WHERE / HAVING

🧩 One-Line Formula (VERY IMPORTANT)

Trend = current − previous over ordered time

If you remember only one thing, remember this.*/
WITH rental_gaps AS (
    SELECT
        customer_id,
        rental_date,
        CAST(
            julianday(rental_date) -
            julianday(
                LAG(rental_date) OVER (
                    PARTITION BY customer_id
                    ORDER BY rental_date
                )
            ) AS INTEGER
        ) AS gap_days
    FROM rental
),
gap_trends AS(
    select
    customer_id,
    gap_days,
    Lag(gap_days)over(partition by customer_id order by rental_date) as prev_gap
    from rental_gaps
)
select distinct customer_id
from gap_trends
where gap_days<prev_gap;

SELECT
        customer_id,
        strftime('%Y-%m', rental_date) AS month,
        COUNT(*) AS rental_count
    FROM rental
    GROUP BY customer_id, month;


 /*I prefer NOT EXISTS over NOT IN because NOT EXISTS is 
NULL-safe and performs better, whereas NOT IN can return incorrect results if the subquery contains NULL values.
*/
-------------
/*NOT EXISTS:
Can stop scanning as soon as a match is found
Works well with indexes
Avoids building large in-memory lists
------------
NOT IN:
Must evaluate the entire subquery result
Can be slow for large datasets*/

--Identify repeat rentals by customers using LAG().
with rentals AS(
    select 
    c.customer_id,
    c.first_name,
    c.last_name,
    DATE(r.rental_date) as rental_day,
    Lag(Date(rental_date))over(partition by c.customer_id order by r.rental_date) as prev_day
    from rental r join customer c on r.customer_id=c.customer_id
)
select *
from rentals where rental_day=prev_day;

--Find customers whose total spending exceeds the top 10% customers’ average spending.
/* steps to solve the question
1.First you just find out the Top 10% spending customers by cummulative spending 
2.Find the avg of that top 10% 
3.Find all the customers whose spending is greater that that avg value*/

--step 1
with sum_calculation AS(
    select c.customer_id,
    sum(p.amount) as cust_pay
    from customer c join payment p on c.customer_id=p.customer_id
    group by c.customer_id
),
percentage_contribution as(
    select *,
    (cust_pay*100/sum(cust_pay)over()) as percent_contri
    from sum_calculation
),
cummulative_percentage AS(
    select *,
    sum(percent_contri) over(
        order by cust_pay desc)as cummulative_contri
    from percentage_contribution
)
    select customer_id,sum(amount) as amt from payment group by customer_id having amt>(
    select
    avg(cust_pay) as avg_of_customer from cummulative_percentage WHERE
    cummulative_contri<=10
    )
    order by amt desc;

--Show store-wise percentage contribution to total revenue.
with percent_contribution AS(
    select s.store_id,
    sum(p.amount) as store_sum
    from store s join staff st on s.store_id=st.store_id JOIN
    payment p on st.staff_id=p.staff_id
    group by s.store_id
)
select store_id,store_sum*100.0/sum(store_sum)over() as contri from percent_contribution;

--Find peak rental hours
/* By peak rental hours it means that the hour in which we are getting the maximum rental*/

WITH hourly_rentals AS (
    SELECT
        strftime('%H', rental_date) AS rental_hour,
        COUNT(*) AS rental_count
    FROM rental
    GROUP BY rental_hour
)
SELECT
    rental_hour,
    rental_count
FROM hourly_rentals
WHERE rental_count = (
    SELECT MAX(rental_count)
    FROM hourly_rentals
);

--Find actors who worked in films rented only once.
select a.actor_id,a.first_name,a.last_name
from actor a join film_actor fa on a.actor_id=fa.actor_id JOIN
film f on fa.film_id=f.film_id join inventory i on f.film_id=i.film_id
join rental r on i.inventory_id=r.inventory_id
where EXISTS
(
    select 1,
    count(*) as rental_count
    from rental
    where rental_count=1
);
SELECT DISTINCT
    a.actor_id,
    a.first_name,
    a.last_name
FROM actor a
JOIN film_actor fa
    ON a.actor_id = fa.actor_id
WHERE EXISTS (
    SELECT 1
    FROM inventory i
    JOIN rental r
        ON i.inventory_id = r.inventory_id
    WHERE i.film_id = fa.film_id
    GROUP BY i.film_id
    HAVING COUNT(*) = 1
);


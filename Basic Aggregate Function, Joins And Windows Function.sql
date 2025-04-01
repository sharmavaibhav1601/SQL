 -- Question 1: Total number of rentals  

SELECT COUNT(*) AS total_rentals FROM rental;


-- Question 2: Average rental duration (in days)  
SELECT AVG(rental_duration) AS avg_rental_duration FROM film;


-- Question 3: Display customers' names in uppercase  
SELECT UPPER(first_name) AS first_name, UPPER(last_name) AS last_name FROM customer;


-- Question 4: Extract the month from the rental date  
SELECT rental_id, MONTH(rental_date) AS rental_month FROM rental;


-- Question 5: Count of rentals per customer  
SELECT customer_id, COUNT(*) AS rental_count 
FROM rental 
GROUP BY customer_id;


-- Question 6:** Total revenue per store  

SELECT store_id, SUM(amount) AS total_revenue 
FROM payment 
GROUP BY store_id;


-- Question 7: Total number of rentals per category  
SELECT c.name AS category, COUNT(rental.rental_id) AS total_rentals
FROM rental
JOIN inventory ON rental.inventory_id = inventory.inventory_id
JOIN film ON inventory.film_id = film.film_id
JOIN film_category fc ON film.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name;

-- Question 8: Average rental rate per language  
SELECT l.name AS language, AVG(f.rental_rate) AS avg_rental_rate
FROM film f
JOIN language l ON f.language_id = l.language_id
GROUP BY l.name;


-- Question 9: Movie titles and customers who rented them  
SELECT f.title, c.first_name, c.last_name
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN customer c ON r.customer_id = c.customer_id;


-- Question 10:Actors in "Gone with the Wind"  

SELECT a.first_name, a.last_name
FROM film_actor fa
JOIN film f ON fa.film_id = f.film_id
JOIN actor a ON fa.actor_id = a.actor_id
WHERE f.title = 'Gone with the Wind';


-- Question 11: Total amount spent per customer  
SELECT c.first_name, c.last_name, SUM(p.amount) AS total_spent
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name;


-- Question 12: Movie titles rented by customers in a particular city (e.g., 'London')  
SELECT f.title, c.first_name, c.last_name
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN customer c ON r.customer_id = c.customer_id
JOIN address a ON c.address_id = a.address_id
JOIN city ci ON a.city_id = ci.city_id
WHERE ci.city = 'London'
GROUP BY c.customer_id, f.title;


-- Question 13:** Top 5 rented movies  
SELECT f.title, COUNT(r.rental_id) AS rental_count
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
GROUP BY f.title
ORDER BY rental_count DESC
LIMIT 5;


-- Question 14:** Customers who rented from both stores  
SELECT customer_id
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN store s ON i.store_id = s.store_id
GROUP BY customer_id
HAVING COUNT(DISTINCT s.store_id) = 2;

-- Window Functions

-- 1. Rank customers by total spending

SELECT customer_id, first_name, last_name, SUM(amount) AS total_spent,
RANK() OVER (ORDER BY SUM(amount) DESC) AS rank
FROM customer
JOIN payment USING (customer_id)
GROUP BY customer_id, first_name, last_name;


-- 2. Cumulative revenue by film

SELECT f.title, p.payment_date, SUM(p.amount) OVER (PARTITION BY f.film_id ORDER BY p.payment_date) AS cumulative_revenue
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id;


-- 3. Average rental duration for films with similar lengths  
SELECT f.title, f.length, AVG(f.rental_duration) OVER (PARTITION BY f.length) AS avg_rental_duration
FROM film f;


-- 4. Top 3 films in each category based on rental count
SELECT c.name AS category, f.title, COUNT(r.rental_id) AS rental_count,
RANK() OVER (PARTITION BY c.name ORDER BY COUNT(r.rental_id) DESC) AS rank
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name, f.title
HAVING rank <= 3;


-- 5. Calculate the difference in rental counts between each customer's total rentals and the average rentals across all customers.
SELECT customer_id, 
       COUNT(rental_id) AS total_rentals,
       (COUNT(rental_id) - AVG(COUNT(rental_id)) OVER ()) AS rental_difference
FROM rental
GROUP BY customer_id;

-- 6. Find the monthly revenue trend for the entire rental store over time
SELECT DATE_FORMAT(payment_date, '%Y-%m') AS month, 
       SUM(amount) AS total_revenue
FROM payment
GROUP BY month
ORDER BY month;

-- 7. Identify the customers whose total spending on rentals falls within the top 20% of all customers.
WITH customer_spending AS (
    SELECT customer_id, SUM(amount) AS total_spent
    FROM payment
    GROUP BY customer_id
)
SELECT customer_id, total_spent
FROM customer_spending
WHERE total_spent >= (
    SELECT PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY total_spent) 
    FROM customer_spending
);
   
-- 8. Calculate the running total of rentals per category, ordered by rental count.
SELECT c.name AS category, COUNT(r.rental_id) AS rental_count,
       SUM(COUNT(r.rental_id)) OVER (PARTITION BY c.name ORDER BY COUNT(r.rental_id) DESC) AS running_total
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name, f.title
ORDER BY c.name, rental_count DESC;

-- 9.Find the films that have been rented less than the average rental count for their respective categories.
WITH category_avg AS (
    SELECT c.name AS category, AVG(rental_count) AS avg_rentals
    FROM (
        SELECT fc.category_id, f.film_id, COUNT(r.rental_id) AS rental_count
        FROM rental r
        JOIN inventory i ON r.inventory_id = i.inventory_id
        JOIN film f ON i.film_id = f.film_id
        JOIN film_category fc ON f.film_id = fc.film_id
        GROUP BY fc.category_id, f.film_id
    ) AS film_rental_counts
    JOIN category c ON film_rental_counts.category_id = c.category_id
    GROUP BY c.name
)
SELECT f.title, c.name AS category, COUNT(r.rental_id) AS rental_count
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
JOIN category_avg ca ON c.name = ca.category
GROUP BY f.title, c.name
HAVING COUNT(r.rental_id) < ca.avg_rentals
ORDER BY c.name, rental_count;
 
 -- 10. Identify the top 5 months with the highest revenue and display the revenue generated in each month.
SELECT DATE_FORMAT(payment_date, '%Y-%m') AS month, 
       SUM(amount) AS total_revenue
FROM payment
GROUP BY month
ORDER BY total_revenue DESC
LIMIT 5;


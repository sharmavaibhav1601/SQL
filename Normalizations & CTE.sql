-- Normalisation & CTE

-- 1. First Normal Form (1NF)
-- a. Identify a table in the Sakila database that violates 1NF. Explain how you would normalize it to achieve 1NF.
-- Table: `film`
-- Violation: The `special_features` column is a `SET('Trailers','Commentaries','Deleted Scenes','Behind the Scenes')`, allowing multiple values in a single field (e.g., "Trailers, Commentaries"). This violates 1NF’s requirement for atomic values.
-- Normalization Steps:
  -- 1. Create a new table `film_special_features`:
  
     CREATE TABLE film_special_features (
         film_id SMALLINT UNSIGNED NOT NULL,
         special_feature VARCHAR(20) NOT NULL,
         PRIMARY KEY (film_id, special_feature),
         FOREIGN KEY (film_id) REFERENCES film (film_id) ON DELETE CASCADE ON UPDATE CASCADE
     );
  
  -- 2. Populate it by splitting `special_features` into individual rows (e.g., film_id 1 with "Trailers, Commentaries" becomes two rows).
  -- 3. Drop `special_features` from the `film` table.
-- Result: Each special feature is stored atomically, achieving 1NF.

-- 2. Second Normal Form (2NF)
-- a. Choose a table in Sakila and describe how you would determine whether it is in 2NF. If it violates 2NF, explain the steps to normalize it.**

-- **Table**: `film_actor`
-- **Determination**:
-- 2NF requires 1NF and no partial dependencies on a composite key.
-- Primary key: `(actor_id, film_id)`. Attributes: `last_update`.
 -- `last_update` depends on the entire composite key `(actor_id, film_id)` because it tracks when an actor was associated with a film.
-- No partial dependency exists (e.g., `last_update` doesn’t depend solely on `actor_id` or `film_id`).
-- **Conclusion**: `film_actor` is in 2NF.
-- **If it violated 2NF** (hypothetical):
-- Suppose `actor_name` was added, dependent only on `actor_id`.
-- **Steps**:
   /* 1. Split into `film_actor` (`actor_id`, `film_id`, `last_update`) and `actor` (`actor_id`, `actor_name`).
    2. Maintain foreign key relationships.
  - Since no such violation exists, no changes are needed.*/

-- 3. Third Normal Form (3NF)
/*a. Identify a table in Sakila that violates 3NF. Describe the transitive dependencies present and outline the steps to normalize the table to 3NF.**

- **Table**: `customer`
- **Violation**: 
  - Primary key: `customer_id`.
  - `address_id` references `address`, which includes `city_id`, and `city_id` references `city`, which includes `country_id`. If `customer` redundantly stored `city` or `country` (not in the schema but hypothetical), it would violate 3NF dueanden transitive dependency: `customer_id` → `address_id` → `city`.
- **Actual Case**: The `staff` table has `address_id` and `store_id`, with `store_id` linked to `address_id` in the `store` table, suggesting a potential transitive dependency (`staff_id` → `store_id` → `address_id`).
- **Steps**:
  1. Move `address_id` to relate directly to `staff_id` without `store_id` interference.
  2. Ensure `store` maintains its own `address_id`.*/

    CREATE TABLE staff_location (
        staff_id TINYINT UNSIGNED PRIMARY KEY,
        address_id SMALLINT UNSIGNED,
        FOREIGN KEY (address_id) REFERENCES address (address_id)	
    );
    
-- Update `staff` to remove redundant `address_id` if fully dependent on `store_id`.
-- **Result**: Eliminate transitive dependencies, achieving 3NF.

/* 4. Normalization Process
**a. Take a specific table in Sakila and guide through the process of normalizing it from the initial unnormalized form up to at least 2NF.**

- **Table**: `film` (assuming unnormalized with `special_features` and hypothetical `actor_names` as a comma-separated list).
- **Unnormalized Form**:
  - `film(film_id, title, special_features, actor_names)`
  - Example: `(1, 'Film A', 'Trailers,Commentaries', 'Actor1,Actor2')`
- **To 1NF**:
  1. Split `special_features`: */
    
     CREATE TABLE film_special_features (
         film_id SMALLINT UNSIGNED,
         special_feature VARCHAR(20),
         PRIMARY KEY (film_id, special_feature)
     );
 
 -- 2. Split `actor_names`:
   
     CREATE TABLE film_actor (
         film_id SMALLINT UNSIGNED,
         actor_name VARCHAR(45),
         PRIMARY KEY (film_id, actor_name)
     );
     
  /*3. Update `film`: `(film_id, title)`.
- **To 2NF**:
  - `film_actor` has composite key `(film_id, actor_name)`. If `actor_name` were replaced with `actor_id`, ensure no partial dependency (e.g., add `actor` table: `actor(actor_id, name)`).
  - Current `film_actor` in Sakila (`actor_id, film_id`) is already 2NF.
- **Result**: `film`, `film_special_features`, and `film_actor` are in 2NF.
*/

/* 5. CTE Basics
a. Write a query using a CTE to retrieve the distinct list of actor names and the number of films they have acted in from the actor and film_actor tables.*/

WITH ActorFilmCount AS (
    SELECT 
        a.actor_id,
        a.first_name,
        a.last_name,
        COUNT(fa.film_id) AS film_count
    FROM actor a
    JOIN film_actor fa ON a.actor_id = fa.actor_id
    GROUP BY a.actor_id, a.first_name, a.last_name
)
SELECT 
    CONCAT(first_name, ' ', last_name) AS actor_name,
    film_count
FROM ActorFilmCount
ORDER BY actor_name;


/*6. CTE with Joins
a. Create a CTE that combines information from the film and language tables to display the film title, language name, and rental rate.*/

WITH FilmLanguage AS (
    SELECT 
        f.title,
        l.name AS language_name,
        f.rental_rate
    FROM film f
    JOIN language l ON f.language_id = l.language_id
)
SELECT 
    title,
    language_name,
    rental_rate
FROM FilmLanguage
ORDER BY title;

/*7. CTE for Aggregation
a. Write a query using a CTE to find the total revenue generated by each customer (sum of payments) from the customer and payment tables.*/

WITH CustomerRevenue AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        SUM(p.amount) AS total_revenue
    FROM customer c
    JOIN payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT 
    customer_id,
    CONCAT(first_name, ' ', last_name) AS customer_name,
    total_revenue
FROM CustomerRevenue
ORDER BY total_revenue DESC;


/* 8. CTE with Window Functions
*a. Utilize a CTE with a window function to rank films based on their rental duration from the film table.*/

WITH FilmRank AS (
    SELECT 
        title,
        rental_duration,
        RANK() OVER (ORDER BY rental_duration DESC) AS duration_rank
    FROM film
)
SELECT 
    title,
    rental_duration,
    duration_rank
FROM FilmRank
ORDER BY duration_rank;

/* 9. CTE and Filtering
a. Create a CTE to list customers who have made more than two rentals, and then join this CTE with the customer table to retrieve additional customer details.*/

WITH FrequentRenters AS (
    SELECT 
        customer_id,
        COUNT(rental_id) AS rental_count
    FROM rental
    GROUP BY customer_id
    HAVING rental_count > 2
)
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    fr.rental_count
FROM FrequentRenters fr
JOIN customer c ON fr.customer_id = c.customer_id
ORDER BY rental_count DESC;

/* 10. CTE for Date Calculations
a. Write a query using a CTE to find the total number of rentals made each month, considering the rental_date from the rental table.*/

WITH MonthlyRentals AS (
    SELECT 
        DATE_FORMAT(rental_date, '%Y-%m') AS rental_month,
        COUNT(rental_id) AS rental_count
    FROM rental
    GROUP BY DATE_FORMAT(rental_date, '%Y-%m')
)
SELECT 
    rental_month,
    rental_count
FROM MonthlyRentals
ORDER BY rental_month;

/* 11. CTE and Self-Join
a. Create a CTE to generate a report showing pairs of actors who have appeared in the same film together, using the film_actor table.*/

WITH ActorPairs AS (
    SELECT 
        fa1.actor_id AS actor_id1,
        fa2.actor_id AS actor_id2,
        fa1.film_id
    FROM film_actor fa1
    JOIN film_actor fa2 ON fa1.film_id = fa2.film_id AND fa1.actor_id < fa2.actor_id
)
SELECT 
    CONCAT(a1.first_name, ' ', a1.last_name) AS actor1,
    CONCAT(a2.first_name, ' ', a2.last_name) AS actor2,
    COUNT(ap.film_id) AS shared_films
FROM ActorPairs ap
JOIN actor a1 ON ap.actor_id1 = a1.actor_id
JOIN actor a2 ON ap.actor_id2 = a2.actor_id
GROUP BY ap.actor_id1, ap.actor_id2, a1.first_name, a1.last_name, a2.first_name, a2.last_name
ORDER BY shared_films DESC;

/* 12. CTE for Recursive Search
a. Implement a recursive CTE to find all employees in the staff table who report to a specific manager, considering the reports_to column.*/


WITH RECURSIVE StaffHierarchy AS (
    SELECT 
        staff_id,
        first_name,
        last_name,
        reports_to,
        0 AS level
    FROM staff
    WHERE staff_id = 1 -- Starting with a specific manager (e.g., staff_id 1)
    UNION ALL
    SELECT 
        s.staff_id,
        s.first_name,
        s.last_name,
        s.reports_to,
        sh.level + 1
    FROM staff s
    JOIN StaffHierarchy sh ON s.reports_to = sh.staff_id
)
SELECT 
    staff_id,
    CONCAT(first_name, ' ', last_name) AS staff_name,
    reports_to,
    level
FROM StaffHierarchy
ORDER BY level, staff_id;

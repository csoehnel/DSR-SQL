-- Single line comment
SELECT title, rating, length
FROM film;

/*
Multiline comment
 */
SELECT title, rating, length
FROM film f
WHERE f.rating = 'R'
  AND f.length < 60
ORDER BY f.length DESC;

-- List all film titles with their actors' names --> 5462
SELECT title, first_name, last_name
FROM film
       INNER JOIN film_actor ON film.film_id = film_actor.film_id
       INNER JOIN actor ON film_actor.actor_id = actor.actor_id
ORDER BY 1;

-- List titles of films that are not in the inventory --> 42
SELECT title
FROM film
       LEFT JOIN inventory ON film.film_id = inventory.film_id
WHERE inventory.film_id IS NULL;

-- List distinct titles of all ilms returned on 2005-05-27 --> 46
SELECT DISTINCT ON (title) title, r.return_date
FROM film
       INNER JOIN inventory i on film.film_id = i.film_id
       INNER JOIN rental r on i.inventory_id = r.inventory_id
WHERE r.return_date BETWEEN '2005-05-27' AND '2005-05-28';

-- Names of all customers who returned a rental on 2005-05-27 --> 49
SELECT first_name, last_name
FROM customer
WHERE customer_id IN (SELECT customer_id FROM rental WHERE return_date BETWEEN '2005-05-27' AND '2005-05-28');

-- Names of customers who have made a payment --> 599
SELECT first_name, last_name
FROM customer
WHERE customer_id IN (SELECT customer_id FROM payment)
ORDER BY (first_name, last_name) ASC;

-- Names of customers who have made a payment --> 599
SELECT DISTINCT first_name, last_name
FROM customer
       INNER JOIN payment p on customer.customer_id = p.customer_id
ORDER BY 1, 2;

-- Names of all customers who returned a rental on 2005-05-27 --> 49
WITH rentals AS (SELECT customer_id FROM rental WHERE CAST(return_date AS DATE) = '2005-05-27')
SELECT first_name, last_name
FROM customer
       JOIN rentals ON rentals.customer_id = customer.customer_id;

-- Customers ordered by how much they spent
SELECT c.first_name, c.last_name, SUM(amount)
FROM payment
       INNER JOIN customer c on payment.customer_id = c.customer_id
GROUP BY first_name, last_name
ORDER BY SUM(amount) DESC;

-- Customers who have spent more than 200
SELECT c.first_name, c.last_name, SUM(amount) as total
FROM payment
       INNER JOIN customer c on payment.customer_id = c.customer_id
GROUP BY first_name, last_name
HAVING SUM(amount) > 200;

-- Number of rentals for each category
SELECT c.name, COUNT(rental.inventory_id)
FROM rental
       JOIN inventory i ON rental.inventory_id = i.inventory_id
       JOIN film_category fc ON fc.film_id = i.film_id
       JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name
ORDER BY COUNT(rental.inventory_id) DESC;

-- Number of rentals for each film with its category (my solution probably on works if film only belongs to one category)
SELECT film.title, COUNT(rental.inventory_id)
FROM rental
       JOIN inventory i ON rental.inventory_id = i.inventory_id
       JOIN film_category fc ON fc.film_id = i.film_id
       JOIN category c ON fc.category_id = c.category_id
       JOIN film ON fc.film_id = film.film_id
GROUP BY film.title
ORDER BY COUNT(rental.inventory_id) DESC;
SELECT film.title,
       category.name,
       count(rental.rental_id)
FROM rental
       JOIN inventory ON rental.inventory_id = inventory.inventory_id
       JOIN film_category ON inventory.film_id = film_category.film_id
       JOIN category ON film_category.category_id = category.category_id
       JOIN film ON inventory.film_id = film.film_id
GROUP BY 1, 2
ORDER BY 3 DESC;

-- Films which have film.rental_rate higher than the average film.rental_rate between all films in the DB
SELECT film.title, film.rental_rate
FROM film
WHERE (SELECT AVG(rental_rate) FROM film) <= film.rental_rate
ORDER BY film.rental_rate DESC;

-- Find the last returned film title - show customer name and return date
WITH rets AS (SELECT film.title, c.first_name, c.last_name, r.return_date, rank() OVER (ORDER BY r.return_date DESC)
              FROM film
                     JOIN inventory i on film.film_id = i.film_id
                     JOIN rental r on i.inventory_id = r.inventory_id
                     JOIN customer c on r.customer_id = c.customer_id
              WHERE r.return_date IS NOT NULL)
SELECT *
FROM rets
WHERE rank = 1

-- Find the 10 % most profitable customers (top 10 %)
WITH profit AS (SELECT c.last_name, c.first_name, sum(p.amount), NTILE(10) OVER (ORDER BY sum(p.amount) DESC)
                FROM customer c
                       JOIN payment p on c.customer_id = p.customer_id
                GROUP BY c.last_name, c.first_name, p.customer_id
                ORDER BY sum(p.amount) DESC)
SELECT *
FROM profit
WHERE ntile = 1

-- Find the most rented film for each category
WITH mosre as (SELECT ct.name,
                      f.title,
                      count(r.inventory_id),
                      dense_rank() OVER (PARTITION BY ct.name ORDER BY count(r.inventory_id) DESC)
               FROM category ct
                      JOIN film_category fc on ct.category_id = fc.category_id
                      JOIN film f on fc.film_id = f.film_id
                      JOIN inventory i on f.film_id = i.film_id
                      JOIN rental r on i.inventory_id = r.inventory_id
               GROUP BY ct.name, f.title)
SELECT *
FROM mosre
WHERE dense_rank = 1;

WITH mosre as (SELECT ct.name,
                      f.title,
                      count(r.inventory_id),
                      row_number() OVER (PARTITION BY ct.name ORDER BY count(r.inventory_id) DESC)
               FROM category ct
                      JOIN film_category fc on ct.category_id = fc.category_id
                      JOIN film f on fc.film_id = f.film_id
                      JOIN inventory i on f.film_id = i.film_id
                      JOIN rental r on i.inventory_id = r.inventory_id
               GROUP BY ct.name, f.title)
SELECT *
FROM mosre
WHERE row_number = 1;
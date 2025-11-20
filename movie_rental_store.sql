-- ==========================================
-- Movie Rental Store – SQL Mini Project (MySQL)
-- ==========================================
-- Author: Hrishabh Khandelwal
-- Purpose: Demonstrates hands-on SQL skills: schema design, inserts,
-- joins, aggregates, subqueries, and a window function.
-- Instructions: Run this script in MySQL (or compatible) to create the sample DB.
-- ==========================================

-- 1. Create and use database
CREATE DATABASE IF NOT EXISTS movie_rental_store;
USE movie_rental_store;

-- 2. Drop tables if they already exist (to re-run script easily)
DROP TABLE IF EXISTS RentalItems;
DROP TABLE IF EXISTS Rentals;
DROP TABLE IF EXISTS Movies;
DROP TABLE IF EXISTS Customers;

-- 3. Create tables

CREATE TABLE Customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    full_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(100) UNIQUE NOT NULL,
    phone       VARCHAR(20),
    city        VARCHAR(50),
    created_at  DATE NOT NULL
);

CREATE TABLE Movies (
    movie_id    INT PRIMARY KEY AUTO_INCREMENT,
    title       VARCHAR(200) NOT NULL,
    director    VARCHAR(100),
    genre       VARCHAR(50),
    release_year INT,
    rental_price DECIMAL(6,2) NOT NULL,
    stock_qty   INT NOT NULL DEFAULT 0
);

CREATE TABLE Rentals (
    rental_id   INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    rental_date DATE NOT NULL,
    due_date    DATE NOT NULL,
    return_date DATE,
    status      VARCHAR(20) NOT NULL,
    CONSTRAINT fk_rentals_customer
        FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

CREATE TABLE RentalItems (
    rental_item_id INT PRIMARY KEY AUTO_INCREMENT,
    rental_id      INT NOT NULL,
    movie_id       INT NOT NULL,
    quantity       INT NOT NULL,
    unit_price     DECIMAL(6,2) NOT NULL,
    CONSTRAINT fk_items_rental
        FOREIGN KEY (rental_id) REFERENCES Rentals(rental_id) ON DELETE CASCADE,
    CONSTRAINT fk_items_movie
        FOREIGN KEY (movie_id) REFERENCES Movies(movie_id)
);

-- 4. Insert sample data

INSERT INTO Customers (full_name, email, phone, city, created_at) VALUES
('Hrishabh Khandelwal', 'hrishabh@example.com', '9876543210', 'Hyderabad', '2024-01-20'),
('Anita Mehra', 'anita@example.com', '9123456780', 'Delhi', '2024-02-11'),
('Vikram Joshi', 'vikram@example.com', '9988776655', 'Mumbai', '2024-03-05'),
('Meera Patel', 'meera@example.com', '9012345678', 'Ahmedabad', '2024-03-15');

INSERT INTO Movies (title, director, genre, release_year, rental_price, stock_qty) VALUES
('Skyward Rise', 'A. Kumar', 'Drama', 2019, 49.00, 10),
('Fast Escape', 'B. Roy', 'Action', 2021, 59.00, 8),
('Love & Reason', 'C. Singh', 'Romance', 2020, 39.00, 12),
('Galaxy Wars: Dawn', 'D. Patel', 'Sci-Fi', 2022, 79.00, 5),
('Laugh Riot', 'E. Sharma', 'Comedy', 2018, 29.00, 7);

INSERT INTO Rentals (customer_id, rental_date, due_date, return_date, status) VALUES
(1, '2024-04-01', '2024-04-07', '2024-04-06', 'Returned'),
(2, '2024-04-02', '2024-04-09', NULL, 'Rented'),
(3, '2024-04-03', '2024-04-10', '2024-04-11', 'Returned Late'),
(1, '2024-04-10', '2024-04-17', NULL, 'Rented');

INSERT INTO RentalItems (rental_id, movie_id, quantity, unit_price) VALUES
(1, 1, 1, 49.00),
(1, 5, 1, 29.00),
(2, 2, 1, 59.00),
(3, 4, 1, 79.00),
(4, 3, 2, 39.00);

-- 5. Example queries (showcases skills)

-- Q1. List all movies with genre and rental price (ordered by price desc)
SELECT movie_id, title, genre, rental_price FROM Movies ORDER BY rental_price DESC;

-- Q2. Total rentals and total rental revenue (only rented/returned statuses)
SELECT
    COUNT(DISTINCT r.rental_id) AS total_rentals,
    SUM(ri.quantity * ri.unit_price) AS total_revenue
FROM Rentals r
JOIN RentalItems ri ON r.rental_id = ri.rental_id
WHERE r.status IN ('Returned','Returned Late','Rented');

-- Q3. Top customers by total spent
SELECT
    c.customer_id, c.full_name,
    SUM(ri.quantity * ri.unit_price) AS total_spent
FROM Customers c
JOIN Rentals r ON c.customer_id = r.customer_id
JOIN RentalItems ri ON r.rental_id = ri.rental_id
GROUP BY c.customer_id, c.full_name
ORDER BY total_spent DESC
LIMIT 3;

-- Q4. Movies never rented
SELECT m.movie_id, m.title FROM Movies m
LEFT JOIN RentalItems ri ON m.movie_id = ri.movie_id
WHERE ri.movie_id IS NULL;

-- Q5. Overdue rentals (today assumed '2024-04-12' for example)
SELECT r.rental_id, c.full_name, r.due_date, r.status
FROM Rentals r
JOIN Customers c ON r.customer_id = c.customer_id
WHERE r.return_date IS NULL AND r.due_date < '2024-04-12';

-- Q6. Monthly rentals count (2024)
SELECT DATE_FORMAT(r.rental_date, '%Y-%m') AS year_month, COUNT(*) AS rentals_count
FROM Rentals r
GROUP BY year_month
ORDER BY year_month;

-- Q7. Window function: rank movies by number of rentals within each genre
SELECT
    m.title, m.genre,
    COUNT(ri.rental_item_id) AS times_rented,
    RANK() OVER (PARTITION BY m.genre ORDER BY COUNT(ri.rental_item_id) DESC) AS rent_rank_in_genre
FROM Movies m
LEFT JOIN RentalItems ri ON m.movie_id = ri.movie_id
GROUP BY m.movie_id, m.title, m.genre;

-- Q8. Customers who rented more than average rentals
SELECT customer_id, full_name, customer_rentals FROM (
    SELECT c.customer_id, c.full_name, COUNT(r.rental_id) AS customer_rentals
    FROM Customers c
    LEFT JOIN Rentals r ON c.customer_id = r.customer_id
    GROUP BY c.customer_id
) t
WHERE customer_rentals > (
    SELECT AVG(customer_count) FROM (
        SELECT COUNT(r2.rental_id) AS customer_count
        FROM Customers c2
        LEFT JOIN Rentals r2 ON c2.customer_id = r2.customer_id
        GROUP BY c2.customer_id
    ) z
);

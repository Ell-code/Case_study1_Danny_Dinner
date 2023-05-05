-- Danny's Diner:- Case Study #1
/* Danny wants to open a cute little resturant that sells 3 of his best food:-
'Sushi', 'Curry', and 'Ramen'.

Danny wants to use the data to answer a few simple questions about his customers, 
especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. 
Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

He plans on using these insights to help him decide whether he should expand the existing customer loyalty program 
- additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.

Danny has shared with you 3 key datasets for this case study:

- sales
- menu
- members
*/

CREATE DATABASE dannys_diner;

USE dannys_diner;


CREATE TABLE sales (
	sales_id INT NOT NULL IDENTITY PRIMARY KEY,
	customer_id VARCHAR(1),
	order_date DATE,
	product_id INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


-- Each of the following case study questions can be answered using a single SQL statement:

-- 1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, SUM(m.price) AS Total_amount_spent
FROM sales s
JOIN menu m 
	ON m.product_id = s.product_id
GROUP BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT s.order_date) AS Total_Customer_visitation
FROM sales s
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
SELECT * FROM sales;

-- First method
WITH CTE AS(
	SELECT 
		customer_id,
		product_name,
		order_date,
		DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS rnk,
		ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) AS RN
	FROM sales s
	JOIN menu m 
		ON m.product_id = s.product_id
			)
SELECT  customer_id, product_name
FROM CTE
WHERE 
	rnk = 1 
	AND 
	RN = 1

-- Second method

WITH CTE AS(
	SELECT 
		customer_id,
		product_name,
		order_date,
		DENSE_RANK() OVER(ORDER BY order_date) AS rnk,
		ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) AS RN
	FROM sales s
	JOIN menu m 
		ON m.product_id = s.product_id
			)
SELECT  customer_id, product_name
FROM CTE
WHERE 
	rnk = 1 
	AND 
	RN = 1

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
WITH CTE AS(
	SELECT TOP 1 s.product_id, COUNT(m.product_name) AS Total_Purchased 
	FROM sales s
	JOIN menu m 
		ON m.product_id = s.product_id
	GROUP BY s.product_id
	ORDER BY Total_Purchased DESC
	)

SELECT customer_id, COUNT(m.product_name) AS Total_amount_spent, m.product_name
FROM sales s
JOIN menu m 
	ON m.product_id = s.product_id
RIGHT JOIN CTE c 
	ON c.product_id = s.product_id
GROUP BY s.product_id, customer_id, m.product_name;

-- 5. Which item was the most popular for each customer?

WITH CTE AS(
	SELECT customer_id, 
		m.product_name,
		COUNT(s.order_date) AS Total_amount_spent, 
		RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(s.order_date) DESC) AS RNK,
		ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY COUNT(s.order_date) DESC) AS RN
	FROM sales s
	JOIN menu m 
		ON m.product_id = s.product_id
	GROUP BY m.product_name, s.product_id, customer_id
	)
SELECT customer_id, product_name FROM CTE WHERE RNK = 1 AND RN = 1

-- 6. Which item was purchased first by the customer after they became a member?
WITH CTE AS 
	(
	SELECT 
		s.customer_id,
		order_date,
		join_date,
		product_name,
		RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS RNK,
		ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS RN
	FROM sales s
	JOIN members m
		ON m.customer_id = s.customer_id
	join menu me
		ON me.product_id = s.product_id
	WHERE order_date >= join_date
	)

SELECT customer_id,
	product_name
FROM CTE
WHERE RNK = 1 AND RN = 1;
-- 7. Which item was purchased just before the customer became a member?
WITH CTE AS 
	(
	SELECT 
		s.customer_id,
		order_date,
		join_date,
		product_name,
		RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS RNK,
		ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS RN
	FROM sales s
	JOIN members m
		ON m.customer_id = s.customer_id
	join menu me
		ON me.product_id = s.product_id
	WHERE order_date < join_date
	)

SELECT customer_id,
	product_name
FROM CTE
WHERE RNK = 1 AND RN = 1;
-- 8. What is the total items and amount spent for each member before they became a member?
WITH CTE AS 
	(
	SELECT 
		s.customer_id,
		COUNT(product_name) AS Total_item,
		SUM(price) AS amount_spent--,
--		RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS RNK,
--		ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS RN
	FROM sales s
	JOIN members m
		ON m.customer_id = s.customer_id
	join menu me
		ON me.product_id = s.product_id
	WHERE order_date < join_date
	GROUP BY s.customer_id
	)

SELECT *
FROM CTE;
-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT customer_id,
SUM(
	CASE 
		WHEN product_name = 'sushi' 
		THEN price * 10 *2
	ELSE price * 10
	END) AS point
FROM menu m
JOIN sales s
	ON s.product_id = m.product_id
GROUP BY customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT s.customer_id,
SUM(
	CASE 
		WHEN order_date BETWEEN join_date AND DATEADD('d', 6, join_date)
		THEN price * 10 *2
	ELSE price * 10
	END) AS point,
FROM menu m
JOIN sales s
	ON s.product_id = m.product_id
JOIN members mb 
	ON mb.customer_id = s.customer_id
GROUP BY s.customer_id

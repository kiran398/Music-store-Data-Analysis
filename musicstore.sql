/*1. Who is the senior most employee based on job title?
2. Which countries have the most Invoices?
3. What are top 3 values of total invoice?
4. Which city has the best customers? We would like to throw a promotional Music 
Festival in the city we made the most money. Write a query that returns one city that 
has the highest sum of invoice totals. Return both the city name & sum of all invoice 
totals
5. Who is the best customer? The customer who has spent the most money will be 
declared the best customer. Write a query that returns the person who has spent the 
most money   */


--  Who is the senior most employee based on job title?
INSERT INTO employee
VALUES (9,'Madan', 'Mohan', 'Senior General Manager','0', 'L7', '1961-01-26 00:00:00', '2016-01-14 00:00:00', '1008 Vrinda Ave MT', 'Edmonton', 'AB', 'Canada', 'T5K 2N1', '+1 (780) 428-9482', '+1 (780) 428-3457', 'madan.mohan@chinookcorp.com');

select *
from employee 
order by levels desc
limit 1;

-- Which countries have the most Invoices?
select billing_country,
count(billing_country) as max_invoice
from invoice
group by billing_country
order by max_invoice desc;

-- What are top 3 values of total invoice?

select * from invoice;
select billing_country,
total 
from invoice
order by total desc
limit 3;

 /* Which city has the best customers? We would like to throw a promotional Music 
Festival in the city we made the most money. Write a query that returns one city that 
has the highest sum of invoice totals. Return both the city name & sum of all invoice 
totals */

select * from invoice;

select billing_city,
sum(total) as max_invoice
from invoice
group by billing_city
order by max_invoice desc;

/*Who is the best customer? The customer who has spent the most money will be 
declared the best customer. Write a query that returns the person who has spent the 
most money*/
select c.first_name,
sum(i.total) as total
from invoice i
join customer c on i.customer_id = c.customer_id
group by c.customer_id,c.first_name
order by total desc;

/*1. Write query to return the email, first name, last name, & Genre of all Rock Music 
listeners. Return your list ordered alphabetically by email starting with A
2. Let's invite the artists who have written the most rock music in our dataset. Write a 
query that returns the Artist name and total track count of the top 10 rock bands
3. Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the 
longest songs listed first   */

select distinct c.first_name, c.last_name, c.email
from customer c
join invoice i on c.customer_id = i.customer_id
join invoice_line l on i.invoice_id = l.invoice_id 
where track_id in(
select track_id 
from track t
join genre g on t.genre_id = g.genre_id
where g.name like 'Rock')
order by c.email;


select artist.name, artist.artist_id, count(artist.artist_id) as num_of_songs
from track
join album on track.album_id = album.album_id
join artist on artist.artist_id = album.artist_id
join genre on track.genre_id = genre.genre_id
where genre.name like 'Rock'
group by artist.artist_id, artist.name
order by num_of_songs desc
limit 10;

SELECT name, avg_length
FROM (
    SELECT name, AVG(milliseconds) AS avg_length
    FROM track
    GROUP BY name
) AS avg_track_length
WHERE avg_length > (
    SELECT AVG(milliseconds)
    FROM track
)
order by avg_length desc;



/*1. Find how much amount spent by each customer on artists? Write a query to return
customer name, artist name and total spent
2. We want to find out the most popular music Genre for each country. We determine the 
most popular genre as the genre with the highest amount of purchases. Write a query 
that returns each country along with the top Genre. For countries where the maximum 
number of purchases is shared return all Genres
3. Write a query that determines the customer that has spent the most on music for each 
country. Write a query that returns the country along with the top customer and how
much they spent. For countries where the top amount spent is shared, provide all 
customers who spent this amount   */


-- Query 1
WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name, SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY 1,2
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;


/* -- Query 2 attempt
with total_revenue as 
(select  genre.name as genre_name, invoice.billing_country as country_name,
	round(sum(invoice_line.unit_price * invoice_line.quantity),2) as sum_amount
    from track
    join invoice_line on track.track_id = invoice_line.track_id
    join genre on genre.genre_id = track.genre_id
    join invoice on invoice.invoice_id = invoice_line.invoice_id
    group by genre.name, invoice.billing_country
    order by sum_amount desc) 
  
     select country_name,
     sum(sum_amount) as total_sum_per_genre
     from total_revenue
     group by country_name,genre_name
     order by total_sum_per_genre desc
	*/
    
    -- Query 2
WITH popular_genre AS (
    SELECT
        COUNT(invoice_line.quantity) AS purchases,
        genre.name AS genre_name,
        customer.country,
        genre.genre_id,
        ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS row_num
    FROM
        invoice_line
        JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
        JOIN customer ON customer.customer_id = invoice.customer_id
        JOIN track ON track.track_id = invoice_line.track_id
        JOIN genre ON genre.genre_id = track.genre_id
    GROUP BY
        genre.name, customer.country, genre.genre_id
)
SELECT
    purchases,
    genre_name,
    country
FROM
    popular_genre
WHERE
    row_num = 1;

    
    
    -- Query 3
    
    WITH most_spent AS (
    SELECT
        round(sum(invoice.total),2) AS total_spent,
        customer.first_name as Name,
        customer.customer_id,
        invoice.billing_country as Country,
        ROW_NUMBER() OVER(PARTITION BY invoice.billing_country ORDER BY sum(total) DESC) AS row_num
    FROM
        customer
        JOIN invoice ON invoice.customer_id = customer.customer_id
    GROUP BY
        customer.first_name, customer.customer_id, invoice.billing_country
)
SELECT
    total_spent,
    Name,
    Country
FROM
    most_spent
WHERE
    row_num = 1
order by total_spent desc;

    

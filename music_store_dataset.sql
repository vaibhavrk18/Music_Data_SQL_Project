select * from album;
select * from track;
select * from genre;
select * from artist;
select * from playlist;


/* EASY QUESTIONS */

/* Q1: Who is the senior most employee based on job title? */
select * from employee;

select first_name,last_name, title as job_title, levels
from employee
order by levels desc limit 1;


/* what are the job title offered in this dataset? */

select title as job_title,count(*) as job_count, levels
from employee
group by 1,3
order by 3 desc;

/* Q2: Which countries have the most Invoices? */
select * from invoice;

select count(*) as count, billing_country
from invoice
group by billing_country
order by count desc;

/* Q3: what are top 3 values of invoices*/
select * from invoice
order by total desc limit 3;

/* Q4: which city has the best customers? we would like to through the promotional music fetival
in the city we made the most money. write a query that returns one city that has the highest sum of 
invoice totals. return both the city name and sum of all invoice totals.*/

select * from customer;
select * from invoice;

select billing_city, sum(total) as invoice_total
from invoice
group by billing_city
order by invoice_total desc limit 1;

/* Q5: who is the best customer? the customer who has spent the most money will be declared the best 
customer. Write the query that returns the person who has spent the most money.*/
select * from customer;
select * from invoice;

select c.first_name, c.last_name, i.billing_city, sum(i.total) as invoice_total
from customer c
	left join invoice i on i.customer_id = c.customer_id
group by first_name, last_name, billing_city
order by invoice_total desc limit 1;

/* Moderate Questions */

/* Q1: Write a query to return email, first name, last name and genre of all rock music listeners
return your list ordered alphabetically by email starting wiht A */

select * from customer;

select c.first_name, c.last_name, c.email, g.name
from customer c
	join invoice i on c.customer_id = i.customer_id
	join invoice_line il on il.invoice_id = i.invoice_id
	join track t on t.track_id = il.track_id
	join genre g on g.genre_id = t.genre_id
group by c.first_name, c.last_name, c.email, g.name
having g.name like 'Rock'
order by c.email asc;

-- same question using subquery / Query optimization:

select c.email, c.first_name, c.last_name
from customer c
join invoice i on i.customer_id = c.customer_id
join invoice_line il on il.invoice_id = i.invoice_id
where track_id in (
	select track_id 
	from track t
		join genre g on t.genre_id = g.genre_id
	where g.name like 'Rock'
)
order by email;

/* Q2: Lets invite the artists who have written the most rock music in our dataset.
Write the query that returns the artist name and total track count of the top 10 rock bands. */

select a.artist_id, a.name, count(t.name) as track_count
from artist a
	join album m on a.artist_id = m.artist_id
	join track t on m.album_id = t.album_id
	join genre g on g.genre_id = t.genre_id
where g.name like 'Rock'
group by a.artist_id, a.name
order by track_count desc limit 10;

/* Q3: Written all the track names that have song length longer than the average song length.
Return the Name and Milliseconds for each track. Order by the song length with the longest 
songs listed first. */

select name, milliseconds
from track
where milliseconds > (
	select avg(milliseconds) as avg_song_length
	from track)
order by milliseconds desc; 

/* Advanced Question */
/* Q1 : Find how much amount spent by each customer on artists? Write a query to return customer
name, astist name and total spend. */
select * from invoice_line;

with best_selling_artist as(
	select a.artist_id, a.name as artist_name, 
		sum(il.unit_price*il.quantity) as total_sales
	from invoice_line il
		join track t on t.track_id = il.track_id
		join album on album.album_id = t.album_id
		join artist a on a.artist_id = album.artist_id
	group by 1
	order by 3 desc limit 1
)
select c.customer_id, c.first_name, c.last_name,bsa.artist_name, 
	sum(il.unit_price*il.quantity) as total_spend
from invoice i
	join customer c on c.customer_id = i.customer_id
	join invoice_line il on il.invoice_id = i.invoice_id
	join track t on t.track_id = il.track_id
	join album on album.album_id = t.album_id
	join best_selling_artist bsa on bsa.artist_id = album.artist_id
group by 1,2,3,4
order by 5 desc;


/* Q2: We want to find out the most popular music genre for each country. We determine the most
popular genre as the genre with the highest amount of purchases. Write a query that returns
each country along with the top genre for country where maximum number of purhcases is shared 
return all genres. */

-- Method 1: using CTE
with popular_genre as 
(	select count(il.quantity) as purchases, c.country, g.name as genre_name, g.genre_id,
 	row_number() over(partition by c.country order by count(il.quantity) desc) as row_number
 	from invoice_line il
 	join invoice i on i.invoice_id = il.invoice_id
 	join customer c on c.customer_id = i.customer_id
 	join track t on t.track_id = il.track_id
 	join genre g on g.genre_id = t.genre_id
 	group by 2,3,4
 	order by 2 asc, 1 desc
)
select * from popular_genre where row_number <= 1 order by purchases desc;

-- Method 2: using recursive CTE

with recursive
	sales_per_country as(
		select count(*) as purchase_per_genre, c.country, g.name as genre_name, g.genre_id
 		from invoice_line il
 		join invoice i on i.invoice_id = il.invoice_id
 		join customer c on c.customer_id = i.customer_id
 		join track t on t.track_id = il.track_id
 		join genre g on g.genre_id = t.genre_id
 		group by 2,3,4
 		order by 2 asc
	),
	max_genre_per_country as (select max(purchase_per_genre) as max_genre_number, country
	  	from sales_per_country
		group by 2
		order by 2)
select sales_per_country.*
from sales_per_country
join max_genre_per_country  on max_genre_per_country.country = sales_per_country.country
where sales_per_country.purchase_per_genre = max_genre_per_country.max_genre_number

/* Q3: Write a query that determines the customer that has spent the most on music for each country.
Write a query that returns the country along with the customers and how much they spent. for countries
where the top amount spent is shared, provide all customers who spent this amount. */

-- Method 1: Using Recursive CTE
with recursive
		customer_with_country as(
			select c.customer_id, c.first_name, c.last_name, i.billing_country, sum(i.total) as total_spending
			from invoice i
				join customer c on c.customer_id = i.customer_id
			group by 1,2,3,4
			order by 2,3 desc),
		country_max_spending as(
			select max(total_spending) as max_spending, billing_country
			from customer_with_country
			group by billing_country)
			
select cc.first_name, cc.last_name, cc.billing_country, cc.total_spending, cc.customer_id
from customer_with_country cc
	join country_max_spending ms on cc.billing_country = ms.billing_country
where cc.total_spending = ms.max_spending
order by 3;
	
-- Method 2: Using CTE

with customer_with_country as(
	select c.customer_id, first_name, last_name, billing_country, sum(total) as total_spending,
		row_number() over(partition by billing_country order by sum(total) desc ) as row_number
	from invoice i
		join customer c on c.customer_id = i.customer_id
	group by 1,2,3,4
	order by 4 asc, 5 desc)
select * from customer_with_country where row_number <= 1;
	
	
	 
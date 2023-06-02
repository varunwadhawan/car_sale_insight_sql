use cars_sales_data;
SELECT * FROM cars_sales_data.customer_data;
SELECT * FROM cars_sales_data.order_data;
SELECT * FROM cars_sales_data.product_data;
SELECT * FROM cars_sales_data.shipper_details;


-------------------------What is the distribution percentage of customers across states?-----------------------------------------

SELECT cd.state, ROUND((COUNT(od.order_id)/(SELECT COUNT(order_id) FROM cars_sales_data.order_data))*100,1) as Percentage_of_Customer_across_the_state
 FROM cars_sales_data.order_data AS od
JOIN cars_sales_data.customer_data AS cd 
ON cd.customer_id = od.customer_id
GROUP BY cd.state
order by Percentage_of_Customer_across_the_state DESC

------------------------What is the average rating in each quarter?----------------------------------------------------

WITH rating_table as (
	SELECT *, 
		CASE WHEN customer_feedback = 'Very Bad' THEN 1
		WHEN customer_feedback = 'Bad' THEN 2
		WHEN customer_feedback = 'Okay' THEN 3
		WHEN customer_feedback = 'Good' THEN 4
		WHEN customer_feedback = 'Very Good' THEN 5
	END AS R_table
FROM cars_sales_data.order_data)

SELECT quarter_number, ROUND(avg(R_table),1) as Avg_rating
FROM rating_table
GROUP BY quarter_number


------------------------------Are customers getting more dissatisfied over time?----------------------------------------------------


WITH rating_table as (
	SELECT *, 
		CASE WHEN customer_feedback = 'Very Bad' THEN 1
		WHEN customer_feedback = 'Bad' THEN 2
		WHEN customer_feedback = 'Okay' THEN 3
		WHEN customer_feedback = 'Good' THEN 4
		WHEN customer_feedback = 'Very Good' THEN 5
	END AS R_table
FROM cars_sales_data.order_data),

feedback_counts as (
	SELECT quarter_number ,
		SUM(CASE WHEN R_table = 1 THEN 1 else 0 END) as very_bad_counts,
        SUM(CASE WHEN R_table = 2 THEN 1 else 0 END) as bad_counts,
        SUM(CASE WHEN R_table = 3 THEN 1 else 0 END) as okay_counts,
        SUM(CASE WHEN R_table = 4 THEN 1 else 0 END) as good_counts,
        SUM(CASE WHEN R_table = 5 THEN 1 else 0 END) as very_good_counts,
        COUNT(*) as total_counts
FROM rating_table
GROUP BY quarter_number), 

feedback_percentage as (
	SELECT quarter_number,
		ROUND((very_bad_counts/total_counts)*100,0) as very_bad_per,
        ROUND((bad_counts/total_counts)*100,0) as bad_per,
       ROUND( (okay_counts/total_counts)*100,0) as okay_per,
        ROUND((good_counts/total_counts)*100,0) as good_per,
        ROUND((very_good_counts/total_counts)*100,0) as very_good_per
FROM feedback_counts )

SELECT quarter_number,very_bad_per, bad_per, okay_per, good_per, very_good_per
FROM feedback_percentage


---------------------------------Which are the top 5 vehicle makers preferred by the customer-----------------------------------------------------

SELECT 
pd.vehicle_maker, 
COUNT(od.customer_id) as order_count
FROM cars_sales_data.order_data as od
JOIN cars_sales_data.product_data as pd
ON od.product_id = pd.product_id
GROUP BY pd.vehicle_maker
ORDER BY order_count DESC limit 5


----------------------------What is the most preferred vehicle make in each state?--------------------------------------------------------------------

SELECT state, vehicle_maker,  customer_count
FROM (
  SELECT cd.state, pd.vehicle_maker,
         COUNT(*) AS customer_count,
         DENSE_RANK() OVER (PARTITION BY cd.state ORDER BY COUNT(*) DESC) AS rank_num
  FROM cars_sales_data.order_data AS od
  JOIN cars_sales_data.customer_data AS cd ON cd.customer_id = od.customer_id
  JOIN cars_sales_data.product_data AS pd ON pd.product_id = od.product_id
  GROUP BY cd.state, pd.vehicle_maker
) AS p
WHERE rank_num = 1
ORDER BY customer_count DESC


--------------------------------What is the trend of number of orders by quarters?--------------------------------------------------------------------------

SELECT quarter_number, COUNT(order_id) as no_of_order,
	ROUND((COUNT(order_id)/(SELECT COUNT(*) FROM cars_sales_data.order_data))*100,0) as Percentage
FROM cars_sales_data.order_data
GROUP BY quarter_number

-------------------------------What is the quarter over quarter % change in revenue?-------------------------------------------------------------------------

WITH price as(
SELECT quarter_number, car_price*quantity*(1-discount) as selling_price
FROM  cars_sales_data.order_data
),
sum_selling_price as  (
SELECT quarter_number, ROUND(SUM(selling_price),2) as total_sales
FROM price
GROUP BY quarter_number
),
sale_diff as (
SELECT quarter_number, total_sales,
LAG(total_sales) OVER (order by quarter_number) as previous_quater_sale,
ROUND(total_sales - LAG(total_sales) OVER (order by quarter_number),2) as sale_diff
FROM sum_selling_price
)

SELECT quarter_number, total_sales, previous_quater_sale, sale_diff, ROUND((sale_diff/previous_quater_sale)*100,2) as percentage_change
FROM sale_diff

----------------------------What is the trend of revenue and orders by quarters?--------------------------------------------------------------------------------


SELECT quarter_number, ROUND(SUM(Sale1),0) as Sale , COUNT(order_id) as no_of_customer
FROM (
SELECT od.quarter_number , od.order_id, ROUND(od.car_price*quantity*(1-discount),2) as Sale1
FROM cars_sales_data.customer_data as cd
JOIN cars_sales_data.order_data as od
on cd.customer_id = od.customer_id ) as p
GROUP BY 1

----------------------------What is the average discount offered for different types of credit cards?------------------------------------------------------------


SELECT cd.credit_card_type, ROUND(AVG(od.discount),2) as avg_discount
FROM cars_sales_data.customer_data as cd
JOIN cars_sales_data.order_data as od
on cd.customer_id = od.customer_id
GROUP BY cd.credit_card_type
ORDER BY avg_discount DESC

----------------------------What is the average time taken to ship the placed orders for each quarters?----------------------------------------------------------

WITH date_table as (
SELECT *, str_to_date(`order_date`, '%m/%d/%Y') as order_date1,
str_to_date(`ship_date`, '%m/%d/%Y') as ship_date1
from cars_sales_data.order_data)

SELECT quarter_number, AVG(days_taken)
FROM (
SELECT quarter_number, DATEDIFF(ship_date1, order_date1) as days_taken
from date_table ) as p
GROUP BY quarter_number


--------------------------------------------------------Percentage of Credit Card used to purchase car --------------------------------------------------------


SELECT cd.credit_card_type, ROUND(COUNT(od.customer_id)/(SELECT COUNT(customer_id) FROM cars_sales_data.order_data)*100,2) as No_of_credit_issued
FROM cars_sales_data.customer_data as cd
JOIN cars_sales_data.order_data as od 
on cd.customer_id = od.customer_id
JOIN cars_sales_data.product_data as pd
on od.product_id = pd.product_id
GROUP BY  cd.credit_card_type
ORDER BY No_of_credit_issued DESC

------------------------------------------No of Credit issued in different state-------------------------------------------------------------------------------

SELECT cd.state, cd.credit_card_type , COUNT(od.customer_id) as No_of_credit_issued
FROM cars_sales_data.customer_data as cd
JOIN cars_sales_data.order_data as od 
on cd.customer_id = od.customer_id
GROUP BY cd.state, cd.credit_card_type
ORDER BY No_of_credit_issued DESC

--------------------------------------------------------Cars preffered by different job title--------------------------------------------------------------

SELECT cd.job_title, pd.vehicle_maker, COUNT(od.customer_id) as No_of_car_purchased
FROM cars_sales_data.customer_data as cd
JOIN cars_sales_data.order_data as od 
on cd.customer_id = od.customer_id
JOIN cars_sales_data.product_data as pd
on od.product_id = pd.product_id
GROUP BY cd.job_title, pd.vehicle_maker
order by No_of_car_purchased DESC


-----------------------------------------------------State wise Cars Sale-----------------------------------------------------------------------------------------------

SELECT state, ROUND(SUM(sale1),2) as Sale
FROM (
SELECT od.customer_id, cd.state, od.car_price, od.quantity, od.discount, ROUND(od.car_price*quantity*(1-discount),2) as Sale1
FROM cars_sales_data.customer_data as cd
JOIN cars_sales_data.order_data as od
on cd.customer_id = od.customer_id 
) as p
GROUP BY 1
ORDER BY Sale DESC

------------------------------------------------------Top 5 Most rated Cars----------------------------------------------------------------------------------------------


WITH rating_table as (
	SELECT *, 
		CASE WHEN customer_feedback = 'Very Bad' THEN 1
		WHEN customer_feedback = 'Bad' THEN 2
		WHEN customer_feedback = 'Okay' THEN 3
		WHEN customer_feedback = 'Good' THEN 4
		WHEN customer_feedback = 'Very Good' THEN 5
	END AS r_table
FROM cars_sales_data.order_data)


SELECT pd.vehicle_maker ,COUNT(R.Quantity) as cars_ordered, AVG(R.r_table) as Avg_Rating
FROM rating_table as R
JOIN cars_sales_data.product_data as pd
on R.product_id = pd.product_id
GROUP BY pd.vehicle_maker
ORDER BY Avg_Rating desc LIMIT 5

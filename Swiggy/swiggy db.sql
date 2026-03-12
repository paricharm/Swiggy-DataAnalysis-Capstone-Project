USE [swiggy DB];
GO

select * from Swiggy_Data;
-------copy and rename teh table----------
------------------------------------------
select * into  swiggy from Swiggy_Data;
select * from swiggy;


---BUSINESS REQUIREMENTS---------
------------------------------------------------
-----DATA CLEANING & VALIDATION-----------------
--STEP 1:NULL CHECK---------------
select 
sum(case when State is null then 1 else 0 end),
sum(case when City is null then 1 else 0 end),
sum(case when Order_Date is null then 1 else 0 end),
sum(case when Restaurant_Name is null then 1 else 0 end),
sum(case when Location is null then 1 else 0 end),
sum(case when Category is null then 1 else 0 end),
sum(case when Dish_Name is null then 1 else 0 end),
sum(case when Price_INR is null then 1 else 0 end),
sum(case when Rating is null then 1 else 0 end),
sum(case when Rating_Count is null then 1 else 0 end)
FROM swiggy;
-----------------------------------------------------
--------ANOTEHR METHOD TO NULL CHECK-----------------
select *  from swiggy where State is null or
City is null or
Order_Date is null or
 Restaurant_Name is null or
 Location is null or
 Category is null or
 Dish_Name is null or
 Price_INR is null or
 Rating is null or
 Rating_Count is null 

------Blank or Empty strings-------------------
-----------------------------------------------
select * from swiggy
where state=''or city=''or Restaurant_Name=''or category=''
or Dish_Name='';

-----Duplicate records find----------------
select state,city,order_date,restaurant_name,location,
category,dish_name,price_inr,rating,rating_count,count(*) as CNT from swiggy
group by state,city,order_date,restaurant_name,location,
category,dish_name,price_inr,rating,rating_count
having count(*)>1;

----duplicate deletion-----------
WITH cte AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY 
                   state, city, order_date, restaurant_name, location,
                   category, dish_name, price_inr, rating, rating_count
               ORDER BY (SELECT NULL)
           ) AS rn
    FROM swiggy
)
DELETE FROM cte
WHERE rn > 1;

-----SCHEMA REPRESENTATION-----------------
-------------DIM DATE---------------------

create table Dim_Date(
Date_Id INT Identity(1,1) PRIMARY KEY,
Full_date DATE,
Year INT,
Month INT,
Month_name varchar(20),
Quarter INT, 
Day INT,
week int
)
drop table dim_date
drop table fact_swiggy_orders
select * from Dim_Date

--DIM_LOCATION 
create table Dim_Location(
Location_Id INT Identity(1,1) PRIMARY KEY,
State varchar(100),
City varchar(100),
Location varchar(200)
)


select * from Dim_Location 

--DIM_RESTAURANT
create table Dim_Restaurant(
Restaurant_Id INT Identity(1,1) PRIMARY KEY,
Restaurant_Name varchar(200)
)

select * from Dim_Restaurant 

--DIM_CATEGORY
create table Dim_Category(
Category_Id INT Identity(1,1) PRIMARY KEY,
Category varchar(200)
)

select * from Dim_Category 

--DIM_DISH
create table Dim_Dish(
Dish_Id INT Identity(1,1) PRIMARY KEY,
Dish_name varchar(200)
)

select * from Dim_Dish
select * from Dim_Category
select * from Dim_Location
select * from Dim_Date 
select * from Dim_Restaurant
-----------------------------------------------------------------

--fact table ------------------
drop table fact_swiggy_orders

create table fact_swiggy_orders(
    order_id int identity(1,1) primary key,
    date_id int,
    location_id int,
    restaurant_id int,
    category_id int,
    dish_id int,
    price_inr decimal(10,2),
    rating_count int,
    rating decimal(10,2),

    foreign key(location_id) references dim_location(location_id),
    foreign key(restaurant_id) references dim_restaurant(restaurant_id),
    foreign key(category_id) references dim_category(category_id),
    foreign key(dish_id) references dim_dish(dish_id),
    foreign key(date_id) references dim_date(date_id))

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------NOW INSERT VALUES INTO DIM TABLES------------------------------

insert into dim_dish(dish_name)
select distinct dish_name from swiggy

-----------------------------------------------------------------------------------------
insert into Dim_Restaurant(Restaurant_Name)
select distinct restaurant_name from swiggy;

-----------------------------------------------------------------------------------------

insert into Dim_category(category)
select distinct category from swiggy;

-------------------------------------------------------------------------------------------

insert into Dim_Location(state,city,location)
select distinct 
state,city,location from swiggy;
----------------------------------------------------------------------------------------
insert into Dim_date(Full_date,
Year,
Month,
Month_name,
Quarter, 
Day,
week)
select distinct
order_date,

Year (order_date),
Month (order_date),
datename(Month,order_date),
datepart(Quarter,order_date), 
Day(order_date),
datepart(WEEK,order_date)
from swiggy where order_date is not null;

select * from swiggy;

----------------------------------------------------------------------------------------
--fact tables--
insert into fact_swiggy_orders(
    date_id,price_inr,rating,rating_count,location_id,restaurant_id,
category_id,dish_id)
select
    dd.date_id,
    s.price_inr,
    s.rating,
    s.rating_count,
    
    dl.location_id,
    dr.restaurant_id,
    dc.category_id,
    ds.dish_id
    
    from swiggy s

    join dim_date dd on dd.full_date=s.order_date

    join dim_location dl on dl.state=s.state and dl.city = s.city and dl.location=s.location

    join Dim_Restaurant dr on dr.Restaurant_Name=s.Restaurant_Name

    join Dim_Category dc on dc.Category=s.Category
    
    join Dim_dish ds on ds.dish_name=s.dish_name;

select * from fact_swiggy_orders
---------------------------------------------------------------------------------------
select * from fact_swiggy_orders

select * from fact_swiggy_orders as f
join dim_date d on f.date_id=d.date_id
join dim_location l on f.location_id=l.location_id
join Dim_Restaurant r on f.Restaurant_id=r.Restaurant_id
join Dim_category c on f.category_id=c.category_id
join Dim_dish di on f.dish_id=di.dish_id

select * from fact_swiggy_orders
------Total Orders--------------------------------------------------------------------

select count(*) as total_orders from fact_swiggy_orders

-----Total Revenue--------------------------------------------------------------------

select format(sum(convert(float,price_inr))/1000000,'N2') + ' INR Million' as Total_Revenue from fact_swiggy_orders;

-----Avg Dish Price-----------------------------------------------------------------------

select format(avg(convert(float,price_inr)),'N2') + ' INR' as Avg_dish_price from fact_swiggy_orders;

----Avg Rating--------------------------------------------------------------------------
 
select avg(rating) as avg_rating from fact_swiggy_orders

------------Date-Based Analysis----Monthly order trends-------------------------------
--
select
d.year,
d.month,
d.month_name, sum(price_inr) as Monthly_treds from fact_swiggy_orders f
join dim_date d on f.date_id=d.date_id
group by 
d.year,
d.month,
d.month_name
order by sum(price_inr) desc 

------------------•	Quarterly order trends-----------------------------------------

select
d.year,
d.quarter,
count(*) as Quarterly_Trends from fact_swiggy_orders f
join dim_date d on f.date_id=d.date_id
group by 
d.year,

d.quarter
order by count(*) desc 

select * from fact_swiggy_orders
select * from dim_date
-------•	Year-wise growth----------------------------------------------------------
select d.year,
count(*) as Year_trends
from fact_swiggy_orders f
join dim_date d on f.date_id = d.date_id

group by d.year
order by count(*) desc


---------------	Day-of-week patterns--------------------------------------------------

select * from fact_swiggy_orders
select * from dim_date

-------Day-of-week pat terns-------------------------------------------------------
select
datename(weekday,d.full_date),count(*) as Day_week_patterns from fact_swiggy_orders f
join dim_date d on f.date_id=d.date_id

group by datename(weekday,d.full_date),datepart(weekday, d.full_date)
order by datename(weekday,d.full_date)


---Location-Based Analysis
---------------------Top 10 cities by order volume----------------------------
select  * from Dim_Location;
select *  from fact_swiggy_orders

select top 10 l.city,sum(price_inr) as order_volume from fact_swiggy_orders f
join dim_location l on f.Location_Id=l.location_id
group by city 
order by sum(price_inr) desc

------	Revenue contribution by states---------------------------------------------------
select l.State,sum(price_inr) as revenue_contribution from fact_swiggy_orders f
join dim_location l on l.Location_Id=f.location_id
group by state
order by sum(price_inr) desc

--------------Food Performance---------------------------------------------------------
-----Top 10 restaurants by orders-----------------------------------------------------
select * from Dim_Restaurant
select * from fact_swiggy_orders

select top 10 r.Restaurant_Name,sum(price_inr) as Order_value from fact_swiggy_orders f
join Dim_Restaurant r on r.Restaurant_Id=f.restaurant_id
group by Restaurant_Name
order by sum(price_inr) desc

----------Top categories (Indian, Chinese, etc.)--------------------------------------

select * from Dim_Category
select * from fact_swiggy_orders
select * from swiggy

select c.category,count(*) from fact_swiggy_orders f
join dim_category c on c.category_id=f.category_id
group by category
order by count(*) desc
-----------Most ordered dishes------------------------------------------------------
select * from dim_dish

select di.dish_name,count(*) from fact_swiggy_orders f
join dim_dish di on di.dish_id=f.dish_id
group by dish_name
order by count(*) desc
------------Cuisine performance → Orders + Avg Rating----------------------------------
select * from swiggy

select c.category,count(*) as orders,
avg(rating) as avg_rating
from fact_swiggy_orders f
join dim_category c on c.category_id=f.category_id
group by category
order by count(*) desc

------------Customer Spending Insights
-------Buckets of customer spend:-----------------------------------------------------
--------Under 100,,100–199,,200–299,,,300–499,,500+------------------------------------

select
case
when convert(float,price_inr)<100 then 'under 500'
when convert(float,price_inr) between 100 and 199 then ' 100-199'
when convert(float,price_inr) between 200 and 299 then ' 200-299'
when convert(float,price_inr) between 300 and 399 then ' 300-499'

else '500+'
end 
as price_range,count(*) from fact_swiggy_orders
group by
case
when convert(float,price_inr)<100 then 'under 500'
when convert(float,price_inr) between 100 and 199 then ' 100-199'
when convert(float,price_inr) between 200 and 299 then ' 200-299'
when convert(float,price_inr) between 300 and 399 then ' 300-499'

else '500+'
end 

order by count(*) desc;

---------------------------Ratings Analysis-----------------------------
--------------------Distribution of dish ratings from 1–5----------------------
select * from fact_swiggy_orders

select rating,count(*) as rating_count from fact_swiggy_orders
group by rating
order by count(*) desc
-----------------------------------------------------------------------------
----------END----------------------------------------------------------------

















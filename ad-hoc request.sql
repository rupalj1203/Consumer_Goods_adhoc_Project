
-- 1. List of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

select distinct market 
from dim_customer
where customer = "Atliq Exclusive" and region = "APAC";

-- 2. The percentage of unique product increase in 2021 vs. 2020

with products2020 as (
		select count(*) as unique_product_2020
		from dim_product as a 
		join fact_manufacturing_cost as b
		on a.product_code = b.product_code 
		where cost_year=2020) ,
     products2021 as (
		select count(*) as unique_product_2021
		from dim_product as a 
		join fact_manufacturing_cost as b
		on a.product_code = b.product_code 
		where cost_year=2021)
 
select 
      a.unique_product_2020,
      b.unique_product_2021,
      round((b.unique_product_2021-a.unique_product_2020)*100/a.unique_product_2020,2) as percentage_chg
from products2020 a
join products2021 b ;

-- 3. All the unique product counts for each segment and sorting them in descending order of product counts.

select distinct segment , count( distinct product ) as product_count  
from dim_product 
group by segment 
order by product_count desc ;

-- 4. Segment which had the most increase in unique products in 2021 vs 2020.

select d.segment , d.product_count_2020 ,e.product_count_2021, (e.product_count_2021-d.product_count_2020) as difference
from
(select distinct c.segment , count(c.product) as product_count_2020
from
(select a.product_code , a.segment ,a.product , b.cost_year
from dim_product as a
join fact_manufacturing_cost b
on a.product_code = b.product_code
where b.cost_year=2020) c
group by c.segment) d
left join
(select distinct c.segment , count(c.product) as product_count_2021
from
(select a.product_code , a.segment ,a.product , b.cost_year
from dim_product as a
join fact_manufacturing_cost b
on a.product_code = b.product_code
where b.cost_year=2021) c
group by c.segment) e
on d.segment=e.segment
order by difference desc;


-- 5. Products that have the highest and lowest manufacturing costs.

with d as (
		select a.product_code, a.product,b.manufacturing_cost
		from dim_product a
		join fact_manufacturing_cost b
		on  a.product_code=b.product_code) 
select product_code , product , manufacturing_cost 
from d
where manufacturing_cost = (select min(manufacturing_cost) from d) 
union
select product_code , product , manufacturing_cost 
from d
where manufacturing_cost = (select max(manufacturing_cost) from d);

-- 6. Top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. 

with average_high_pre_invoice as (
			select *
			from fact_pre_invoice_deductions
			where pre_invoice_discount_pct > (select avg(pre_invoice_discount_pct) from fact_pre_invoice_deductions)
			)
select 
      customer_code , 
      customer , 
      round(pre_invoice_discount_pct*100,2) as average_discount_percentage
from average_high_pre_invoice
join dim_customer 
using (customer_code)
where fiscal_year = 2021 and market = 'India'
group by customer_code
order by average_discount_percentage desc
limit 5  ;

-- 7. The Gross sales amount for the customer “Atliq Exclusive” for each month. 

select 
      monthname(s.date) as  Month , 
      year(s.date) as Year , 
      round(sum(s.sold_quantity*gp.gross_price),2) as 'Gross sales Amount'
from dim_customer c
join fact_sales_monthly  s
using (customer_code)
join fact_gross_price    gp
using (product_code)
where customer = 'Atliq Exclusive'
group by Month , Year ;

-- 8. In which quarter of 2020, got the maximum total_sold_quantity
 
with Quarter_year as (
	  select date , 
            month(date)  ,
            sold_quantity ,
			case when month(date) in (9,10,11) then 1
				 when month(date) in (12,1,2) then 2
				 when month(date) in (3,4,5) then 3
				 when month(date) in (6,7,8) then 4
			end  as Quarter      
	from fact_sales_monthly
    where fiscal_year=2020)

select Quarter, sum(sold_quantity) as total_sold_quantity
from Quarter_year
group by Quarter
order by total_sold_quantity desc ;

-- 9. Channel that helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution

with gross_sale as (
		select c.channel, 
		round(sum(sm.sold_quantity*gp.gross_price)/1000000,2) as grosssale
		from fact_gross_price gp
		join fact_sales_monthly sm
		using (product_code)
		join dim_customer c
		using(customer_code)
		where sm.fiscal_year=2021
		group by channel
		)
select 
      channel,
      grosssale , 
      round(grosssale*100/(select sum(grosssale) from gross_sale),2) as percentage
from gross_sale
group by channel
order by percentage desc
;

-- 10.Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021

with division_product as 
		(select division , product_code, product , sum(sold_quantity) as total_sold_quantity
		from dim_product p
		JOIN fact_sales_monthly sm
		using (product_code)
		GROUP BY product
		order by total_sold_quantity desc) ,
   product_ranking as  
        (select division , product_code, product , total_sold_quantity,
               rank () over ( 
							 partition by division 
							 order by total_sold_quantity desc
							) rank_order 
		 from division_product)

select division , product_code , product ,  total_sold_quantity,rank_order
from product_ranking
where rank_order <4;











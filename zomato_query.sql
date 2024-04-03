/*Inspecting the data*/
select * from users;
select * from goldusers_signup;
select * from sales;
select * from product;

/*Total amount spend by each customer*/
select a.userid, sum(b.price) as total_amount_spent from sales a inner join product b on a.product_id=b.product_id group by a.userid;
/*userid 1: 7190
         2: 3490
         3: 6530*/
                           
/*Total no of days each customer visited the app*/
select userid, count(distinct(created_date)) as no_of_days_visited from sales group by userid;
/* userid 1:	7
          2:	4
          3:	5*/

/*First product purchased by each of the customer*/
select * from
(select userid,created_date, product_id, rank() over(partition by userid order by created_date) rank from sales) 
where rank=1;
/*Product Id: 3 has been the first choice of customer*/

/*The most purchased item on the menu and no. of times it was purchased by all the customers*/
select userid, count(product_id) as cnt 
from sales where product_id in 
(select product_id from sales group by product_id order by count(product_id) desc) 
group by userid;
/*Product Id: 2 is the most purchased product and purchased 7 times*/

/*The most popular for each customer*/
select * from 
(select userid, product_id, cnt, rank() over(partition by userid order by cnt desc) rnk from
(select userid, product_id, count(product_id) cnt from sales group by userid, product_id)) where rnk =1;
/*Product Id: 2 is the most popular product*/

/*First item purchased by the customer after they become a member*/
select * from 
(select c.*,rank() over(partition by userid order by created_date) rnk from 
(select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales a INNER JOIN goldusers_signup b on a.userid=b.userid and a.created_date>=b.gold_signup_date order by a.userid)c) 
where rnk =1;
/*userid created_date product_id gold_signup_date rank
  1	      19-03-18	    3	        22-09-17	  1
  3	      12-07-17	    2	        21-04-17	  1*/
  
/*The item purchased just before the customer became a member*/
select * from 
(select c.*, rank() over(partition by userid order by created_date desc) rnk from 
(select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales a INNER JOIN goldusers_signup b on a.userid = b.userid and a.created_date <= b.gold_signup_date order by a.userid)c) 
where rnk = 1;
/*userid created_date product_id gold_signup_date rank
    1	    19-04-17	2	        22-09-17	    1
    3	    20-12-16	2	        21-04-17	    1*/
    
/*Total orders and amounts spent for each member before they became member*/
select userid, count(created_date) as Total_order_purchased, sum(price) as Total_amount_spend from
(select c.*, d.price from
(select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales a INNER JOIN goldusers_signup b 
  on a.userid = b.userid and a.created_date < b.gold_signup_date order by a.userid)c 
  INNER JOIN product d on c.product_id = d.product_id)
  group by userid;
/*userid Total_order_purchased Total_amount_spend
    1	        7	                5990
    3	        4	                3700*/

/* a)If byuing each product generates points for eg: 5rs = 2 zomato point and each product has differnt purchasing points 
    for p1 5rs = 1 zomato point, for p2 10rs = 5 (2rs = 1 zomato point) zomato point and p3 5rs = 1 zomato points
    b)Calculate points collected by each customers and for which product most points have been given till now. --each zomato point = 2.5rs(5rs/2)*/
a)
select f.userid, sum(total_points) total_points_earned, sum(total_points)*2.5 total_points_earned from --according to the points they hv earned, calculation of total cashback they have received
(select e.*, amount/points total_points from   --total points they have earned acoording to the price they have spend group by userid
(select d.*, case when product_id = 1 then 5
                 when product_id = 2 then 2
                 when product_id = 3 then 1
                 else 0 end as points from                     --points applicable product wise
(select c.userid, c.product_id,c.product_name, sum(price) amount from --product wise sum of amount spend by user
(select a.userid, a.product_id, b.product_name, b.price from sales a INNER JOIN product b on a.product_id = b.product_id)c --total details of users with their purchased product
group by userid,product_id,product_name order by userid)d)e)f group by userid;
/*userid total_points_earned total_points_earned
    1	        2749	        6872.5
    2	        1487	        3717.5
    3	        2089	        5222.5 */

b)select * from --gives that exact product which has the highest purchased
(select g.*,rank() over(order by total_points_earned desc) rnk from --gives the rank according to the spend over product
(select product_id, sum(total_points) total_points_earned from --total points earned according to the product category
(select e.*, amount/points total_points from   --total points they have earned acoording to the price they have spend group by userid
(select d.*, case when product_id = 1 then 5
                 when product_id = 2 then 2
                 when product_id = 3 then 1
                 else 0 end as points from                     --points applicable product wise
(select c.userid, c.product_id, sum(price) amount from --product wise sum of amount spend by user
(select a.* , b.price from sales a INNER JOIN product b on a.product_id = b.product_id)c --total details of users with their purchased product
group by userid,product_id order by userid)d)e)f group by product_id)g) where rnk = 1;
/*Product Id: 2 has earned the highest creadit point*/

/*In the first one year after a customer joins the gold program(including their join date) irrespective 
of what the customer has purchased they earn 5 zomato points for every 10rs spent, who earned more than 1 or 3 
and what was their points earnings in their first year? note: 1zp = 2rs => 0.5zp = 1rs*/
select * from
(select g.*, rank() over(order by total_points_earned desc) rnk from
(select c.*, d.price, d.price* 0.5 as total_points_earned from -- get the price of the products purchased in an year after buying gold
(select a.*, b.gold_signup_date from sales a INNER JOIN goldusers_signup b on a.userid=b.userid ---to get the customers who have purchased in an year after taking gold
and a.created_date>=b.gold_signup_date and created_date<= to_char(add_months(gold_signup_date,12),'dd-mm-yyyy'))c
INNER JOIN product d on c.product_id = d.product_id)g) where rnk = 1;
/*The userid 2 has earned the highest earning of 435 points*/

/*Rank all the transactions of the customer*/
select userid,created_date,product_id, rank() over(partition by userid order by created_date desc) rnk from sales;

/*Rank all the transactions for each member whenver they are a zomato gold member for every non-gold member transaction mark as NA*/
select e.*, 
    case when rnk = 0 then 'NA' else rnk end as rnkk 
from (
     select c.*,cast((case when gold_signup_date is null then 0 
        else rank() over(partition by userid order by created_date desc) end) as varchar) as rnk 
    from(
        select a.userid, a.created_date, a.product_id, b.gold_signup_date 
        from sales a LEFT JOIN goldusers_signup b 
        on a.userid = b.userid and a.created_date>=b.gold_signup_date)c) e;

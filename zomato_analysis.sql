

CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 
INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017')

CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;



/*  Exploratory Data Analysis  */



/*what is the total ammount each customer spent on zomato
*/


select s.userid,sum(p.price) total_amnt_spent
from sales s join users u
on s.userid=u.userid join product p on p.product_id=s.product_id
group by s.userid



/*how many days has each customer visited zomato
*/

select userid,count(distinct(created_date))as days_visited 
from sales
group by userid



/*what was the first product purchased by each customer
*/


select * from
(select*,DENSE_RANK() over (partition by userid order by created_date) ran_k
from sales)z
where ran_k=1




/*what is the most purchased item on the menu and how many times was it purchased 
  by all customers?
*/


with cte as
(select *,count(userid) over (partition by product_id)cnt from sales
group by product_id,userid,created_date)
select userid,count(cnt)no_of_time_purchased from cte where product_id='2' group by userid



/*which item was the most popular for each customer
*/


select userid, product_id,cnt from
(select*,dense_rank() over (partition by userid order by cnt desc )r from
(select userid,product_id,count(product_id)cnt from sales
group by userid, product_id)a)b
where r='1'



/*which item was purchased first by the customer after they became a member
*/


select * from
(select s.userid,s.created_date,s.product_id,
DENSE_RANK() over (partition by s.userid order by s.created_date)r
from sales s join goldusers_signup g
on s.userid=g.userid
where s.created_date>g.gold_signup_date)a where r='1'



/*which item was purchased just before the customer beacame a member
*/


select * from
(select s.userid,s.created_date,s.product_id,
DENSE_RANK() over (partition by s.userid order by s.created_date desc)r
from sales s join goldusers_signup g
on s.userid=g.userid
where s.created_date<g.gold_signup_date)a where r='1'



/*what is the total orders and amount spent for each member before they became a member?
*/


select userid,sum(cnt)order_count,sum(amnt_spent)sum_of_amnt from
(select s.userid, s.product_id,count(s.product_id)cnt,sum(p.price)amnt_spent
from sales s join goldusers_signup g
on s.userid=g.userid join product p on s.product_id=p.product_id
where s.created_date<g.gold_signup_date
group by s.userid, s.product_id)a
group by userid




/*if buying each product generates points for eg 5rs=2 zomato point and each product has different
  purchasing points for eg p1 5rs=1 zomato point, for p2 10rs=5 zomato point and
  p3 5 rs=1 zomato point

  calculate points collected by each customer and for which product most points have been given
  till now
*/


select *,total_points*2.5 as cashback  from
(select userid,sum(points)total_points from
(select y.*,sum_of_sale/per_point as points from
(select x.*,case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 
else 0 end as per_point from
(select userid,product_id,sum(price)sum_of_sale from
(select s.*,p.price
from sales s join product p
on s.product_id=p.product_id)z
group by userid,product_id)x)y)a
group by userid)l



with cte as
(select product_id,sum(points)total_points from
(select y.*,sum_of_sale/per_point as points from
(select x.*,case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 
else 0 end as per_point from
(select userid,product_id,sum(price)sum_of_sale from
(select s.*,p.price
from sales s join product p
on s.product_id=p.product_id)z
group by userid,product_id)x)y)a
group by product_id) select * from cte
where total_points=(select max(total_points)from cte)






/*in the first one year after the customer join the gold program(including their join date)
  irrespective of what the cutomer has purchased they earn 5 zomato points for every 10rs
  spent who earned more 1 or 3 and what was their points earning in the first year?
*/

select *,price/2 as points from
(select s.*,p.price
from sales s join goldusers_signup g
on s.userid=g.userid join product p
on s.product_id=p.product_id
where s.created_date>=g.gold_signup_date and created_date<=DATEADD(year,1,g.gold_signup_date)
)a



/*rank all the transaction of the customer
*/


select s.*,p.price,rank() over (partition by userid order by created_date)rnk
from sales s join product p
on s.product_id=p.product_id



/*rank all the transactions for each member whenever they are a gold member for every non
  gold member transaction mark as na
*/


select userid,product_id,created_date,gold_signup_date,case when rnk=0 then 'na' else rnk end rnkk   from
(select a.*,cast((case when gold_signup_date is null then 0 else rank() 
over(partition by userid order by created_date desc) end)as varchar) rnk from
(select s.userid,s.product_id,s.created_date,g.gold_signup_date
from sales s left join goldusers_signup g
on s.userid=g.userid and created_date>=gold_signup_date)a)b

-- 🚀 Customer Behavior & Flight Patterns

-- 1. Who are the most frequent flyers? List the top 10 customers by total number of flights over all time.

SELECT loyalty_number AS "Loyalty Numbers",
  flights_booked AS "Number of Flights"
FROM customer_flight_activity
WHERE flights_booked >= 10
ORDER BY flights_booked DESC 
LIMIT 10 ;

SELECT MAX(flights_booked)
FROM customer_flight_activity ;

-- returned 21

-- 2. How many flights are booked with companions? 

SELECT SUM(flights_with_companions) AS total_companion_flights
FROM customer_flight_activity ;

-- returned 416207

-- Aggregate the number or percentage of companion flights across all customers or per loyalty tier.

SELECT 
  H.loyalty_card,
  SUM(F.flights_with_companions) AS total_companion_flights,
  SUM(F.total_flights) AS total_flights,
  ROUND(SUM(F.flights_with_companions) * 100.0 / NULLIF(SUM(F.total_flights), 0), 2) AS percentage_with_companions
FROM customer_flight_activity AS F
JOIN customer_loyalty_history AS H 
ON F.loyalty_number = H.loyalty_number
GROUP BY H.loyalty_card
ORDER BY percentage_with_companions DESC ;

"loyalty_card","total_companion_flights","total_flights","percentage_with_companions"
"Star","190265","947938","20.07"
"Aurora","85553","427533","20.01"
"Nova","140389","702345","19.99"


-- 3. What is the average distance flown by customers in each province?

SELECT H.province,
  ROUND(AVG(F.distance), 2) AS avg_distance_flown
FROM customer_flight_activity AS F
JOIN customer_loyalty_history AS H
ON F.loyalty_number = H.loyalty_number
GROUP BY H.province
ORDER BY avg_distance_flown DESC ;

"province","avg_distance_flown"
"Yukon","1291.07"
"New Brunswick","1259.40"
"British Columbia","1219.05"
"Alberta","1218.79"
"Nova Scotia","1215.22"
"Ontario","1215.17"
"Saskatchewan","1205.60"
"Quebec","1200.63"
"Manitoba","1189.88"
"Newfoundland","1182.89"
"Prince Edward Island","1161.28"



-- 4. Are there seasonal trends in flight bookings?

SELECT F.MONTH,
  SUM(F.flights_booked) AS total_flights_booked
FROM customer_flight_activity AS F
GROUP BY F.month
ORDER BY total_flights_booked DESC ;

"month","total_flights_booked"
7,"192602"
6,"172528"
8,"168516"
12,"165327"
5,"141538"
9,"135813"
3,"130425"
10,"128785"
11,"121766"
4,"111988"
1,"96604"
2,"95717"


-- June, August, and July are the top 3

-- 💰 Loyalty Points & Financials

-- 5. Which loyalty tier (Star vs Aurora) accumulates and redeems the most points?

SELECT H.loyalty_card,
  SUM(F.points_redeemed) AS total_points_redeemed,
  SUM(F.points_accumulated) AS total_points_accumulated
FROM customer_flight_activity AS F
JOIN customer_loyalty_history AS H
ON F.loyalty_number = H.loyalty_number
GROUP BY H.loyalty_card
ORDER BY total_points_accumulated DESC ; 

"loyalty_card","total_points_redeemed","total_points_accumulated"
"Star","5673211",22467445.000000026
"Nova","4126568",16859774.5
"Aurora","2562347",10550164.5


-- returned Star, Nova, Aura respectively

-- 6. Is there a relationship between customer salary and points accumulated or redeemed?

-- Divide by salary ranges

SELECT
    CASE
        WHEN H.salary < 50000 THEN 'Low Salary (< $50k)'
        WHEN H.salary >= 50000 AND H.salary < 100000 THEN 'Medium Salary ($50k - $100k)'
        ELSE 'High Salary (>$100k)'
    END AS salary_bracket,
    ROUND(AVG(F.points_accumulated)::numeric, 2) AS avg_points_accumulated,
    ROUND(AVG(F.points_redeemed)::numeric, 2) AS avg_points_redeemed
FROM customer_loyalty_history AS H
JOIN customer_flight_activity AS F
ON H.loyalty_number = F.loyalty_number
GROUP BY salary_bracket
ORDER BY MIN(H.salary);

"salary_bracket","avg_points_accumulated","avg_points_redeemed"
"Low Salary (< $50k)","122.05","31.65"
"Medium Salary ($50k - $100k)","124.11","30.33"
"High Salary (>$100k)","124.61","31.41"


-- Divide ba salary quantiles

WITH CustomerQuantiles AS (
    SELECT
        H.loyalty_number,
        H.salary,
        F.points_accumulated,
        F.points_redeemed,
        -- This function divides all customers into 4 equal groups based on their salary
        NTILE(4) OVER (ORDER BY H.salary) AS salary_quantile
    FROM
        customer_loyalty_history AS H
    JOIN
        customer_flight_activity AS F
        ON H.loyalty_number = F.loyalty_number
)
SELECT
    salary_quantile,
    ROUND(AVG(points_accumulated)::numeric, 2) AS avg_points_accumulated,
    ROUND(AVG(points_redeemed)::numeric, 2) AS avg_points_redeemed,
    COUNT(DISTINCT loyalty_number) AS num_of_customers
    -- COUNT(loyalty_number) AS num_of_customers
FROM CustomerQuantiles
GROUP BY salary_quantile
ORDER BY salary_quantile ;


"salary_quantile","avg_points_accumulated","avg_points_redeemed","num_of_customers"
1,"122.21","30.39","4187"
2,"124.01","30.31","4186"
3,"125.93","30.97","5354"
4,"124.53","31.42","4237"


-- 7. What’s the average 'dollar cost of points redeemed' per customer, and how does that differ by region or card type?

-- By loyalty card types

SELECT H.loyalty_card,
  ROUND(AVG(F.dollar_cost_points_redeemed), 2) AS dollor_cost_points_redeemed
FROM customer_flight_activity AS F
JOIN customer_loyalty_history AS H 
ON F.loyalty_number = H.loyalty_number
GROUP BY H.loyalty_card 
ORDER BY dollor_cost_points_redeemed DESC;

"loyalty_card","dollor_cost_points_redeemed"
"Aurora","2.52"
"Star","2.51"
"Nova","2.45"


-- Regions

SELECT H.province,
  ROUND(AVG(F.dollar_cost_points_redeemed), 2) AS dollor_cost_points_redeemed
FROM customer_flight_activity AS F
JOIN customer_loyalty_history AS H 
ON F.loyalty_number = H.loyalty_number
GROUP BY H.province
ORDER BY dollor_cost_points_redeemed DESC;

"province","dollor_cost_points_redeemed"
"New Brunswick","2.53"
"Quebec","2.53"
"Nova Scotia","2.52"
"Ontario","2.49"
"Prince Edward Island","2.49"
"British Columbia","2.49"
"Alberta","2.45"
"Manitoba","2.45"
"Newfoundland","2.40"
"Saskatchewan","2.40"
"Yukon","2.28"


-- Regions + Loyalty card

SELECT H.province,
  H.loyalty_card,
  ROUND(AVG(F.dollar_cost_points_redeemed), 2) AS dollor_cost_points_redeemed
FROM customer_flight_activity AS F
JOIN customer_loyalty_history AS H 
ON F.loyalty_number = H.loyalty_number
GROUP BY H.province, H.loyalty_card
ORDER BY dollor_cost_points_redeemed DESC;

"province","loyalty_card","dollor_cost_points_redeemed"
"Prince Edward Island","Aurora","3.74"
"Saskatchewan","Aurora","2.82"
"Newfoundland","Aurora","2.72"
"Manitoba","Aurora","2.71"
"Nova Scotia","Aurora","2.68"
"New Brunswick","Star","2.65"
"Manitoba","Star","2.61"
"Nova Scotia","Nova","2.60"
"Quebec","Nova","2.58"
"Ontario","Star","2.52"
"Ontario","Aurora","2.52"
"British Columbia","Star","2.51"
"Quebec","Star","2.51"
"Quebec","Aurora","2.48"
"Alberta","Aurora","2.47"
"British Columbia","Aurora","2.47"
"British Columbia","Nova","2.47"
"New Brunswick","Nova","2.47"
"Alberta","Star","2.46"
"Ontario","Nova","2.44"
"Alberta","Nova","2.43"
"Newfoundland","Star","2.42"
"Yukon","Star","2.40"
"Nova Scotia","Star","2.39"
"New Brunswick","Aurora","2.38"
"Saskatchewan","Nova","2.35"
"Prince Edward Island","Star","2.31"
"Saskatchewan","Star","2.25"
"Yukon","Aurora","2.24"
"Newfoundland","Nova","2.16"
"Yukon","Nova","2.08"
"Prince Edward Island","Nova","2.05"
"Manitoba","Nova","2.03"


-- 8. Which customers have high point accumulation but low redemption?
-- Identify potential upsell or engagement targets.

WITH CustomerPointsSummary AS (
    SELECT
        F.loyalty_number,
        SUM(F.points_accumulated) AS total_points_accumulated,
        SUM(F.points_redeemed) AS total_points_redeemed
    FROM customer_flight_activity AS F
    GROUP BY F.loyalty_number
)
SELECT
    CPS.loyalty_number,
    H.loyalty_card,
    CPS.total_points_accumulated,
    CPS.total_points_redeemed
FROM CustomerPointsSummary AS CPS
JOIN customer_loyalty_history AS H
ON CPS.loyalty_number = H.loyalty_number
WHERE
    -- Condition for "high accumulation" (e.g., more than 1000 points)
    CPS.total_points_accumulated > 1000
    AND
    -- Condition for "low redemption" (e.g., redemption ratio is less than 5%)
    (CAST(CPS.total_points_redeemed AS DECIMAL) / NULLIF(CPS.total_points_accumulated, 0)) < 0.05
ORDER BY CPS.total_points_accumulated DESC ;


-- 🧑‍🤝‍🧑 Customer Demographics & Segmentation

-- 9. How does marital status or gender relate to flight behavior or loyalty points usage?

WITH CustomerStatus AS (
  SELECT
    H.marital_status,
    SUM(F.points_accumulated) AS total_points_accumulated,
    SUM(F.points_redeemed) AS total_points_redeemed
  FROM customer_flight_activity AS F
  JOIN customer_loyalty_history AS H 
  ON F.loyalty_number = H.loyalty_number
  GROUP BY H.marital_status
)
SELECT 
  CS.marital_status,
  CS.total_points_accumulated,
  CS.total_points_redeemed
FROM CustomerStatus AS CS 
ORDER BY CS.total_points_accumulated DESC;

"marital_status","total_points_accumulated","total_points_redeemed"
"Married",29056092.48000002,"7162842"
"Single",13383501.570000015,"3313838"
"Divorced",7437789.949999997,"1885446"



-- 10. Which education levels are most associated with high CLV or frequent travel?
-- Customer lifetime value - total invoice value for all flights ever booked by member

SELECT H.education,
  ROUND(AVG(H.clv),2) AS avg_clv
FROM customer_flight_activity AS F
JOIN customer_loyalty_history AS H 
ON F.loyalty_number = H.loyalty_number
GROUP BY H.education
ORDER BY avg_clv DESC ;

"education","avg_clv"
"Bachelor","8206.99"
"Doctor","7832.92"
"High School or Below","7707.08"
"College","7594.57"
"Master","7440.62"


-- Bachelor, Doctor, High School or Below, College, Master respectively

-- 11. Are there provinces with significantly higher or lower CLV averages?

-- Avg clv
SELECT ROUND(AVG(H.clv),2)
FROM customer_loyalty_history AS H ;

-- return 7988.90

-- Below average

SELECT
    province,
    ROUND(AVG(clv), 2) AS province_avg_clv
FROM
    customer_loyalty_history
GROUP BY
    province
HAVING
    AVG(clv) < (SELECT AVG(clv) FROM customer_loyalty_history)
ORDER BY
    province_avg_clv DESC;

"province","province_avg_clv"
"Nova Scotia","7983.30"
"Ontario","7913.75"
"Alberta","7752.79"
"Prince Edward Island","7704.49"
"Yukon","6771.66"


-- Above or equal average

SELECT
    province,
    ROUND(AVG(clv), 2) AS province_avg_clv
FROM
    customer_loyalty_history
GROUP BY
    province
HAVING
    AVG(clv) >= (SELECT AVG(clv) FROM customer_loyalty_history)
ORDER BY
    province_avg_clv DESC;

"province","province_avg_clv"
"Quebec","8160.96"
"New Brunswick","8154.18"
"Saskatchewan","8076.37"
"Manitoba","8066.56"
"Newfoundland","8025.08"
"British Columbia","7993.73"



-- 📉 Churn & Retention
-- 11. What’s the average CLV and flight activity difference between churned and active customers?

SELECT 
    CASE
      WHEN cancellation_year IS NULL THEN 'Active'
      WHEN cancellation_year IS NOT NULL THEN 'Churned'
    END AS Customer_status,
    ROUND(AVG(clv),2) AS Average_clv
FROM
    customer_loyalty_history
GROUP BY
    Customer_status;

"customer_status","average_clv"
"Churned","8131.78"
"Active","7968.76"



-- 13. Among customers who cancelled, how many had low activity or low point redemption in the prior months?

WITH ChurnedCustomersActivities AS (
    SELECT
        H.loyalty_number,
        H.cancellation_year,
        H.cancellation_month,
        F.flights_booked,
        F.points_redeemed
    FROM
        customer_loyalty_history AS H
    JOIN
        customer_flight_activity AS F
        ON H.loyalty_number = F.loyalty_number
    WHERE
        -- Filter for churned customers
        H.cancellation_year IS NOT NULL
        -- Filter for activity that occurred before cancellation
        AND (
            (F.year < H.cancellation_year) OR
            (F.year = H.cancellation_year AND F.month < H.cancellation_month)
        )
),
ChurnedCustomersSummary AS (
    SELECT
        loyalty_number,
        SUM(flights_booked) AS total_flights_booked,
        SUM(points_redeemed) AS total_points_redeemed
    FROM
        ChurnedCustomersActivities
    GROUP BY
        loyalty_number
)
SELECT
    COUNT(*) AS total_customers_with_low_activity_or_redemption
FROM
    ChurnedCustomersSummary
WHERE
    -- Check for "low activity" or "low redemption"
    total_flights_booked < 5 OR total_points_redeemed < 50;

"total_customers_with_low_activity_or_redemption"
"599"


-- 14. Is there a correlation between enrollment type (Standard vs Promotion) and churn rate?

SELECT
    enrollment_type,
    COUNT(loyalty_number) AS total_customers,
    COUNT(CASE WHEN cancellation_year IS NOT NULL THEN 1 END) AS churned_customers,
    -- Calculate the churn rate by casting the numerator to numeric
    CAST(COUNT(CASE WHEN cancellation_year IS NOT NULL THEN 1 END) AS NUMERIC) / COUNT(loyalty_number) AS churn_rate
FROM
    customer_loyalty_history
GROUP BY
    enrollment_type;

"enrollment_type","total_customers","churned_customers","churn_rate"
"Standard","15766","1952","0.12381073195483952810"
"2018 Promotion","971","115","0.11843460350154479918"


-- 📊 Marketing & Promotion Impact
-- 15. Did customers enrolled through promotions behave differently from standard enrollees?
-- Compare their flight frequency, points, and cancellation rates.

-- points

SELECT H.enrollment_type,
  AVG(F.points_accumulated) AS avg_points_accom,
  AVG(F.points_redeemed) AS avg_points_redeemed
FROM customer_flight_activity AS F
JOIN customer_loyalty_history AS H 
ON F.loyalty_number = H.loyalty_number
GROUP BY H.enrollment_type

"enrollment_type","avg_points_accom","avg_points_redeemed"
"2018 Promotion",94.81610581874358,"22.4971678681771370"
"Standard",125.97728622246193,"31.2852869043088503"


-- flights booked

SELECT 
    CASE
      WHEN H.enrollment_type = '2018 Promotion' THEN '2018 Promotion'
      WHEN H.enrollment_type = 'Standard' THEN 'Standard'
    END AS Customer_status,
    ROUND(AVG(F.flights_booked),2) AS avg_flights_booked
FROM customer_flight_activity AS F
JOIN customer_loyalty_history AS H 
ON F.loyalty_number = H.loyalty_number
GROUP BY Customer_status;

"customer_status","avg_flights_booked"
"2018 Promotion","3.20"
"Standard","4.19"


-- 16. Which enrollment year brought in the highest average CLV?

SELECT enrollment_year,
  ROUND(AVG(clv), 2) AS average_clv
FROM customer_loyalty_history
GROUP BY enrollment_year
ORDER BY average_clv DESC;

"enrollment_year","average_clv"
2015,"8177.79"
2016,"8058.06"
2013,"8045.48"
2018,"8019.87"
2012,"7998.54"
2014,"7850.49"
2017,"7776.88"


-- 17. How do customer activities change in their first year compared to subsequent years?

SELECT
    CASE
        WHEN F.year = H.enrollment_year THEN 'First Year'
        ELSE 'Subsequent Years'
    END AS activity_period,
    ROUND(AVG(F.total_flights), 2) AS avg_total_flights,
    ROUND(AVG(F.distance), 2) AS avg_distance,
    ROUND(AVG(F.flights_booked), 2) AS avg_flights_booked,
    ROUND(AVG(F.flights_with_companions), 2) AS avg_flights_with_companions,
    ROUND(AVG(F.points_accumulated)::numeric, 2) AS avg_points_accumulated
FROM customer_loyalty_history AS H
JOIN customer_flight_activity AS F
ON H.loyalty_number = F.loyalty_number
GROUP BY activity_period
ORDER BY activity_period;

"activity_period","avg_total_flights","avg_distance","avg_flights_booked","avg_flights_with_companions","avg_points_accumulated"
"First Year","3.62","844.39","2.89","0.73","85.74"
"Subsequent Years","5.48","1286.36","4.38","1.10","131.72"

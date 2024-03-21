-- CREATING DATABASE
CREATE DATABASE PAYPAL;
USE PAYPAL;

-- 1. Data Integrity Checking & Cleanup

-- Alphabetically list all of the country codes in the continent_map table that appear more than once. Display any values where country_code is null as 
-- country_code = "FOO" and make this row appear first in the list, even though it should alphabetically sort to the middle. Provide the results 
-- of this query as your answer.

-- ANS:

SELECT ISNULL(country_code,'FOO') AS COUNTRY_CODE
FROM continent_map
GROUP BY country_code
HAVING COUNT(*) > 1
ORDER BY CASE WHEN country_code='FOO' THEN 0 ELSE 1 END

-- For all countries that have multiple rows in the continent_map table, delete all multiple records leaving only the 1 record per country. 
-- The record that you keep should be the first one when sorted by the continent_code alphabetically ascending. Provide the query/ies and 
-- explanation of step(s) that you follow to delete these records.

-- ANS:

-- ORDERING THE CONTINENT TABLE USING WINDOW DUNCTION ROW_NUMBER() TO DETECT THE ROWS APPEARING MORE THAN ONCE
WITH
    CTE
    AS
    (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY COUNTRY_CODE ORDER BY country_code) AS ROW_NUMBER
        FROM continent_map
    )
DELETE FROM CTE WHERE ROW_NUMBER > 1;

-- UPDATING THE NULL VALUES OF COUNTRY_CODE TO 'FOO'
UPDATE continent_map SET COUNTRY_CODE = 'FOO' WHERE COUNTRY_CODE IS NULL;

-- FETCHING THE RESULTS BY ALPHABETICALLY ORDERING WITH RESPECT TO COUNTRY_CODE
SELECT *
FROM continent_map
ORDER BY COUNTRY_CODE;


-- 2. List the countries ranked 10-12 in each continent by the percent of year-over-year growth descending from 2011 to 2012.

-- The percent of growth should be calculated as: ((2012 gdp - 2011 gdp) / 2011 gdp)

-- The list should include the columns:

-- rank
-- continent_name
-- country_code
-- country_name
-- growth_percent

-- ANS:

CREATE VIEW MAIN_TABLE
AS
    SELECT CONTINENT_NAME, CM.COUNTRY_CODE, COUNTRY_NAME, YEAR, GDP_PER_CAPITA
    FROM CONTINENTS CO INNER JOIN CONTINENT_MAP CM ON CO.CONTINENT_CODE=CM.CONTINENT_CODE INNER JOIN
        COUNTRIES C ON C.COUNTRY_CODE=CM.COUNTRY_CODE INNER JOIN PER_CAPITA PC ON CM.COUNTRY_CODE=PC.COUNTRY_CODE;


WITH
    CTE
    AS
    (
        SELECT CONTINENT_NAME, T1.COUNTRY_CODE, COUNTRY_NAME, CONCAT(ROUND(GDP_2012 - GDP_2011 / GDP_2011,2),'%') AS GROWTH_RATE, RANK() OVER 
(PARTITION BY CONTINENT_NAME ORDER BY (GDP_2012 - GDP_2011 / GDP_2011)) AS RANK
        FROM (SELECT CONTINENT_NAME, COUNTRY_CODE, COUNTRY_NAME, GDP_PER_CAPITA AS GDP_2011
            FROM MAIN_TABLE
            WHERE YEAR = 2011) T1
            INNER JOIN
            (SELECT COUNTRY_CODE, GDP_PER_CAPITA AS GDP_2012, YEAR
            FROM MAIN_TABLE
            WHERE YEAR = 2012) T2
            ON T1.COUNTRY_CODE=T2.COUNTRY_CODE
    )
SELECT *
FROM CTE
WHERE RANK BETWEEN 10 AND 12


-- 3. For the year 2012, create a 3 column, 1 row report showing the percent share of gdp_per_capita for the following regions:

-- (i) Asia, (ii) Europe, (iii) the Rest of the World. Your result should look something like

-- ANS:

CREATE VIEW CONT_TABLE
AS
    SELECT CONTINENT_NAME, YEAR, GDP_PER_CAPITA
    FROM PER_CAPITA PC INNER JOIN CONTINENT_MAP CM ON PC.COUNTRY_CODE=CM.COUNTRY_CODE INNER JOIN CONTINENTS C ON C.CONTINENT_CODE=CM.CONTINENT_CODE;

SELECT(CONCAT(ROUND(((SELECT SUM(GDP_PER_CAPITA)
    FROM CONT_TABLE
    WHERE CONTINENT_NAME='ASIA' AND YEAR=2012)/
(SELECT SUM(GDP_PER_CAPITA)
    FROM CONT_TABLE
    WHERE YEAR=2012) * 100),1),'%')) AS ASIA,
    CONCAT(ROUND(((SELECT SUM(GDP_PER_CAPITA)
    FROM CONT_TABLE
    WHERE CONTINENT_NAME='EUROPE' AND YEAR=2012)/
(SELECT SUM(GDP_PER_CAPITA)
    FROM CONT_TABLE
    WHERE YEAR=2012) * 100),1),'%') AS EUROPE,
    CONCAT(ROUND(((SELECT SUM(GDP_PER_CAPITA)
    FROM CONT_TABLE
    WHERE CONTINENT_NAME<>'ASIA' AND CONTINENT_NAME<>'EUROPE' AND YEAR=2012)/
(SELECT SUM(GDP_PER_CAPITA)
    FROM CONT_TABLE
    WHERE YEAR=2012) * 100),1),'%')
AS REST


-- 4a. What is the count of countries and sum of their related gdp_per_capita values for the year 2007 where the string 'an' (case insensitive) 
-- appears anywhere in the country name?

-- ANS:

SELECT COUNT(*) AS COUNTRY_COUNT, SUM(GDP_PER_CAPITA) AS TOTAL_GDP
FROM PER_CAPITA PC INNER JOIN COUNTRIES C ON PC.COUNTRY_CODE=C.COUNTRY_CODE
WHERE YEAR=2007 AND COUNTRY_NAME LIKE '%an%'

-- 4b. Repeat question 4a, but this time make the query case sensitive.

-- ANS:

SELECT COUNT(*) AS COUNTRY_COUNT, SUM(GDP_PER_CAPITA) AS TOTAL_GDP
FROM PER_CAPITA PC INNER JOIN COUNTRIES C ON PC.COUNTRY_CODE=C.COUNTRY_CODE
WHERE YEAR=2007 AND COUNTRY_NAME COLLATE LATIN1_GENERAL_CS_AS LIKE '%an%';


-- 5. Find the sum of gpd_per_capita by year and the count of countries for each year that have non-null gdp_per_capita where (i) the year is before 
-- 2012 and (ii) the country has a null gdp_per_capita in 2012. Your result should have the columns:

-- year
-- country_count
-- total

-- ANS:

SELECT YEAR, COUNT(DISTINCT COUNTRY_CODE) AS COUNTRY_COUNT, SUM(GDP_PER_CAPITA) AS TOTAL
FROM PER_CAPITA
WHERE COUNTRY_CODE IN (SELECT T1.COUNTRY_CODE
FROM COUNTRIES T1 LEFT JOIN (SELECT *
    FROM PER_CAPITA
    WHERE YEAR=2012) T2 ON T1.COUNTRY_CODE=T2.COUNTRY_CODE
WHERE YEAR=2012 AND GDP_PER_CAPITA IS NULL)
GROUP BY YEAR


-- 6. All in a single query, execute all of the steps below and provide the results as your final answer:

-- a. create a single list of all per_capita records for year 2009 that includes columns:

-- continent_name
-- country_code
-- country_name
-- gdp_per_capita

-- b. order this list by:
-- continent_name ascending
-- characters 2 through 4 (inclusive) of the country_name descending

-- c. create a running total of gdp_per_capita by continent_name

-- d. return only the first record from the ordered list for which each continent's running total of gdp_per_capita meets or exceeds $70,000.00 
-- with the following columns:

-- continent_name
-- country_code
-- country_name
-- gdp_per_capita
-- running_total

-- ANS:

CREATE VIEW GDP_CAPITA_TABLE
AS
    SELECT CONTINENT_NAME, C.COUNTRY_CODE, COUNTRY_NAME, GDP_PER_CAPITA, YEAR
    FROM PER_CAPITA PC INNER JOIN COUNTRIES C ON PC.COUNTRY_CODE=C.COUNTRY_CODE INNER JOIN
        CONTINENT_MAP CP ON PC.COUNTRY_CODE=CP.COUNTRY_CODE INNER JOIN CONTINENTS CO ON CP.CONTINENT_CODE=CO.CONTINENT_CODE;


WITH
    CTE
    AS

    (
        SELECT
            continent_name,
            country_code,
            country_name,
            gdp_per_capita,
            SUM(gdp_per_capita) OVER (PARTITION BY continent_name ORDER BY gdp_per_capita ASC) AS running_total,
            ROW_NUMBER() OVER (PARTITION BY continent_name ORDER BY gdp_per_capita ASC) AS row_num
        FROM
            GDP_CAPITA_TABLE
        WHERE 
        year = 2009
    )
SELECT *
FROM CTE
WHERE ROW_NUM=1 AND RUNNING_TOTAL>70000
ORDER BY CONTINENT_NAME, SUBSTRING(COUNTRY_NAME,2,4) DESC


-- 7. Find the country with the highest average gdp_per_capita for each continent for all years. Now compare your list to the following data set. 
-- Please describe any and all mistakes that you can find with the data set below. Include any code that you use to help detect these mistakes.

-- ANS:

CREATE VIEW RANK_TABLE
AS
    SELECT CONTINENT_NAME, C.COUNTRY_CODE, COUNTRY_NAME, GDP_PER_CAPITA
    FROM PER_CAPITA PC INNER JOIN COUNTRIES C ON PC.COUNTRY_CODE=C.COUNTRY_CODE INNER JOIN
        CONTINENT_MAP CP ON PC.COUNTRY_CODE=CP.COUNTRY_CODE INNER JOIN CONTINENTS CO ON CP.CONTINENT_CODE=CO.CONTINENT_CODE


WITH
    AvgGDPPerCapita
    AS
    (
        SELECT
            continent_name,
            country_code,
            country_name,
            '$' + CONVERT(VARCHAR, CAST(AVG(gdp_per_capita) AS MONEY),1) AS avg_gdp_per_capita,
            ROW_NUMBER() OVER (PARTITION BY continent_name ORDER BY AVG(gdp_per_capita) DESC) AS rank_by_avg_gdp_per_capita
        FROM
            RANK_TABLE
        GROUP BY 
        continent_name, country_code, country_name
    )
SELECT
    continent_name,
    country_code,
    country_name,
    avg_gdp_per_capita
FROM
    AvgGDPPerCapita
WHERE 
    rank_by_avg_gdp_per_capita = 1;

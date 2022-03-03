/* 
*******************************************************************************************
INTRODUCTION
*******************************************************************************************
 */

-- Create the view requested by the problem statement
CREATE  VIEW forestation
AS
SELECT fa.*,
       la.total_area_sq_mi * 2.59 as total_area_sqkm,
       re.region, re.income_group,
       ROUND(CAST((fa.forest_area_sqkm / (la.total_area_sq_mi * 2.59))*100 as NUMERIC), 2) as perc_forest
FROM forest_area fa
JOIN land_area la
    ON fa.country_code = la.country_code
    AND fa.year = la.year
JOIN regions re
	ON re.country_code = fa.country_code

/* 
*******************************************************************************************
ADDITIONAL VIEW CREATED TO SIMPLIFY LATER QUERIES
*******************************************************************************************
 */

-- Create additional view computing yearly changes down to country level (separate to differentiate from
-- the view required by the problem statement)
CREATE  VIEW forest_area_changes
AS
     -- Compute lags of the areas and perc_forest to subsequently calculate yearly changes
WITH area_lags AS ( 
                      SELECT *,
                             LAG(forest_area_sqkm, 1) OVER (
                                    PARTITION BY country_name ORDER BY year) AS prevyear_forest_sqkm,
                             LAG(perc_forest, 1) OVER (
                             PARTITION BY country_name ORDER BY year) as prevyear_perc_forest
                      FROM forestation
                      ORDER BY country_name, year
                  ),

      -- Extract forest areas in 1990, taken as reference to compute percentage losses later
     areas_1990 AS (
          SELECT country_name, forest_area_sqkm as farea_1990_sqkm
          FROM forest_area
          WHERE year = 1990
        )

SELECT *,

      -- Compute the total forest area loss
      ROUND(CAST((forest_area_sqkm - prevyear_forest_sqkm) AS NUMERIC), 1) AS yearly_forest_loss_sqkm,
      ROUND(CAST((SUM(forest_area_sqkm - prevyear_forest_sqkm) OVER (PARTITION BY country_name ORDER BY year)) AS NUMERIC), 1) AS cum_forest_loss_sqkm,

      -- Compute percentage area loss using forest area in 1990 as reference
      ROUND(CAST((SELECT farea_1990_sqkm 
            from areas_1990 as a1990
            where a1990.country_name = alags.country_name) AS NUMERIC), 1) AS farea_1990,
      ROUND(CAST((100*SUM(forest_area_sqkm - prevyear_forest_sqkm) OVER (PARTITION BY country_name ORDER BY year)) / 
            (SELECT farea_1990_sqkm 
             FROM areas_1990 as a1990
             WHERE a1990.country_name = alags.country_name) 
            AS NUMERIC), 2) AS cum_perc_forest_loss_ref1990,

      -- To compute the perc forest loss referred to the total land area of each country
      ROUND(CAST((perc_forest - prevyear_perc_forest) AS NUMERIC), 1) AS yearly_pforest_loss,
      ROUND(CAST((SUM(perc_forest - prevyear_perc_forest) OVER (PARTITION BY country_name ORDER BY year)) AS NUMERIC), 1) AS cum_pforest_loss

      FROM area_lags as alags
      
ORDER BY country_name, year

/* 
*******************************************************************************************
GLOBAL SITUATION
*******************************************************************************************
 */

/* a. What was the total forest area (in sq km) of the world in 1990? Please keep in mind 
that you can use the country record denoted as “World" in the region table. */
SELECT forest_area_sqkm
FROM forest_area_changes
WHERE country_name = 'World'
AND year = 1990

/* b. What was the total forest area (in sq km) of the world in 2016? Please keep in 
mind that you can use the country record in the table is denoted as “World.” */
SELECT forest_area_sqkm
FROM forest_area_changes
WHERE country_name = 'World'
AND year = 2016

/* c. What was the change (in sq km) in the forest area of the world from 1990 to 2016? */
SELECT cum_forest_loss_sqkm
FROM forest_area_changes
WHERE country_name = 'World'
AND year = 2016

/* d. What was the percent change in forest area of the world between 1990 and 2016? */
SELECT region, year,
       ROUND(CAST(100*SUM(forest_area_sqkm) / SUM(total_area_sqkm) AS NUMERIC), 2) as forest_perc
FROM forest_area_changes
WHERE year in (1990, 2016)
      AND region = 'World'
GROUP BY 1, 2

/* e. If you compare the amount of forest area lost between 1990 and 2016, to which country's 
total area in 2016 is it closest to? */
WITH world_area_lost AS (
      SELECT ABS(cum_forest_loss_sqkm)
      FROM forest_area_changes
      WHERE country_name = 'World'
      AND year = 2016
)

SELECT *
FROM forest_area_changes
WHERE total_area_sqkm < (SELECT * FROM world_area_lost)
	  AND year = 2016
ORDER BY total_area_sqkm DESC
LIMIT 1;

/* 
*******************************************************************************************
REGIONAL OUTLOOK
*******************************************************************************************
 */

-- Create view grouped by region that will be used through this section
CREATE VIEW region_forest_perc AS (
      SELECT region, year,
             -- Compute forest_percentages corresponding to each region
             ROUND(CAST(100*SUM(forest_area_sqkm) / SUM(total_area_sqkm) AS NUMERIC), 2) as forest_perc,

             -- Compute yearly deltas in the forest percentage area
             ROUND(CAST(100*SUM(forest_area_sqkm) / SUM(total_area_sqkm) AS NUMERIC), 2) -
             LAG(ROUND(CAST(100*SUM(forest_area_sqkm) / SUM(total_area_sqkm) AS NUMERIC), 2), 1) 
                  OVER (PARTITION BY region ORDER BY year, region) AS yr_delta_forest_perc

      FROM forest_area_changes
      GROUP BY 1, 2
)

/* a.1 What was the percent forest of the entire world in 2016?  */
SELECT region, year, forest_perc
FROM region_forest_perc
WHERE year = 2016
      AND region = 'World'

/* a.2 Which region had the HIGHEST percent forest in 2016, and which had the LOWEST, to 2 decimal places? */

-- Highest
SELECT region, year, forest_perc
FROM region_forest_perc
WHERE year = 2016
      AND region <> 'World'
ORDER BY forest_perc DESC
LIMIT 1

-- Lowest
SELECT region, year, forest_perc
FROM region_forest_perc
WHERE year = 2016
      AND region <> 'World'
ORDER BY forest_perc
LIMIT 1

/* b.1 What was the percent forest of the entire world in 1990?  */
SELECT region, year, forest_perc
FROM region_forest_perc
WHERE year = 1990
      AND region = 'World'

/* b.2 Which region had the HIGHEST percent forest in 1990, and which had the LOWEST, to 2 decimal places? */

-- Highest
SELECT region, year, forest_perc
FROM region_forest_perc
WHERE year = 1990
      AND region <> 'World'
ORDER BY forest_perc DESC
LIMIT 1

-- Lowest
SELECT region, year, forest_perc
FROM region_forest_perc
WHERE year = 1990
      AND region <> 'World'
ORDER BY forest_perc
LIMIT 1

/* c. Based on the table you created, which regions of the world DECREASED in forest area from 1990 to 2016? */

-- Table to compute the cumulative deltas in forest percentage area per region
WITH cum_forest_deltas AS (
      SELECT region, year, forest_perc, yr_delta_forest_perc,
            SUM(yr_delta_forest_perc) OVER (PARTITION BY region ORDER BY year, region) AS cum_delta_forest_perc
      FROM region_forest_perc 
)

SELECT region, year, forest_perc, cum_delta_forest_perc 
FROM cum_forest_deltas
WHERE year = 2016
      AND cum_delta_forest_perc < 0

/* 
*******************************************************************************************
COUNTRY LEVEL DETAIL
*******************************************************************************************
 */

/* a.1 Which 5 countries saw the largest amount decrease in forest area from 1990 to 2016? */
/* a.2 What was the difference in forest area for each? */

-- METHOD 1 - using the view created previously which computes yearly changes and the cummulative changes
SELECT year, country_name, region, cum_forest_loss_sqkm
FROM forest_area_changes
WHERE year = 2016
      AND country_name <> 'World'
      AND cum_forest_loss_sqkm IS NOT NULL
ORDER BY cum_forest_loss_sqkm
LIMIT 5

-- METHOD 2 - Subqueries
WITH areas_1990 AS (
            SELECT region, country_name, year, forest_area_sqkm
            FROM forestation
            WHERE year = 1990
                  AND forest_area_sqkm IS NOT NULL
      ),
      areas_2016 AS (
            SELECT region, country_name, year, forest_area_sqkm
            FROM forestation
            WHERE year = 2016
                  AND forest_area_sqkm IS NOT NULL
      )

SELECT areas_1990.region, areas_1990.country_name,
       (areas_2016.forest_area_sqkm - areas_1990.forest_area_sqkm) as farea_change_sqkm
FROM areas_1990
JOIN areas_2016
  ON areas_1990.country_name = areas_2016.country_name
WHERE areas_1990.country_name <> 'Word'
ORDER BY farea_change_sqkm
LIMIT 5

/* b. Which 5 countries saw the largest percent decrease in forest area from 1990 to 2016? 
What was the percent change to 2 decimal places for each? */

-- METHOD 1 - referring the losses to the initial forest area in 1990
SELECT region, year, country_name, cum_perc_forest_loss_ref1990	
FROM forest_area_changes
WHERE year = 2016
	  AND region <> 'World'
      AND forest_area_sqkm IS NOT NULL
ORDER BY cum_perc_forest_loss_ref1990
LIMIT 5

/* 
-- METHOD 2 - using subqueries
WITH perc_1990 AS (
            SELECT region, country_name, year, perc_forest
            FROM forestation
            WHERE year = 1990
                  AND perc_forest IS NOT NULL
      ),
      perc_2016 AS (
            SELECT region, country_name, year, perc_forest
            FROM forestation
            WHERE year = 2016
                  AND perc_forest IS NOT NULL
      )

SELECT perc_1990.region, perc_1990.country_name,
       (perc_2016.perc_forest - perc_1990.perc_forest) as perc_forest_change
FROM perc_1990
JOIN perc_2016
  ON perc_1990.country_name = perc_2016.country_name
ORDER BY perc_forest_change
LIMIT 5

-- METHOD 3 - using the view created previously which computes yearly changes and the cummulative changes
SELECT region, year, country_name, cum_pforest_loss	
FROM forest_area_changes
WHERE year = 2016
	AND region <> 'World'
      AND forest_area_sqkm IS NOT NULL
ORDER BY cum_pforest_loss
 */

/* c. If countries were grouped by percent forestation in quartiles, 
which group had the most countries in it in 2016? */
WITH quartiles_perc AS (
      SELECT country_name, year, perc_forest,
            NTILE(4) OVER (ORDER BY perc_forest) AS quartile
      FROM forestation
      WHERE year = 2016
            AND perc_forest IS NOT NULL
)

SELECT quartile,
       COUNT(*) as n_countries
FROM quartiles_perc
GROUP BY 1
ORDER BY n_countries DESC

/* d. List all of the countries that were in the 4th quartile (percent forest > 75%) in 2016. */
WITH quartiles_perc AS (
      SELECT country_name, year, perc_forest,
            NTILE(4) OVER (ORDER BY perc_forest) AS quartile
      FROM forestation
      WHERE year = 2016
            AND perc_forest IS NOT NULL
)

SELECT country_name, quartile
FROM quartiles_perc
WHERE quartile = 4
ORDER BY country_name

/* e. How many countries had a percent forestation higher than the United States in 2016? */
SELECT COUNT(*)
FROM forestation
WHERE perc_forest > (
      SELECT perc_forest
      FROM forestation
      WHERE country_name = 'United States'
            AND year = 2016
)
      AND year = 2016

SELECT country_name, year, perc_forest
FROM forestation
WHERE year = 1990
      AND perc_forest IS NOT NULL
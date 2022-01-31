CREATE  VIEW forestation
AS
SELECT fa.*, -- Be careful with repeated names
	   la.total_area_sq_mi,
       re.region, re.income_group,
       fa.forest_area_sqkm / (la.total_area_sq_mi * 2.59) as perc_forest
FROM forest_area fa
JOIN land_area la
    ON fa.country_code = la.country_code
    AND fa.year = la.year
JOIN regions re
	ON re.country_code = fa.country_code



-- Uncomment thise of you wish to create a table
-- CREATE w_forest_area_evol
-- AS

     -- Forest area each years along with its lags
WITH world_forest_area AS ( 
        SELECT year, forest_area_sqkm,
                LAG(forest_area_sqkm, 1) OVER (
                ORDER BY year) as prevyear_forest_sqkm
        FROM forestation
        WHERE country_name = 'World'
		),

      -- Area in 1990
      area_1990 AS (
		SELECT MAX(forest_area_sqkm) as max_area
		FROM forest_area      
        )

SELECT year, forest_area_sqkm,
       forest_area_sqkm - prevyear_forest_sqkm as forest_loss_sqkm,
       SUM(forest_area_sqkm - prevyear_forest_sqkm) OVER (ORDER BY year) AS total_forest_loss_sqkm,
       100*SUM(forest_area_sqkm - prevyear_forest_sqkm) OVER (ORDER BY year) /
            (SELECT max_area FROM area_1990) as perc_forest_loss

FROM world_forest_area


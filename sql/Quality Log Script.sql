/* quality_log.sql 
This is a log of all the rules used for cleaning each data set */
SELECT 1 AS step, 'raw_city' AS table_name, 'Rows loaded' AS [rule],
       (SELECT COUNT(*) FROM dbo.CityLevelOwners) AS rows_affected, '8726' AS expected
UNION ALL SELECT 2, 'raw_rent', 'Rows loaded',
       (SELECT COUNT(*) FROM dbo.CityLevelRenters), '203'
UNION ALL SELECT 3, 'raw_province', 'Rows loaded',
       (SELECT COUNT(*) FROM dbo.ProvinceWideHousingSales), '760'
UNION ALL SELECT 4, 'raw_city', 'Duplicate key groups',
       (SELECT COUNT(*) FROM (SELECT [CMA_ID] FROM dbo.CityLevelOwners
                              GROUP BY [CMA_ID], [YEAR], [QUARTER], [HOUSING_TYPE]
                              HAVING COUNT(*) > 1) AS d), '0'
UNION ALL SELECT 5, 'raw_rent', 'Duplicate key groups',
       (SELECT COUNT(*) FROM (SELECT [CMA] FROM dbo.CityLevelRenters
                              GROUP BY [CMA], [YEAR], [QUARTER]
                              HAVING COUNT(*) > 1) AS d), '0'
UNION ALL SELECT 6, 'raw_province', 'Duplicate key groups',
       (SELECT COUNT(*) FROM (SELECT [YEAR] FROM dbo.ProvinceWideHousingSales
                              GROUP BY [YEAR], [QUARTER], [HOUSING_TYPE]
                              HAVING COUNT(*) > 1) AS d), '0'
UNION ALL SELECT 7, 'clean_city', 'Housing-type label not mapped',
       (SELECT COUNT(*) FROM dbo.CityLevelOwners) - (SELECT COUNT(*) FROM dbo.clean_cityowners), '0'
UNION ALL SELECT 8, 'clean_province', 'Housing-type label not mapped',
       (SELECT COUNT(*) FROM dbo.ProvinceWideHousingSales) - (SELECT COUNT(*) FROM dbo.clean_provincesales), '0'
UNION ALL SELECT 9, 'clean_rent', 'City name not mapped to CMA ID',
       (SELECT COUNT(*) FROM dbo.clean_rentowners WHERE cma_id IS NULL), '0'
UNION ALL SELECT 10, 'clean_city', 'No matching province quarter',
       (SELECT COUNT(*) FROM dbo.clean_cityowners WHERE prov_income IS NULL), '0'
UNION ALL SELECT 11, 'clean_city', 'Fewer than 30 resales',
       (SELECT SUM(flag_low_sales) FROM dbo.clean_cityowners), '1516'
UNION ALL SELECT 12, 'clean_city', 'Income > 1.5x provincial median',
       (SELECT SUM(flag_income_outlier) FROM dbo.clean_cityowners), '27'
UNION ALL SELECT 13, 'clean_rent', 'All rent values missing in a quarter',
       (SELECT SUM(flag_all_rent_missing) FROM dbo.clean_rentowners), '1'
UNION ALL SELECT 14, 'clean_rent', '3-bedroom rent missing',
       (SELECT COUNT(*) FROM dbo.clean_rentowners WHERE rent_3bed IS NULL), '117'
ORDER BY step;

-- 02_clean.sql : clean views with a real date column and quality flags.
-- Flags mark suspect rows (1) instead of deleting them.

CREATE OR ALTER VIEW dbo.clean_provincesales AS
WITH housing_type_dim AS (
    SELECT
        d.HOUSING_TYPE,
        DENSE_RANK() OVER (ORDER BY d.HOUSING_TYPE) AS housing_type_id
    FROM (
        SELECT DISTINCT p.HOUSING_TYPE
        FROM dbo.ProvinceWideHousingSales AS p
    ) AS d
)
SELECT
    p.YEAR AS [year],
    p.QUARTER AS [quarter],
    DATEFROMPARTS(p.YEAR, ((p.QUARTER - 1) * 3) + 1, 1) AS quarter_start,
    h.housing_type_id,
    h.HOUSING_TYPE AS housing_type,
    p.MEDIAN_HOUSING_PRICE AS median_price,
    p.MEDIAN_AFTER_TAX_ANNUAL_FAMILY_INCOME AS median_income,
    p.PRIME_INTEREST_RATE AS prime_rate,
    p.MORTGAGE_PAYMENT_PERCENT_INCOME AS mppi,
    p.NUMBER_OF_RESALES AS resales
FROM dbo.ProvinceWideHousingSales AS p
INNER JOIN housing_type_dim AS h
    ON h.HOUSING_TYPE = p.HOUSING_TYPE;
GO

CREATE OR ALTER VIEW dbo.clean_cityowners AS
WITH prov_income AS (
    SELECT
        cp.[year],
        cp.[quarter],
        MAX(cp.median_income) AS prov_income
    FROM dbo.clean_provincesales AS cp
    GROUP BY
        cp.[year],
        cp.[quarter]
),
housing_type_dim AS (
    SELECT
        d.HOUSING_TYPE,
        DENSE_RANK() OVER (ORDER BY d.HOUSING_TYPE) AS housing_type_id
    FROM (
        SELECT DISTINCT c.HOUSING_TYPE
        FROM dbo.CityLevelOwners AS c
    ) AS d
)
SELECT
    c.CMA_ID AS cma_id,
    c.CMA_NAME AS cma_name,
    c.YEAR AS [year],
    c.QUARTER AS [quarter],
    DATEFROMPARTS(c.YEAR, ((c.QUARTER - 1) * 3) + 1, 1) AS quarter_start,
    h.housing_type_id,
    h.HOUSING_TYPE AS housing_type,
    c.MEDIAN_HOUSING_PRICE AS median_price,
    c.MEDIAN_AFTER_TAX_ANNUAL_FAMILY_INCOME AS median_income,
    c.PRIME_INTEREST_RATE AS prime_rate,
    c.MORTGAGE_PAYMENT_PERCENT_INCOME AS mppi,
    c.HISTORIC_PAYMENT_PERCENT_INCOME AS historic_mppi,
    c.NUMBER_OF_RESALES AS resales,
    p.prov_income,
    CASE
        WHEN c.NUMBER_OF_RESALES < 30 THEN 1
        ELSE 0
    END AS flag_low_sales,
    CASE
        WHEN c.MEDIAN_AFTER_TAX_ANNUAL_FAMILY_INCOME > 1.5 * p.prov_income THEN 1
        ELSE 0
    END AS flag_income_outlier
FROM dbo.CityLevelOwners AS c
INNER JOIN housing_type_dim AS h
    ON h.HOUSING_TYPE = c.HOUSING_TYPE
LEFT JOIN prov_income AS p
    ON p.[year] = c.YEAR
   AND p.[quarter] = c.QUARTER;
GO

CREATE OR ALTER VIEW dbo.clean_rentowners AS
SELECT
    r.CMA_ID AS cma_id,
    r.CMA AS cma_name,
    r.YEAR AS [year],
    r.QUARTER AS [quarter],
    DATEFROMPARTS(r.YEAR, ((r.QUARTER - 1) * 3) + 1, 1) AS quarter_start,
    r.ASKING_RENT_1BED AS rent_1bed,
    r.ASKING_RENT_2BED AS rent_2bed,
    TRY_CONVERT(int, r.ASKING_RENT_3BED) AS rent_3bed,
    r.RENT_TO_INCOME_PCT_1BED AS rti_1bed,
    r.RENT_TO_INCOME_PCT_2BED AS rti_2bed,
    TRY_CONVERT(float, r.RENT_TO_INCOME_PCT_3BED) AS rti_3bed,
    CASE
        WHEN r.ASKING_RENT_1BED IS NULL
         AND r.ASKING_RENT_2BED IS NULL
         AND TRY_CONVERT(int, r.ASKING_RENT_3BED) IS NULL THEN 1
        ELSE 0
    END AS flag_all_rent_missing
FROM dbo.CityLevelRenters AS r;
GO

/* Obtains the year and quarter of house owners by city and the rent owners in the province accounting for every type of house, */
WITH latest AS (
    SELECT TOP (1)
        c.[year],
        c.[quarter]
    FROM dbo.clean_cityowners AS c
    ORDER BY c.[year] DESC, c.[quarter] DESC
),
prov AS (
    SELECT
        p.housing_type_id,
        p.mppi AS prov_mppi
    FROM dbo.clean_provincesales AS p
    JOIN latest AS l
        ON l.[year] = p.[year]
       AND l.[quarter] = p.[quarter]
)

/* Ranks all the cities on their mppi by year and the quarter while also checking if the income for each city is within the 30-40% range or not */
SELECT
    c.housing_type,
    RANK() OVER (
        PARTITION BY c.housing_type
        ORDER BY c.mppi ASC
    ) AS mppi_rank,
    c.cma_name,
    ROUND(c.mppi, 1) AS mppi,
    ROUND(pr.prov_mppi, 1) AS province_mppi,
    ROUND(c.mppi - pr.prov_mppi, 1) AS gap_vs_province,
    ROUND(c.historic_mppi, 1)              AS own_long_run_avg,
    ROUND(c.mppi - c.historic_mppi, 1)     AS gap_vs_own_history,   -- positive = worse than its normal
    CASE WHEN c.mppi <= c.historic_mppi AND c.mppi <= pr.prov_mppi THEN 'Below both'
         WHEN c.mppi >  c.historic_mppi AND c.mppi >  pr.prov_mppi THEN 'Above both'
         WHEN c.mppi <= c.historic_mppi                            THEN 'Below own history only'
         ELSE 'Below province only' END    AS comparison_label,
    c.resales,
    CASE
        WHEN c.mppi < 30 THEN 'Under 30%'
        WHEN c.mppi <= 40 THEN '30-40%'
        ELSE 'Over 40%'
    END AS affordability_tier
FROM dbo.clean_cityowners AS c
JOIN latest AS l
    ON l.[year] = c.[year]
   AND l.[quarter] = c.[quarter]
JOIN prov AS pr
    ON pr.housing_type_id = c.housing_type_id
WHERE c.housing_type IN ('All Housing Types', 'Detached Homes', 'Condos', 'Row Homes')
  AND c.flag_low_sales = 0
  AND c.flag_income_outlier = 0
ORDER BY
    c.housing_type,
    mppi_rank;
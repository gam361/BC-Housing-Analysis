# Data-quality log

Source: BC Stats, B.C. Housing Affordability dataset (Open Government Licence – British Columbia).
Files: city owners (Q1 2000–Q2 2026), city rent (Q1 2019–Q1 2026), province (Q1 1979–Q2 2026).
Produced by `sql/03_quality_log.sql`. Rerun it after every data refresh and update the counts.

## Load checks

| # | Table | Check | Rows | Result |
|---|---|---|---|---|
| 1 | raw_city | Rows loaded | 8,726 | OK |
| 2 | raw_rent | Rows loaded | 203 | OK (7 cities × 29 quarters) |
| 3 | raw_province | Rows loaded | 760 | OK (190 quarters × 4 types) |
| 4 | raw_city | Duplicate primary key | 0 | OK |
| 5 | raw_rent | Duplicate primary key | 0 | OK |
| 6 | raw_province | Duplicate primary key | 0 | OK |

## Standardization

| # | Table | Rule | Rows | Action |
|---|---|---|---|---|
| 7 | clean_city | Housing-type labels mapped to `dim_housing_type` | 0 unmapped | OK |
| 8 | clean_province | "Row Homes" mapped to Townhouse; "All Housing Types" to All types | 0 unmapped | OK |
| 9 | clean_rent | City names ("Abbotsford-Mission, British Columbia") mapped to CMA ID | 0 unmapped | OK |
| 10 | clean_city | Every city quarter matches a province quarter | 0 missing | OK |

## Quality flags

| # | Table | Rule | Rows flagged | Decision |
|---|---|---|---|---|
| 11 | clean_city | Fewer than 30 resales in the quarter | 1,516 (17%) | Kept for trend charts; excluded from city rankings. Mostly condos (34.5% of condo rows) and townhouses (31.2%). |
| 12 | clean_city | Income more than 1.5× the provincial median for that quarter | 27 | All are Salmon Arm, 2004–2006 (1.84× the province on average; a fixed $91,731 for every 2004 quarter). Treated as a data error and excluded. |
| 13 | clean_rent | Every rent value missing for the quarter | 1 | Kelowna, Q2 2025. Row kept; shown as a gap in charts. |
| 14 | clean_rent | 3-bedroom rent missing | 117 | Only Vancouver, Victoria and Kamloops report 3-bedroom rent. 3-bedroom comparisons limited to those cities. |

## Known limits not fixed by a rule

- Medians move when the mix of homes sold changes (for example, Williams Lake, Q3 2003). Rankings use detached homes and all types side by side.
- Cities enter the series in different years (Parksville and Squamish 2001, Salmon Arm 2004). Comparisons use a common window from 2018.
- The rent file ends one quarter before the owner files (Q1 2026 vs. Q2 2026).

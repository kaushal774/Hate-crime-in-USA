-- 1. Create table with proper data types
CREATE TABLE hate_crimes (
    INCIDENT_ID INT,
    DATA_YEAR INT,
    ORI VARCHAR(20),
    PUB_AGENCY_NAME VARCHAR(255),
    PUB_AGENCY_UNIT VARCHAR(255),
    AGENCY_TYPE_NAME VARCHAR(100),
    STATE_ABBR VARCHAR(5),
    STATE_NAME VARCHAR(100),
    DIVISION_NAME VARCHAR(100),
    REGION_NAME VARCHAR(100),
    POPULATION_GROUP_CODE VARCHAR(50),
    POPULATION_GROUP_DESC VARCHAR(255),
    INCIDENT_DATE DATE,
    ADULT_VICTIM_COUNT INT,
    JUVENILE_VICTIM_COUNT INT,
    TOTAL_OFFENDER_COUNT INT,
    ADULT_OFFENDER_COUNT INT,
    JUVENILE_OFFENDER_COUNT INT,
    OFFENDER_RACE VARCHAR(100),
    OFFENDER_ETHNICITY VARCHAR(100),
    VICTIM_COUNT INT,
    OFFENSE_NAME VARCHAR(500),
    TOTAL_INDIVIDUAL_VICTIMS INT,
    LOCATION_NAME VARCHAR(255),
    BIAS_DESC VARCHAR(255),
    VICTIM_TYPES VARCHAR(255),
    MULTIPLE_OFFENSE CHAR(1),
    MULTIPLE_BIAS CHAR(1)
);

-- 2. Remove leading/trailing spaces from text
UPDATE hate_crimes
SET PUB_AGENCY_NAME = TRIM(PUB_AGENCY_NAME),
    AGENCY_TYPE_NAME = TRIM(AGENCY_TYPE_NAME),
    STATE_NAME = TRIM(STATE_NAME),
    OFFENSE_NAME = TRIM(OFFENSE_NAME),
    LOCATION_NAME = TRIM(LOCATION_NAME),
    BIAS_DESC = TRIM(BIAS_DESC);

-- 3. Fill NULLs in numeric columns with 0
UPDATE hate_crimes
SET ADULT_VICTIM_COUNT = COALESCE(ADULT_VICTIM_COUNT, 0),
    JUVENILE_VICTIM_COUNT = COALESCE(JUVENILE_VICTIM_COUNT, 0),
    ADULT_OFFENDER_COUNT = COALESCE(ADULT_OFFENDER_COUNT, 0),
    JUVENILE_OFFENDER_COUNT = COALESCE(JUVENILE_OFFENDER_COUNT, 0),
    TOTAL_INDIVIDUAL_VICTIMS = COALESCE(TOTAL_INDIVIDUAL_VICTIMS, 0);

-- 4. Fill NULLs in text columns with 'Unknown'
UPDATE hate_crimes
SET PUB_AGENCY_UNIT = COALESCE(PUB_AGENCY_UNIT, 'Unknown'),
    OFFENDER_RACE = COALESCE(OFFENDER_RACE, 'Unknown'),
    OFFENDER_ETHNICITY = COALESCE(OFFENDER_ETHNICITY, 'Unknown');

-- 5. Standardize ethnicity codes
UPDATE hate_crimes
SET OFFENDER_ETHNICITY = CASE
    WHEN OFFENDER_ETHNICITY = 'H' THEN 'Hispanic Or Latino'
    WHEN OFFENDER_ETHNICITY = 'N' THEN 'Not Hispanic Or Latino'
    WHEN OFFENDER_ETHNICITY = 'U' THEN 'Unknown'
    ELSE OFFENDER_ETHNICITY
END;

-- 6. Convert OFFENSE_NAME to Title Case (MySQL example using INITCAP in other DBs)
UPDATE hate_crimes
SET OFFENSE_NAME = CONCAT(UCASE(LEFT(OFFENSE_NAME, 1)), LCASE(SUBSTRING(OFFENSE_NAME, 2)));

# now anaylysis of different kpis

-- 1. Total incidents per year
SELECT data_year, COUNT(*) AS total_incidents
FROM hate_crimes
GROUP BY data_year
ORDER BY data_year;

-- 2. Year-on-year percentage change in incidents
SELECT data_year,
       COUNT(*) AS total_incidents,
       ROUND(100.0 * (COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY data_year)) / 
             NULLIF(LAG(COUNT(*)) OVER (ORDER BY data_year), 0), 2) AS yoy_change_percent
FROM hate_crimes
GROUP BY data_year
ORDER BY data_year;

-- 3. Top 10 states by total incidents
SELECT state_name, COUNT(*) AS total_incidents
FROM hate_crimes
GROUP BY state_name
ORDER BY total_incidents DESC
LIMIT 10;

-- 4. State with highest average victim count
SELECT state_name, ROUND(AVG(victim_count), 2) AS avg_victims
FROM hate_crimes
GROUP BY state_name
ORDER BY avg_victims DESC
LIMIT 1;

-- 5. Monthly trend of incidents (all years combined)
SELECT EXTRACT(MONTH FROM incident_date) AS month, COUNT(*) AS total_incidents
FROM hate_crimes
GROUP BY month
ORDER BY month;

-- 6. Most common offense types
SELECT offense_name, COUNT(*) AS frequency
FROM hate_crimes
GROUP BY offense_name
ORDER BY frequency DESC
LIMIT 10;

-- 7. Distribution of incidents by offender race
SELECT offender_race, COUNT(*) AS total_incidents
FROM hate_crimes
GROUP BY offender_race
ORDER BY total_incidents DESC;

-- 8. Distribution by offender ethnicity
SELECT offender_ethnicity, COUNT(*) AS total_incidents
FROM hate_crimes
GROUP BY offender_ethnicity
ORDER BY total_incidents DESC;

-- 9. Victim type breakdown
SELECT victim_types, COUNT(*) AS total_incidents
FROM hate_crimes
GROUP BY victim_types
ORDER BY total_incidents DESC;

-- 10. Locations with most incidents
SELECT location_name, COUNT(*) AS total_incidents
FROM hate_crimes
GROUP BY location_name
ORDER BY total_incidents DESC
LIMIT 10;

-- 11. Most frequent bias motivations
SELECT bias_desc, COUNT(*) AS total_incidents
FROM hate_crimes
GROUP BY bias_desc
ORDER BY total_incidents DESC
LIMIT 10;

-- 12. Multiple offense vs single offense
SELECT multiple_offense, COUNT(*) AS total_incidents
FROM hate_crimes
GROUP BY multiple_offense;

-- 13. Region-wise incidents
SELECT region_name, COUNT(*) AS total_incidents
FROM hate_crimes
GROUP BY region_name
ORDER BY total_incidents DESC;

-- 14. Top states by multiple bias cases
SELECT state_name, COUNT(*) AS multiple_bias_cases
FROM hate_crimes
WHERE multiple_bias = 'M'
GROUP BY state_name
ORDER BY multiple_bias_cases DESC
LIMIT 10;

-- 15. Average victims per incident per state
SELECT state_name, ROUND(AVG(victim_count), 2) AS avg_victims
FROM hate_crimes
GROUP BY state_name
ORDER BY avg_victims DESC;

-- 16. Agencies with highest reported incidents
SELECT pub_agency_name, COUNT(*) AS total_incidents
FROM hate_crimes
GROUP BY pub_agency_name
ORDER BY total_incidents DESC
LIMIT 10;

-- 17. Most common offense for each bias type
SELECT bias_desc, offense_name, COUNT(*) AS total_cases
FROM hate_crimes
GROUP BY bias_desc, offense_name
ORDER BY bias_desc, total_cases DESC;

-- 18. Race vs bias relationship
SELECT offender_race, bias_desc, COUNT(*) AS total_incidents
FROM hate_crimes
GROUP BY offender_race, bias_desc
ORDER BY total_incidents DESC;

-- 19. Quarterly incidents trend
SELECT data_year, EXTRACT(QUARTER FROM incident_date) AS quarter, COUNT(*) AS total_incidents
FROM hate_crimes
GROUP BY data_year, quarter
ORDER BY data_year, quarter;

-- 20. Adult vs juvenile offender ratio
SELECT 
    SUM(adult_offender_count) AS total_adult_offenders,
    SUM(juvenile_offender_count) AS total_juvenile_offenders,
    ROUND(SUM(adult_offender_count) * 1.0 / NULLIF(SUM(juvenile_offender_count),0), 2) AS ratio
FROM hate_crimes;

-- 21. Percentage of incidents with juvenile offenders
SELECT ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM hate_crimes), 2) AS percent_with_juveniles
FROM hate_crimes
WHERE juvenile_offender_count > 0;

-- 22. Year with highest average multiple bias incidents
SELECT data_year, ROUND(AVG(CASE WHEN multiple_bias = 'M' THEN 1 ELSE 0 END), 3) AS avg_multi_bias
FROM hate_crimes
GROUP BY data_year
ORDER BY avg_multi_bias DESC
LIMIT 1;

-- 23. State with most aggravated assaults
SELECT state_name, COUNT(*) AS aggravated_cases
FROM hate_crimes
WHERE offense_name ILIKE '%Aggravated Assault%'
GROUP BY state_name
ORDER BY aggravated_cases DESC
LIMIT 1;

-- 24. Bias trends over time (example: Anti-Black or African American)
SELECT data_year, COUNT(*) AS total_cases
FROM hate_crimes
WHERE bias_desc ILIKE 'Anti-Black%'
GROUP BY data_year
ORDER BY data_year;

-- 25. Location-based bias patterns
SELECT location_name, bias_desc, COUNT(*) AS total_cases
FROM hate_crimes
GROUP BY location_name, bias_desc
ORDER BY total_cases DESC
LIMIT 15;

-- 26. State ranking by hate crime rate per population group
SELECT state_name, population_group_desc, COUNT(*) AS total_incidents
FROM hate_crimes
GROUP BY state_name, population_group_desc
ORDER BY total_incidents DESC;

-- 27. Month with highest incidents historically
SELECT EXTRACT(MONTH FROM incident_date) AS month, COUNT(*) AS total_incidents
FROM hate_crimes
GROUP BY month
ORDER BY total_incidents DESC
LIMIT 1;

-- 28. Region comparison in offense diversity
SELECT region_name, COUNT(DISTINCT offense_name) AS unique_offenses
FROM hate_crimes
GROUP BY region_name
ORDER BY unique_offenses DESC;

-- 29. Offense severity ranking by victim count
SELECT offense_name, SUM(victim_count) AS total_victims
FROM hate_crimes
GROUP BY offense_name
ORDER BY total_victims DESC
LIMIT 10;

-- 30. Multi-variable correlation query
SELECT state_name, bias_desc, offense_name, AVG(victim_count) AS avg_victims
FROM hate_crimes
GROUP BY state_name, bias_desc, offense_name
ORDER BY avg_victims DESC
LIMIT 20;





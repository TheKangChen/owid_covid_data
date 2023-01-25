-- ALTER TABLE CovidVaccinations
-- MODIFY new_vaccinations INT;

SELECT location,
       STR_TO_DATE(date, '%m/%d/%y') as date,
       total_cases,
       new_cases,
       total_deaths,
       population
FROM CovidDeaths
WHERE continent is not null
ORDER BY location, date;


-- total cases vs total deaths (USA)
SELECT location,
       STR_TO_DATE(date, '%m/%d/%y')                 as date,
       IFNULL(total_cases, 0),
       IFNULL(total_deaths, 0),
       IFNULL((total_deaths / total_cases) * 100, 0) as death_percentage
FROM CovidDeaths
WHERE location like '%states'
  AND continent is not null
ORDER BY location, date;


-- total cases vs population (USA)
SELECT location,
       STR_TO_DATE(date, '%m/%d/%y')               as date,
       IFNULL(total_cases, 0)                      as total_cases,
       IFNULL(population, 0)                       as population,
       IFNULL((total_cases / population) * 100, 0) as infection_rate
FROM CovidDeaths
WHERE location like '%states'
  AND continent is NOT NULL
ORDER BY location, date;


-- looking at countries with the highest covid infection rate
SELECT location,
       MAX(total_cases)                                 as highest_count,
       population,
       IFNULL((MAX(total_cases) / population) * 100, 0) as infection_rate
FROM CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY infection_rate desc;


-- looking at countries with the highest death count per population
SELECT continent,
       location,
       MAX(total_deaths) as highest_death_count
FROM CovidDeaths
WHERE continent is not null
GROUP BY continent, location
ORDER BY highest_death_count desc;


-- global death percentage
SELECT SUM(IFNULL(new_cases, 0))                                               as total_cases,
       SUM(IFNULL(new_deaths, 0))                                              as total_deaths,
       IFNULL(SUM(IFNULL(new_deaths, 0)) / SUM(IFNULL(new_cases, 0)), 0) * 100 as death_percentage
FROM CovidDeaths
WHERE continent is not null
ORDER BY date;


-- looking at total population vs vaccinations (CTE)
with Pop_v_Vac (continent, location, date, population, new_vaccination, rolling_people_vaccinated)
         as (SELECT d.continent,
                    d.location,
                    STR_TO_DATE(d.date, '%m/%d/%y') as date,
                    d.population,
                    IFNULL(v.new_vaccinations, 0) as new_vaccinations,
                    SUM(IFNULL(v.new_vaccinations, 0))
                        OVER (PARTITION BY d.location ORDER BY STR_TO_DATE(d.date, '%m/%d/%y')) as rolling_people_vaccinated
             FROM CovidDeaths d
                      JOIN CovidVaccinations v on d.location = v.location
                 AND d.date = v.date
             WHERE d.continent is not null
             ORDER BY 2, 3)
SELECT *, (rolling_people_vaccinated / population) * 100 as percentage_of_total_population
FROM Pop_v_Vac;


-- total population vs vaccinations temp table
DROP TABLE if exists percent_population_vaccinated;
CREATE TABLE percent_population_vaccinated
(
    continent nvarchar(255),
    location nvarchar(255),
    date DATETIME,
    population NUMERIC,
    new_vaccinations NUMERIC,
    rolling_people_vaccinated NUMERIC
);

INSERT INTO percent_population_vaccinated
SELECT d.continent,
       d.location,
       STR_TO_DATE(d.date, '%m/%d/%y')                                             as date,
       d.population,
       IFNULL(v.new_vaccinations, 0)                                               as new_vaccinations,
       SUM(IFNULL(v.new_vaccinations, 0))
           OVER (PARTITION BY d.location ORDER BY STR_TO_DATE(d.date, '%m/%d/%y')) as rolling_people_vaccinated
FROM CovidDeaths d
         JOIN CovidVaccinations v on d.location = v.location
    AND d.date = v.date
WHERE d.continent is not null
ORDER BY 2, 3;


-- percent population vs vaccinations view
DROP VIEW if exists percent_population_vaccinated_view;
CREATE VIEW percent_population_vaccinated_view AS
SELECT d.continent,
       d.location,
       STR_TO_DATE(d.date, '%m/%d/%y')                                             as date,
       d.population,
       IFNULL(v.new_vaccinations, 0)                                               as new_vaccinations,
       SUM(IFNULL(v.new_vaccinations, 0))
           OVER (PARTITION BY d.location ORDER BY STR_TO_DATE(d.date, '%m/%d/%y')) as rolling_people_vaccinated
FROM CovidDeaths d
         JOIN CovidVaccinations v on d.location = v.location
    AND d.date = v.date
WHERE d.continent is not null
ORDER BY 2, 3;

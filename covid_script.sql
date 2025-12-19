select location,continent, total_cases , date , new_cases, total_deaths,population
from CovidDeaths
order by 1,2



-- fixing the name of country
UPDATE CovidDeaths
SET location = 'Palestine'
WHERE location = 'Israel';



-- Compare total cases and total deaths
-- Calculate the likelihood of death after contracting COVID-19 in each country
select location, total_cases , date , (total_deaths/total_cases)*100 as persentage_of_deaths
from CovidDeaths
order by 1,2



-- Compare total COVID-19 cases relative to population size
select location, total_cases , date , population,(total_deaths/population)*100 as persentage_of_population_got_covid
from CovidDeaths
order by 1,2




-- looking at countries withe highest infection rate compared to population 

-- Calculate the highest infection count and infection rate by country

SELECT
    location,
    MAX(population) AS population,
    MAX(total_cases) AS highest_infection_count,
    MAX(total_cases * 100.0 / NULLIF(population,0)) AS percentage_of_population_infected
FROM CovidDeaths
GROUP BY location
ORDER BY percentage_of_population_infected DESC;


-- showing the country with highest death count per population 

SELECT
    location,
    MAX(total_deaths) as totale_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY totale_death_count DESC;


-- let's look at the continent 

SELECT
   continent,
    MAX(total_deaths) as totale_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY totale_death_count DESC;



-- global numbers

SELECT  
    SUM(new_cases) AS total_new_cases,
    SUM(CAST(new_deaths AS SIGNED)) AS total_new_deaths,
    SUM(CAST(new_deaths AS SIGNED)) * 100.0 / NULLIF(SUM(new_cases), 0) AS percentage_of_population_got_covid
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;




 -- Looking at total population vs cumulative vaccinations



SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.date
    ) AS RollingPeopleVaccinated
-- (RollingPeopleVaccinated / dea.population) * 100 AS percentage_vaccinated
FROM CovidDeaths dea
JOIN CovidVaccnations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;




-- Using CTE to perform Calculation on Partition By in previous query



WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS
(
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (
            PARTITION BY dea.location 
            ORDER BY dea.date
        ) AS RollingPeopleVaccinated
    FROM CovidDeaths dea
    JOIN CovidVaccnations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *,
       (RollingPeopleVaccinated / Population) * 100 AS PercentageVaccinated
FROM PopvsVac
ORDER BY Location, Date;



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TEMPORARY TABLE IF EXISTS PercentPopulationVaccinated;

CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date DATETIME,
    Population BIGINT,
    New_vaccinations BIGINT,
    RollingPeopleVaccinated BIGINT
);

INSERT INTO PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    STR_TO_DATE(dea.date, '%d/%m/%Y') AS date_corrected,
    dea.population,
    CAST(COALESCE(NULLIF(vac.new_vaccinations, ''), 0) AS SIGNED) AS new_vaccinations,
    SUM(CAST(COALESCE(NULLIF(vac.new_vaccinations, ''), 0) AS SIGNED)) 
        OVER (PARTITION BY dea.location ORDER BY STR_TO_DATE(dea.date, '%d/%m/%Y')) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccnations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *,
       (RollingPeopleVaccinated / Population) * 100 AS PercentageVaccinated
FROM PercentPopulationVaccinated
ORDER BY Location, Date;

-- Creating View to store data for later visualizations
CREATE OR REPLACE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent,
    dea.location,
    STR_TO_DATE(dea.date, '%d/%m/%Y') AS date_corrected,
    dea.population,
    CAST(COALESCE(NULLIF(vac.new_vaccinations, ''), 0) AS SIGNED) AS new_vaccinations,
    SUM(CAST(COALESCE(NULLIF(vac.new_vaccinations, ''), 0) AS SIGNED)) 
        OVER (PARTITION BY dea.location ORDER BY STR_TO_DATE(dea.date, '%d/%m/%Y')) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccnations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

select *
from PercentPopulationVaccinated
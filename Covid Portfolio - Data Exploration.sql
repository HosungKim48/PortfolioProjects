/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT *
  FROM Covid19.CovidDeaths
 WHERE continent IS NOT NULL
 ORDER BY 3,
          4;


-- Select Data that we are going to be starting with

SELECT Location,
       date,
       total_cases,
       new_cases,
       total_deaths,
       population
  FROM Covid19.CovidDeaths
 WHERE continent IS NOT NULL
 ORDER BY 1,
          2;
          

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in my country(South Korea)
            
SELECT Location,
       date,
       total_cases,
       total_deaths,
       (CAST (total_deaths AS FLOAT) / CAST (total_cases AS FLOAT) ) * 100 AS DeathPercentage
  FROM Covid19.CovidDeaths
 WHERE location = "South Korea" AND 
       continent IS NOT NULL
 ORDER BY 1,
          2;
          

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
            
SELECT Location,
       date,
       Population,
       total_cases,
       (CAST (total_cases AS FLOAT) / CAST (population AS FLOAT) * 100) AS PercentPopulationInfected
  FROM Covid19.CovidDeaths
 ORDER BY 1,
          2;
          

-- Countries with Highest Infection Rate compared to Population

SELECT Location,
       Population,
       MAX(total_cases) AS HighestInfectionCount,
       Max( (CAST (total_cases AS FLOAT) / CAST (population AS FLOAT) ) * 100) AS PercentPopulationInfected
  FROM Covid19.CovidDeaths
 GROUP BY Location,
          Population
 ORDER BY PercentPopulationInfected DESC;
 

-- Countries with Highest Death Count per Population

SELECT Location,
       MAX(CAST (Total_deaths AS INT) ) AS TotalDeathCount
  FROM Covid19.CovidDeaths
 WHERE continent IS NOT NULL
 GROUP BY Location
 ORDER BY TotalDeathCount DESC;
 

-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population
                               
SELECT continent,
       MAX(CAST (Total_deaths AS INT) ) AS TotalDeathCount
  FROM Covid19.CovidDeaths
 WHERE continent IS NOT NULL
 GROUP BY continent
 ORDER BY TotalDeathCount DESC;
 

-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases,
       SUM(CAST (new_deaths AS INT) ) AS total_deaths,
       SUM(CAST (new_deaths AS FLOAT) ) / SUM(CAST (new_cases AS FLOAT) ) * 100 AS DeathPercentage
  FROM Covid19.CovidDeaths
 WHERE continent IS NOT NULL
 ORDER BY 1,
          2;
          

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.continent,
       dea.location,
       dea.date,
       dea.population,
       vac.new_vaccinations,
       SUM(CAST (vac.new_vaccinations AS INT) ) OVER (PARTITION BY dea.location ORDER BY dea.location,
       dea.date) AS RollingPeopleVaccinated
  FROM Covid19.CovidDeaths dea
       JOIN
       Covid19.CovidVaccinations vac ON dea.location = vac.location AND 
                                        dea.date = vac.date
 WHERE dea.continent IS NOT NULL
 ORDER BY 2,
          3;
          

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (
    Continent,
    Location,
    Date,
    Population,
    New_Vaccinations,
    RollingPeopleVaccinated
)
AS (
    SELECT dea.continent,
           dea.location,
           dea.date,
           dea.population,
           vac.new_vaccinations,
           SUM(CAST (vac.new_vaccinations AS INT) ) OVER (PARTITION BY dea.location ORDER BY dea.location,
           dea.date) AS RollingPeopleVaccinated
      FROM CovidDeaths dea
           JOIN
           CovidVaccinations vac ON dea.location = vac.location AND 
                                    dea.date = vac.date
     WHERE dea.continent IS NOT NULL
     ORDER BY 2,
              3
)
SELECT *,
       (CAST (RollingPeopleVaccinated AS FLOAT) / CAST (Population AS FLOAT) ) * 100
  FROM PopvsVac;






-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS PercentPopulationVaccinated;

CREATE TABLE PercentPopulationVaccinated (
    Continent               NVARCHAR (255),
    Location                NVARCHAR (255),
    Date                    DATETIME,
    Population              NUMERIC,
    New_vaccinations        NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO PercentPopulationVaccinated SELECT dea.continent,
                                               dea.location,
                                               dea.date,
                                               dea.population,
                                               vac.new_vaccinations,
                                               SUM(CAST (vac.new_vaccinations AS INT) ) OVER (PARTITION BY dea.location ORDER BY dea.location,
                                               dea.date) AS RollingPeopleVaccinated
                                          FROM CovidDeaths dea
                                               JOIN
                                               CovidVaccinations vac ON dea.location = vac.location AND 
                                                                        dea.date = vac.date
                                         WHERE dea.continent IS NOT NULL;




SELECT *,
       (CAST (RollingPeopleVaccinated AS FLOAT) / CAST (Population AS FLOAT) ) * 100 AS PercentPopulationVaccinated
  FROM PercentPopulationVaccinated;




-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated_view AS
    SELECT dea.continent,
           dea.location,
           dea.date,
           dea.population,
           vac.new_vaccinations,
           SUM(CAST (vac.new_vaccinations AS INT) ) OVER (PARTITION BY dea.location ORDER BY dea.location,
           dea.date) AS RollingPeopleVaccinated
      FROM CovidDeaths dea
           JOIN
           CovidVaccinations vac ON dea.location = vac.location AND 
                                    dea.date = vac.date
     WHERE dea.continent IS NOT NULL;

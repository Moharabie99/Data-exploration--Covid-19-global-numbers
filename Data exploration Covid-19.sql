-- Covid 19 Data Exploration [2020-2023]

-- Select all records where continent is not null, ordered by the third and fourth columns
SELECT *
FROM CovidDeath
WHERE continent IS NOT NULL
ORDER BY 3, 4;

-- Select starting data
SELECT
    Location,
    date,
    total_cases,
    new_cases,
    total_deaths,
    population
FROM CovidDeath
WHERE continent IS NOT NULL
ORDER BY 1, 2;

-- Total Cases vs Total Deaths for Sudan
SELECT
    Location,
    date,
    total_cases,
    total_deaths,
    CAST((total_deaths / total_cases) AS INT) * 100 AS DeathPercentage
FROM CovidDeath
WHERE location LIKE '%sudan%'
    AND continent IS NOT NULL
ORDER BY 1, 2;

-- Total Cases vs Population
SELECT
    Location,
    date,
    Population,
    total_cases,
    (total_cases / population) * 100 AS PercentPopulationInfected
FROM CovidDeath
ORDER BY 1, 2;

-- Countries with Highest Infection Rate compared to Population
SELECT
    Location,
    Population,
    MAX(total_cases) AS HighestInfectionCount,
    MAX((total_cases / population) * 100) AS PercentPopulationInfected
FROM CovidDeath
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

-- Countries with Highest Death Count per Population
SELECT
    Location,
    MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeath
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population
SELECT
    continent,
    MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeath
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- GLOBAL NUMBERS
-- GLOBAL RECORDED CASES, GLOBAL RECORDED DEATHS, AND PERCENTAGE OF DEATH
SELECT
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS INT)) AS total_deaths,
    SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM CovidDeath
WHERE continent IS NOT NULL;
--GROUP BY date
--ORDER BY 1, 2;

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has received at least one Covid Vaccine
WITH PopVsVac AS (
    SELECT
        cod.continent,
        cod.location,
        cod.date,
        cod.population,
        vac.new_vaccinations,
        SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY cod.Location ORDER BY cod.location, cod.Date) AS RollingPeopleVaccinated
    FROM CovidDeath cod
    JOIN CovidVaccine vac ON cod.location = vac.location AND cod.date = vac.date
    WHERE cod.continent IS NOT NULL
)
SELECT
    *,
    CASE
        WHEN Population > 0 THEN (RollingPeopleVaccinated / Population) * 100
        ELSE 0 -- Handle division by zero
    END AS PercentPopulationVaccinated
FROM PopVsVac;

-- Using Temp Table to perform in the previous query
DROP TABLE IF EXISTS #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT
    cod.continent,
    cod.location,
    cod.date,
    cod.population,
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY cod.Location ORDER BY cod.location, cod.Date) AS RollingPeopleVaccinated
FROM CovidDeath cod
JOIN CovidVaccine vac ON cod.location = vac.location AND cod.date = vac.date;

SELECT *,
    (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated;

-- Creating Views to store data for later visualizations

-- View to store: Percentage of vaccinated population per country
CREATE VIEW PercentPopulationVaccinated AS
SELECT
    cod.continent,
    cod.location,
    cod.date,
    cod.population,
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY cod.Location ORDER BY cod.location, cod.Date) AS RollingPeopleVaccinated
FROM CovidDeath cod
JOIN CovidVaccine vac ON cod.location = vac.location AND cod.date = vac.date
WHERE cod.continent IS NOT NULL;

-- View to store: Vaccinated population for each country
CREATE VIEW VaccinatedPopulation AS
SELECT
    cod.continent,
    cod.location,
    cod.date,
    cod.population,
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY cod.Location ORDER BY cod.location, cod.Date) AS RollingPeopleVaccinated
FROM CovidDeath cod
JOIN CovidVaccine vac ON cod.location = vac.location AND cod.date = vac.date
WHERE cod.continent IS NOT NULL;

-- View to store: Deaths counts for continents
CREATE VIEW ContinentsDeathsPerCountry AS
SELECT
    continent,
    MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeath
WHERE continent IS NOT NULL
GROUP BY continent;

-- View to store: Countries with the highest infection rate
CREATE VIEW InfectionRatePerCountry AS
SELECT
    Location,
    Population,
    MAX(total_cases) AS HighestInfectionCount,
    MAX((total_cases / population) * 100) AS PercentPopulationInfected
FROM CovidDeath
GROUP BY Location, Population;

-- View to store: Percentage of infection in comparison with the population
CREATE VIEW InfectionPercentage AS
SELECT
    Location,
    date,
    Population,
    total_cases,
    (total_cases / population) * 100 AS PercentPopulationInfected
FROM CovidDeath;

-- View to store: Countries with the highest death rates
CREATE VIEW HighestDeathRates AS
SELECT
    Location,
    MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeath
WHERE continent IS NOT NULL
GROUP BY Location;

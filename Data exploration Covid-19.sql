/*
Covid 19 Data Exploration [2020-2023]
*/

Select *
From CovidDeath
Where continent is not null 
order by 3,4


-- Select starting data

Select Location, date, total_cases, new_cases, total_deaths, population
From CovidDeath
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country (Sudan, in this query)

Select Location, date, total_cases,total_deaths, CAST((total_deaths/total_cases) as int)*100 as DeathPercentage
From CovidDeath
Where location like '%sudan%'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From CovidDeath
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeath
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeath
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeath
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS 
-- GLOBAL RECOREDED CASES, GLOBAL RECORDED DEATHS, AND PERCENTAGE OF DEATH

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From CovidDeath
where continent is not null 
--Group By date
order by 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select cod.continent, cod.location, cod.date, cod.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by cod.Location Order by cod.location, cod.Date) as RollingPeopleVaccinated
From CovidDeath cod
Join CovidVaccine vac
	On cod.location = vac.location
	and cod.date = vac.date
where cod.continent is not null 
order by 2,3


-- Using CTE to perform Calculation in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select cod.continent, cod.location, cod.date, cod.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by cod.Location Order by cod.location, cod.Date) as RollingPeopleVaccinated
From CovidDeath cod
Join CovidVaccine vac
	On cod.location = vac.location
	and cod.date = vac.date
where cod.continent is not null 
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



-- Using Temp Table to perform in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select cod.continent, cod.location, cod.date, cod.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by cod.Location Order by cod.location, cod.Date) as RollingPeopleVaccinated
From CovidDeath cod
Join CovidVaccine vac
	On cod.location = vac.location
	and cod.date = vac.date

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated



-- Creating Views to store data for later visualizations

--View to store: Percentage of vaccinated population per country

Create View PercentPopulationVaccinated 

as
Select cod.continent, cod.location, cod.date, cod.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by cod.Location Order by cod.location, cod.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeath cod
Join CovidVaccine vac
	On cod.location = vac.location
	and cod.date = vac.date
where cod.continent is not null 

--View to store: Vaccinated population for each country

CREATE VIEW VaccinatedPopulation
AS
Select cod.continent, cod.location, cod.date, cod.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by cod.Location Order by cod.location, cod.Date) as RollingPeopleVaccinated
From CovidDeath cod
Join CovidVaccine vac
	On cod.location = vac.location
	and cod.date = vac.date
where cod.continent is not null 

-- View to store: Deaths counts for continents

CREATE VIEW ContinentsDeathsPerCountry
AS
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeath
Where continent is not null 
Group by continent


-- View to store: Countries with highest infection rate 
CREATE VIEW infectionratepercountry
AS
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeath
Group by Location, Population

--View to store: Percentage of infection in comparsion with the population
CREATE VIEW infectionpercentage
AS

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From CovidDeath

-- View to store: Countries with highest deaths rates
CREATE VIEW highestDeathRates
AS

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeath
Where continent is not null 
Group by Location
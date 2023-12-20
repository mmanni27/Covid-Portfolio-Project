/* 

COVID 19 Data Exploration

Skills used: Joins, CTEs, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types
Data used from 01-03-20 to 12-13-23

*/

-- Review basic data 

Select *
From PortfolioProject1..CovidDeaths
Where continent is not null
Order by 3,4


-- Select data that we will be using for exploration

Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject1..CovidDeaths
Where continent is not null
Order by 1, 2


-- Total cases vs total deaths
-- Shows likelihood of dying if you contract Covid in US
-- US: 1.11%

Select location, date, total_cases, total_deaths, (Convert(float,total_deaths)/NULLIF(Convert(float,total_cases),0))*100 AS DeathPercentage
From PortfolioProject1..CovidDeaths
Where location = 'United States'
Order by 1,2


-- Total cases vs population
-- Shows percent of population that got covid
-- US: 30.58%

Select location, date, population, total_cases, (total_cases/population)*100 AS CovidCasesPercentage
From PortfolioProject1..CovidDeaths
Where location = 'United States'
Order by 1,2


-- Countries with highest infection rate compared to population
-- Populations over 1 million: Austria leads with 68.03%

Select location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
From PortfolioProject1..CovidDeaths
Where population > 1000000
Group by location, population
Order by 4 DESC


-- Countries with highest death count per population
-- US: 1,144,877 total deaths

Select location, MAX(cast(total_deaths as int)) AS TotalDeathCount
From PortfolioProject1..CovidDeaths
WHERE continent is not null
Group by location
Order by 2 DESC


-- Data by continent 

-- Highest death count by continent per population
-- Europe: 2,086,180

Select continent, SUM(new_deaths) AS TotalDeaths
From PortfolioProject1..CovidDeaths
WHERE continent IS Not null
Group by continent
Order by 2 DESC


-- Global numbers by day

Select date, SUM(new_cases) as TotalCases, SUM(Cast(new_deaths as int)) as TotalDeaths, Sum(cast(new_deaths as int))/NULLIF(SUM(new_cases),0)*100 AS DeathPercentage
From PortfolioProject1..CovidDeaths
Where continent is not null
Group by date
Order by 1,2


-- Total global numbers
-- Total cases: 772,466,989
-- Total deaths: 6,976,835
-- Death percentage: 0.9%

Select SUM(new_cases) as TotalCases, SUM(Cast(new_deaths as int)) as TotalDeaths, Sum(cast(new_deaths as int))/NULLIF(SUM(new_cases),0)*100 AS DeathPercentage
From PortfolioProject1..CovidDeaths
Where continent is not null
Order by 1,2


-- Join Tables 
-- Total population vs vaccinations
-- Shows cumulative number of vaccinations given to population (does not account for more than 1 vaccination received)
-- US: 676,683,162

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(Convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date ROWS Unbounded Preceding) AS CumulativeVaccinated
From PortfolioProject1..CovidDeaths AS Dea
Join PortfolioProject1..CovidVaccinations AS Vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
Order by 2,3


-- Using CTE to perform calculation on partition by in previous query

WITH PopVsVac (continent, location, date, population, new_vaccinations, CumulativeVaccinated)
as (
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(Convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date ROWS Unbounded Preceding) AS CumulativeVaccinated
From PortfolioProject1..CovidDeaths AS Dea
Join PortfolioProject1..CovidVaccinations AS Vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
)
Select *, (CumulativeVaccinated/population)*100 AS PercentVaccinated
From PopVsVac


-- Create Temp Table to perform calculation on partition by in previous query

Drop table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
Continent nvarchar(255), 
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
CumulativeVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(Convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date ROWS Unbounded Preceding) AS CumulativeVaccinated
From PortfolioProject1..CovidDeaths AS Dea
Join PortfolioProject1..CovidVaccinations AS Vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null

Select *, (CumulativeVaccinated/population)*100 AS PercentVaccinated
From #PercentPopulationVaccinated


-- Create a view to store data for tableau visualisations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(Convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date ROWS Unbounded Preceding) AS CumulativeVaccinated
From PortfolioProject1..CovidDeaths AS Dea
Join PortfolioProject1..CovidVaccinations AS Vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null

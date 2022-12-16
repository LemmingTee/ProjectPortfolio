

--                                By Abhinav Srivastava


-- Viewing the dataset in the objective

select * from Covid_Insight..covid_deaths$ order by 3, 5           --Death by Covid dataset
select * from Covid_Insight..covid_vaccinations order by 3,5       --Vaccinations against Covid dataset 


-- Query for dataset for death due to covid in India

select * from Covid_Insight..covid_deaths$ where location='india' order by date


-- By continent

select * from Covid_Insight..covid_deaths$ where continent is not null order by location, date 


-- Query for Progression of Covid infection

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as deathpercentage
From Covid_Insight..covid_deaths$
where continent is not null 
order by location, date



-- Progression in India

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From covid_insight..covid_deaths$
--where location='india'
order by location, date



-- Display of list of countries in decreasing order of infected population percentage

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From covid_insight..covid_deaths$
--where location='india'
group by Location, Population
order by PercentPopulationInfected desc



-- List of deaths from covid (countrywise)

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From Covid_insight..covid_deaths$
--Where location='india'
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From Covid_Insight..covid_deaths$
--Where location='india'
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Covid_Insight..covid_deaths$
--Where location='india' 
where continent is not null 
order by total_cases, total_deaths




-- Total Population vs Vaccinations
-- Shows Percentage of Population that has received at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as CumulativeVaccinations
--, (CumulativeVaccinations/population)*100
From Covid_Insight..covid_deaths$ dea
Join Covid_Insight..covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null and dea.location='india'
order by location, date


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, CumulativeVaccinations)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as CumulativeVaccinations
--, (CumulativeVaccinations)*100
From Covid_Insight..covid_deaths$ dea
Join Covid_Insight..covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (CumulativeVaccinations/Population)*100 as Vaccination_drive_progress
From PopvsVac where location='india'



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
CumulativeVaccinations numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as CumulativeVaccinations
--, (CumulativeVaccinations/population)*100
From Covid_Insight..covid_deaths$ dea
Join Covid_Insight..covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3

Select *, (CumulativeVaccinations/Population)*100
From #PercentPopulationVaccinated




-- Data for subsequent visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.date) as CumulativeVaccinations
, (CumulativeVaccinations/dea.population)*100
From Covid_Insight..covid_deaths$ dea
Join Covid_Insight..covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
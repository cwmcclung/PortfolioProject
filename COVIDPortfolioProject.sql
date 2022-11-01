/*

Project: Exploring Data in SQL

In this project, I took a look at Coronavirus (COVID-19) Deaths and Vaccinations data 
in order to demonstrate an ability to meaningfully explore data.

First, I imported the two Excel datasets into Microsoft SQL Server and ran basic queries on both tables 
to ensure that everything was imported correctly. I broadly selected some relevant data, including location, 
total cases, new cases, total deaths, and population, and ordered it by location and date to get an 
all-things-considered generalization.

*/


Select *
From PortfolioProject..CovidDeaths
Where continent is not null
order by 3,4




Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where location like '%states%' 
and continent is not null
order by 1,2

/*

Objective: Represent Total Cases Vs. Total Deaths In USA

Next, I looked at the total cases vs total deaths in the US, to determine the likelihood of dying from COVID 
if you are infected here; I divided the total deaths by total cases and multiplied by 100 to get a percentage.

*/

Select Location, date, total_cases, total_deaths, (Total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
and continent is not null
order by 1,2

/*

Objective: Determine what percentage of the US population has contracted COVID

I divided the total cases by population and multiplied by 100 to get a percentage. 

*/

Select Location, date, population, total_cases, (total_cases/population)*100 as PercentagePopInfected
From PortfolioProject..CovidDeaths
Where location like '%states%'
order by 1,2

/*

Objective: Determine Highest Infection Rate

Next, I looked at the countries with the highest infection rate compared to the population. I did this 
through an aggregate function (MAX) and applied it to total cases. I also took the MAX of total cases 
and divided it by population to reflect the percentage of the population that was infected. I grouped 
this query by the location and the population and ordered it by the percentage of the population that 
was infected (in descending order, so you see the higher percentages first).

*/

Select Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))* 100 as PercentagePopInfected
From PortfolioProject..CovidDeaths
Group by Location, population
order by PercentagePopInfected desc

/*

Objective: Determine Highest Death Count

Next, I looked at the countries with the highest death count as a percentage of the population. 
I used MAX of total deaths, and ordered the data by this criterion (descending, so you see the bigger numbers first). 
I also cast this total deaths data as an integer, and grouped the query by location. I noticed here that entire continents 
were represented alongside country totals, which seemed wrong to me, so I excluded those from the query by excluding all 
the data where the continent is null. I then added that qualification back into previous queries as well, in an attempt 
to view the data more consistently. Then I wrote a similar query to see the continents with the highest death count 
as a percentage of their populations.

*/

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by continent
order by TotalDeathCount desc

/*

Objective: Determine Global Death Percentage

Next, I looked at some more global data, omitting location and continent from the queries. I selected the SUM of new cases 
to get the total # of cases throughout the world, as well as the SUM of new deaths (cast as an integer) to get the total # 
of deaths throughout the world. I then selected the global death percentage by dividing the total # of deaths throughout 
the world by the total # of cases throughout the world. 

*/

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast
	(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

/*

Objective: Explore COVID vaccination data

Next, I explored COVID vaccination data. I joined this data with our previous table ordered by location and date. 
Then I looked at the world population vs the population of individuals who have been vaccinated. 
Here, I performed a window function, looking at the SUM of new vaccinations partitioned over the location 
(so as to avoid a rolling count aggregation that does not take location into account).

*/

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, 
dea.date) as RollingPeopleVaccinated
, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

/*

Objective: Determine percentage of the population that is vaccinnated

Next, I wanted to find what percentage of the people from each country were vaccinated. Because this query 
includes a reference to the previous aggregate function, I grouped the previous query inside a CTE 
(otherwise, an error would occur). The final percentage listed for each country is the true percentage of that 
country’s population that is vaccinated (e.g. 12% of the population in Albania is vaccinated). 

*/

With PopVsVac(Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as 
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, 
dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
Select *, (RollingPeopleVaccinated/Population)*100 as 
From PopVsVac


/*

Objective: Use Temp Table Instead of CTE

Next, I implemented a temp table as an alternative to the previous CTE query. 
I had to specify the datatype for each column, since I was creating an entirely new table. 
I then simulated what would happen if I wanted to change something in the temp table, using “DROP Table if exists” 
at the top of my query. Finally, I created a view (of the same info) to store data for a future visualization.

*/


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
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, 
dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100 
From #PercentPopulationVaccinated


--Finally, I created a view (of the same info) to store data for a future visualization.

Create View PercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, 
dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

Select *
From PercentPopulationVaccinated

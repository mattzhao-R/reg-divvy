# Oeconomica Divvy Bike Project 2021-2022
## Overview
This repo contains code and documents used for the 2021-2022 Labor and Consumption Cohort's research project. This project examined the impact of creating a divvy bike station in front of the Regenstein Library on the library's daily visitor count. We utilized public access divvy data from the city of Chicago as well as data from the University of Chicago on historical enrollment and Regenstein Library visitor counts. This README will describe the files, data, and code contained in this repo. Please direct any questions/comments/suggestions about the code, project, Oeconomica, etc. to [Matthew Zhao](mzhao117@uchicago.edu).

## Table of Contents
1. [Files](#files)
2. [Data](#data)
3. [Code](#code)

### Files
Folders are italicized, files in the working directory are bolded.


*data*<br>
This folder contains 3 datasets. We used Library-Data.csv and undergrad_uchi.csv. Regenstein_Divvy_Trips.csv is manually downloaded divvy trip data using the Chicago Data Portal interface. In the project itself, we query divvy bike trip data using the Socrata Open Data API (SoDA). Details on the data can be found in the Data section.


**SoDA Queries.Rmd**<br>
This RMarkdown file was used to create a reference document describing how to use the Socrata Open Data API and specifically how to write queries for this project. It describes the components of the query used and basiscs about how to get started with SoDA, along with providing an example of a query and its output.


**seasonality_test.png**<br>
This image is a graph produced by the Exploratory Data Analysis performed in wrangling.R. It separates out the seasonal trend in Regenstein Library visitor data from the overall trend. It was created by following [this guide](https://dev.socrata.com/blog/2015/06/17/forecasting_with_rsocrata.html).


**wrangling.R**<br>
This is the primary code used in this project. Details about this file can be found in the Code section.

[Back to TOC](#table-of-contents)


### Data
**Library-Data.csv**<br>
This file contains a novel dataset which we obtained from the University of Chicago through the Center for Digital Scholarship, holding daily library visitor counts. It has four variables: Date.of.Entry, Regenstein, Crear, and Total. Date.of.Entry specifies the date which the visitor entered and is documented at daily frequency (with some minor gaps). It starts July 1, 2009 and ends June 30, 2019, and has 3649 rows. Regenstein and Crear contain the corresponding date's visitor count, while total is the sum of the two. There are very few missing data in this file, with most coming from the Crear visitor counts. Our project only utilized Date.of.Entry and Regenstein.


**undergrad_uchi.csv**<br>
This file contains historical undergraduate enrollment numbers for the University of Chicago. Enrollment is reported at the start of each school year, meaning that year refers to the year that autumn quarter is in e.g. 2021-2022 school year, in which the class of '22 graduates, is labeled as 2021. This data was manually compiled from the University of Chicago registrar's [website](https://registrar.uchicago.edu/data-reporting/historical-enrollment/) and contains enrollment numbers for the academic years 2008-2009 to 2021-2022.

**Temp and Precip Midway Airport.csv**<br>
This file from NOAA contains daily weather data recorded at the Midway Airport Observatory from 2013 through 2019. There should be one observation per day.

Columns (see data dictionary [here](https://www1.ncdc.noaa.gov/pub/data/cdo/documentation/GHCND_documentation.pdf)):
* AWND = Average daily wind speed (should be in mph)
* PGTM = Peak gust time (hours and minutes, i.e., HHMM)
* PRCP = Precipitation (should be in inches)
* TMAX: Max Temp (Degrees F).
* TMIN: Min Temp (Degrees F).
* WDF2 = Direction of fastest 2-minute wind (degrees)
* WSF2 = Fastest 2-minute wind speed (should be mph)
* WT** = Weather Type where ** has one of the following values:
  * 01 = Fog, ice fog, or freezing fog (may include heavy fog)
  * 02 = Heavy fog or heaving freezing fog (not always
   distinguished from fog)
  * 03 = Thunder
  * 04 = Ice pellets, sleet, snow pellets, or small hail
  * 05 = Hail (may include small hail)
  * 06 = Glaze or rime
  * 07 = Dust, volcanic ash, blowing dust, blowing sand, or blowing obstruction
  * 08 = Smoke or haze
  * 09 = Blowing or drifting snow
  * 10 = Tornado, waterspout, or funnel cloud

[Back to TOC](#table-of-contents)


### Code
**wrangling.R**

[Back to TOC](#table-of-contents)

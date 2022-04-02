library(tidyverse)
library(lubridate)
library(soql)
library(RSocrata)
library(foreach)
library(plyr)
library(magrittr)


###########################################################################
######################## QUERYING FOR TRIP DATA ###########################
###########################################################################

#getting data for divvy trips to/from Regenstein Library using Socrata API
#Reg - University Ave %26 57th St; Constructed on April 17, 2015

api_urldivvy <- "https://data.cityofchicago.org/resource/fg6s-gzvg.json"
q1 <- paste0(api_urldivvy,"?",
            "to_station_name=University Ave %26 57th St")
system.time(df1 <- read.socrata(query,
                   app_token = "02II4N98cTMglzlWigswMRwyR",
                   email = "matthewzhao20@gmail.com",
                   password = "Divvyproject2022!")
            )

q2 <- paste0(api_urldivvy,"?",
             "from_station_name=University Ave %26 57th St")
system.time(df2 <- read.socrata(query,
                                app_token = "02II4N98cTMglzlWigswMRwyR",
                                email = "matthewzhao20@gmail.com",
                                password = "Divvyproject2022!")
)
df_trips <- rbind(df1,df2)

###########################################################################
########################## VERIFYING ASSUMPTIONS ##########################
###########################################################################

#verifying earliest Regenstein trip was on station creation date (4/17/2015)
head(df_trips %>% select(start_time) %>% arrange(start_time),1)

#checking that queried trips are in chronological order
q1 <- paste0(api_urldivvy,"?",
             "to_station_name=University Ave %26 57th St","&",
             "$limit=1")
system.time(df1 <- read.socrata(q1,
                   app_token = "02II4N98cTMglzlWigswMRwyR",
                   email = "matthewzhao20@gmail.com",
                   password = "Divvyproject2022!")
)

q2 <- paste0(api_urldivvy,"?",
            "to_station_name=University Ave %26 57th St"
            )
system.time(df2 <- read.socrata(q2,
                    app_token = "02II4N98cTMglzlWigswMRwyR",
                    email = "matthewzhao20@gmail.com",
                    password = "Divvyproject2022!")
)

if(ncol(df2)>18){
  df2 <- df2 %>% select(!c("gender","birth_year"))
}

all.equal(df1,df2[1,])

#checking first trip/construction dates for other stations
#Stations:
#2013
#North - "Woodlawn Ave %26 55th St"
#Bookstore - "Ellis Ave %26 58th St"
#2015 (same day)
#Ratner - "Ellis Ave %26 55th St"
#South - "Ellis Ave %26 60th St"
#Reg - "University Ave %26 57th St"
st_list <- c("Woodlawn Ave %26 55th St", "University Ave %26 57th St",
             "Ellis Ave %26 55th St", "Ellis Ave %26 58th St",
             "Ellis Ave %26 60th St")

system.time(df <- foreach(x=1:5, .combine = rbind.fill)%do%{
  q <- paste0(api_urldivvy,"?",
              "to_station_name=",st_list[x],"&","$limit=1")
  read.socrata(q,
               app_token = "02II4N98cTMglzlWigswMRwyR",
               email = "matthewzhao20@gmail.com",
               password = "Divvyproject2022!")
})

beg_stat <- df %>% select(start_time,stop_time,from_station_name,
                          to_station_name) %>%
  mutate(start_time = ymd_hms(start_time)) %>% arrange(start_time)

###########################################################################
##################### CLEANING & CREATING NEW VARIABLES ###################
###########################################################################

#import and clean library visitor data
#add school year for control and merging 
df_visitors <- read.csv("./data/Library-Data.csv")

visitors <- df_visitors %>% select(Date.of.Entry,Regenstein) %>%
  mutate(Date = mdy(Date.of.Entry), Date.of.Entry=NULL, 
         visitor_count = Regenstein, Regenstein = NULL,
         is_schyr = if_else(quarter(Date)!=3,1,0),
         school_year = if_else(month(Date)>=10, year(Date),year(Date)-1))

visitors <- na.omit(visitors)

#importing uchicago enrollment control
#https://registrar.uchicago.edu/data-reporting/historical-enrollment/
enroll_df <- read.csv("./data/undergrad_uchi.csv")
enroll <- enroll_df %>% mutate(school_year = as.numeric(school_year))

#trip_count is for aggregation
#Date set to start_time for merging with visitor count
#need to show that there are an insignificant number of rides which start
#on one day and end the next to show minimal differene between start & stop
trips <- df %>% select(start_time, stop_time) %>% 
  mutate(start_time = ymd_hms(start_time), stop_time = ymd_hms(stop_time),
         same_day = date(stop_time)-date(start_time),trip_count = 1,
         Date = start_time)

(nrow(filter(trips,same_day!=0)))/(nrow(trips))*100

c_trips <- na.omit(trips)

###########################################################################
################################# EDA #####################################
###########################################################################

#separating seasonality from trend in reg visits
vts <- ts(visits$Regenstein, 
           start=c(year(visits$Date[1]), 
                   as.numeric(format(visits$Date[1],"%j"))), 
          end=c(year(visits$Date[nrow(visits)]), 
                as.numeric(format(visits$Date[nrow(visits)],"%j"))), 
          frequency=365)
plot(vts)
fit <- stl(vts, s.window = "period")
plot(fit)


###########################################################################
############################ MERGING DATASETS #############################
###########################################################################

#aggregating trips, merging on Date with visitor data
f_trips <- c_trips %>% select(Date,trip_count) %>% 
  mutate(Date = date(Date)) %>% group_by(Date) %>%
  dplyr::summarise(total_trips = sum(trip_count))

#combined is final combined dataset for regression
#add enrollment control for visitor data
combined <- left_join(visitors,enroll,by="school_year")
combined <- left_join(combined,f_trips,by="Date")
#trips per day is zero before station creation date
combined <- combined %>% replace_na(list(total_trips=0))

###########################################################################
################################ REGRESSION ###############################
###########################################################################

#RDD dummy code
#consider using is_schyr indicator variable?
cutoff <- f_trips$Date[1]

lm_divvy <- combined %>% 
  mutate(threshold = ifelse(Date >= cutoff, 1, 0)) %$% 
  lm(visitor_count ~ threshold + I(Date - cutoff) + factor(enrollment) + 
       factor(school_year))

summary(lm_divvy) 

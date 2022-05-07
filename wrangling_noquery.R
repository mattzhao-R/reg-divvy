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

#Input your credentials for accessing the Socrata API (See SoDA Queries.Rmd
#for details).

app_token = "jbAeckoAqtqGhJJ3Lb2HHGbfR"
email = "mic@uchicago.edu"
password = "Divvytemppass0358"

#Name of Divvy station we want to query
reg_name = "University Ave %26 57th St"
crerar_name = "Ellis Ave %26 58th St"
station = reg_name
if (station == crerar_name) {
  station_short = "crerar"
} else if (station == reg_name) {
  station_short = "reg"
} else {
  print("ERROR: Invalid station_short")
}

df_trips <- read.csv(sprintf("./newdata/full_trip_data_%s.csv",station_short))


###########################################################################
##################### CLEANING & CREATING NEW VARIABLES ###################
###########################################################################

#import and clean library visitor data
#add school year for control and merging 
df_visitors <- read.csv("./data/Library-Data.csv")

if (station == reg_name) {
  visitors <- df_visitors %>% select(Date.of.Entry,Regenstein) %>%
    mutate(Date = mdy(Date.of.Entry), Date.of.Entry=NULL, 
           visitor_count = Regenstein, Regenstein = NULL,
           is_schyr = if_else(quarter(Date)!=3,1,0),
           quarter = quarter(Date),
           year = year(Date),
           school_year = if_else(month(Date)>=10, year(Date),year(Date)-1))
} else if (station == crerar_name) {
  visitors <- df_visitors %>% select(Date.of.Entry,Crerar) %>%
    mutate(Date = mdy(Date.of.Entry), Date.of.Entry=NULL, 
           visitor_count = Crerar, Crerar = NULL,
           is_schyr = if_else(quarter(Date)!=3,1,0),
           quarter = quarter(Date),
           year = year(Date),
           school_year = if_else(month(Date)>=10, year(Date),year(Date)-1))
} else {
  stop("Not a valid station name.")
}

visitors <- na.omit(visitors)

#importing uchicago enrollment control
#https://registrar.uchicago.edu/data-reporting/historical-enrollment/
enroll_df <- read.csv("./data/undergrad_uchi.csv")
enroll <- enroll_df %>% mutate(school_year = as.numeric(school_year))

#trip_count is for aggregation
#Date set to start_time for merging with visitor count
#need to show that there are an insignificant number of rides which start
#on one day and end the next to show minimal difference between start & stop
trips <- df_trips %>% select(start_time, stop_time) %>% 
  mutate(start_time = ymd_hms(start_time), stop_time = ymd_hms(stop_time),
         same_day = date(stop_time)-date(start_time),trip_count = 1,
         Date = start_time)

(nrow(filter(trips,same_day!=0)))/(nrow(trips))*100

c_trips <- na.omit(trips)


###########################################################################
############################CS DATASET#####################################
###########################################################################
cs_data <- 
  read.csv("./data/UChicago Enrollment XLSX/CS Majors and Total Majors.csv")


##Weather
midway_weather_df <- read_csv("./data/Midway Weather new.csv")
midway_weather <- midway_weather_df %>% mutate(Date=mdy(DATE))
#AWND PRCP TMAX

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

#add vars here
cs_data2 <- na.omit(cs_data)
combined <- left_join(combined,cs_data2,by=c("quarter","year"))

#add weather
combined <- left_join(combined,midway_weather,by="Date")



###########################################################################
################################ REGRESSION ###############################
###########################################################################

#RDD dummy code
#consider using is_schyr indicator variable?
#MC: f_trips$Date[1] is not hardcoded
cutoff <- f_trips$Date[1]
crerar_renovation_date <- mdy("10/01/2018")

lm_divvy <- combined %>% 
  mutate(threshold = ifelse(Date >= cutoff, 1, 0), 
         crerar_renov_dummy = ifelse(Date > crerar_renovation_date, 1, 0)) %$% 
  lm(visitor_count ~ threshold + I(Date - cutoff) + major_enroll + quarter
     + quarter * major_enroll + year + is_schyr + cs_pct + totcs + totcy 
     + AWND + TMAX + PRCP)

summary(lm_divvy)

lm_divvy_small <- combined %>% 
  mutate(threshold = ifelse(Date >= cutoff, 1, 0)) %$% 
  lm(visitor_count ~ threshold + I(Date - cutoff) + major_enroll + quarter
     + quarter * major_enroll + year + is_schyr + totcy + AWND + TMAX + PRCP)
summary(lm_divvy_small)

lm_divvy_small_trips <- combined %>% 
  mutate(threshold = ifelse(Date >= cutoff, 1, 0)) %$% 
  lm(visitor_count ~ threshold + total_trips + I(Date - cutoff) + major_enroll + quarter
     + quarter * major_enroll + year + is_schyr + totcy + AWND + TMAX + PRCP)
summary(lm_divvy_small_trips)


##EXTRAS
library(lubridate)

combined %>%
  mutate(month = month(Date), year = year(Date)) %>% 
  group_by(month, year) %>% dplyr::summarize(n = mean(visitor_count)) %>% 
  filter(month %in% c(1,2,3,5,6,7), (year %in% c(2014,2015)))

#overall regression data
write.csv(combined,sprintf("./newdata/combined_%s.csv",station_short))

#trip data
write.csv(f_trips,sprintf("./newdata/final_trips_%s.csv",station_short))

# full divvy dataset
#df_trips$from_location.coordinates = as.character(df_trips$from_location.coordinates)
#df_trips$to_location.coordinates = as.character(df_trips$to_location.coordinates)
#write.csv(df_trips,sprintf("./newdata/full_trip_data_%s.csv",station_short))

#library data
write.csv(visitors,sprintf("./newdata/libvisitors.csv"))

#enrollment data
write.csv(visitors,sprintf("./newdata/enroll.csv"))

stargazer(lm_divvy_small,title="Reginstein Library Station Results",align=TRUE)
#texreg(list(lm_divvy,lm_divvy_small))



######################COUNTS$$$$$$$$$$$$$$$$$$
by_quarter <- combined %>% group_by(quarter,year) %>% 
  dplyr::summarise(total_trips = sum(total_trips),visitor_count = sum(visitor_count)) %>%
  mutate(pct = total_trips / visitor_count)


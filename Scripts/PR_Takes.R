# NOAA Protected Resources Permit #22306 
# Marine mammal take tables and questionnaires need to be submitted annually for given reporting time range
# This script will not return the final report, the take numbers reported from this script need to be added to 
# the final Take Table provided by the permit coordinator

# Lines to update
  # Set your working directory in line 12
  # Set the reporting date range (start and end date) in line 34
  # Set the path to save file output in line 46

# SET WORKING DIRECTORY AND LOAD PACKAGES
setwd('~/GitHub/SAEL-lab-manual/Scripts')
library(readr)
library(dplyr)
library(lubridate)
 
#TAKE TABLE
# Import sightings from SpotterPro (https://spotter.conserve.io/spotter/projects)
# Complete a quality check on all sightings to ensure there were no data entry errors
sightings <- read_csv("sightings.csv")

# We will record all close approaches (regardless if we or the animal are approaching)
# and all sightings w/in 250 yards as a take

# CLEAN SIGHTINGS DATA
takes <- subset(sightings, select = c(`CINMS Species`, 
                                      `Total Sighted (Including Calves)`,
                                      `create_date`,
                                      `Distance Category`))

takes$`Distance Category`[takes$`Distance Category` == 'A'] <- '<25'
takes$`Distance Category`[takes$`Distance Category` == 'B'] <- '25-250'
takes$`Distance Category`[takes$`Distance Category` == 'C'] <- '>250'

takes <- takes[takes$create_date >= ymd("2023-01-01") & takes$create_date <= ymd("2023-12-31"), ]

takes <- takes[takes$`Distance Category` == '<25' | takes$`Distance Category` == '25-250',]

#Combine sightings to get total per species
takes <- takes %>%
  group_by(`CINMS Species`) %>%
  summarise(ActualTake = sum(`Total Sighted (Including Calves)`))

colnames(takes) <- c('Species', 'ActualTake')

# EXPORT FINAL TAKE TABLE
write.csv(takes, "2023_Takes.csv", row.names=FALSE)

#Extract HP sensitivity information from Inventory and DeploymentDetails worksheets
# adapted from Anne's code here https://github.com/asimonis/Odontocetes/blob/main/R/find_system_sensitivity.R

#----Example Use Case----
##----Use case for single deployment sensitivity, returns values in console----
  # Input = DepID is a string defining the deployment id ex:'ADRIFT_048'
SysSens(DepID = "ADRIFT_010")
##----Use case for multiple deployment sensitivity, returns values in data frame----
# list deployments of interest
# DepIDs <- c("PASCAL_001", "PASCAL_002") 
# OR
DepIDs <- c(sprintf("ADRIFT_%03d", 1:108), sprintf("CalCurCEAS_%03d", 1:27)) 

warnings <- character(0)
results_list <- lapply(DepIDs, function(id) {
  tryCatch({
    SysSens(id)
  }, error = function(e) {
    warnings <<- c(warnings, paste("Warning: incomplete data for deployment", id))
    NULL  # skip error silently
  })
})

calibrations <- do.call(rbind, results_list)

# print skipped deployments
calibrations
print(warnings)

# optional - save data frame as csv
write.csv(calibrations, "Scripts/All_calibrations.csv", row.names = FALSE)


#----Set Up Function----
# Load packages
library(googlesheets4)
# library(xlsx)
library(dplyr)
library(here)

# Read data outside the function
# download and read in sheets
# DeployDetails <- read.csv(here('data', 'Deployment Details - deployDetails.csv'), header=TRUE)
# Array <- read.csv(here('data', 'Inventory - Array.csv'), header=TRUE)
# Sens <- read.csv(here('data', 'Inventory - Hydrophones.csv'), header=TRUE)
# STSens <- read.csv(here('data', 'Inventory - RECORDERS.csv'), header=TRUE)

# OR 
# load from google sheets link
DeployDetails <- read_sheet("https://docs.google.com/spreadsheets/d/10bxlwfVOe1LFfj69B_YddxcA0V14m7codYwgD2YncFk/edit?gid=42687545#gid=42687545",
                            sheet = "deployDetails")
Array <- read_sheet("https://docs.google.com/spreadsheets/d/12u6cwwbuM7BfPt2GKjMXEOwr9yeK0_ztD04aNVYoFIk/edit?gid=395300949#gid=395300949", sheet = "Array")
Sens <- read_sheet("https://docs.google.com/spreadsheets/d/12u6cwwbuM7BfPt2GKjMXEOwr9yeK0_ztD04aNVYoFIk/edit?gid=395300949#gid=395300949", sheet = "Hydrophones")
STSens <- read_sheet("https://docs.google.com/spreadsheets/d/12u6cwwbuM7BfPt2GKjMXEOwr9yeK0_ztD04aNVYoFIk/edit?gid=395300949#gid=395300949", 
                     sheet = "RECORDERS")

SysSens <- function(DepID) {
  # Extract the row for this deployment
  DepIDDetails <- DeployDetails %>% 
    filter(Data_ID == DepID)
  
  # Extract the SoundTrap Serial Number
  STSN <- as.character(unlist(DepIDDetails$Instrument_ID))
  
  # Get SoundTrap sensitivity
  STSens_val <- STSens %>%
    filter(`Instrument_ID (serial number)` == STSN) %>%
    pull(`Sensitivity dB re. 1 μPa/V`)
  
  # Extract array name for deployment
  DepArray <- DepIDDetails$Array_name
  
  # Get hydrophone serial numbers and distances for each channel
  DepHP <- Array %>%
    filter(`Array_name (Array letter + 2 digit version number_Hydrophone model numbers)` 
           == DepArray) %>%
    rename(
      CH1.HP = `SensorNumber_1 (hydrophone serial number)`, 
      CH2.HP = `SensorNumber_2 (hydrophone serial number)`,
      CH1.Dist = `HydrophoneDistance_1 (m)`,
      CH2.Dist = `HydrophoneDistance_2 (m)`
    )
  
  # Coerce hydrophone serial numbers to character
  DepHP$CH1.HP <- as.character(unlist(DepHP$CH1.HP))
  DepHP$CH2.HP <- as.character(unlist(DepHP$CH2.HP))
  
  # Subset Sensitivity table for those serial numbers
  DepSN <- c(DepHP$CH1.HP, DepHP$CH2.HP)
  Sens$`Serial Number` <- as.character(unlist(Sens$`Serial Number`))
  
  DepSens <- Sens %>%
    filter(`Serial Number` %in% DepSN) %>%
    select(Model, `Serial Number`, `Hydrophone Sensitivity dB re: 1V/uPa`)
  
  # Rename column
  names(DepSens)[names(DepSens) == "Hydrophone Sensitivity dB re: 1V/uPa"] <- "Sensitivity"
  
  # Match each channel's sensitivity
  DepHP$CH1.Sens <- DepSens$Sensitivity[DepSens$`Serial Number` == DepHP$CH1.HP]
  DepHP$CH2.Sens <- DepSens$Sensitivity[DepSens$`Serial Number` == DepHP$CH2.HP]
  
  # Combine and return result
  return(data.frame(
    DepID = DepID,
    CH1_Sens_dB = as.numeric(DepHP$CH1.Sens),
    CH1_Dist_m = as.numeric(DepHP$CH1.Dist),
    CH2_Sens_dB = as.numeric(DepHP$CH2.Sens),
    CH2_Dist_m = as.numeric(DepHP$CH2.Dist),
    ST_Sens_dB = as.numeric(STSens_val),
    FullSystem_CH1_dB = (as.numeric(STSens_val) + as.numeric(DepHP$CH1.Sens))
  ))
}


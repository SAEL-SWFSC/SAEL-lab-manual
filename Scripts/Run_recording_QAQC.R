# Run quality assurance and control check on audio data
# There are some assumptions on folder structure and data types that must be met to avoid errors in this workflow. See more information here; [PAM QAQ/QC Tools PAMverse page](https://nmfs-ost.github.io/PAMverse/content/QAQC.html) and [PAMscapes QAQC User Guide](https://docs.google.com/document/d/1coo21rPb7WIxkFPqjt7CQKAkDu5KjdqXsZs_0PVbI9M/edit?usp=sharing)

#----Load packages----
library(PAMmisc)
library(PAMscapes)
library(googlesheets4)
library(dplyr)

#----Read deployment metadata (deployment IDs and calibration values)----
# download and read in sheets
# DeployDetails <- read.csv(here('data', 'Deployment Details - deployDetails.csv'), header=TRUE)

# OR 
# load from google sheets link
DeployDetails <- read_sheet("https://docs.google.com/spreadsheets/d/10bxlwfVOe1LFfj69B_YddxcA0V14m7codYwgD2YncFk/edit?gid=42687545#gid=42687545",
                            sheet = "deployDetails")

#----Run QAQC Function For Single Deployment----
DepID <- 'PASCAL_001' # list deployment of interest

DepSens <- DeployDetails %>%
 filter(Data_ID == DepID) %>%
 pull(SystemSensitivity)
 
qaqcData <- evaluateDeployment(dir = paste0("Z:/RECORDINGS/DRIFTERS/PASCAL_2016/RAW/", DepID), 
                              sensitivity = DepSens, 
                              outDir = paste0("Z:/METADATA/PASCAL/", DepID,"/", DepID, "_QAQC"))

# This will open a shiny app to review the data
# runQAQCReview(qaqcData)

#----Run QAQC Function For Group of Deployments----
# list deployments of interest manually
# DepIDs <- c("PASCAL_001", "PASCAL_002") 

# OR
filtered_data <- DeployDetails %>%
  filter(Project == "ADRIFT", Status == "Complete")

filtered_data <- filtered_data[-c(1:56), ]

DepIDs <- filtered_data$Data_ID

Sens_df <- DeployDetails %>%
  filter(Data_ID %in% DepIDs) %>%
  select(Data_ID, SystemSensitivity) %>%
  rename(DepID = Data_ID, Sensitivity = SystemSensitivity)

# Set directories
rawAudio <- "Z:/RECORDINGS/DRIFTERS/ADRIFT/RAW/"
output <- "Z:/METADATA/ADRIFT/"

for (i in 1:nrow(Sens_df)) {
  evaluateDeployment(dir = paste0(rawAudio, Sens_df$DepID[i], "_CENSOR"), 
                     sensitivity = Sens_df$Sensitivity[i], 
                     outDir = paste0(output, Sens_df$DepID[i], "/", Sens_df$DepID[i], "_QAQC"))
}



# Uncomment the line below to review data in a shiny app
# runQAQCReview('Path to data csv file')

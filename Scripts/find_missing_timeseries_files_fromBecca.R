## Script to identify missing files from cloud upload

library(lubridate)
library(ggplot2)
library(tidyverse)

# Given that we expect 6 files per day, this script generates 3 figures that help identify days that have fewer than 6 files


#### Set file paths for wav file and log/sud file folder ####

# These directory path examples assume that you have the nefsc-1 bucket mapped to the Y: drive
wavFolderPath = "Y:/bottom_mounted/NEFSC_MA-RI/NEFSC_MA-RI_202407_NS13/NEFSC_MA-RI_202407_NS13_ST/NEFSC_MA-RI_202407_NS13/8544_48kHz_UTC"
logSudFolderPath = "Y:/bottom_mounted/NEFSC_MA-RI/NEFSC_MA-RI_202407_NS13/NEFSC_MA-RI_202407_NS13_ST/NEFSC_MA-RI_202407_NS13/8544_LOG-and-SUD/"


#### Run the rest of the script as is to generate 3 plots that should help identify gaps ####

#### Find missing wav files
wavFolder = as.data.frame(list.files(wavFolderPath, pattern = "\\.wav$"))
colnames(wavFolder) = "filename"

# extract date time and date as separate columns from the standard ST filename
wavFolder$dateTimes = as_datetime(substring(wavFolder$filename,6,17)) 
wavFolder$dates = date(wavFolder$dateTimes)

# calculate the number of files per day
nWavfileDate = wavFolder %>%
  group_by(dates)%>%
  summarize(nfiles = n())

ggplot(data = nWavfileDate, aes(x = dates, y = nfiles))+
  geom_point()+
  ggtitle("Number of wav files per day")


#### Find missing log files ####
LogFolder = as.data.frame(list.files(logSudFolderPath, pattern = "\\.log.xml$"))
colnames(LogFolder) = "filename"

# extract date time and date as separate columns from the standard ST filename
LogFolder$dateTimes = as_datetime(substring(LogFolder$filename,6,17)) 
LogFolder$dates = date(LogFolder$dateTimes)

# calculate the number of files per day
nLogfileDate = LogFolder %>%
  group_by(dates)%>%
  summarize(nfiles = n())

ggplot(data = nLogfileDate, aes(x = dates, y = nfiles))+
  geom_point()+
  ggtitle("Number of log files per day")

#### Find missing sud files ####
sudFolder = as.data.frame(list.files(logSudFolderPath, pattern = "\\.sud$"))
colnames(sudFolder) = "filename"

# extract date time and date as separate columns from the standard ST filename
sudFolder$dateTimes = as_datetime(substring(sudFolder$filename,6,17)) 
sudFolder$dates = date(sudFolder$dateTimes)

# calculate the number of files per day
nfileDate = sudFolder %>%
  group_by(dates)%>%
  summarize(nfiles = n())

ggplot(data = nfileDate, aes(x = dates, y = nfiles))+
  geom_point()+
  ggtitle("Number of sud files per day")


# ----------------------------
# Front End Paths / Decisions
# ----------------------------
Local_dir <- "C:/Users/kourtney.burger/Desktop/test" # Path to Local Directory you want to copy FROM
Cloud_dir <- "swfsc-1/drifting_recorder/kbtest"      # Path to Cloud Directory you want to copy TO
offHoursCopy <- FALSE                                # TRUE = Copy on nights/weekends, FALSE = copy until complete
file_type <- c("\\.wav$",
               "\\.log.xml$",
               "\\.accel.csv$",
               "\\.temp.csv$",
               "\\.ltsa$"
)

# Leave as is, unless you want to change where the log file is saved to, in this structure it is built to be saved to the /Scripts folder in the GitHub repo 
log_file <- paste0(getwd(), "/GCP_transfer_log_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".txt")  # Log file name, with path (used with gsutil -L command)


# -----------RUN AS IS-----------
# Check for weekday and hour, run between 6 AM and 6 PM on weekdays
is_weekday = function(x){
  weekdays = c('Thursday', 'Friday', 'Monday', 'Tuesday', 'Wednesday')
  return(weekdays(x) %in% weekdays)
}
is_after_hours = function(x){
  return(as.integer(format(x,"%H")) < 6 | as.integer(format(x, "%H")) > 18)
}

# List all the files in the local directory, recursively
file_type <- paste(file_type, collapse = "|") # combine all file types to one regex (uses or expression)
good_files <- list.files(Local_dir, pattern = file_type, full.names = TRUE, recursive = TRUE)

# Copy files one by one and create a log
for (file in good_files) {
  # check for after hours, will run any time if offHoursCopy = FALSE above
  if (offHoursCopy) {
    while (is_weekday(Sys.time()) & !is_after_hours(Sys.time())) {
      cat(paste('waiting...',Sys.time(), "\n"))
      Sys.sleep(600) #wait 10 minutes until trying again
    }
  }
  
  # build a relative GCP path to retain local folder structure
  rel_path <- gsub(paste0("^", Local_dir, "/?"), "", file)
  GCP_path <- paste0("gs://", Cloud_dir, "/", rel_path)
  
  # create gsutil command
  cmd <- paste0("gsutil -m cp -c -L ", log_file, " ", file, " ", GCP_path)
  
  # pass command to process and print progress message in R console
  message("Uploading: ", file, " -> ", GCP_path)
  system(cmd)
}

# convert log file to csv to make it easier to check upload
log <- read.csv(log_file, header = TRUE)
write.csv(log, paste0(log_file, ".csv"), row.names = FALSE)


# -------------OLD CODE------------- 
# # Google  cloud bucket to transfer to
# Cloud_dir = 'swfsc-1/drifting_recorder/ADRIFT'

# # List deployment IDs to copy to bucket
# Local_dir <- "Z:/RECORDINGS/DRIFTERS/ADRIFT/RAW" #path to top level directory
# all_deployments <- list.dirs(Local_dir, full.names = FALSE, recursive = FALSE) #list deployment IDs based on folder names within top level directory
# Local_dir <- grep("^ADRIFT_\\d{3}", all_deployments, value = TRUE) #remove Opps deployments


# # Copy files
# for (folder in Local_dir) {
#   #check day and time
#   # while (is_weekday(Sys.time()) & !is_after_hours(Sys.time())) {
#   #   cat(paste('waiting...',Sys.time(), "\n"))
#   #   Sys.sleep(600) #wait 10 minutes until trying again
#   # }
#   
#   # LocalDir <- file.path(Local_dir) #local folder with wav files
#   
#   # wav <- list.files(LocalDir, pattern = "\\.wav$", full.names = TRUE) #list of wav files to copy
#   good.file <- list.files(Local_dir, pattern = file_type, full.names = TRUE) #list of wav files to copy
#   
#   # GCP_FolderName <- sub("_CENSOR$", "", folder) # create folder name for GCP bucket, removing CENSOR from folder name
#   
#   # GCP_FolderName <- folder
#   
#   GCP_path <- paste0(Cloud_dir, "/") # create path to GCP folder
#   
#   for (file in good.file) {
# #     string <- paste("gsutil -m cp -r ", file, " ", "gs://", GCP_path, "/", sep="") # create command to pass to google cloud sdk command window
#     
#     string <- paste0("gsutil -m cp -c -L ", log_file, " -r ", file, " gs://", GCP_path)
#     
#     message("Uploading: ", file, " -> ", GCP_path) # print a progress message in R console
#     
#     system(string) # pass the command for processing and wav file transfer
#   }
# }


# -------------ORIGINAL GoogleCloudBulkUpload.R-------------
# # Check for weekday and hour
# is_weekday = function(x){
#   weekdays = c('Thursday', 'Friday', 'Monday', 'Tuesday', 'Wednesday')
#   return(weekdays(x) %in% weekdays)
# }
# 
# is_after_hours = function(x){
#   return(as.integer(format(x,"%H")) < 6 | as.integer(format(x, "%H")) > 18)
# }
# 
# # Google  cloud bucket to transfer to
# my_fmc_bucket_name = 'swfsc-1/drifting_recorder/ADRIFT'
# 
# # List deployment IDs to copy to bucket
# deployment_dir <- "Z:/RECORDINGS/DRIFTERS/ADRIFT/RAW" #path to top level directory
# all_deployments <- list.dirs(deployment_dir, full.names = FALSE, recursive = FALSE) #list deployment IDs based on folder names within top level directory
# ADRIFT_deployments <- grep("^ADRIFT_\\d{3}", all_deployments, value = TRUE) #remove Opps deployments
# 
# # Copy wav files
# for (folder in ADRIFT_deployments) {
#   #check day and time
#   while (is_weekday(Sys.time()) & !is_after_hours(Sys.time())) {
#     cat(paste('waiting...',Sys.time(), "\n"))
#     Sys.sleep(600) #wait 10 minutes until trying again
#   }
#   
#   LocalDir <- file.path(deployment_dir, folder) #local folder with wav files
#   
#   wav <- list.files(LocalDir, pattern = "\\.wav$", full.names = TRUE) #list of wav files to copy
# 
#   GCP_FolderName <- sub("_CENSOR$", "", folder) # create folder name for GCP bucket, removing CENSOR from folder name
# 
#   GCP_path <- file.path(my_fmc_bucket_name, GCP_FolderName) # create path to GCP folder
#   
#   for (file in wav) {
#     string <- paste("gsutil -m cp -r ", file, " ", "gs://", GCP_path, "/", sep="") # create command to pass to google cloud sdk command window
#     
#     message("Uploading: ", file, " -> ", GCP_path) # print a progress message in R console
#     
#     system(string) # pass the command for processing and wav file transfer
#   }
# }

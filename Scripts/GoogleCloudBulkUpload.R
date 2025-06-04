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

# Leave as is, unless you want to change where the log file is saved to. This structure is built to save it to your current working directory 
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

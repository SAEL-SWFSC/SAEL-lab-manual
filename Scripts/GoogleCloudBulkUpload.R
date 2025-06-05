# -----------LIBRARIES-----------
library(xlsx)

# -----------FRONT END PATHS / DECISIONS-----------
Local_dir <- "C:/Users/kourtney.burger/Desktop/test" # Path to Local Directory you want to copy FROM
Cloud_dir <- "swfsc-1/drifting_recorder/kbtest"      # Path to Cloud Directory you want to copy TO
offHoursCopy <- FALSE                                # TRUE = Copy on nights/weekends, FALSE = copy until complete
file_type <- NULL                                    # Copy all files in a directory
# file_type <- c("\\.wav$",                          # Copy files with select extensions
#                "\\.log.xml$",
#                "\\.accel.csv$",
#                "\\.temp.csv$",
#                "\\.ltsa$",
#                "\\.flac$"
# )
log_file <- paste0(getwd(), "/GCP_transfer_log_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".txt")  # Log file name, with path (used with gsutil -L command). Leave as is, unless you want to change where the log file is saved to. This structure is built to save it to your current working directory


# -----------OPTIONAL BUT RECOMMENDED-----------
# If there are any spaces within your filenames/foldernames, this batch upload will not work
# We recommend you run this and replace any spaces in your ORIGINAL filenames/foldernames
# Risk: If you have documents, code that require the exact names (with spaces), you may have issues
# IF you need to retain your spaces, then consider direct upload via GCP

# Short recursive space-to-underscore renamer
rename_spaces <- function(path = ".") {
  # Get all files and folders, deepest first
  all_paths <- list.files(path, recursive = TRUE, full.names = TRUE, include.dirs = TRUE)
  all_paths <- all_paths[order(nchar(all_paths), decreasing = TRUE)]
  
  # Rename each item that contains spaces
  for (p in all_paths) {
    if (grepl(" ", basename(p))) {
      new_path <- file.path(dirname(p), gsub(" ", "_", basename(p)))
      file.rename(p, new_path)
      cat("Renamed:", basename(p), "->", basename(new_path), "\n")
    }
  }
}

rename_spaces(Local_dir)


# -----------COPY FILES TO GCP-----------
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
  cmd <- paste0("gsutil -m cp -c -L \"", log_file, "\" \"", file, "\" \"", GCP_path, "\"")
  
  # pass command to process and print progress message in R console
  message("Uploading: ", file, " -> ", GCP_path)
  system(cmd)
}


# -----------Clean log file and summarize-----------
# read in log file created in cmd
log_df <- read.csv(log_file, header = TRUE)

# subset files that successfully transferred and failed 
successful_log <- subset(log_df, Result == "OK") 
failed_log <- subset(log_df, Result == "ERROR" | Result == "SKIPPED")

# number of files that successfully copied and failed 
N_files_copied <- nrow(successful_log)
N_files_failed <- nrow(failed_log)

# number of folders copied 
successful_log$Folder <- dirname(successful_log$Source)  
num_folders_copied <- length(unique(successful_log$Folder)) 

# Total local size and total cloud size 
total_local_size <- sum(as.numeric(successful_log$Source.Size), na.rm = TRUE)
total_bytes_transferred <- sum(as.numeric(successful_log$Bytes.Transferred), na.rm = TRUE) 

# create summary dataframes and write both to an excel file
summary_df <- data.frame(Files_Copied = N_files_copied, N_files_failed, Folders_Copied = num_folders_copied, Total_Local_Size_bytes = total_local_size, Total_Cloud_Size_bytes = total_bytes_transferred)
failed_df <- failed_log[, c("Source", "Destination", "Source.Size", "Bytes.Transferred", "Result")]

xlsx_file <- sub("\\.txt$", ".xlsx", log_file)
write.xlsx(summary_df, xlsx_file, sheetName = "Summary", row.names = FALSE)
write.xlsx(failed_df, xlsx_file, sheetName = "Failed Files", row.names = FALSE, append = TRUE)
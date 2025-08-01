logs <- list.files(pattern = "\\.txt$")

#i=2

for (i in 1:length(logs)) {
  # read in log file created in cmd
  log_df <- read.csv(logs[i], header = TRUE)
  log_file <- paste0(getwd(), "/", logs[i])
  
  # subset files that successfully transferred and failed 
  successful_log <- subset(log_df, Result == "OK") 
  failed_log <- subset(log_df, Result == "error" | Result == "SKIPPED" | Result == "skipped")
  
  # number of files that successfully copied and failed 
  N_files_copied <- nrow(successful_log)
  N_files_failed <- nrow(failed_log)
  
  # number of folders copied 
  successful_log$Folder <- dirname(as.character(successful_log$Source))  
  num_folders_copied <- length(unique(successful_log$Folder)) 
  
  # Total local size and total cloud size 
  total_local_size <- sum(as.numeric(successful_log$Source.Size), na.rm = TRUE)
  total_bytes_transferred <- sum(as.numeric(successful_log$Bytes.Transferred), na.rm = TRUE) 
  
  # create summary dataframe
  summary_df <- data.frame(Files_Copied = N_files_copied, N_files_failed, Folders_Copied = num_folders_copied, Total_Local_Size_bytes = total_local_size, Total_Cloud_Size_bytes = total_bytes_transferred)
  
  xlsx_file <- sub("\\.txt$", ".xlsx", log_file)
  
  # Create a new workbook
  wb <- createWorkbook()
  
  # Add Summary sheet
  addWorksheet(wb, "Summary")
  writeData(wb, "Summary", summary_df)
  
  # Add Success Files Sheet
  addWorksheet(wb, "Completed Files")
  writeData(wb, "Completed Files", successful_log)
  
  # Add Failed Files sheet
  addWorksheet(wb, "Failed Files")
  writeData(wb, "Failed Files", failed_log)
  
  # Save the workbook
  saveWorkbook(wb, xlsx_file, overwrite = TRUE)
}



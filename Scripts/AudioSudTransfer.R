# Set working directory where your local folders are located
local_dir <- "X:\\RECORDINGS\\DRIFTERS\\ADRIFT\\trasnfer_to_GCP"
log_file <- file.path(local_dir, "gsutil_copy_log.txt")


# List all folders matching pattern

# ONLY LIST 101-108
folders <- list.dirs(local_dir, recursive = FALSE, full.names = TRUE)
target_folders <- folders[grepl("ADRIFT_\\d{3}_audio_SUD$", basename(folders))]

# Iterate over folders and construct gsutil commands
for (src_path in target_folders) {
  folder_name <- basename(src_path)
  match <- regmatches(folder_name, regexpr("ADRIFT_\\d{3}", folder_name))
  
  if (length(match) == 1) {
    # Construct destination GCS path
    dest_path <- paste0("gs://swfsc-1/drifting_recorder/SWFSC-CC/2021-23_ADRIFT_SRankin/", match, "/audio_SUD/")
    
    # gsutil cp command with logging
    cmd <- sprintf(
      'gsutil -m cp -r -L "%s" "%s/*" "%s"',
      log_file, src_path, dest_path
    )
    
    # Print and run the command
    cat("Running command:\n", cmd, "\n\n")
    system(cmd)
  } else {
    cat("Skipping unrecognized folder format:", folder_name, "\n")
  }
}

# batch_template.R

# Theresa Swayne, Columbia University, 2025
# -------- Suggested text for acknowledgement by core facility users -----------
#   "These studies used the Confocal and Specialized Microscopy Shared Resource 
#   of the Herbert Irving Comprehensive Cancer Center at Columbia University, 
#   funded in part through the NIH/NCI Cancer Center Support Grant P30CA013696."

# --------- About this script ------------
# Framework for running R code on every CSV file in a user-selected folder
# Input: A folder of files specified by the user on launch (when prompted, select any file within the folder)
# The "pattern" in the file list command can be changed to match other file name patterns. By default it includes all CSV files.
# Output folder is created to store results, with a time-date stamp
# Optionally, the results files can be merged using the combine_csv_files.R script

# ---- Setup ----

require(tidyverse) # for data processing
require(stringr) # for string harvesting
require(tools) # for file name processing

# ---- Input and output setup ----

# Prompt for a file. No message will be displayed. Choose one of the files in the folder.
selectedFile <- file.choose()
inputFolder <- dirname(selectedFile) # the input is the parent of the selected file

# Create an output folder with time-date stamp

thisTime = format(Sys.time(),"%Y-%m-%d_%H%M")
outputFolder <- file.path(inputFolder,paste0("Output_",thisTime))
dir.create(outputFolder) # creates within the input folder if it does not already exist

# Get names of CSV files in the folder
# Change the pattern as needed to match other aspects of the file name

files <- list.files(inputFolder, pattern = "*.csv")

# ----- Function to process a single file ------

process_file_func <- function(f, out) {
  
  # read the file
  data <- read_csv(file.path(inputFolder, f))
  
  # ---- Insert your processing steps here! ----
  
  # example processing step: get the mean of each column in the CSV file
  result <- data %>% summarise_all(mean)
  
  # ---- Save results ----
  
  # generate output filename from input name
  outputName = paste(file_path_sans_ext(basename(f)),"_processed.csv", sep = "")
  # write CSV file
  write_csv(result,file.path(out, outputName))
  
  return()
} # end of process file function

# ---- Run the function on each file ----

for (file in files){
  process_file_func(file, outputFolder)
}


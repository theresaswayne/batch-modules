# combine_csv_files.R

# Merges a batch of csv files, putting the filename in a new column
# Theresa Swayne, adapted from http://serialmentor.com/blog/2016/6/13/reading-and-combining-many-tidy-data-files-in-R
# -------- Suggested text for acknowledgement by core facility users -----------
#   "These studies used the Confocal and Specialized Microscopy Shared Resource 
#   of the Herbert Irving Comprehensive Cancer Center at Columbia University, 
#   funded in part through the NIH/NCI Cancer Center Support Grant P30CA013696."

# Requirement: All files must be within a single folder and the name must end with the pattern stored in the finalText variable
# Output file will be named after the input folder and will be stored in the input folder's parent directory.

# ---- Setup ----

require(tidyverse)

# text to filter for in the end of the file name
finalText <- "meas_results.csv"
# finalText <- "quant_results.csv"

# ---- Prompt for an input folder ----

# No message will be displayed. Choose any file within the folder
selectedFile <- file.choose()
inputFolder <- dirname(selectedFile) # the input is the parent of the selected file

# Read all the files in the folder ------

outputFolder <- dirname(inputFolder) # parent of the input folder

# get file names
files <- dir(inputFolder, pattern = paste("*",finalText,sep=""))

mergedDataWithNames <- tibble(filename = files) %>% # tibble holding file names
  mutate(file_contents =
           map(filename,          # read files into a new data column
               ~ read_csv(file.path(inputFolder, .),
                          locale = locale(encoding = "latin1"),
                          na = c("", "N/A"))))

# unnest to make the list into a flat file again,
# but it now has 1 extra column to hold the filename
mergedDataFlat <- unnest(mergedDataWithNames, cols = c(file_contents))


# Write an output file of all the merged data ----------

outputFile = paste(basename(inputFolder), "_merged_", finalText, sep = "")
write_csv(mergedDataFlat,file.path(outputFolder, outputFile))


# combine_data_for_superplot.R

# commands (not a runnable script) to combine replicates and conditions into a dataframe for use in creating a superplot
# This accomplishes 2 necessary tasks for making a superplot:
# 1) Combining all replicates into 1 dataframe with a column identifying the replicate
# 2) Combining all experimental conditions into unique group descriptors.
#     What this means: If you are varying 2 or more parameters (e.g. genotype and drug), 
#     you need to create a Condition that includes all of the parameters: e.g WT Control, WT Drug, KO Control, KO Drug.


# ---- Important Assumptions! ----

# Assumes 3 replicates
# Load 1 dataframe for each replicate under the names:
# replic1, replic2, replic3
# Data should contain at least column(s) identifying the experimental condition(s),
# and some measurement (provide the name in measurementName below).
# (TODO: load from a folder to support an indeterminate number of replicates)

# For Cue5: Replicate files can be the filtered_distances or the intden contact files.

# Enter the desired final column name for the measurement you want to visualize
measurementName <- "Fraction of Puncta IntDen in Contact"

# ---- Setup ----
require(tidyverse)
require(ggplot2)
require(ggpubr) # for comparing means
require(ggbeeswarm)

# ---- Combine the replicates into a single dataframe ----

# Add a column identifying the replicate
# TODO: do this in a more automated way like in the combine_csv_files script

replic1_mod <- replic1 |> 
  mutate(Replicate = 1, .before = filename)

replic2_mod <- replic2 |> 
  mutate(Replicate = 2, .before = filename)

replic3_mod <- replic3 |> 
  mutate(Replicate = 3, .before = filename)

# Combine all data
combined <- rbind(replic1_mod, replic2_mod, replic3_mod)

# ---- Combine all conditions into a single column ----

# parse image filename to get genotype (1st 6 chars) 
#    and treatment (search for CON or 6hr)
geno <- substr(combined$filename, 0, 6)
treat <- substr(combined$filename, 8, 10)

# replace original genotype, filename, and treatment with more readable info
geno <- str_replace(geno, "CTY132", "WT")
geno <- str_replace(geno, "CTY212", "cue5∆")
treat<- str_replace(treat, "6hr", "DTT")
treat<- str_replace(treat, "CON", "Control")

combined <- mutate(combined, 
                 Genotype = geno, 
                 Treatment = treat, 
                 .after = filename)


# combine the genotype and treatment into a single string
condition <- paste(combined$Genotype, combined$Treatment, sep=" ")

# check that the resulting Condition strings are what you want
unique(condition)

# add the new condition column to the dataframe
combined <- mutate(combined, Condition = condition, .after = Treatment)

# rename the measurement column (select the appropriate measurement column as needed)
# note that !! and := are required if you want to rename with the value of a variable
# combined_mod <- rename(combined, !!measurementName:= V1)
combined <- rename(combined, !!measurementName:= FxnIntDenContact)

# re-order so WT is first
combined <- mutate(combined, Condition = fct_relevel(Condition, "WT Control", "WT DTT", "cue5∆ Control", "cue5∆ DTT"))

# ---- Save the result ----

write_csv(combined, paste0(measurementName,"_all_replicates.csv"))


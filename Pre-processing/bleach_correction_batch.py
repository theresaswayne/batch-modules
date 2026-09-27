#@ File(label = "Input folder:", style = "directory") inDir
#@ File(label = "Output folder:", style = "directory") outDir
#@ String(label="Image File Extension", required=false, value=".tif") image_extension
#@ String  (label = "File name contains", value = "") containString

# bleach_correction_batch.py
# ImageJ/Fiji jython script 
# Theresa Swayne, 2024, adapted from Kota Miura's script at https://gist.github.com/miura/9080feb52eb74079ae393dd9320cb6ed 

#  -------- Suggested text for acknowledgement by core facility users -----------
#   "These studies used the Confocal and Specialized Microscopy Shared Resource 
#   of the Herbert Irving Comprehensive Cancer Center at Columbia University, 
#   funded in part through the NIH/NCI Cancer Center Support Grant P30CA013696."

# Limitations: If the BleachCorrection function finds that any dataset is "not decaying" (no bleaching detected) it will stop.

# ---- Setup ----

import os
import math
import io
from net.imglib2.view import Views
from ij import IJ, ImagePlus, ImageStack
from ij.process import ImageProcessor, FloatProcessor, StackProcessor
import string
from emblcmci import BleachCorrection
from java.lang import System

# Record start time
start_time = System.nanoTime()
IJ.log("Started at " + str(start_time))

# ---- Find image files ---- 
inputdir = str(inDir) # convert the directory object into a string
outputdir = str(outDir)
fnames = [] # empty array for filenames
for fname in os.listdir(inputdir):
	if fname.startswith("."): # avoid dotfiles that have the extension and filename filter
		continue
	if fname.endswith(image_extension):
		if containString not in fname:
			continue
		fnames.append(os.path.join(inputdir, fname)) # add matching file paths to the array
		
fnames = sorted(fnames) # sort the file names

if len(fnames) < 1: # no files
	raise Exception("No image files found in %s" % inputdir)

# ---- Loop through files ----
for fname in fnames: 
	print "Processing:",fname

	# Access the image
	IJ.log("Opening image file "+ fname)
	# imp = IJ.openImage(fname) # open the image normally
	imp = ImagePlus(fname) # for headless (faster and less glitchy)
	IJ.log("Stack size: " + str(imp.getStackSize()))
	
	bc = BleachCorrection() # prepare bleach correction
	
	# select method (comment out unused methods)
	
	### simple ratio method
	#bc.setHeadlessProcessing(True)
	#bc.setCorrectionMethod(BleachCorrection.SIMPLE_RATIO)
	#bc.setSimpleRatioBaseline(5) # can update with your own background level
	
	### exponential fit method
	bc.setCorrectionMethod(BleachCorrection.EXPONENTIAL_FIT)
	bc.setHeadlessProcessing(True)
	
	### Histogram Matching Method
	#bc.setCorrectionMethod(BleachCorrection.HISTOGRAM_MATCHING)
	#bc.setHeadlessProcessing(True)
	
	# perform correction
	impcorrected = bc.doCorrection(imp)
	
	#imp.show()
	#impcorrected.show()
	IJ.log("Finished correcting "+fname)

	outputName = string.join((os.path.basename(fname)[0:-4],"_corr", image_extension), "")
	# save the output image
	IJ.log("Saving to " + outputdir)
	IJ.saveAs(impcorrected, "Tiff", os.path.join(outputdir, outputName));
	#imp.close()
 
#  Record end time
end_time = System.nanoTime()

#  Calculate duration
elapsed_time = end_time - start_time
elapsed_seconds = elapsed_time / 1000000000.0

IJ.log("Finished in: " + str(elapsed_seconds) + " seconds")



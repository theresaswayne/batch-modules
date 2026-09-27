#@ File (label = "Input directory", style = "directory") inDir
#@ File (label = "Output directory", style = "directory") outDir
#@ String(label="Image File Extension", required=false, value=".tif") image_extension
#@ String  (label = "C1 name contains", value = "RFP") C1name
#@ String  (label = "C2 name contains", value = "GFP") C2name

# ImageJ/Fiji jython script to merge exactly 2 channels
# limitations: not recursive; images are merged in sort order

#  -------- Suggested text for acknowledgement by core facility users -----------
#   "These studies used the Confocal and Specialized Microscopy Shared Resource 
#   of the Herbert Irving Comprehensive Cancer Center at Columbia University, 
#   funded in part through the NIH/NCI Cancer Center Support Grant P30CA013696."

# ---- Setup ----

import os
import math
import io
from net.imglib2.view import Views
from ij import IJ, ImagePlus, ImageStack
from ij.process import ImageProcessor, FloatProcessor, StackProcessor
import string
from ij.plugin import RGBStackMerge
from ij import WindowManager
from java.lang import System

# Record start time
start_time = System.nanoTime()
print "Started at",start_time

# Create the arrays

wm = WindowManager

# ---- Find image files ---- 
inputDir = str(inDir) # convert the directory object into a string
outputDir = str(outDir)
fnames = [] # empty array for filenames

# set up arrays for channels
C1 = []
C2 = []

# get full file list
for fname in os.listdir(inputDir):
	if fname.startswith("."): # avoid dotfiles that have the extension and filename filter
		continue
	if fname.endswith(image_extension):
		#fnames.append(os.path.join(inputDir, fname))
		fnames.append(fname)

if len(fnames) < 1: # no files
	raise Exception("No image files found in %s" % inputDir)

fnames = sorted(fnames) # so correct images are matched up
print "Found", str(len(fnames)),"usable files"

# fill the channel arrays
for fname in fnames:
	if C1name in fname:
		C1.append(os.path.join(inputDir, fname))
		#print "Adding C1 image", fname
	elif C2name in fname:
		C2.append(os.path.join(inputDir, fname))
		#print "Adding C2 image", fname

print (str(len(C1)), str(len(C2)))
if (len(C1) != len(C2)):
	raise Exception("Unequal number of channel images found")

IJ.log("Found " + str(len(C1)) + " image sets")

# Loop over the images
for i in range(0, len(C1)):
	IJ.log("Processing set " + str(i))
	
	imp1 = IJ.openImage(os.path.join(inputDir,C1[i])) #image plus
	imp2 = IJ.openImage(os.path.join(inputDir,C2[i]))
	
	C1file = os.path.basename(C1[i])
	#print "File basename is", C1file
	C2file = os.path.basename(C2[i])
		
	images = [imp1, imp2]
	impMerge = RGBStackMerge.mergeChannels(images, False) # much faster than IJ.run
	
	base = os.path.splitext(os.path.basename(C1file))[0]
	outputName = string.join((base,"_merge",image_extension), "")
	IJ.saveAs(impMerge, "Tiff", os.path.join(outputDir, outputName))

	# clean up
	imp1.close()
	imp2.close()
	imp1 = None
	imp2 = None
	
	IJ.run("Collect Garbage")

#  Record end time
end_time = System.nanoTime()

#  Calculate duration
elapsed_time = end_time - start_time
elapsed_seconds = elapsed_time / 1000000000.0

IJ.log("Finished in: " + str(elapsed_seconds) + " seconds")


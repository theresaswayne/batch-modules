#@ File(label = "Input folder:", style = "directory") inDir
#@ File(label = "Output folder:", style = "directory") outDir
#@ String(label="Image File Extension", required=false, value=".tif") image_extension
#@ String(label="Image File Extension", required=false, value=".tif") image_extension
#@ int(label = "# of timepoints:",style = "spinner") numTimepoints

# stack_to_images.py
# Theresa Swayne, 2024
# From a folder of multichannel time stacks, saves all slices as multichannel tiff
# Useful for generating images for cellpose segmentation

# TO USE: Run the macro and specify folders for input and output.
# Limitations: Expects either Z or T series format.

# ---- Setup ----

import os
import math
import io
from net.imglib2.view import Views
from ij import IJ, ImagePlus, ImageStack
from ij.process import ImageProcessor, FloatProcessor, StackProcessor
import string
from ij import WindowManager

# Find image files
inputdir = str(inDir) # convert the directory object into a string
outputdir = str(outDir)
fnames = [] # empty array for filenames
for fname in os.listdir(inputdir):
	if fname.endswith(image_extension):
		fnames.append(os.path.join(inputdir, fname)) # add matching files to the array
fnames = sorted(fnames) # sort the file names

if len(fnames) < 1: # no files
	raise Exception("No image files found in %s" % inputdir)

print "Processing",len(fnames), "stacks"
		
for fname in fnames:

	currentFile = os.path.basename(fname)
	print "Processing:",currentFile
	
	imp = IJ.openImage(os.path.join(inputdir, fname)) # open image
	stack = imp.getStack()
	# get number of t slices, channels, etc
	slices = imp.getNSlices()
	frames = imp.getNFrames()
	#stack.getDimensions(width, height, channels, slices, frames)

	# fix Z/T confusion
	if slices > 1:
		print "Re-ordering"
		IJ.run("Re-order Hyperstack ...", "channels=[Channels (c)] slices=[Frames (t)] frames=[Slices (z)]")
		# get the new numbers
		#stack.getDimensions(width, height, channels, slices, frames)
		slices = imp.getNSlices()
		frames = imp.getNFrames()
	else:
		print "No need to re-order"
		
	# show the image so we can use the IJ.run later
	imp.show()
	
	# loop through frames
	for frameNum in range(1, frames+1):
		print "Processing frame",frameNum
		
		basename = currentFile[0:-4] # removes .tif
		frameNumPadded = str(frameNum).zfill(3)
		frameName = string.join((basename, "_t", frameNumPadded, ".tif"), "")
		
		IJ.run("Duplicate...", "title="+frameName+" duplicate frames="+str(frameNum)+"-"+str(frameNum))

		impFrame = wm.getImage(frameName)
		
		# print "Saving image",str(frameNum),"with name", frameName
		IJ.save(impFrame, os.path.join(outputdir, frameName))

		impFrame.close() # the frame
			
	imp.close() # the stack


print "Finished"


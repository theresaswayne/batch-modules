//@File(label = "Input image directory", style = "directory") inputDir
//@File(label = "Input ROIset directory", style = "directory") roiDir
//@File(label = "Output directory", style = "directory") outputDir
//@String (label = "Image file suffix", value = ".nd2") fileSuffix

// crop_from_saved_rois_batch.ijm
// ImageJ/Fiji script to process a batch of images and corresponding ROIsets to generate one image for each ROI, with the area outside cleared
// Theresa Swayne, 2025

//  -------- Suggested text for acknowledgement by core facility users -----------
//   "These studies used the Confocal and Specialized Microscopy Shared Resource 
//   of the Herbert Irving Comprehensive Cancer Center at Columbia University, 
//   funded in part through the NIH/NCI Cancer Center Support Grant P30CA013696."

// Input: ROIset must be a Zip file with the same base name as the image
// 	Image: MyImage.tif (or .nd2, etc)
// 	ROIset: MyImage.zip
// Output: A cropped image or stack matching the dimensionality of input,
//		corresponding to the bounding box of each ROI
//		with the area outside the label cleared to black (0); 
//		a snapshot of the ROI locations;
//		and a log.
//	Limitations -- cannot have >1 dots in the filename unless it is ome.tiff. 

// TO USE: Place all input images in the input image folder. 
//			ROI sets can be in the same or a different folder (but not nested in the image folder!). 
// 	Create a folder for the output files. 
//  Run the script in the Fiji Script Editor. 

// ---- Setup ----

while (nImages>0) { // close all open images
	selectImage(nImages);
	close();
}
run("Collect Garbage"); // helps to clear memory
print("\\Clear"); // clear Log window
startTime = getTime(); // keep track of time
setBatchMode(true); // faster performance 
run("Bio-Formats Macro Extensions"); // support native microscope files
roiManager("reset");

// ---- Run ----

print("Starting");

// Call the processFolder function, including the parameters collected at the beginning of the script
// returns the number of files processed 
n = processFolder(inputDir, roiDir, outputDir, fileSuffix);

// clean up
while (nImages > 0) { // close all open images
	selectImage(nImages);
	close(); 
}
setBatchMode(false);

// report processing time
time = getTime();
elapsedTime = (time - startTime)/1000;
print("Finished",n,"images in ", elapsedTime , " sec");

// save log
selectWindow("Log");
saveAs("text", outputRoiDir + File.separator + "Crop_Log.txt");

// ---- Functions ----

function processFolder(input, roiInput, output, suffix) {
	// this function searches for files matching the criteria and sends them to the processFile function

	filenum = 0;
	print("Processing folder", input);
	// scan folder tree to find files with correct suffix
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i])) {
			processFolder(input + File.separator + list[i], output, suffix); // handles nested folders
		}
		if(endsWith(list[i], suffix)) {
			filenum = filenum + 1;
			processFile(input, roiInput, output, list[i], filenum); // passes the filename and parameters to the processFile function
		}
	}
	return filenum;
} // end of processFolder function

function processFile(inputFolder, roiFolder, outputFolder, fileName, fileNumber) {
	// this function processes a single image
	
	// ---------- SETUP
	
	roiManager("reset");
	imagePath = inputFolder + File.separator + fileName;

	// determine the name of the file without extension -- support ome tiff
    if(endsWith(fileName, ".ome.tiff")){
	    basename_temp = File.getNameWithoutExtension(fileName);
	    basename = File.getNameWithoutExtension(basename_temp);
	    extension = ".ome.tiff";
    }
    else{
		dotIndex = lastIndexOf(fileName, ".");
	    basename = File.getNameWithoutExtension(basename);
		extension = substring(fileName, dotIndex);
    }
	
	print("Processing image",fileNumber," at path" ,imagePath, "with basename",basename, "and extension",extension );	

	// open the image file
	run("Bio-Formats", "open=&imagePath");
	rename("image"); // easier handling of files
	
	// open the corresponding ROIset
	//filenameParsed = split(basename, "-");
	roiFile = basename + ".zip"; 
	roiPath = roiFolder + File.separator +roiFile;
	
	roiManager("reset");
	print("Opening ROIset at", roiPath);
	
	if (File.exists(roiPath)) {
		roiManager("Open", roiPath);
	}
	else {
		print("No matching ROIset at " , roiPath);
		return; // skip to next image in the list
	}
	
	numROIs = roiManager("count");	
	// how much to pad?
	digits = Math.ceil((log(numROIs + 1)/log(10)));
	
	// ---------- DOCUMENT ROI LOCATIONS
	
	// save a snapshot
	getDimensions(width, height, channels, slices, frames);

	// view as composite using the 1st timepoint, middle slice
	if (frames > 1) {
		Stack.setFrame(1);
	}
	if (slices > 1) {
		midslice = Math.ceil(slices/2);
		Stack.setSlice(midslice);
	}
	if (channels > 1) {
		// auto contrast all channels
		Stack.setDisplayMode("color");
		for (i = 1; i <= channels; i ++) {
			Stack.setChannel(i);
			resetMinAndMax;
		}
		if (is("composite")) {
			Stack.setDisplayMode("composite");
		}
	}
	else { 
		// auto contrast a single channel 
		resetMinAndMax;
	}
	
	// create an RGB snapshot
	selectWindow("image");
	run("Select None");

	if (is("composite")) {
		Stack.setDisplayMode("composite"); 
		run("Stack to RGB", "keep"); // create an RGB image while keeping the original
	}
	else {
		run("Duplicate...", "title=copy"); // for single-channel non-RGB images; Flatten doesn't create new window
	}
	rgbID = getImageID(); // current image, should be the RGB or the duplicate
	selectImage(rgbID);

	// display ROIs on the image
	//run("Labels...", "color=white font=16 show draw bold"); // optional increase label size above the default
	roiManager("Show All with labels");
	run("Flatten");
	flatID = getImageID();
	selectImage(flatID);
	saveAs("tiff", outputFolder+File.separator+basename+"_ROIlocs.tif");
	
	print("Saved snapshot for image",basename);
	
	// close images from snapshot generation
	if (isOpen(flatID)) {
		selectImage(flatID);
		close();
	}
	if (isOpen(rgbID)) {
		selectImage(rgbID);
		close();
	}
	
	// ---------- CROP AND SAVE
	
	// make sure nothing is selected to begin with
	selectImage(id);
	roiManager("deselect");
	run("Select None");
	
	for(roiIndex=0; roiIndex < numROIs; roiIndex++) // loop through ROIs
		{ 
		selectImage(id);
		roiNum = roiIndex + 1; // so that image names start with 1 like the ROI labels
		roiManager("Select", roiIndex);  // ROI indices start with 0
		// roiName = Roi.getName();
		// print("The name of ROI number",roiNum, "is",roiName);
		roiNumPad = IJ.pad(roiNum, digits);
		cropName = basename+"_roi_"+roiNumPad + ".tif";
		run("Duplicate...", "title=&cropName duplicate"); // creates the cropped stack
		selectWindow(cropName);
		
		if ((selectionType() != 0) && (selectionType() != -1)) {
			run("Clear Outside","stack"); // this works because non-rectangular rois are still active on the cropped image
			run("Select None");// clears the selection that is otherwise saved with the image (although it can be recovered with "restore selection")
		}
		saveAs("tiff", outputFolder+File.separator+cropName);
		print("Saving ROI",roiNumPad,"as",cropName);
		close();
		}
	// ---------- CLEANUP
	
	run("Select None");
	print("Processed",numROIs," ROIs.");
	selectImage(id);
	close();
	roiManager("Reset");
	
	while (nImages > 0) { // close all open images
		selectImage(nImages);
		close(); 
	}
	run("Collect Garbage");
} // end of processFile function


	
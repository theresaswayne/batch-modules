//@File(label = "Input directory", style = "directory") inputDir
//@File(label = "Output directory", style = "directory") outputDir
//@String (label = "File suffix", value = ".tif") fileSuffix
//@ int(label="Min threshold for spots:")  minThresh

// batch_3DSeg.ijm
// ImageJ/Fiji script to process a batch of images
// Applies 3D spot segmentation using Gaussian criteria
// Saves the 3D mask
// Theresa Swayne, 2025
//  -------- Suggested text for acknowledgement -----------
//   "These studies used the Confocal and Specialized Microscopy Shared Resource 
//   of the Herbert Irving Comprehensive Cancer Center at Columbia University, 
//   funded in part through the NIH/NCI Cancer Center Support Grant P30CA013696."

// Input: A folder of single-channel Z stacks. Isotropic scaling is recommended.
// Output: Label stacks showing detected objects.
//	Limitation -- cannot have >1 dots in the filename (due to the peak finder)
// 	

// ---- Setup ----

while (nImages>0) { // clean up open images
	selectImage(nImages);
	close();
}
run("Collect Garbage");
print("\\Clear"); // clear Log window

setBatchMode(true); // faster performance
run("Bio-Formats Macro Extensions"); // support native microscope files


// keep track of time
startTime = getTime();

// ---- Run ----

print("Starting");

// Call the processFolder function, including the parameters collected at the beginning of the script

n = processFolder(inputDir, outputDir, fileSuffix, minThresh);

// Clean up images and get out of batch mode

while (nImages > 0) { // clean up open images
	selectImage(nImages);
	close(); 
}
setBatchMode(false);

time = getTime();
elapsedTime = (time - startTime)/1000;
print("Finished",n,"images in", elapsedTime , "sec");

// save Log
selectWindow("Log");
saveAs("text", outputDir + File.separator + "Seg_Log.txt");

// ---- Functions ----

function processFolder(input, output, suffix, minthresh) {

	// this function searches for files matching the criteria and sends them to the processFile function
	filenum = 0;
	print("Processing folder", input, "with minimum threshold",minthresh);
	
	// scan folder tree to find files with correct suffix
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i])) {
			processFolder(input + File.separator + list[i], output, suffix); // handles nested folders
		}
		if(endsWith(list[i], suffix)) {
			filenum = filenum + 1;
			processFile(input, output, list[i], filenum, minthresh); // passes the filename and parameters to the processFile function
		}
	}
	return filenum;
} // end of processFolder function


function processFile(inputFolder, outputFolder, fileName, fileNumber, minThreshold) {
	
	// this function processes a single image
	
	path = inputFolder + File.separator + fileName;
	print("Processing file",fileNumber," at path" ,path);	

	// determine the name of the file without extension
	dotIndex = lastIndexOf(fileName, ".");
	basename = substring(fileName, 0, dotIndex); 
	extension = substring(fileName, dotIndex);
	
	print("File basename is",basename);
	time = getTime();
	
	// open the file
	run("Bio-Formats", "open=&path");
	
	// Look at only channel 5
	//dupName = basename + "-c5";
	//run("Duplicate...", "title="+dupName+" duplicate channels=5");

	// rename sensibly
	rename("orig");
	
	// Find seeds for the spots using 3d local maxima
	selectWindow("orig");
	run("3D Maxima Finder", "minimmum="+minThresh+" radiusxy=2 radiusz=2 noise=300");
	seedName = "peaks_orig";
	
	// Find spots with a radius of ~ 1 SD of the Gaussian fit
	//run("3D Spot Segmentation", "seeds_threshold=0 local_background=0 local_diff=700 radius_0=0 radius_1=0 radius_2=0 weigth=0 radius_max=4 sd_value=1.17 local_threshold=[Gaussian fit] seg_spot=Classical watershed volume_min=10 volume_max=100 seeds=" + seedName + " spots=" + basename + " radius_for_seeds=2 output=[Label Image] verbose");
	
	run("3D Spot Segmentation", "seeds_threshold=0 local_background=0 local_diff=700 radius_0=0 radius_1=0 radius_2=0 weigth=0 radius_max=4 sd_value=1.17 local_threshold=[Gaussian fit] seg_spot=Classical watershed volume_min=10 volume_max=100 seeds=" + seedName + " spots=orig radius_for_seeds=2 output=[Label Image] verbose");
	
	// save the output, if any
	if (isOpen("Index")) {
		selectWindow("Index");
		outputName = basename + "_seg.tif";
		saveAs("tiff", outputFolder + File.separator + outputName);
	
		// report completion of this image
		print("Segmented image " + basename + " in " + (getTime() - time) + " msec");
	}
	else {
		print("Image " + basename + " did not contain any detected objects.");
	}
	
	// clean up
	while (nImages > 0) { // clean up open images
		selectImage(nImages);
		close(); 
	}
	

} // end of processFile function


	
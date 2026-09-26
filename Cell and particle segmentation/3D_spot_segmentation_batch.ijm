//@File(label = "Input directory", style = "directory") inputDir
//@File(label = "Output directory", style = "directory") outputDir
//@String (label = "File suffix", value = ".tif") fileSuffix
//@ int(label="Min threshold for seeds:")  minThresh

// 3D_spot_segmentation_batch.ijm
// ImageJ/Fiji script to process a batch of single-channel Z stacks
// Applies 3D spot segmentation using Gaussian criteria using 3D ImageJ Suite
// more info: https://mcib3d.frama.io/3d-suite-imagej/plugins/Segmentation/Custom/3D-Spots-Segmentation/
// Saves the label image mask
// Theresa Swayne, 2025
//  -------- Suggested text for acknowledgement by core facility users -----------
//   "These studies used the Confocal and Specialized Microscopy Shared Resource 
//   of the Herbert Irving Comprehensive Cancer Center at Columbia University, 
//   funded in part through the NIH/NCI Cancer Center Support Grant P30CA013696."

// Input: A folder of single-channel Z stacks. Isotropic scaling is recommended.
// Output: Label stacks showing detected objects.
//	Limitation -- cannot have >1 dots in the filename (due to the peak finder)
// ** To change other parameters in the spot segmentation, either edit directly or add script parameters to collect user input

// ---- Setup ----

while (nImages>0) { // close all open images
	selectImage(nImages);
	close();
}
run("Collect Garbage"); // helps to clear memory
print("\\Clear"); // clear Log window
startTime = getTime(); // keep track of total time
setBatchMode(true); // faster performance
run("Bio-Formats Macro Extensions"); // support native microscope files

// ---- Run ----

print("Starting");

// call the processFolder function, including the parameters collected at the beginning of the script
// returns the number of files processed 
n = processFolder(inputDir, outputDir, fileSuffix, minThresh);

// clean up
while (nImages > 0) { // close all open images
	selectImage(nImages);
	close(); 
}
setBatchMode(false);

// report total processing time
time = getTime();
elapsedTime = (time - startTime)/1000;
print("Finished",n,"images in", elapsedTime , "sec");

// save log
selectWindow("Log");
saveAs("text", outputDir + File.separator + "Seg_Log.txt");

// ---- Functions ----

function processFolder(input, output, suffix, minthresh) {
	// this function searches for files matching the criteria and sends them to the processFile function

	filenum = 0;
	print("Processing folder", input, "with minimum seed threshold",minthresh);
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

	print("File basename is",basename, "and extension is",extension );
	
	// open the file
	run("Bio-Formats", "open=&path");
	
	// rename for easier image name handling
	rename("orig");
	
	time = getTime(); // keep track of time for each image

	// find seeds for the spots using 3d local maxima
	selectWindow("orig");
	run("3D Maxima Finder", "minimmum="+minThresh+" radiusxy=2 radiusz=2 noise=300");
	seedName = "peaks_orig";
	
	// Find spots with a radius of ~ 1 SD of the Gaussian fit	
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
	while (nImages > 0) { // close all open images
		selectImage(nImages);
		close(); 
	}
	run("Collect Garbage"); // helps to clear memory
} // end of processFile function


	
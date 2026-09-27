//@File(label = "Input directory", style = "directory") inputDir
//@File(label = "Output directory", style = "directory") outputDir
//@String (label = "File suffix", value = ".tif") fileSuffix
//@ int(label="Registration channel:")  regChannel

// batch registration (drift correction) of multichannel stacks using Linear Stack Alignment with SIFT
// Theresa Swayne, 2026
//  -------- Suggested text for acknowledgement by core facility users -----------
//   "These studies used the Confocal and Specialized Microscopy Shared Resource 
//   of the Herbert Irving Comprehensive Cancer Center at Columbia University, 
//   funded in part through the NIH/NCI Cancer Center Support Grant P30CA013696."

//  Run the script in Fiji. 
//	Limitation -- cannot have >1 dots in the filename
// 	

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

// ---- Run ----

print("Processing ",fileSuffix,"images in folder", inputDir, "using channel", regChannel);

// call the processFolder function, including the parameters collected at the beginning of the script
// returns the number of files processed 
n = processFolder(inputDir, outputDir, fileSuffix, regChannel);

// clean up
while (nImages > 0) { // close all open images
	selectImage(nImages);
	close(); 
}
setBatchMode(false);

// report processing time
time = getTime();
elapsedTime = (time - startTime)/1000;
print("Processed",n,"images in ", elapsedTime , " sec");

// save log
selectWindow("Log");
saveAs("text", outputDir + File.separator + "Registration_Log.txt");


// ---- Functions ----

function processFolder(input, output, suffix, regChannel) {
	// this function searches for files matching the criteria and sends them to the processFile function

	filenum = 0;
	print("Processing folder", input);
	// scan folder tree to find files with correct suffix
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i])) {
			processFolder(input + File.separator + list[i], output, suffix, regChannel); // handles nested folders
		}
		if(endsWith(list[i], suffix)) {
			filenum = filenum + 1;
			processFile(input, output, list[i], filenum, regChannel); // passes the filename and parameters to the processFile function
		}
	}
	return filenum;
} // end of processFolder function


function processFile(inputFolder, outputFolder, fileName, fileNumber, channel) {
	// this function processes a single image
	
	path = inputFolder + File.separator + fileName;
	
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

	print("Processing image",fileNumber," at path" ,path, "with basename",basename, "and extension",extension );	
	
	// open the file
	run("Bio-Formats", "open=&path");

	// align stack based on the indicated channel
	run("Linear Stack Alignment with SIFT MultiChannel", "registration_channel="+channel+" initial_gaussian_blur=1.60 steps_per_scale_octave=3 minimum_image_size=64 maximum_image_size=1024 feature_descriptor_size=4 feature_descriptor_orientation_bins=8 closest/next_closest_ratio=0.92 maximal_alignment_error=25 inlier_ratio=0.05 expected_transformation=Rigid interpolate");
	
	// save the output
	outputName = basename + "_aligned.tif";
	selectImage("Aligned_"+fileName);
	saveAs("tiff", outputFolder + File.separator + outputName);
	close();
	
	// clean up
	while (nImages > 0) { // close all open images
		selectImage(nImages);
		close(); 
		}
	run("Collect Garbage"); // helps to clear memory

} // end of processFile function


	
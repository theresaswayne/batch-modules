// @File(label = "Input directory", style = "directory") inputDir
// @File(label = "Output directory", style = "directory") outputDir
// @String(label = "File suffix", value = ".tif") fileSuffix

// split_channels_batch.ijm
// Theresa Swayne, 2017
// -------- Suggested text for acknowledgement by core facility users -----------
//   "These studies used the Confocal and Specialized Microscopy Shared Resource 
//   of the Herbert Irving Comprehensive Cancer Center at Columbia University, 
//   funded in part through the NIH/NCI Cancer Center Support Grant P30CA013696."

// Input: a folder containing multi-channel images
// Output: individual channel images (same dimensionality as input). 
// Output file name will be the image name prefixed with C1, C2, etc.

// ---- Setup

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

// call the processFolder function, including the parameters collected at the beginning of the script
// returns the number of files processed 
n = processFolder(inputDir, outputDir, fileSuffix);

// clean up
while (nImages>0) { // close all open images
	selectImage(nImages);
	close();
}
setBatchMode(false);

// report processing time
time = getTime();
elapsedTime = (time - startTime)/1000;
print("Processed",n,"images in", elapsedTime , "sec");

// save Log
selectWindow("Log");
saveAs("text", outputDir + File.separator + "Split_Channels_Log.txt");

// ---- Functions ----

function processFolder(input, output, suffix) {
	// this function searches for files matching the criteria and sends them to the processFile function

	filenum = 0;
	print("Processing folder", input);
	list = getFileList(input);
	for (i=0; i<list.length; i++) {
	    if(File.isDirectory(input + File.separator + list[i])) {
			processFolder("" + input +File.separator+ list[i], output, suffix); 
		}
	    else if (endsWith(list[i], suffix)) {
			filenum = filenum + 1;
	       	processFile(input, output, list[i], filenum, suffix); 
	    } 
	}
	return filenum;
} // end of processFolder function

function processFile(inputFolder, outputFolder, fileName, fileNumber, fileSuffix, chan, reslice) {
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
	run("Bio-Formats", "open=&path use_virtual_stack"); // supports larger files
	
	// split channels and save
	run("Split Channels");
	while (nImages > 0) { // works on any number of channels
		selectImage(nImages);
		saveAs ("tiff", outputDir + File.separator + getTitle());
		close();
	}
	
	run("Collect Garbage"); // helps to clear memory

} // end of processFile function

 


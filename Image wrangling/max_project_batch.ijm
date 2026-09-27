//@File(label = "Input directory", style = "directory") inputDir
//@File(label = "Output directory", style = "directory") outputDir
//@String (label = "File suffix", value = ".nd2") fileSuffix

// max_project_batch.ijm
// ImageJ/Fiji script to max project a batch of images
// Theresa Swayne, 2025
//  -------- Suggested text for acknowledgement by core facility users -----------
//   "These studies used the Confocal and Specialized Microscopy Shared Resource 
//   of the Herbert Irving Comprehensive Cancer Center at Columbia University, 
//   funded in part through the NIH/NCI Cancer Center Support Grant P30CA013696."

// Input: a folder of stacks
// Output: a maximum intensity projection of each stack

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

print("Processing ",fileSuffix,"images in folder", inputDir);

// call the processFolder function, including the parameters collected at the beginning of the script
// returns the number of files processed 
n = processFolder(inputDir, outputDir, fileSuffix);

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
saveAs("text", outputDir + File.separator + "Projection_Log.txt");

// ---- Functions ----

function processFolder(input, output, suffix) {
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
			processFile(input, output, list[i], filenum); // passes the filename and parameters to the processFile function
		}
	}
	return filenum;
} // end of processFolder function

function processFile(inputFolder, outputFolder, fileName, fileNumber) {
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
	
	// open the file as a virtual stack to save time and memory
	run("Bio-Formats", "open=&path virtual");

	// make the projection
	run("Z Project...", "projection=[Max Intensity]");
	
	// save the output
	outputName = basename + "-MaxIP.tif";
	selectWindow("MAX_"+fileName);
	saveAs("tiff", outputFolder + File.separator + outputName);
	
	// clean up
	while (nImages > 0) { // close all open images
		selectImage(nImages);
		close(); 
	}
	run("Collect Garbage"); // clear memory
} // end of processFile function


	
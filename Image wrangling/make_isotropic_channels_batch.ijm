// @File(label = "Input directory", style = "directory") inputDir
// @File(label = "Output directory", style = "directory") outputDir
// @String(label = "File suffix", value = ".tif") fileSuffix
// @int(label="Channel to process:")  chan
// @Double(label = "Reslice Z step size", value = 0.0645, stepSize=0.001) reslice

// make_isotropic_channels_batch.ijm
// ImageJ/Fiji script to prepare multichannel Z stacks for 3D analysis
// Theresa Swayne, 2026
////  -------- Suggested text for acknowledgement by core facility users -----------
//   "These studies used the Confocal and Specialized Microscopy Shared Resource 
//   of the Herbert Irving Comprehensive Cancer Center at Columbia University, 
//   funded in part through the NIH/NCI Cancer Center Support Grant P30CA013696."

// Input: folder of multichannel z stacks
// Output: single-channel stacks, optionally resampled in the Z axis to a desired spacing


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

print("Processing ",fileSuffix,"images in folder", inputDir);
print("Reslicing channel",chan,"to get a Z step size of",reslice);

// call the processFolder function, including the parameters collected at the beginning of the script
// returns the number of files processed 
n = processFolder(inputDir, outputDir, fileSuffix, chan, reslice); 

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
saveAs("text", outputDir + File.separator + "Reslice_C" + chan +  "_Log.txt");

// ---- Functions ----

function processFolder(inputDir, outputDir, fileSuffix, chan, reslice) {
	// this function searches for files matching the criteria and sends them to the processFile function

	filenum = 0;
	print("Processing folder", input);
	list = getFileList(inputDir);
	for (i=0; i<list.length; i++) 
		{
	    if(File.isDirectory(inputDir + File.separator + list[i])) {
			processFolder("" + inputDir +File.separator+ list[i]); 
			}
	    else if (endsWith(list[i], fileSuffix)) {
			filenum = filenum + 1;
	       	processFile(inputDir, outputDir, list[i], filenum, fileSuffix, chan, reslice); 
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
	run("Bio-Formats", "open=&path");

	getVoxelSize(voxwidth, voxheight, depth, unit);
	getDimensions(stackwidth, stackheight, channels, slices, frames);
	origBitDepth = bitDepth(); 
	
	// select the channel of interest
	if (chan > channels) { // error in selection
		showMessage("That channel does not exist in this file!");
		continue; 
	}
	else {
		dupName = basename + "-c"+chan;
		run("Duplicate...", "title="+dupName+" duplicate channels="+chan);
	
		// make voxels isotropic
		//run("Reslice Z", "new="+voxwidth);
		run("Reslice Z", "new="+reslice);
		
		processedName = dupName + "_resliced.tif";
		rename(processedName);
		
		selectWindow(processedName);
		//setVoxelSize(voxwidth, voxheight, voxwidth, unit);
	
		// save processed image
		saveAs("tiff", outputFolder + File.separator + processedName);
	}

	// clean up
	while (nImages > 0) { // close all open images
		selectImage(nImages);
		close(); 
	}
	run("Collect Garbage"); // helps to clear memory
} // end processFile function
	

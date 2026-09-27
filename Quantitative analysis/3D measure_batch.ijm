//@File(label = "Resliced image input directory", style = "directory") imageInputDir
//@File(label = "Segmented image input directory", style = "directory") segInputDir
//@File(label = "Output directory", style = "directory") outputDir
//@String (label = "File suffix", value = ".tif") fileSuffix
//@String (label = "Object Name", value = "LD") objectName

// ImageJ/Fiji script to measure a batch of images using a previously generated segmentation (label mask)
// Theresa Swayne, 2025-2026
//  -------- Suggested text for acknowledgement by core facility users -----------
//   "These studies used the Confocal and Specialized Microscopy Shared Resource 
//   of the Herbert Irving Comprehensive Cancer Center at Columbia University, 
//   funded in part through the NIH/NCI Cancer Center Support Grant P30CA013696."

// Input: 2 folders, of single-channel fluorescence images and label images showing segmented objects
// Output: Measurements of position, size, intensity (2 tables per image)
// File name constraint: The label image name must be the name of the fluorescence image plus "_seg"

//	Limitation -- cannot have >1 dots in the filename
// 	
// Requires 3D ImageJ Suite  
// see https://mcib3d.frama.io/3d-suite-imagej/plugins/3DManager/3D-Manager-macros/

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

run("Clear Results");

// collect log in a table with a time/date stamp; this allows us to "Fresh Start" if needed to preserve memory
startTime = getTime();
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
month = month+1;
timeString = "" + year + "-" + month + "-" + dayOfMonth + "-" + hour + "-" + minute; // have to start with empty string
logName = timeString + "_3DMeasure_Log.txt";
logFile = outputDir + File.separator + logName;
logStartString = "Batch 3D Measure started " + timeString +"\n";
if (File.exists(logFile)==false) { // start the file with headers
	File.append(logStartString, logFile);	
	print("Created log file");
    }

// dataset counter
n=0;

// ---- Run ----

print("Processing ",fileSuffix,"images in folder", imageInputDir, "and segmentations in",segInputDir);

// set up 3D measurements
// options: important to NOT show as IJ results table beause it conflicts with the other table
run("3D Manager Options", "volume integrated_density mean_grey_value feret centroid_(pix) centroid_(unit) distance_to_surface objects radial_distance distance_between_centers=0 distance_max_contact=0 drawing=Contour use_0");

// Call the processFolder function, including the parameters collected at the beginning of the script
n = processFolder(imageInputDir, segInputDir, outputDir, fileSuffix, objectName);

// clean up
while (nImages > 0) { // close all open images
	selectImage(nImages);
	close(); 
}
setBatchMode(false);
run("Clear Results");

time = getTime();
elapsedTime = (time - startTime)/1000;
logString = "Processed " + n + " images in " + elapsedTime + " sec";
File.append(logString, logFile);

// ---- Functions ----

function processFolder(imginput, seginput, output, suffix, objname) {
	// this function searches for files matching the criteria and sends them to the processFile function
	filenum = 0;
	print("Processing folder", imginput);
	// scan folder tree to find files with correct suffix
	list = getFileList(imginput);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(imginput + File.separator + list[i])) {
			processFolder(imginput + File.separator + list[i], seginput, output, suffix, objname); // handles nested folders
		}
		if(endsWith(list[i], suffix)) {
			filenum = filenum + 1;
			processFile(imginput, seginput, output, list[i], filenum, objname); // passes the filename and parameters to the processFile function
		}
	}
	return filenum;
} // end of processFolder function


function processFile(imgInputFolder, segInputFolder, outputFolder, imgFile, fileNumber, objName) {
	// this function processes a single image

	run("Fresh Start"); // clears log, results, etc. -- important for saving memory
	// initialize 3D functions
	run("3D Manager");
	Ext.Manager3D_Close(); // suggested by  https://forum.image.sc/t/how-to-speed-up-adding-or-removing-objects-in-3d-manager/110750/5 to move mgr to background
	//Ext.Manager3D_Reset();

	imgPath = imgInputFolder + File.separator + imgFile;

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
	
	logString = "Processing image " + fileNumber + " at path " + imgPath + " with basename " + basename;
	File.append(logString, logFile);	

	// open the image file
	run("Bio-Formats", "open=&imgPath");
	
	// rename for easier handling
	rename("dup");
	
	// check for the segmented image
	segFile = basename + "_seg.tif";
	
	// open the segmented image
	segPath = segInputFolder + File.separator + segFile;
	if (!(File.exists(segPath))) {
		logString = "No segmented image found for " + basename;
		File.append(logString, logFile);
		close("*");
		while(nImages!=0) wait(500);
		run("Collect Garbage");
		return; // go to next file in folder
	}
	else {
		run("Bio-Formats", "open=&segPath");
		
		selectImage(segFile);
		rename("seg");
		
		wait(500); // a little space to let things catch up

		// check for objects (if there are none and we try to measure, it will crash)
		selectWindow("seg");
		Stack.getStatistics(area, mean, min, max, std, histogram);
		if (max == 0) {
			logString = "No objects in " + basename;
			File.append(logString, logFile);
			//print("No objects in", basename);
			run("Collect Garbage");
			//continue;
			return; // go to next file in folder
		}
		else {
			// add segmented objects to the mgr
			selectWindow("seg");
			Ext.Manager3D_AddImage();
			Ext.Manager3D_DeselectAll();
			Ext.Manager3D_Count(objCount); // number of objects
			
			logString = "Found " + objCount + " " + objName + " objects in image " + basename;
			File.append(logString, logFile);
			
			selectWindow("dup"); // activate the ROIs on the fluorescence image
			
			Ext.Manager3D_Quantif();
			// save results; Q is prepended automatically
			Ext.Manager3D_SaveResult("Q", outputDir + File.separator + basename + "_" + objName + "_quant_results.csv");
			Ext.Manager3D_CloseResult("Q");
			
			Ext.Manager3D_Measure(); 
			// save results; M is prepended automatically
			Ext.Manager3D_SaveResult("M", outputDir + File.separator + basename + "_" + objName + "_meas_results.csv");
			Ext.Manager3D_CloseResult("M");
			
			run("Clear Results");
			Ext.Manager3D_Reset();
		}
		// clean up before next cycle
		close("*");
		while(nImages!=0) wait(500); // waits for "close" to catch up
		run("Collect Garbage");
		wait(500); // a little space to let things catch up
	}	
} // end of processFile function


	
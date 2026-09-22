//@File(label = "Red channel input directory", style = "directory") inputRedImg
//@File(label = "Green channel input directory", style = "directory") inputGreenImg
//@File(label = "Segmented red channel input directory", style = "directory") inputRedSeg
//@File(label = "Segmented green channel input directory", style = "directory") inputGreenSeg
//@File(label = "Output directory", style = "directory") outputDir
//@String (label = "File suffix", value = ".tif") fileSuffix

// cellbook.ijm
// ImageJ/Fiji script to make gallery of fluor and segmented images for inspection

// Theresa Swayne, 2026
//  -------- Suggested text for acknowledgement -----------
//   "These studies used the Confocal and Specialized Microscopy Shared Resource 
//   of the Herbert Irving Comprehensive Cancer Center at Columbia University, 
//   funded in part through the NIH/NCI Cancer Center Support Grant P30CA013696."

// NOTES:  If any files in the red image folder do not have matches, they will be skipped
//  All files must be in the same directory level -- there is no recursive search

// ---- Setup ----

roiManager("reset");

while (nImages>0) { // clean up open images
	selectImage(nImages);
	close();
}
print("\\Clear"); // clear Log window

startTime = getTime(); // keep track of time

run("Bio-Formats Macro Extensions"); // support native microscope files

setBatchMode(true); // faster performance

// ---- Run ----

print("Starting");

// Call the processFolder function, including the parameters collected at the beginning of the script

n = processFolder(inputRedImg, inputGreenImg, inputRedSeg, inputGreenSeg, outputDir, fileSuffix);

// Now make a mega montage of all of the montages

// count the images in the output folder (NOTE this assumes the folder has nothing else in it!)

montlist = getFileList(outputDir);
montlist = Array.sort(montlist);
montCount = montlist.length;

// divide into batches
batchSize = 8;
sheetCount = Math.ceil(montCount/batchSize);

print("There are",montCount, "montages, which we will display in",sheetCount,"contact sheets");

for (i = 0; i < sheetCount; i++) { // loop through contact sheets
	
	print("Processing sheet",i);
	//showMessageWithCancel("Escape from infinite loop","Processing sheet "+i); // for debugging
	// open a batch of images
	for (j= 0; j < batchSize; j++) { // loop through images in the sheet
		
		imageNumber = (i * batchSize) + j;
		print("Processing image number",imageNumber);
		if (imageNumber >= montCount) {
			print("image number is too high");
			break; // exit this inner loop
		}
		imageName = montlist[imageNumber];
		print("opening image",imageNumber,"named",imageName);
		open(outputDir + File.separator + imageName);
	}
	//	if (imageNumber > montCount) {
	//		print("exiting outer loop");
	//		break; // exit this outer loop
	//	}
	// stack the images and make a montage
	sheetName = "cellbook" + i;
	
	// check for case where only 1 image is open
	titleList = getList("image.titles");
	numImages = titleList.length;
	if (numImages > 1) {
	
		run("Images to Stack", "name=&sheetName use");
		run("Make Montage...", "columns=1 rows=&batchSize scale=1 border=1"); // will take the 1st n images it finds in the stack
	}
	else {
		rename("Montage");
	}
	// save the montage
	selectWindow("Montage");
	saveAs("Tiff", outputDir + File.separator + sheetName + ".tif");
	
	while (nImages>0) { // clean up open images
		selectImage(nImages);
		close();
	}
	run("Collect Garbage");
}
	
// Clean up images and get out of batch mode

while (nImages > 0) { // clean up open images
	selectImage(nImages);
	close(); 
}
setBatchMode("exit and display");

time = getTime();
elapsedTime = (time - startTime)/1000;
print("Finished",n,"images in ", elapsedTime , " sec");

selectWindow("Log");
saveAs("text", outputDir + File.separator + "Cellbook_Log.txt");


// ---- Functions ----

// Helper function to max project, enhance contrast, and close original

function niceProjection(input) {
	
	print("Projecting",input);
	// make max projection
	selectWindow(input);
	run("Z Project...", "projection=[Max Intensity]");

	// close original
	selectWindow(input);
	close();
	
	// reset display contrast limits to min/max
	selectWindow("MAX_"+input);
	//	run("Enhance Contrast", "saturated=0.35");
	resetMinAndMax;
	
	// return the image ID
	outputID = getImageID();
	return(outputID)
}

// Function to process a folder 
function processFolder(inputRedImg, inputGreenImg, inputRedSeg, inputGreenSeg, outputDir, fileSuffix) {

	// this function searches for files in the first input folder that match the criteria and sends them to the processFile function

	filenum = 0;
	print("Processing red image input folder", inputRedImg);
	// scan folder tree to find files with correct suffix
	list = getFileList(inputRedImg);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(endsWith(list[i], fileSuffix)) { // we will process this image
			filenum = filenum + 1;
			processFile(inputRedImg, inputGreenImg, inputRedSeg, inputGreenSeg, outputDir, list[i], filenum); // passes the filename and parameters to the processFile function
		}
	}
	return filenum;
} // end of processFolder function


function processFile(inputRedImg, inputGreenImg, inputRedSeg, inputGreenSeg, outputDir, fileName, fileNumber) {
	
	// this function processes a single image
	
	// Set up parameters
	// What differentiates red and green file names?
	
	redChan = "c4";
	greenChan = "c5";
	
	redPath = inputRedImg + File.separator + fileName;
	print("Processing file",fileNumber," at path" ,redPath);	

	// determine the name of the file without extension
	dotIndex = lastIndexOf(fileName, ".");
	basename = substring(fileName, 0, dotIndex); 
	extension = substring(fileName, dotIndex);
	nameLength = lengthOf(basename);
	origName = substring(basename, 0, nameLength-12); // remove "-cX-resliced"
	print("Red image file basename is",basename,"and the original image name is",origName);
	
	// open the red image file
	run("Bio-Formats", "open=&redPath");
	rename("red");
	
	// open green fluor image
	// the name is going to be the original name with the other channel number and "resliced"

	greenfileName = origName + "-" + greenChan + "_resliced.tif";
	greenPath = inputGreenImg + File.separator + greenfileName;
	print("Opening green image at",greenPath);
	if (File.exists(greenPath)) {
		run("Bio-Formats", "open=&greenPath");
		rename("green");
	}
	else {
		print("No matching green image at",greenPath);
		return; // skip to next red file
	}

	// open the red segmented image
	// the name will be basename + "seg"

	redSegName = basename + "_seg.tif";
	redSegPath = inputRedSeg + File.separator+ redSegName;
	print("Opening red segmented image at",redSegPath);
	if (File.exists(redSegPath)) {
		run("Bio-Formats", "open=&redSegPath");
		rename("redseg");
	}
	else {
		print("No matching red segmented image at",redSegPath);
		return; // skip to next red file
	}

	// open the green segmented image
	greendotIndex = lastIndexOf(greenfileName, ".");
	greenbasename = substring(greenfileName, 0, greendotIndex); 

	greenSegName = greenbasename + "_seg.tif";
	greenSegPath = inputGreenSeg + File.separator+ greenSegName;
	print("Opening green segmented image at",greenSegPath);
	if (File.exists(greenSegPath)) {
		run("Bio-Formats", "open=&greenSegPath");
		rename("greenseg");
	}
	else {
		print("No matching green segmented image at",greenSegPath);
		return; // skip to next red file
	}

	// project and adjust contrast
	
	redProjID = niceProjection("red");
	selectImage(redProjID);
	rename("redproj");
	run("Red");
	
	greenProjID = niceProjection("green");
	selectImage(greenProjID);
	rename("greenproj");
	run("Green");
	
	redSegProjID = niceProjection("redseg");
	selectImage(redSegProjID);
	rename("redsegproj");
	run("Red");
	
	greenSegProjID = niceProjection("greenseg");
	selectImage(greenSegProjID);
	rename("greensegproj");
	run("Green");
	
	// make RG merge
	run("Merge Channels...", "c1=&redproj c2=&greenproj create keep");
	selectImage("Composite");
	rename("fluormerge");
	
	selectWindow("fluormerge");
	// make nice colors
	Stack.setDisplayMode("color");
	Stack.setChannel(1); //red
	run("Red");
	Stack.setChannel(2);
	run("Green");
	Stack.setDisplayMode("composite");
	Property.set("CompositeProjection", "Sum");
	
	// make seg merge
	run("Merge Channels...", "c1=redsegproj c2=greensegproj create keep");
	selectImage("Composite");
	rename("segmerge");
	// enhance the contrast so that we can see all of the objects
	selectWindow("segmerge");
	Stack.setDisplayMode("color");
	Stack.setChannel(1); //red
	setMinAndMax(0,1);
	run("Red");
	Stack.setChannel(2); //green
	setMinAndMax(0,1);
	run("Green");
	Stack.setDisplayMode("Composite");
	Property.set("CompositeProjection", "Sum");
	
	// overlay the red seg as ROIs on the single color proj
	
	// convert to ROIs in the manager
	selectWindow("redsegproj");
	// alt run("Label Map to ROIs", "connectivity=C4 vertex_location=Corners name_pattern=r%03d");
	run("Label image to ROIs", "rm=[RoiManager[size=11, visible=true]]");
	
	selectWindow("redproj");
	run("Red");
	run("RGB Color");
	roiManager("Show All");
	// convert to an RGB overlay
	run("Flatten");
	
	selectWindow("redsegproj");
	close();
	selectWindow("redproj");
	close();
	
	//selectWindow("redproj-1");
	//rename("redproj");
	
	// overlay the green seg as ROIs on the single color proj
	
	// convert to ROIs in the manager
	selectWindow("greensegproj");
	roiManager("reset");
	// alt run("Label Map to ROIs", "connectivity=C4 vertex_location=Corners name_pattern=r%03d");
	run("Label image to ROIs", "rm=[RoiManager[size=11, visible=true]]");
	
	selectWindow("greenproj");
	run("Green");
	run("RGB Color");
	roiManager("Show All");
	// convert to an RGB overlay
	run("Flatten");
	
	selectWindow("greensegproj");
	close();
	selectWindow("greenproj");
	close();
	
	// set up the montage
	selectWindow("fluormerge");
	Stack.setDisplayMode("Composite");
	run("Stack to RGB");
	selectWindow("fluormerge");
	close();

	selectWindow("segmerge");
	Stack.setDisplayMode("Composite");
	run("Stack to RGB");
	selectWindow("segmerge");
	close();
	
	// check for what images are open
//    titleList = getList("image.titles"); 
//    print("before making stack, these are the open images:");
//    count = lengthOf(titleList); 
//    for (s = 0; s < count; s++) {
//		imageTitle = titleList[s];
//		print(imageTitle);
//    	}
	run("Images to Stack", "use");
	run("Make Montage...", "columns=4 rows=1 scale=1 border=1"); // will take the 1st n images it finds in the stack
	selectWindow("Montage");
	getDimensions(width, height, channels, slices, frames);
	
	// place the title above the images
	newHeight = height + 30;
	selectWindow("Montage");
	run("Canvas Size...", "width=width height=newHeight position=Bottom-Center");
	setFont("SansSerif", 14, " antialiased");
	setColor("black");
	setJustification("center");
	drawString(origName, width/2,20);

	montageName = origName + "_montage";
	saveAs("Tiff", outputDir  + File.separator + montageName);

	// save the output
	//outputName = basename + "_processed.tif";
	//saveAs("tiff", outputFolder + File.separator + outputName);
	//close();
	
	// clean up
	while (nImages > 0) { // clean up open images
		selectImage(nImages);
		close(); 
	}
	roiManager("reset");
	
} // end of processFile function


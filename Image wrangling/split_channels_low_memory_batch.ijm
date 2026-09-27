// @File(label = "Input directory", style = "directory") dir1
// @File(label = "Output directory", style = "directory") dir2
// @String(label = "File suffix", value = ".tif") suffix

// Note: DO NOT DELETE OR MOVE THE FIRST 3 LINES -- they supply essential parameters

// split_Channels_Batch_low_memory.ijm
// Theresa Swayne, 2017-2025
// TO USE: Create a folder for the output files. 
// 	Run the script in Fiji. 
//  Limitation -- cannot have >1 dots in the filename

// User is prompted for a folder containing multi-channel composite images
// Output: individual channel images saved in a folder specifed by the user.
// This macro processes all the images in a folder and any subfolders.



// ---- Setup ----

while (nImages>0) { // clean up open images
	selectImage(nImages);
	close();
}
print("\\Clear"); // clear Log window

setBatchMode(true); // faster performance
run("Bio-Formats Macro Extensions"); // support native microscope files

// ---- Run ----
n = 0;
time = getTime();
print("Starting");
processFolder(dir1, dir2, suffix);
print("Finished in", (getTime() - time)/60, " sec");


// ---- Functions ----

function processFolder(dir1, dir2, suffix) {
 list = getFileList(dir1);
 for (i=0; i<list.length; i++) {
      if (endsWith(list[i], "/"))
          processFolder(dir1++File.separator+list[i]);
      else if (endsWith(list[i], suffix))
         processImage(dir1, dir2, list[i]);
  }
}

function processImage(dir1, dir2, name) {

	path = dir1 + File.separator + name;
	
	run("Bio-Formats", "open=&path use_virtual_stack"); // virtual stack is twice as fast
	
	print("Processing image", n++, "at path" ,path);
	
	id = getImageID();
	title = getTitle();
	dotIndex = indexOf(title, ".");
	basename = substring(title, 0, dotIndex);
	
	// here is the actual processing code
	run("Split Channels");
	while (nImages > 0) { // works on any number of channels
		saveAs ("tiff", dir2+File.separator+getTitle);				// save every image
		close();
	}
}
 


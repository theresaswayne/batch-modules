// shading.ijm
// Post-hoc shading correction for stacks (no reference required)

// Theresa Swayne, 2026
//  -------- Suggested text for acknowledgement by core facility users -----------
//   "These studies used the Confocal and Specialized Microscopy Shared Resource 
//   of the Herbert Irving Comprehensive Cancer Center at Columbia University, 
//   funded in part through the NIH/NCI Cancer Center Support Grant P30CA013696."

// An alternative method to process a batch of images, 
// if you have a simple 1:1 input:output pipeline, 
// is to use the ImageJ/Fiji Process > Batch > Macro... command.

// TO USE: Select one of the 3 options for shading correction. 
//	Copy and paste the appropriate section of text (Option 1, 2 or 3) into theProcess > Batch > Macro... window 
//  Select input and output folders and click Process images.

// Limitations: Shading is calculated from the data images, not from reference images.
// As a result:
//  -- persistent objects may be interpreted as background and cause artifacts
//  -- image intensity will be changed in ways that may compromise quantitative data analysis
// For more robust correction, use reference images.

// Option 1: BioVoxxel Pseudo Flat Field (will crash on large images)
title = getTitle();
run("Pseudo Flat Field Correction (2D/3D)", "flatfieldradius=50.0 force2dfilter=true activechannelonly=false showbackgroundimage=false stackslice=1");
selectImage(title);
close();
selectImage("PFFC_"+title);
rename(title);

// Option 2: BaSiC correction calculated from all images in the stack -- no correction of the baseline level over time
title = getTitle();
run("BaSiC ", "processing_stack=&title flat-field=None dark-field=None shading_estimation=[Estimate shading profiles] shading_model=[Estimate flat-field only (ignore dark-field)] setting_regularisationparametes=Automatic temporal_drift=Ignore correction_options=[Compute shading and correct images] lambda_flat=0.50 lambda_dark=0.50");
selectImage(title);
close();
selectImage("Corrected:"+title);
rename(title);
selectImage("Flat-field:"+title);
close();

// Option 3: BaSiC correction calculated from all images in the stack -- also corrects for change in baseline over time
title = getTitle();
run("BaSiC ", "processing_stack=&title flat-field=None dark-field=None shading_estimation=[Estimate shading profiles] shading_model=[Estimate flat-field only (ignore dark-field)] setting_regularisationparametes=Automatic temporal_drift=[Replace with temporal mean] correction_options=[Compute shading and correct images] lambda_flat=0.50 lambda_dark=0.50");
selectImage(title);
close();
selectImage("Corrected:"+title);
rename(title);
selectImage("Flat-field:"+title);
close();





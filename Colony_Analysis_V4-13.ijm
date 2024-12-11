/********** Informations ********************
 THIS SCRIPT BORROWS THE FRAMEWORK OF CALIBRATION STEP, COLOR THRESHOLDER, AND PARTICLES ANALYSIS FROM LENDENMANN'S IMAGE ANALYSIS PROCESSING.

V1.0 - Modif BY WENCONG ZHU, 14/09/2021. 		- SAVE THE ROI MANAGER. - SET UP THE PARAMETERS IN THE COLOR THRESHOLDER (E.G. HUE:[125,175] "STOP" TO REMOVE BLUE BACKGROUND) AND REMOVE THE BACKGROUND BY RECTANGLE CROP - Color Thresholder 2.1.0/1.53c BY WENCONG ZHU
V1.1 - Modif by Julien Alassimone 16/09/2021 	- Added the scale selection tool - Added bach mode - Plate selection cropping 
V1.2 - Modif by Julien Alassimone 19/09/2021 	- scaling on first image and auto positioning tool based on absolute coordinate
V1.3 - Modif by Julien Alassimone 19/09/2021 	- Add autocalibration tool
V1.4 - Modif by WENCONG ZHU, 19/09/2021.        - New strategies for coordinates positioning, Add white balance adjustment following with cropping of measurable area, adjust HUE:[90,175].
V1.5 - Modif by Julien Alassimone 19/09/2021	- Fixed the autocalibration tool (this version does not displa V1.4 modif)
V2.0 - Modif by Julien Alassimone 20/09/2021	- Changed the Autocalibration tool for the circle detection strategy
V2.2 - Modif by Julien Alassimone 20/09/2021	- Finished Autocalibration, Added folder creation, Added autoscaling, Added scaling QC, Added Autocropping, Adaptated Mesurement
V2.3 - Modif by Julien Alassimone 23/09/2021	- added choice to process only Hue or HSB thresholding, added interface
V2.3.1.3 - Modif by Julien Alassimone 23/09/2021 - unbugg V2.3 : Autoscale still not precise enough, HSB mode not working yet
V2.3 - Modif by Julien Alassimone 23/09/2021	- Replace auto-scaling by user interface on the first image 

V3.21 - Modif by Julien Alassimone 28/01/2022	- Make a main histogram result file - Make separates folders for the histogram results
V3.22 - Modif by Julien Alassimone 28/01/2022	- correct typos in the setting file - add a setting menu - prepare for other detection methods (but not implemented yet) - add the threshold selection option for the Mesurement techniques
												line 576: maxSize= maxArea+20;//calculate max area to detect only the biggest circle - 31/01/2022 unbugging
												line 574 :minSize= maxArea-20; //calculate min area to detect only the biggest circle - 31/01/2022 unbugging
V3.23 - Modif by Julien Alassimone 31/01/2022 	UNbugged auto dection of the circle (checked several thresholding possibility and adjusted the min area size)
V3-24/25 - Modif by Julien Alassimone 31/01/2022 	add if no cirscle are auto detected start the "no guide" option. under process
V3- Works with Overlays instad of measures 
V4-10 - Modif by Julien Alassimone 09/05/2022 	Whitebalancing added
V4-12 - Modif by Julien Alassimone 09/05/2022 	Added Multi detection tool - fixed the thresholding auto detection part. - Added a blur to the auto dtetction via thresholding

To do list : 

- Fix histogram when doing the No guide method
correct the no guide method in the "failur to autodetect the ring"
- add execturion time in no guide mode
- add mesurement techniques (beside HSB, YSB etc)
- make the "integrative detection tool"
- add the pluggind dependancy download
 Maybe there will be a problem if the pic are read in different order than teh scale list) Need unbuug

Filter via lab - b 128

 //require the Package from EPFL (BIOP)

	
	
	!!!!! to keep trck of loop and increment
	//LAST: increment:at - loop:35 !!! Do not use n,l,x,y
 
*********************************************/
macro "Colony Analysis" {
Version="V4.12"; // Edit the version here when making modifs
/****************************************************
 * 1. Prerequisit
 ****************************************************/
setBatchMode(true); //start work in Bash mode
requires("1.48q");

script = // Move ImageJ window to top left of screen
    "IJ.getInstance().setLocation(10, 0);" 
		eval("script", script); 
		print("\\Clear"); // Clears log window
script = // Moves log window beneath ImageJ window.
    "lw = WindowManager.getFrame('Log');\n"+
    "if (lw!=null) {\n"+ 
    "lw.setLocation(10,100);\n"+ 
    "lw.setSize(600,300);\n"+ 
    "}\n"; 
	eval("script", script);
script = // Moves Results window beneath log window.
    "lw = WindowManager.getFrame('Results');\n"+
    "if (lw!=null) {\n"+ 
    "lw.setLocation(10,400);\n"+ 
    "lw.setSize(500,300);\n"+ 
    "}\n"; 
	eval("script", script);
script = // Moves ROI Manager window 
    "lw = WindowManager.getFrame('ROI Manager');\n"+ 
    "if (lw!=null) {\n"+ 
    "lw.setLocation(10,700);\n"+ 
    "lw.setSize(500,300);\n"+ 
    "}\n"; 
	eval("script", script);

run("Collect Garbage"); // soft reset of ImageJ memory
close("*"); // make sure that no images are open beforehands
close("Results"); // make sure that no results tables are open from previous analysis
print("Macro: \"Colony Analysis\" version ",Version," is running"); //inform user of the version used
//print("the macro will only run with the guide V5 or V5.1 or V5.2 (For V5.2 chosse V5.1)"); //inform user of the version used
print("Used memory:", call("ij.IJ.freeMemory")); //inform user of used memory

OpenWin=getList("window.titles");
for (zz = 0; zz < OpenWin.length; zz++) { //last loop- close all non image windows except the log
	if (OpenWin[zz]!="Log"){ //if the open window is the log
		selectWindow(OpenWin[zz]);
		run("Close");
	}//close if the open window is the log
}//close last 

/*** Functions ****/
function ActivateOverlaySelectionByName(string){
	overlayNb=-1;
	for (i = 0; i < Overlay.size; i++) {
		Overlay.activateSelection(i);
		NameTest=selectionName;
		if (string==NameTest) {
			overlayNb=i;
		}
	}
	if (overlayNb!=-1) {
		Overlay.activateSelection(overlayNb);
		return true;
	}
	else {
		run("Select None");
		return false;
	}
}

function QRcodeDecode(picname,SelectionName){
	selectWindow(picname);
	Overlay.paste;	
	run("Select None");
	run("Duplicate...", "title=QRDetection");
	Overlay.hide;
		
//	size_QR=10; //in mm for fit a rectangle option
	size_QR=9; //in mm pastille
	toUnscaled(size_QR);	
	tempDir=getDirectory("temp");
	tempPath=tempDir+"temp.txt";
	newname="QRfailed";
	
	if (ActivateOverlaySelectionByName(SelectionName)==true){
		run("Make Inverse");
		setBackgroundColor(250,250, 250);
//		setBackgroundColor(0,0,0);//make everything but the large circle black
		run("Clear", "slice");
		run("Select None");
		Evaluation=0;
		Evaluation2=0;
		setOption("BlackBackground", false);
//		setOption("BlackBackground", true);
		run("Convert to Mask");
		QR_DilatErod_Attemps=0;
		SigmaSave=0;
		do {
			QR_DilatErod_Attemps++;
			sigma=0;
			for (aaa= 0; aaa < QR_DilatErod_Attemps; aaa++) {
			run("Dilate");
			}
			for (aaaa = 0; aaaa < (QR_DilatErod_Attemps-1); aaaa++) {
			run("Erode");
			}
			run("QR Decoder JA", "absolute="+tempPath+"");
			run("Table... ", "open="+tempPath+"");
			selectWindow("temp.txt");
			TableReadOut=Table.size;
			if ((Table.size!=0)||(QR_DilatErod_Attemps==6)){
			Evaluation=1;
			}
			else {
				do {
					close("temp.txt");
					selectWindow("QRDetection");
					run("Duplicate...", "title=test");
					sigma++;
					run("Gaussian Blur...", "sigma="+sigma+"");
					run("QR Decoder JA", "absolute="+tempPath+"");
					run("Table... ", "open="+tempPath+"");
					selectWindow("temp.txt");
					TableReadOut=Table.size;
					if ((Table.size!=0)||(sigma==10)) {
						Evaluation2++;
						if (Table.size!=0)	{Evaluation++;}
					}
					close("test");
				}while (Evaluation2==0);	
			}
			run("Erode");	
		}while (Evaluation==0);
		if (TableReadOut!=0){
			selectWindow("temp.txt");
			newname=Table.getString("X", 0);
			Xpos1=parseInt(Table.getString("X", 1));
			Ypos1=parseInt(Table.getString("Y", 1));
			Xpos2=parseInt(Table.getString("X", 2));
			Ypos2=parseInt(Table.getString("Y", 2));
			Xpos3=parseInt(Table.getString("X", 3));
			Ypos3=parseInt(Table.getString("Y", 3));
			QrXCenter=(Xpos1+Xpos3)/2;
			QrYCenter=(Ypos1+Ypos3)/2;
			selectWindow(picname);

		//fit a rectangle to the QR code
		/*
			Xpos4 =Xpos1+ Xpos3- Xpos2	;
			Ypos4 =Ypos1+ Ypos3- Ypos2	;
			Xpos5=(Xpos1+Xpos2)/2;
			Ypos5=(Ypos1+Ypos2)/2;
			Xpos6=(Xpos4+Xpos3)/2;
			Ypos6=(Ypos4+Ypos3)/2;
			Xpos7=(Xpos1+Xpos5)/2;
			Ypos7=(Ypos1+Ypos5)/2;
			Xpos8=(Xpos4+Xpos6)/2;
			Ypos8=(Ypos4+Ypos6)/2;
			Xpos9=(Xpos7+Xpos5)/2;
			Ypos9=(Ypos7+Ypos5)/2;	
			Xpos10=(Xpos8+Xpos6)/2;		
			Ypos10=(Ypos8+Ypos6)/2;
			makeRotatedRectangle(Xpos9, Ypos9, Xpos10, Ypos10, size_QR);
//			enlargeSize=(size_QR/5)*(lengthBigtoSmall/CalibScale);		
//			enlargeSize=(2)*(lengthBigtoSmall/CalibScale);	
			enlargeSize=(2);			
			run("Enlarge...", "enlarge="+enlargeSize+"");
		*/
		//draw ellipse over the pastille
				
		makeEllipse((QrXCenter-size_QR), QrYCenter,(QrXCenter+size_QR), QrYCenter, 1);
		run("Properties... ", "name=QR position=none group=2 width=0 fill=none");
		Overlay.addSelection;
		run("Select None");//22/04
		}
		dummy_var=File.delete(tempPath); //need to clear the line in log when using this function
		selectWindow("temp.txt");					
		run("Close");
	}
	close("QRDetection");	
	return newname;
} //close function

function OverlayDrawCC(CCx,CCy,PicWidth,PicHeight,name,group) {
	if ((CCx<PicWidth)&&(CCy<PicHeight)) {
		makeOval(CCx, CCy, PosWidth, PosWidth); 
		setSelectionName(name);
		Roi.setGroup(group);
		Overlay.addSelection;
	}
}

//function to get AIC
function FitAIC(FitNb,x,y){
	Fit.doFit(FitNb, x, y);
	SumSquareError=newArray();
	for (i = 0; i < x.length; i++) {
		SumSquareError=Array.concat(SumSquareError,(Math.sqr(y[i]-Fit.f(x[i]))));
	}
	Array.getStatistics(SumSquareError, min, max, MeanSumSquareError, stdDev);
	aic=(y.length)*Math.log(MeanSumSquareError)+2*Fit.nParams;
	return aic;
}

//function to get the Fit macro
function FitGetMacro(FitNb){
    ParamArray=newArray("a","b","c","d","e","f","g","h","i","j","k","l");
	Fit.getEquation(FitNb, name, formula, macroCode); // Returns the name, formula and macro code of the specified equation.
    Fit_Param=newArray(Fit.nParams);
    for (ag=0; ag<Fit.nParams; ag++){
    	Fit_Param[ag]=Fit.p(ag);
  	}
  	macroCode=macroCode.replace("Math","MATH");
  	macroCode=macroCode.replace("exp","EXP");
  	macroCode=macroCode.replace("x","v");

  	for (ah = 0; ah < Fit_Param.length; ah++) {
  		macroCode=macroCode.replace(ParamArray[ah],"("+Fit_Param[ah]+")");
  	}
	macroCode=macroCode.replace("MATH","Math");
	macroCode=macroCode.replace("EXP","exp");
	macroCode=macroCode.replace("y = ","v=");
	return macroCode;
}


/****************************************************
 * 2. Interface, Settings, guide data
****************************************************/
/*** Define Help Html information ***
test = "<html>"
     +"<h2>HTML formatted help</h2>"
     +"<font size=+1>
     +"the test.<br>"
          +"</font>";
  Dialog.create("Help");
  Dialog.addHelp(test);
  Dialog.show;
  */
  
ThresholdTypeArray=newArray("Otsu","Triangle","Minimum","Default","Huang","IsoData","IJ_IsoData","Li","Intermodes","MaxEntropy","MinError","Moments","Mean","RenyiEntropy","Shanbhag","Yen","Percentile")

/*** 2.1 Main interface ***/
QRcode=false;
																		
Dialog.create("Macro info/settings"); 
Dialog.setInsets(0,60,0);
Dialog.addMessage("!!! This macro works with Jpg or Tiff files !!!");
Dialog.setInsets(0,50,0);
Dialog.addMessage("!!! To use this macro you need to use the specified detection guide.\nMake sure that the printed guide is at the right scale, using the millimeter paper print out !!");
Dialog.addMessage("");
Dialog.addMessage("");
Dialog.setInsets(0,100,0);
Dialog.addMessage("*********************  Macro settings  **************************** ");
Dialog.addChoice("Petri Dish Crop / Scaling:", newArray("Auto","User defined based on 1st image","no Guide pics"))
Dialog.addNumber("	- Expected min colony diameter (mm):",0.6);
Dialog.addNumber("	- Expected Circularity: min",0.20);
Dialog.addToSameRow();
Dialog.addNumber("-Max:",1);
//Dialog.addChoice("Color threshold :", newArray("HSB Method","Ylab Method","YCbCr Method")); //will be used when we add the "integrative mesurement technique
Dialog.addChoice("Color threshold :", newArray("HSB Method","Ylab Method","YCbCr Method","All")); //will be used when we add the "integrative mesurement technique

labels = newArray("Watersheding","White balance","Scale QC","Histogram Analysis","QR codes");
//labels = newArray("Watersheding (resolves touching Colonies)","auto White balancing","Scale QC","Histogram Analysis","QR codes","Rename");
defaults = newArray(true,false,true,true,true);
//defaults = newArray(true,false,true,true,true,true);
Dialog.addCheckboxGroup(1,5,labels,defaults);
Dialog.addMessage("\n\n");
Dialog.setInsets(0,100,0);
Dialog.addMessage("*********************  Guide settings (does not apply for the \"No Guide pics\" option)  **************************** ");
Dialog.addChoice("- Guide Version:", newArray("V5.2","V5.1","V5"));
Dialog.addNumber("- Auto Mode only: Radius of the big detection ring compare the the image size. At least 1/",4); //used in V2	
Dialog.addNumber("- Distance in between X and Y (mm):",5);
Dialog.addMessage("\n\n");
Dialog.setInsets(0,100,0);
Dialog.addMessage("*********************  Petri crop size  **************************** ");
Dialog.addMessage("\n");
Dialog.addNumber("- Diameter Petri dish crop area (mm):",79);	
Dialog.show(); //display the message

/*** 2.2 Get Settings Main Interface ***/
AnalysisMode=Dialog.getChoice(); // get if user wants to get the scale /petri crop from a user based selection on the first image, or in a full auto mode
MinColPerim=Dialog.getNumber(); // get Expected minimum colony diameter information from the interface
MinColSize=PI*((MinColPerim/2)*(MinColPerim/2)); //Calculate min area of colony based on interface value
CirMin=Dialog.getNumber(); // get Expected minimum Circularity information from the interface
CirMax=Dialog.getNumber(); // get Expected maximum Circularity information from the interface
ThresholdChoice=Dialog.getChoice(); // get the spore detection mode, based on HUE (values from mark), on the HUE value or on the Ylab method
labels = newArray("Watersheding (resolving touching Colonies)","auto White balancing","Scale QC","Histogram Analysis");
watershedChoice=Dialog.getCheckbox();
WhiteBalance=Dialog.getCheckbox();
ScaleQCchoice=Dialog.getCheckbox();
HistoChoice=Dialog.getCheckbox();
QRcode=Dialog.getCheckbox(); 
guide=Dialog.getChoice();//get value from the interface
MinCalibRing=Dialog.getNumber();//define the radius of detected  size to at least 1/5 of the height in pixels of the current image.//used in V2
CalibScaleUser=Dialog.getNumber(); //perimeter of the guide calibration ring (dark cirle) in mm - on V4 it is 135.6mm 
PetriSize=Dialog.getNumber(); //define the radius of the petri dish that need to be kept in mm
OriginalPetriRadius=PetriSize/2;
PetriArea=PI*(Math.sqr(OriginalPetriRadius));

/*** 2.3 Colonies Detection Settings interface ***/	
Rename=false;								  	
Dialog.create("Colonies Detection settings"); 

if(QRcode==true){
	items = newArray("Yes","No");
	Dialog.addRadioButtonGroup("Renaming:", items, 1, 2, "Yes");
}

if (AnalysisMode=="Auto"){
	if(QRcode==true){
		items = newArray("None","Guide Based", "QR based");
		Dialog.addRadioButtonGroup("Rotation on:", items, 1, 3, "QR based");
	}else {
		items = newArray("None","Guide Based");
		Dialog.addRadioButtonGroup("Rotation on:", items, 1, 2, "Guide Based");
	}
}else {
	items = newArray("None","Guide Based");
	Dialog.addRadioButtonGroup("Rotation on:", items, 1, 2,"None");
}

if(HistoChoice==true){
	items = newArray("Yes","No");
	Dialog.addRadioButtonGroup("Save Png plot of Histogram (for each colonies):", items, 1, 2, "Yes");
}

if ((ThresholdChoice=="HSB Method")||(ThresholdChoice=="All")) {
	Dialog.addMessage("********** HSB settings ************ ");
	Dialog.addNumber("- Hue Min value (M.Linderman=57, Suggested=75):",75);	
	Dialog.addNumber("- Hue Max value (M.Linderman=190, Suggested=190):",190);	
	Dialog.addNumber("- Saturation Min value (M.Linderman=0, Suggested=0):",0);
	Dialog.addNumber("- Saturation Max value (M.Linderman=255, Suggested=255):",255);	
	Dialog.addNumber("- Brightness Min value (M.Linderman=0, Suggested=0):",0);	
	Dialog.addNumber("- Brightness Max value (M.Linderman=255, Suggested=255):",255);
	Dialog.addMessage("");
}
if ((ThresholdChoice=="Ylab Method")||(ThresholdChoice=="All")) {
	Dialog.addMessage("********** Ylab settings ************ ");
	Dialog.addChoice("Ylab thresholding method (recommended Threshold: Otsu or Triangle):",ThresholdTypeArray ); //Array used to select Ylab thresholding methods
	Dialog.addMessage("");
}
if ((ThresholdChoice=="YCbCr Method")||(ThresholdChoice=="All")) {
	Dialog.addMessage("********** Ylab settings ************ ");
	Dialog.addChoice("Ylab thresholding method (recommended Threshold: Otsu or Triangle):", ThresholdTypeArray); //Array used to select YcbCr thresholding methods
	Dialog.addMessage("");
}	
	Dialog.show(); //display the message
if (QRcode==true) Rename=Dialog.getRadioButton;
	
RotationMode=Dialog.getRadioButton;
if(HistoChoice==true) SaveHistoPLotChoice=Dialog.getRadioButton;

/*** 2.4 get Colonies Detection Settings ***/
if ((ThresholdChoice=="HSB Method")||(ThresholdChoice=="All")) {
	minHue=Dialog.getNumber();//get value from the interface
	maxHue=Dialog.getNumber();//get value from the interface
	minSat=Dialog.getNumber();//get value from the interface
	maxSat=Dialog.getNumber();//get value from the interface
	minBright=Dialog.getNumber();//get value from the interface
	maxBright=Dialog.getNumber();//get value from the interface
}
if ((ThresholdChoice=="Ylab Method")||(ThresholdChoice=="All")) {
	ThresholdType_Ylab=Dialog.getChoice();
}
if ((ThresholdChoice=="YCbCr Method")||(ThresholdChoice=="All")) {
	ThresholdType_YCbCr=Dialog.getChoice();
}

/** 2.5 define Guide characteristics (complete the array for new guide versions, them the right values are picked up later from the array. caution WbCalArrayYArray require 6 values per guide). **/
	// guide data arrays
AlphaGuideArray=newArray(45,45,45); //angle of the guide in between mark line a center of small calibration circle
BigCircleAreaArray=newArray(37.9461474793,42.5197609917,42.5197609917); //Big circle area is 37.9461474793 bigger than small circle area)
KnownCenterXbigArray=newArray(103.7,103.8,103.8);
KnownCenterXsmallArray=newArray(51.9,53.3,53.3);
KnownCenterYbigArray=newArray(119.2,119.2,119.2);
KnownCenterYsmallArray=newArray(67.5,69,69);
CropDimentionArray=newArray(150,150,150); //define the size of the crop area (square area) (in mm)
ScaleQCxArray=newArray(52.3,50,-53.8); //define the scale control zoom area (x coordinate of the selection upper left corner) in mm (From center of Big Circle to position of millimeter paper => 173.7-103.7 mm
ScaleQCyArray=newArray(1,1,53.2); //define the scale control zoom area (y coordinate of the selection upper left corner) in mm (From center of Big Circle to position of millimeter paper=> 119.2-47.9 mm
WbAreaArray=newArray(6,6,6);
WbCalArrayYArray=newArray(55,38,10,-4,-26,-49,55,38,10,-4,-26,-49,55,38,10,-4,-26,-49);//in mm
WbCalXArray=newArray(72.4,62,62); //in mm (176-103.6)
XuserBasedArray=newArray(50,50,50);// distance in between the point X and the center of the petri dish (in mm)

	//define an increment for the guide version
if (guide=="V5") Vguide=0;
if (guide=="V5.1") Vguide=1;
if (guide=="V5.2") Vguide=2;

	//get guide data from the right guide version
AlphaGuide=AlphaGuideArray[Vguide]; //angle of the guide in between mark line a center of small calibration circle
BigCircleArea=BigCircleAreaArray[Vguide]; //Big circle area is 37.9461474793 bigger than small circle area)
KnownCenterXbig=KnownCenterXbigArray[Vguide];
KnownCenterXsmall=KnownCenterXsmallArray[Vguide];
KnownCenterYbig=KnownCenterYbigArray[Vguide];
KnownCenterYsmall=KnownCenterYsmallArray[Vguide];
CropDimention=CropDimentionArray[Vguide];//define the size of the crop area (square area) (in mm)
ScaleQCx=ScaleQCxArray[Vguide]; //If scale QC don in XY points // define the scale control zoom area (x coordinate of the selection upper left corner) in mm (From center of Big Circle to position of millimeter paper => 173.7-103.7 mm
ScaleQCy=ScaleQCyArray[Vguide];  //If scale QC don in XY points // define the scale control zoom area (y coordinate of the selection upper left corner) in mm (From center of Big Circle to position of millimeter paper=> 119.2-47.9 mm
CalibScale=abs(Math.sqrt((Math.sqr(KnownCenterXbig-KnownCenterXsmall))+(Math.sqr(KnownCenterYbig-KnownCenterYsmall)))); //calculate the known expected scale
WbArea=WbAreaArray[Vguide];
WbCalArrayY=Array.slice(WbCalArrayYArray,(Vguide*6),((Vguide*6)+6));
WbCalX=WbCalXArray[Vguide]; //in mm (165.8-103.8)	
XuserBased=XuserBasedArray[Vguide];;// distance in between the point X and the center of the petri dish (in mm)

/** 2.6 get time for task execution counter **/
TaskTime=getTime();//start the task time from here
StartTime=getTime();//remember the starting time of the macro

/** Process time (To activate/deactivate add/remove "//" in front of the 3 lines below) ***/
Time=getTime();
TaskTime=Time-TaskTime;
if (TaskTime>1000){
	TaskTimeSec=TaskTime/1000;
	print("\\Update:Get Variables - Done (execution time",TaskTimeSec,"sec)"); //print the task progression in the log
} else print("\\Update:Get Variables - Done (execution time",TaskTime,"msec)"); //print the task progression in the log


/****************************************************
 * 3- Open directory
 ****************************************************/
dir=getDirectory("Choose a Directory "); // Ask user to select working directory
list=getFileList(dir); // get names of all files in input directory

/** Process time (To activate/deactivate add/remove "//" in front of the 3 lines below) ***/
Time=getTime();
TaskTime=Time-TaskTime;
if (TaskTime>1000){
	TaskTimeSec=TaskTime/1000;
	print("\\Update:Open Directory - Done (execution time",TaskTimeSec,"sec)"); //print the task progression in the log
} else print("\\Update:Open Directory - Done (execution time",TaskTime,"msec)"); //print the task progression in the log


/****************************************************
 * 4- Defining Arrays
****************************************************/

/** 4.1 Define arrays for macro function **/
NonAnalysed=newArray();//create an array to store names of non analysed files 
nameshortArray=newArray();
AnalysedFile=newArray();//create an array to store names of the analysed files
PetriCroplist=newArray();//create an array to store names of cropped images
AutoCroplist=newArray(); //02/02/2022
NoGuideList=newArray(); //02/02/2022
lengthBigtoSmallArray=newArray();//p13 also Calib lenght
PicWidthArray=newArray();//in pixel
PicHeightArray=newArray();//in pixel
CenterXbigArray=newArray(); //save value in array (in Pixels)
CenterYbigArray=newArray();  //save value in array (in Pixels)
CalibPerimBigArray=newArray();  //save value in array (in Pixels)
CenterXsmallArray=newArray(); //save value in array (in Pixels) 
CenterYsmallArray=newArray();  //save value in array (in Pixels)
CalibPerimSmallArray=newArray(); //save value in array (in Pixels) 
CalibRadiusBigArray=newArray(); //save value in array (in Pixels)
LeftXbigArray=newArray(); //save value in array (in Pixels)
ScaleArray=newArray();
AlphaArray=newArray(); //save detected rotation angle (in radian)
AlphaDegArray=newArray(); //save detected rotation angle (in Degres)
AlphaDeltaArray=newArray(); //save rotation correction angle(in Pixels)
AlphaDeltaQRArray=newArray();
R_fit_name_Array=newArray();
G_fit_name_Array=newArray();
B_fit_name_Array=newArray();
R_fit_MacroCode_Array=newArray();
G_fit_MacroCode_Array=newArray();
B_fit_MacroCode_Array=newArray();
ThresholdType=newArray("MaxEntropy","Otsu","Default","Triangle","IJ_IsoData","Intermodes","Minimum"); //Array used to test different thresholding methods
NewCenterXArray=newArray(); //save value in array (in Pixels)
NewCenterYArray=newArray(); //save value in array (in Pixels)
nArray=newArray(); //save which pics does not have only 2 calbrations cirles detected
if ((ThresholdChoice=="HSB Method")||(ThresholdChoice=="All")) {
	min=newArray(minHue,minSat,minBright); //create Array for thershold min values
	max=newArray(maxHue,maxSat,maxBright); //create Array for thershold max values
}
NonAnalysedPic=newArray(); //remenber No pnalysed pic name for error display
NonAnalyzedDescription=newArray();
lowerThreshold=newArray(); //save value in array
upperThreshold=newArray(); //save value in array
CropPicHeightArray=newArray(); //save value in array
CropPicWidthArray=newArray(); //save value in array

/*** 4.2 Define the Results Arrays (used to create the final Detailed_Results table) ***/
ResultsPic=newArray(); //save results in array
RemovePic=newArray(); //save images without detected colonies.
ResultsID=newArray(); //save results in array
ResultsArea=newArray(); //save results in array
ResultsMean=newArray(); //save results in array
ResultsMin=newArray(); //save results in array
ResultsX=newArray(); //save results in array
ResultsY=newArray(); //save results in array		
ResultsMajor=newArray(); //save results in array
ResultsMinor=newArray(); //save results in array
ResultsAngle=newArray(); //save results in array	
ResultsCirc=newArray(); //save results in array
ResultsAR=newArray(); //save results in array
ResultsRound=newArray(); //save results in array
ResultsSolidity=newArray(); //save results in array		
ResultsStdDev=newArray(); //save results in array
ResultsMode=newArray(); //save results in array
ResultsMax=newArray(); //save results in array


/*** 4.3 Define the Summary Arrays (used to create the final Summary table) ***/
SummaryPic=newArray(); //save results in array
SummaryLabel=newArray(); //save results in array
SummaryArea=newArray(); //save results in array
SummaryMean=newArray(); //save results in array
SummaryMin=newArray(); //save results in array
SummaryStdDev=newArray(); //save results in array
SummaryMode=newArray(); //save results in array
SummaryMax=newArray(); //save results in array
SummaryX=newArray(); //save results in array
SummaryY=newArray(); //save results in array
SummaryMajor=newArray(); //save results in array
SummaryMinor=newArray(); //save results in array
SummaryAngle=newArray(); //save results in array
SummaryCirc=newArray(); //save results in array
SummaryAR=newArray(); //save results in array
SummaryRound=newArray(); //save results in array
SummarySolidity=newArray(); //save results in array

/*** 4.4 Define the Arrays for the result table that only list the picture with detection (used to create the final Detailed_Results_Detection_Only table) ***/
ResultsPicOnly=newArray();
ResultsIDOnly=newArray();
ResultsMeanOnly=newArray();
ResultsModeOnly=newArray(); 
ResultsMinOnly=newArray();
ResultsMaxOnly=newArray();
ResultsAreaOnly=newArray();
ResultsXOnly=newArray();
ResultsYOnly=newArray();
ResultsMajorOnly=newArray();
ResultsMinorOnly=newArray();
ResultsAngleOnly=newArray();
ResultsCircOnly=newArray();
ResultsAROnly=newArray();
ResultsRoundOnly=newArray();
ResultsSolidityOnly=newArray();
ResultsStdDevOnly=newArray();

OriginNameArray=newArray();//
NewNameArray=newArray();//
Xpos1Array=newArray();//
Ypos1Array=newArray(); //
Xpos2Array=newArray();//
Ypos2Array=newArray(); //
Xpos3Array=newArray();//
Ypos3Array=newArray(); //
QrXCenterArray=newArray();//
QrYCenterArray=newArray(); //
QR_DilatErod_Array=newArray(); //
SigmaArray=newArray(); //

/****************************************************
 * 5- Getting Process file path, identifying non processed files
****************************************************/
AnalysedFileNb=0; //increment to check if the dir folder does not have images
for (i=0; i<list.length; i++) { // Loop-1
	if(endsWith(list[i], ".JPG")|endsWith(list[i], ".jpg")|endsWith(list[i], ".jpeg")|endsWith(list[i], ".TIFF")|endsWith(list[i], ".tiff")|endsWith(list[i], ".TIF")|endsWith(list[i], ".tif")|endsWith(list[i], ".PNG")|endsWith(list[i], ".png")){ //detect if file is a Tiff, or Jep file
		AnalysedFile=Array.concat(AnalysedFile,list[i]); //collect files name in the "analysed" arrays
		AnalysedFileNb++;
	}//close if end with
	else{ 
		NonAnalysed = Array.concat(NonAnalysed, list[i]); //collect files name in the "non analysed" arrays
		NonAnalyzedDescription=Array.concat("Not a suporeted Image"); 
		print("File is ",list[i],"is not supported and will not be analysed "); //inform user that the file will not be analysed
	} //Close else
} //close Loop-1

if (AnalysedFileNb==0) exit("No images detected");// if AnalysedFile is empty exit the macro

/** Process time (To activate/deactivate add/remove "//" in front of the 3 lines below) ***/
Time=getTime();
TaskTime=Time-TaskTime;
if (TaskTime>1000){
	TaskTimeSec=TaskTime/1000;
	print("\\Update:Identifying the non processed - Done (execution time",TaskTimeSec,"sec)"); //print the task progression in the log
} else print("\\Update:Identifying the non processed - Done (execution time",TaskTime,"msec)"); //print the task progression in the log


/****************************************************
 * 6- Creating folders
****************************************************/

/*** 6.1 Get time ***/
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
year1=year-2000;
MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
DayNames = newArray("Sun", "Mon","Tue","Wed","Thu","Fri","Sat");
if (month<10) {month = "0"+month;} //if value is smaller than 10 add a 0 in front of it
if (dayOfMonth<10) {dayOfMonth = "0"+dayOfMonth;}//if value is smaller than 10 add a 0 in front of it
if (hour<10) {hour = "0"+hour;}//if value is smaller than 10 add a 0 in front of it
if (minute<10) {minute = "0"+minute;}//if value is smaller than 10 add a 0 in front of it
if (second<10) {second = "0"+second;}//if value is smaller than 10 add a 0 in front of it
TimeStamp = ""+year1+""+month+""+dayOfMonth+"_"+hour+"h"+minute+"_"; //create time stamp for the folder name

/*** 6.2 Define Folder names ***/
AnalysisDir=dir+TimeStamp+"Colony_Analysis"+ File.separator; //create a path for the analysis folder
//ScaleDir=AnalysisDir+"Scale_QC"+ File.separator; //create a path for a folder to save the Scale zoom images
CroppedDir=AnalysisDir+"Original_Pic_With_Features"+ File.separator; //create a path for a folder to save the cropped petri dish images
WBDir=AnalysisDir+"WhiteBalanced_Images"+ File.separator; //create a path for a folder to save the white balanced images
PetriDir=AnalysisDir+"Petri_Crop"+ File.separator; //create a path for a folder to save the cropped petri dish images
DetectDir=AnalysisDir+"Colony_detection"+ File.separator; //create a path for a folder to save the colony detection overlay
RoiDir=AnalysisDir+"ROI_files"+ File.separator; //create a path for a folder to save the selection of each pictures
RoiPetriDir=RoiDir+"ROI_Petri_Crop_Features"+ File.separator; //create a path for a folder to save the selection of each pictures
RoiDetectDir=RoiDir+"ROI_Petri_Crop_Colonie_Detection"+ File.separator; //create a path for a folder to save the selection of each pictures
RoiFeaturesDir=RoiDir+"ROI_Original_Pic_With_Features"+ File.separator; //create a path for a folder to save the selection of each pictures
ResultsDir=AnalysisDir+"Results"+ File.separator; //create a path for a folder to save the results of each pictures analysis individually
HistoDir=AnalysisDir+"Histogram_Analysis"+ File.separator;
HistoPlotDir=HistoDir+"Histogram_plots"+ File.separator;
HistoResultsDir=HistoDir+"Histogram_Results_Per_Plates"+ File.separator;
HistoOverlayDir=HistoDir+"Histogram_Overlays"+ File.separator;
	
/*** 6.3 Create Folders ***/
File.makeDirectory(AnalysisDir); //create the folder
//if (ScaleQCchoice==1){File.makeDirectory(ScaleDir);}//create the folder only if the Scale QC option is selected
//if (WhiteBalance==1){File.makeDirectory(WBDir);}//create the folder only if the White Balance option is selected
if (AnalysisMode=="Auto"){File.makeDirectory(CroppedDir)}; //create the folder only if the Auto-analysis option is selected
File.makeDirectory(RoiDir); //create the folder
//if (AnalysisOnPetriOnly=="Petri only") {
	File.makeDirectory(PetriDir); //create the folder
	File.makeDirectory(RoiPetriDir); //create the folder
//}
File.makeDirectory(RoiDetectDir); //create the folder
File.makeDirectory(RoiFeaturesDir); //create the folder
File.makeDirectory(DetectDir); //create the folder
File.makeDirectory(ResultsDir); //create the folder
if (HistoChoice==1){ //define the following foders only if the Histogram option is selected
	File.makeDirectory(HistoDir);//create the folder
	if(SaveHistoPLotChoice=="Yes") File.makeDirectory(HistoPlotDir);//create the folder
	File.makeDirectory(HistoResultsDir);//create the folder
	File.makeDirectory(HistoOverlayDir);//create the folder
} //close if histoChoice =1

/*** Process time (To activate/deactivate add/remove "//" in front of the 3 lines below) ***/
Time=getTime();
TaskTime=Time-TaskTime;
if (TaskTime>1000){
	TaskTimeSec=TaskTime/1000;
	print("\\Update:Open Directory/create Folders - Done (execution time",TaskTimeSec,"sec)"); //print the task progression in the log
} else print("\\Update:Open Directory/create Folders - Done (execution time",TaskTime,"msec)"); //print the task progression in the log


/****************************************************
 * 7- User based scaling
****************************************************/

if ((AnalysisMode=="User defined based on 1st image")||(AnalysisMode=="no Guide pics")){// if analysis mode is "User defined based on 1st image"

/*** 7.1 open first file, reset scale, prepare selection ***/
	open(dir+AnalysedFile[0]); //open first analysed picture
	run("Set Scale...", "distance=0 known=0 unit=unit"); //Remove pre saved scale
	run("Select None"); //make sure that no other select were made
	setTool("line"); //select line tool
	Xa=-1; //increment fo the While loop.
	setBatchMode("show"); //Displays the active hidden image, while batch mode remains in same state.

/*** 7.2 Ask user to draw over X and Y ***/
	while (Xa==-1){ //Do the following until a line is draw a 1cm line
   		if (AnalysisMode=="User defined based on 1st image") waitForUser("Please draw a line in between point X and Y of the scale calibration\nNot happy with the selection? just redo it...\nNext step will enlarge the area.\nYou can adjust selection in the next step\nclick \"OK\".");//display message to ask again to draw the line
		if (AnalysisMode=="no Guide pics") waitForUser("Please draw a line of "+CalibScaleUser+"mm long on the millimeter paper area\nNot happy with the selection? just redo it...\nNext step will enlarge the area.\nYou can adjust selection in the next step\nclick \"OK\".");//display message to ask again to draw the line
		getLine(Xa,Ya,Xb,Yb,Whatever); //get line coordonates
	} //close While loop
	run("To Selection"); //zoom to selection
	run("Out [-]"); //unzoom to see the area entirely

/*** 7.3 asking is selection is ok ***/
	ScaleOK ="No"; //preset the choice as "NO" to start the while loop.
	while (ScaleOK == "No"){ //While user is not happy with the scale
		if (AnalysisMode=="User defined based on 1st image") waitForUser("Please adjust the line in between point X and Y\nNot happy with the selection? just redo it...\nBe as precise as possible\nclick \"OK\".");//display message to ask again to draw the line
		if (AnalysisMode=="no Guide pics") waitForUser("Please adjust the line so it is "+CalibScaleUser+"mm long.\nNot happy with the selection? just redo it...\nBe as precise as possible\nclick \"OK\".");//display message to ask again to draw the line
		width=512; height=512;
		Dialog.create("AskForSelection");
  		Dialog.addMessage("Are you happy with your selection ?");
  		Dialog.addChoice("      Type:", newArray("Yes","No"));
  		Dialog.addMessage("Be as precise as possible");
  		Dialog.addMessage("NB : If you click on \"cancel\" the macro will be interupted.");
  		Dialog.show(); //display the message
  		ScaleOK = Dialog.getChoice();//get user scale validation
	} //close While loop
	
/*** 7.4 Get User selection infos, set scale ***/
	getLine(Xa,Ya,Xb,Yb,Whatever); //get line coordonates
	CalibLenght=Math.sqrt((Math.sqr(Xb-Xa))+(Math.sqr(Yb-Ya))); //Calcul the lenght of the line drawn by the user
	run("Set Scale...", "distance="+CalibLenght+" known="+CalibScaleUser+" unit=mm global"); //set scale

/** Process time (To activate/deactivate add/remove "//" in front of the 3 lines below) ***/
		Time=getTime();
		TaskTime=Time-TaskTime;
		if (TaskTime>1000){
		TaskTimeSec=TaskTime/1000;
		print("\\Update:Getting scale info - Done (execution time",TaskTimeSec,"sec)"); //print the task progression in the log
		} else print("\\Update:Getting scale info - Done (execution time",TaskTime,"msec)"); //print the task progression in the log
		
/****************************************************
 * 8- IF Analysis is "User defined based on 1st image" - Ask user to review the draw the petri dish selection (Important this in still in the section 7 if condition :if analysis mode is "User defined based on 1st image")
****************************************************/

	if (AnalysisMode=="User defined based on 1st image"){ //if AnalysisMode=="User defined based on 1st image"
		run("Original Scale"); //unzoom the image to it oroginal display size
		toScaled(Xa,Yb); //get values in mm to calculate the folloowing positioning marks
		X=Xa-XuserBased; //determine guide radious from guide
		PetriRadius=OriginalPetriRadius;
		x1=(X-PetriRadius); //calculate left position of the petri crop area in respect to the petri dish center
		x2=(X+PetriRadius);  //calculate right position of the petri crop area in respect to the petri dish center
		toUnscaled(x1,x2,Yb); //get the values i pixel to draw the ellipse
		makeEllipse(x1,Yb,x2, Yb, 1); //draw the petri crop selection
   		waitForUser("Please make sure that the petri selection is correct.\nNot happy with the selection? just redo it...\nThen click \"OK\".");//display message to ask again to draw the line
		setBatchMode("hide"); //Enters (or remains in) batch mode and hides the active image
		pathROI=PetriDir+"PetriSelection.roi"; //define the ROI pathway (for saving detection)
		saveAs("Selection", pathROI);
	} //close  if AnalysisMode=="User defined based on 1st image"
	
//** Process time (To activate/deactivate add/remove "//" in front of the 3 lines below) ***/
		Time=getTime();
		TaskTime=Time-TaskTime;
		if (TaskTime>1000){
		TaskTimeSec=TaskTime/1000;
		print("\\Update:Getting scale info / Crop area based on 1st pic - Done (execution time",TaskTimeSec,"sec)"); //print the task progression in the log
		} else print("\\Update:Getting scale info / Crop area based on 1st pic - Done (execution time",TaskTime,"msec)"); //print the task progression in the log
		close("*"); //close all images
}//close if analysis mode is "User defined based on 1st image"

/****************************************************
 * 9. auto detection feature loop 
****************************************************/

if (AnalysisMode=="Auto"){ // if analysis mode is "Auto"

/***  Open image, get titles ***/
	print("Auto feature detect(0%) - initialisation");
	n=0; //increment for non analysed files
	for (j=0; j<AnalysedFileNb; j++) { //Loop 2
		//showProgress(-j/AnalysedFileNb); Show a progession bar in the ImageJ menu
		path=dir+AnalysedFile[j]; //get path of first analysed image
		print("\\Update:Auto feature detect("+(j+1)*(100/AnalysedFileNb)+"%)-"+AnalysedFile[j]+"-Intitialisation");//print the task progression in the log
		open(path); //Open picture
		PresenceBigCircle=false;
		OneCircleONly=false;
		GuideDetPb=true; //
		AutoDetectBig=false;
		AutoDetectSmall=false;
		OverlayBigCircleNumber=0;
		OverlaySmallCircleNumber=0;
		PetriRadius=OriginalPetriRadius;

		DectNb=0; //increment for the upper threshold reduction (see below)
		nameshort = File.nameWithoutExtension; //get file name without extension
		picname=getTitle(); //get current image title
		run("Set Scale...", "distance=0 known=0 unit=unit"); //Remove pre saved scale

/***  Position calibration based of circle detection of the guide ***/
//		getDimensions(PicWidth,PicHeight,PicChannels,PicSlices,PicFrames);	//get the picture dimensions
		PicWidth=getWidth();
		PicHeight=getHeight();
		PicWidthArray=Array.concat(PicWidthArray,PicWidth);//in pixel
		PicHeightArray=Array.concat(PicHeightArray,PicHeight);//in pixel
		minRadius=(PicHeight/MinCalibRing)/2; //define the radius of detected based on interface value
		minSizePix=(PI*(Math.sqr(minRadius))); //calculate the minimal size of the large calbration ring
		run("Set Measurements...", "area centroid perimeter redirect=None decimal=3"); //define mesure conditions
    	run("Select None");//make sure that there are no selection on the picture
		run("Duplicate...", "title=Calibration");
		run("8-bit"); //convert to 8 bits
		setAutoThreshold("Otsu");//set the threshold to minimum
      	getThreshold(lower, upper); //get threshold values
      	setOption("BlackBackground", false); // non white blackground
		run("Convert to Mask"); //create a mask
		run("Analyze Particles...", "size=0-Infinity pixel circularity=0.80-1.00 show=Overlay exclude clear include");//detect all circles of the picture size, all the circle in the large detections circle will for be considered because of the "include" option
        if (nResults>2) {//if at least 2 circles is detected - unbugged 31/01/2022			
			//identify the biggest circle
			for ( k=0; k<nResults; k++ ) {// Loop3 -Get the bigger circle area
				DetectArea = getResult("Area", k);// Get area results from the results tables
				if (DetectArea > minSizePix) {
					maxArea = DetectArea; //if the area is bigger than maxArea, remember this number
					OverlayBigCircleNumber=k+1;
					AutoDetectBig=true;	
				}
			} //close loop 3
			if(AutoDetectBig==true){
			//identify small circle
			minSize2=(maxArea/(BigCircleArea+5));//min detection for the position ring (big circle Area =37.9461474793* small circle area)
			maxSize2= (maxArea/(BigCircleArea-5));//max detection for the position ring (big circle Area =37.9461474793* small circle area)
			for ( ar=0; ar<nResults; ar++ ) {// Loop33 -Get the small circle area
				DetectArea = getResult("Area", ar);// Get area results from the results tables
				if ((DetectArea > minSize2) &&(DetectArea < maxSize2)){//if the area is bigger within the Small circle mesures
//					maxArea = DetectArea; 
					OverlaySmallCircleNumber=ar+1;
					GuideDetPb=false; //test 13/04 
					AutoDetectSmall=true;
				}	
			}//close loop 33
			}// close if(AutoDetectBig==true
		print("\\Update:Auto feature detect("+(j+1)*(100/AnalysedFileNb)+"%)-Auto Calibration OK");//print the task progression in the log
        } // close if (nResults>0) 
      	
/*** If detection fail try the thresholding approach **/
    	if (GuideDetPb==true){ //upper threshold reduction: in case no circle were detected reduce the thresholding to a very small threshold (helps if a shadow touch the calbration ring)
    	print("\\Update:Auto feature detect("+(j+1)*(100/AnalysedFileNb)+"%)-Auto Calibration Failed_Try Threshold adjustment ");//print the task progression in the log
    		upper=255; //start with a high Thresholding value to test all thresholding values
    		while (DectNb==0) { //try the thresholding approach
    			close("Calibration"); //close calibratin 8Bit picture that was already thresholded
				selectWindow(picname); //select original picture
    			run("Select None");//make sure that there are no selection on the picture
				run("Duplicate...", "title=Calibration"); //creates a duplicate of the current image with the name "Calibration"
//				run("Median...", "radius=5");
				run("Gaussian Blur...", "sigma=5");
				run("Set Scale...", "distance=0 known=0 unit=unit"); //Remove pre saved scale //not needed with Tif removed 22/04
				run("8-bit"); //convert to 8 bits
    			upper=upper-(upper*(10/100)); //reduce the upper threshold by 10% each time
    			setThreshold(lower, upper); //set threshold with the specified values
    			setOption("BlackBackground", false); // non white blackground
				run("Convert to Mask"); //create a mask
   				run("Analyze Particles...", "size=0-Infinity pixel circularity=0.80-1.00 show=Overlay exclude clear include");//detect all circles of the picture size, all the circle in the large detections circle will for be considered because of the "include" option
				AutoDetectBig=false;
   				
   				if (nResults>2) { //if at least 2 circles is detected - unbugged 31/01/2022			
   						//identify the biggest circle
					for ( k=0; k<nResults; k++ ) {// Loop3 -Get the bigger circle area
						DetectArea = getResult("Area", k);// Get area results from the results tables
						if (DetectArea > minSizePix) {
							maxArea = DetectArea; //if the area is bigger than maxArea, remember this number
							OverlayBigCircleNumber=k+1;
							AutoDetectBig=true;
						}
					} //close loop 3
					if(AutoDetectBig==true){
						//identify small circle
						minSize2=(maxArea/(BigCircleArea+5));//min detection for the position ring (big circle Area =37.9461474793* small circle area)
						maxSize2= (maxArea/(BigCircleArea-5));//max detection for the position ring (big circle Area =37.9461474793* small circle area)
						for ( ar=0; ar<nResults; ar++ ) {// Loop33 -Get the small circle area
							DetectArea = getResult("Area", ar);// Get area results from the results tables
							if ((DetectArea > minSize2) &&(DetectArea < maxSize2)){//if the area is bigger within the Small circle mesures
//								maxArea = DetectArea; 
								OverlaySmallCircleNumber=ar+1;
								GuideDetPb=false; //test 13/04 
								AutoDetectSmall=true;
								DectNb++;
							}
						} //close loop 33	
   					}// close if(AutoDetectBig==true
   					if (GuideDetPb==false) DectNb++; //if at least 2 circles is detected or if no circles are detected after threshold adjustement => exit the While loop
  	  			}//close if at least 2 circles is detected 
  	  			if (upper<10) {
  	  				DectNb++;
  	  			}
  	  		}//close While loop		
    	}// close if (DectNb==0)
    	
/*** If detection fail again try the fit circle to large selection approach (not implemented yet) *
    	if (GuideDetPb==true){
	  		close("Calibration"); //close calibratin 8Bit picture that was already thresholded
			selectWindow(picname); //select original picture	
			run("Duplicate...", "title=Cropping");
			run("Select None"); //make sure that no other select were made
			run("HSB Stack");
			run("Stack to Images");
			close("Hue");
			close("Brightness");
			selectWindow("Saturation");
			setAutoThreshold("Percentile"); //other threshold could be tested (triangle or Minimum might work) 01/02/2022
			run("Convert to Mask");
			run("Dilate");
			run("Analyze Particles...", "size="+minSizePix+"-Infinity show=Overlay display clear include");
		
			*** Sort results table (under process issue with ); ***
			inc=nResults;
			Indexes=newArray();
			for (an = 0; an < (inc); an++) Indexes=Array.concat(Indexes,an); //create an index list
			Table.setColumn("Indexes", Indexes); //add the indexes to the results table
			Table.sort("Area"); //sort the table by Area (smallest to biggest)
	  		for (ao=inc; ao>0; ao--) { //test all result table starting with the biggest Area (last in the table after sorting)
    			roiManager("reset"); //make sure that the roi manager is empty
    			indexMaxArea=Table.get("Indexes",(inc-1)); //get the index number of the tested table line 
   				Overlay.activateSelection(indexMaxArea); //select the overlay that match the desired index number
    			//toUnscaled(PetriSize); //make sure that the petri size is in pixels
    			//run("Max Inscribed Circles", "minimum="+PetriSize+" use minimum_0=0.50 closeness=5");
				run("Max Inscribed Circles", "minimum=0 use minimum_0=0.50 closeness=5"); //require the Package from EPFL (BIOP)
				//Roi.getBounds(x, y, width, height);
				if(roiManager("count")>0){
					run("From ROI Manager");
					Overlay.add;
					last=Overlay.size;
					last--;
					Overlay.activateSelection(last);
    				run("Measure");
    				AutoSize=Table.get("Area",(nResults-1));
    				if (AutoSize>PetriArea){
    					i=0; //exit loop 
    					PetriCenterX=getResult("X", (nResults-1));
    					PetriCenterY=getResult("Y", (nResults-1));
    					PerimCheck=getResult("Y", (nResults-1));
						PerimExpect=2*PI*PetriRadius;
						if (PerimCheck>PerimExpect) ao=0;
    				}
				}
    			inc--;
  			}
			//print("x=",PetriCenterX,"-Y:",PetriCenterY);
			//  run("Labels...", "color=white font=14 show use bold");
			//roiManager("Deselect");
			//waitForUser;
			//Overlay.copy;
			//last=Overlay.size;
			//last--;
			//Overlay.activateSelection(last);
			selectWindow(picname);
//			print("scaled PetriRadius",PetriRadius,"-PetriCenterX:",PetriCenterX,"-PetriCenterY:",PetriCenterY);
			** scaling process **
			if (lengthBigtoSmallArray.length>0){ //if some scale were collected from previous pic before
				Array.getStatistics(lengthBigtoSmallArray, lengthBigtoSmallArrayMin, lengthBigtoSmallArrayMax, lengthBigtoSmallArrayMean, lengthBigtoSmallArrayStdDev);
				run("Set Scale...", "distance="+lengthBigtoSmallArrayMean+" known="+CalibScale+" unit=mm"); //set scale
				ScaleAuto=lengthBigtoSmallArrayMean/CalibScale; //calculate scaling info for report table
				ScaleArray=Array.concat(ScaleArray,ScaleAuto); //saving scaling info for report table
			}
			else { //if no scale in formation were previously collected ask for the user to select a scale element
				run("Select None"); //make sure that no other select were made
				setTool("line"); //select line tool
				Xa=-1; //increment fo the While loop.
				setBatchMode("show"); //Displays the active hidden image, while batch mode remains in same state.
			
				*** Ask user to draw over X and Y ***
				while (Xa==-1){ //Do the following until a line is draw a 1cm line
					waitForUser("Please draw a line of "+CalibScaleUser+"mm long on the millimeter paper area\nNot happy with the selection? just redo it...\nNext step will enlarge the area.\nYou can adjust selection in the next step\nclick \"OK\".");//display message to ask again to draw the line
					getLine(Xa,Ya,Xb,Yb,Whatever); //get line coordonates
				} //close While loop
				run("To Selection"); //zoom to selection
				run("Out [-]"); //unzoom to see the area entirely
			
				*** asking is selection is ok ***
				ScaleOK ="No"; //preset the choice as "NO" to start the while loop.
				while (ScaleOK == "No"){ //While user is not happy with the scale
					waitForUser("Please adjust the line so it is "+CalibScaleUser+"mm long.\nNot happy with the selection? just redo it...\nBe as precise as possible\nclick \"OK\".");//display message to ask again to draw the line
					width=512; height=512;
					Dialog.create("AskForSelection");
  					Dialog.addMessage("Are you happy with your selection ?");
  					Dialog.addChoice("      Type:", newArray("Yes","No"));
  					Dialog.addMessage("Be as precise as possible");
  					Dialog.addMessage("NB : If you click on \"cancel\" the macro will be interupted.");
  					Dialog.show(); //display the message
  					ScaleOK = Dialog.getChoice();//get user scale validation
				} //close While loop
	
				*** Get User selection infos, set scale ***
				getLine(Xa,Ya,Xb,Yb,Whatever); //get line coordonates
				CalibLenght=Math.sqrt((Math.sqr(Xb-Xa))+(Math.sqr(Yb-Ya))); //Calcul the lenght of the line drawn by the user
				run("Set Scale...", "distance="+CalibLenght+" known="+CalibScaleUser+" unit=mm global"); //set scale
				ScaleAuto=CalibLenght/CalibScaleUser; //calculate scaling info for report table
				ScaleArray=Array.concat(ScaleArray,ScaleAuto); //saving scaling info for report table
			} // close Else	
		
			//print("scaled PetriRadius",PetriRadius,"-PetriCenterX:",PetriCenterX,"-PetriCenterY:",PetriCenterY);
			toUnscaled(PetriRadius); //transform the valu in pixel based on the current scale.
			//print("Unscaled PetriRadius",PetriRadius,"-PetriCenterX:",PetriCenterX,"-PetriCenterY:",PetriCenterY);
			makeEllipse((PetriCenterX-PetriRadius),PetriCenterY, (PetriCenterX+PetriRadius), PetriCenterY, 1);
			toScaled(PetriRadius); //reset the patri radus to mm value (not pixels)
			//Overlay.paste;
			run("Crop");
			run("Make Inverse"); //select everything but the ellipse
			setBackgroundColor(255,255,255); //set background color to white
			run("Clear", "slice"); //deleted background

			PetriCropPath=PetriDir + nameshort+"_AutoDetectFailed_PetriCrop.jpg"; //define cropped picture path
			PetriCroplist=Array.concat(PetriCroplist,PetriCropPath);//add crop picture path in the area (to open them later)
			saveAs("jpg",PetriCropPath);//save scale pic
			close("*");//close all open images
			roiManager("reset");
			run("Clear Results");
			
			*
			lowerThreshold=Array.concat(lowerThreshold,"NA");
			upperThreshold=Array.concat(upperThreshold,"NA");
	 		CalibRadiusBigArray=Array.concat(CalibRadiusBigArray,"NA"); //save value in array (in Pixels)
 			LeftXbigArray=Array.concat(LeftXbigArray,"NA"); //save value in array (in Pixels)
			AlphaArray=Array.concat(AlphaArray,"NA"); //save value in array (in radian)
 			AlphaDegArray=Array.concat(AlphaDegArray,"NA"); //save value in array (in Degres)
 			AlphaDeltaArray=Array.concat(AlphaDeltaArray,"NA");
			*

 			*** Fill "NA" in the picture auto treatment informations arrays ***
			CenterXbigArray=Array.concat(CenterXbigArray,"NA"); //save value in array (in Pixels)
			CenterYbigArray=Array.concat(CenterYbigArray,"NA");  //save value in array (in Pixels)
			CalibPerimBigArray=Array.concat(CalibPerimBigArray,"NA");  //save value in array (in Pixels)
			CenterXsmallArray=Array.concat(CenterXsmallArray,"NA"); //save value in array (in Pixels) 
			CenterYsmallArray=Array.concat(CenterYsmallArray,"NA");  //save value in array (in Pixels)
			CalibPerimSmallArray=Array.concat(CalibPerimSmallArray,"NA"); //save value in array (in Pixels)
			lengthBigtoSmallArray=Array.concat(lengthBigtoSmallArray,"NA");
 			CalibRadiusBigArray=Array.concat(CalibRadiusBigArray,"NA"); //save value in array (in Pixels)
 			LeftXbigArray=Array.concat(LeftXbigArray,"NA"); //save value in array (in Pixels)
			AlphaArray=Array.concat(AlphaArray,"NA"); //save value in array (in radian)
 			AlphaDegArray=Array.concat(AlphaDegArray,"NA"); //save value in array (in Degres)
 			AlphaDeltaArray=Array.concat(AlphaDeltaArray,"NA"); //save value in array (in Degres)

		} //close else (if (GuideDetPb==false) is still holding 31/01/2022
    	*/

/*** If detection passed proceed ***/
		if (GuideDetPb==false){ // if calibration ring could be detected,(GuideDetPb==false) is still holding 31/01/2022
			print("\\Update:Auto feature detect("+(j+1)*(100/AnalysedFileNb)+"%)-Auto Calibration OK_Get Thresholding infos ");//print the task progression in the log
 			lowerThreshold=Array.concat(lowerThreshold,lower); //save the min threshold value in the array
   			upperThreshold=Array.concat(upperThreshold,upper);//save the max threshold value in the array
//   			AnalysedFile=Array.concat(AnalysedFile,picname);
			maxArea=0; //increment for maximum area
			
		
/*** keeping only the calibration circle from the overlay  ***/				
			if ((AutoDetectBig==true)||(AutoDetectSmall==true)){
				for ( as=nResults;as>0;as--) {//
					Overlay.activateSelection(as-1);
					if (as==OverlayBigCircleNumber) run("Properties... ", "name=LargeCircle position=none group=7 width=0 fill=none");
					if (as==OverlaySmallCircleNumber) run("Properties... ", "name=SmallCircle position=none group=7 width=0 fill=none");
					if ((as!=OverlayBigCircleNumber)&&(as!=OverlaySmallCircleNumber)) Overlay.removeSelection(as-1);
				} //close loop 34
			print("\\Update:Auto feature detect("+(j+1)*(100/AnalysedFileNb)+"%)-Auto Calibration OK_Get Calibration infos ");//print the task progression in the log	
			}
			nb=Overlay.size;//count how many cercle detected

			/*** Get info from detection (in pixels) ***/
			if (nb==2){ //if 2 circles are detected
				ActivateOverlaySelectionByName("largeCircle");
				CenterXbig=getValue("X"); //Get center x coordinate of the calibration ring from the result table (in mm)
				CenterYbig=getValue("Y"); //Get center y coordinate of the calibration ring from the result table (in mm)
				CalibPerimBig=getValue("Perim."); //Get perimeter of the calibration ring from the result table
				toUnscaled(CenterXbig, CenterYbig,CalibPerimBig); //get values in pixel independently of any scale previously saved
				ActivateOverlaySelectionByName("SmallCircle");
				CenterXsmall=getValue("X"); //Get center x coordinate of the calibration ring from the result table
				CenterYsmall=getValue("Y"); //Get center y coordinate of the calibration ring from the result table
				CalibPerimSmall=getValue("Perim."); //Get perimeter of the calibration ring from the result table
//				print(CenterXbig,CenterYbig,CalibPerimBig,CenterXsmall,CenterYsmall,CalibPerimSmall);
				toUnscaled(CenterXsmall, CenterYsmall,CalibPerimSmall); //get values in pixel independently of any scale previously saved
				lengthBigtoSmall=abs(Math.sqrt((Math.sqr(CenterXbig-CenterXsmall))+(Math.sqr(CenterYbig-CenterYsmall))));//p13 also Calib lenght
				
				/*** Auto scaling ***/
				print("\\Update:Auto feature detect("+(j+1)*(100/AnalysedFileNb)+"%)-Auto Calibration OK_Get Scaling infos");//print the task progression in the log
				run("Set Scale...", "distance="+lengthBigtoSmall+" known="+CalibScale+" unit=mm global"); //set scale
		
				/*** save values in array (in pixels) ***/
				CenterXbigArray=Array.concat(CenterXbigArray,CenterXbig); //save value in array (in Pixels)
				CenterYbigArray=Array.concat(CenterYbigArray,CenterYbig);  //save value in array (in Pixels)
//				CalibPerimBigArray=Array.concat(CalibPerimBigArray,CalibPerimBig);  //save value in array (in Pixels)
//				CenterXsmallArray=Array.concat(CenterXsmallArray,CenterXsmall); //save value in array (in Pixels) 
//				CenterYsmallArray=Array.concat(CenterYsmallArray,CenterYsmall);  //save value in array (in Pixels)
//				CalibPerimSmallArray=Array.concat(CalibPerimSmallArray,CalibPerimSmall); //save value in array (in Pixels)
				lengthBigtoSmallArray=Array.concat(lengthBigtoSmallArray,lengthBigtoSmall);
				ScaleAuto=(lengthBigtoSmall/CalibScale);
				ScaleArray=Array.concat(ScaleArray,ScaleAuto);
				
 				// define petri dish area
 				print("\\Update:Auto feature detect("+(j+1)*(100/AnalysedFileNb)+"%)-Auto Calibration OK_Petri position definition ");//print the task progression in the log
				toUnscaled(PetriRadius);
				x1=(CenterXbig-PetriRadius);
				x2=(CenterXbig+PetriRadius);
//				toUnscaled(x1,x2,CenterYbig);
				makeEllipse(x1,CenterYbig,x2,CenterYbig, 1);
				run("Properties... ", "name=Petri position=none group=5 width=0 fill=none");
				Overlay.addSelection;
				Overlay.copy;
				close("Calibration"); //close calibratin 8Bit picture
 				
/*** detection of the Qr Code ***/
 				if(QRcode==true){
 				print("\\Update:Auto feature detect("+(j+1)*(100/AnalysedFileNb)+"%)-Auto Calibration OK_Decoding QR ");//print the task progression in the log
 					newname=QRcodeDecode(picname,"largeCircle");	
					NewNameArray=Array.concat(NewNameArray,newname);
//					nameshort=newname;
				}else {
					Overlay.paste;
				}
				 //close if barcode analsys
				
/*** Get autorotation informations ***/  
				print("\\Update:Auto feature detect("+(j+1)*(100/AnalysedFileNb)+"%)-Auto Calibration OK_GetRotation infos ");//print the task progression in the log
				CalibRadiusBig=(CalibPerimBig/(2*PI)); //calculate the radious of the calibration ring (P12)
				LeftXbig=CenterXbig-CalibRadiusBig;
				Alpha=Math.atan2((CenterYsmall-CenterYbig), (CenterXsmall-CenterXbig))-Math.atan2((CenterYbig-CenterYbig), (LeftXbig-CenterXbig));
				AlphaDeg=(Alpha*180/PI);
				AlphaDelta=AlphaGuide-AlphaDeg; //calculation of rotation angle (for drift correction)
				AlphaDeltaArray=Array.concat(AlphaDeltaArray,AlphaDelta); //save value in array (in Degres)
				if(QRcode==true){
					if(ActivateOverlaySelectionByName("QR")==true){
						QrXCenter=getValue("X"); //Get center x coordinate of the calibration ring from the result table (in mm)
						QrYCenter=getValue("Y"); //Get center y coordinate of the calibration ring from the result table (in mm)
						AlphaQR=Math.atan2((QrYCenter-CenterYbig), (QrXCenter-CenterXbig))-Math.atan2((CenterYbig-CenterYbig), (LeftXbig-CenterXbig));
						AlphaDegQR=(Alpha*180/PI);
						AlphaDeltaQR=-AlphaGuide-AlphaDeg; //calculation of rotation angle (for QR code rotation)
						AlphaDeltaQR=-90-AlphaDeg; //calculation of rotation angle (for QR code rotation)
					}else AlphaDeltaQR=0;	
				AlphaDeltaQRArray=Array.concat(AlphaDeltaQRArray,AlphaDeltaQR); //save value in array (in Degres)	
				}

			
 				//Save values in array (in pixels)
// 				CalibRadiusBigArray=Array.concat(CalibRadiusBigArray,CalibRadiusBig); //save value in array (in Pixels)
// 				LeftXbigArray=Array.concat(LeftXbigArray,LeftXbig); //save value in array (in Pixels)
//				AlphaArray=Array.concat(AlphaArray,Alpha); //save value in array (in radian)
// 				AlphaDegArray=Array.concat(AlphaDegArray,AlphaDeg); //save value in array (in Degres)

 				
	
/*** Color Checker detection (could get rid of rotation) ***/
				print("\\Update:Auto feature detect("+(j+1)*(100/AnalysedFileNb)+"%)-Auto Calibration OK_Checker Card infos ");//print the task progression in the log		
				run("Select All");
				Overlay.addSelection;
				CropIndex=Overlay.size-1;
				run("Select None"); //make sure that no other select were made
				run("Rotate... ", "angle="+AlphaDelta+" enlarge"); //correct for rotation
				//selected areas of the colorchecker card
				ActivateOverlaySelectionByName("largeCircle");
				largX=getValue("X");//get the center of bigCircle
				largY=getValue("Y");//get the center of bigCircle
				toUnscaled(largX, largY);
				pos1=72;
				pos2=87;
				pos3=35;
				pos4=19.5;
				pos5=4.5;
				pos6=10.5;
				pos7=25.5;
				pos8=40;
				pos9=102;
				pos10=117;
				PosWidth=7;
				toUnscaled(pos1, pos2, pos3);
				toUnscaled(pos4, pos5,pos6);
				toUnscaled(pos7, pos8,PosWidth);
				toUnscaled(pos9, pos10);
				CC24x=CC23x=CC22x=CC21x=CC20x=CC19x=largX+pos1;
				CC18x=CC17x=CC16x=CC15x=CC14x=CC13x=largX+pos2;
				CC12x=CC11x=CC10x=CC09x=CC08x=CC07x=largX+pos9;
				CC06x=CC05x=CC04x=CC03x=CC02x=CC01x=largX+pos10;
				CC24y=CC18y=CC12y=CC06y=largY+pos3;
				CC23y=CC17y=CC11y=CC05y=largY+pos4;
				CC22y=CC16y=CC10y=CC04y=largY+pos5;
				CC21y=CC15y=CC09y=CC03y=largY-pos6;
				CC20y=CC14y=CC08y=CC02y=largY-pos7;
				CC19y=CC13y=CC07y=CC01y=largY-pos8;
					
				OverlayDrawCC(CC24x,CC24y,PicWidth,PicHeight,"CC24",3);
				OverlayDrawCC(CC23x,CC23y,PicWidth,PicHeight,"CC23",3);
				OverlayDrawCC(CC22x,CC22y,PicWidth,PicHeight,"CC22",3);
				OverlayDrawCC(CC21x,CC21y,PicWidth,PicHeight,"CC21",3);
				OverlayDrawCC(CC20x,CC20y,PicWidth,PicHeight,"CC20",3);
				OverlayDrawCC(CC19x,CC19y,PicWidth,PicHeight,"CC19",3);
				OverlayDrawCC(CC18x,CC18y,PicWidth,PicHeight,"CC18",3);
				OverlayDrawCC(CC17x,CC17y,PicWidth,PicHeight,"CC17",3);
				OverlayDrawCC(CC16x,CC16y,PicWidth,PicHeight,"CC16",3);
				OverlayDrawCC(CC15x,CC15y,PicWidth,PicHeight,"CC15",3);
				OverlayDrawCC(CC14x,CC14y,PicWidth,PicHeight,"CC14",3);
				OverlayDrawCC(CC13x,CC13y,PicWidth,PicHeight,"CC13",3);
				OverlayDrawCC(CC12x,CC12y,PicWidth,PicHeight,"CC12",3);
				OverlayDrawCC(CC11x,CC11y,PicWidth,PicHeight,"CC11",3);
				OverlayDrawCC(CC10x,CC10y,PicWidth,PicHeight,"CC10",3);
				OverlayDrawCC(CC09x,CC09y,PicWidth,PicHeight,"CC09",3);
				OverlayDrawCC(CC08x,CC08y,PicWidth,PicHeight,"CC08",3);
				OverlayDrawCC(CC07x,CC07y,PicWidth,PicHeight,"CC07",3);
				OverlayDrawCC(CC06x,CC06y,PicWidth,PicHeight,"CC06",3);
				OverlayDrawCC(CC05x,CC05y,PicWidth,PicHeight,"CC05",3);
				OverlayDrawCC(CC04x,CC04y,PicWidth,PicHeight,"CC04",3);
				OverlayDrawCC(CC03x,CC03y,PicWidth,PicHeight,"CC03",3);
				OverlayDrawCC(CC02x,CC02y,PicWidth,PicHeight,"CC02",3);
				OverlayDrawCC(CC01x,CC01y,PicWidth,PicHeight,"CC01",3);

				run("Select None");
				run("Rotate... ", "angle="+-AlphaDelta+""); //correct for rotation
				Overlay.activateSelection(CropIndex);
				run("Crop");
				Overlay.removeSelection(CropIndex);
//				Overlay.useNamesAsLabels(true);
				Overlay.drawLabels(false);


	/*** Save Pic and ROI ***/
				print("\\Update:Auto feature detect("+(j+1)*(100/AnalysedFileNb)+"%)-Auto Calibration OK_Saving Feature Pic ");//print the task progression in the log
				if (Rename=="Yes"){
					nameshort=nameshort+"_"+newname;	
//					saveAs("tif",CroppedDir+nameshort+"_"+newname+".tif"); //save as tif (V3-25)
				}
				
//				else {
//					saveAs("tif",CroppedDir+nameshort+".tif"); //save as tif (V3-25)
//				}
				//add text to indicate that this is an overlay
			setFont("SansSerif", (getWidth()/70));
			makeText("Annotations is an Overlay. To hide click on:Image>Overlay>Hide Overlay - To list click on:Image>Overlay>List Elements",0,0);
			run("Properties... ", "name=Overlay_info group=3 antialiased text1=[Annotations is an Overlay. To hide click on:Image>Overlay>Hide Overlay - To list click on:Image>Overlay>List Elements\n]");
			Overlay.addSelection;
//			Roi.setStrokeColor("");
				saveAs("tif",CroppedDir+nameshort+".tif"); //save as tif (V3-25)
				nameshortArray=	Array.concat(nameshortArray,nameshort);
				print("\\Update:Auto feature detect("+(j+1)*(100/AnalysedFileNb)+"%)-Auto Calibration OK_Saving ROI");//print the task progression in the log 
	roiManager("reset");//26/04
				run("To ROI Manager");
//				if (AnalysisOnPetriOnly=="Petri only") {
		 		pathROI=RoiFeaturesDir+nameshort+"_RoiSet.zip";
//		} else pathROI=RoiDir+nameshort+"_RoiSet.zip"; //define the ROI pathway (for saving detection)
				roiManager("save", pathROI);
				roiManager("reset");
			} //close IF 2 circles are detected
			else { //if not exactly 2 circles are detected. Calibration detection failed. Keep the information for error message display (at the end of the macro) and remove the pict from the arrays
				print("\\Update:Auto feature detect_"+AnalysedFile[j]+"_Auto Calibration Failed_Image Non analysed.\n ");//print the task progression in the log
				q=NonAnalysed.length;
				NonAnalysed = Array.concat(NonAnalysed, AnalysedFile[j]); //collect files name in the "non analysed" arrays
				NonAnalysedPic = Array.concat(NonAnalysedPic, AnalysedFile[j]);
				NonAnalyzedDescription= Array.concat(NonAnalyzedDescription, "Auto Calib. Failed");
				n++; //array filler
				nArray=Array.concat(nArray,q);
				run("Clear Results");
				AnalysedFile=Array.deleteIndex(AnalysedFile,j);//remove value from array because pic is not analysed
				PicWidthArray=Array.deleteIndex(PicWidthArray,j); //remove value from array because pic is not analysed
				PicHeightArray=Array.deleteIndex(PicHeightArray,j); 
				j--;
				AnalysedFileNb--;		
			} //close else 		
		} //close if  (GuideDetPb==false) 

		close("*");
 		print("\\Update:Auto feature detect("+(j+1)*(100/AnalysedFileNb)+"%)");//print the task progression in the log
	}//Close Loop 2

/** Process time (To activate/deactivate add/remove "//" in front of the 3 lines below) ***/
	Time=getTime();
	TaskTime=Time-TaskTime;
	if (TaskTime>1000){
	TaskTimeSec=TaskTime/1000;
	print("\\Update:Auto feature detection - Done (execution time",TaskTimeSec,"sec)"); //print the task progression in the log
	} else print("\\Update:Auto feature detection - Done (execution time",TaskTime,"msec)"); //print the task progression in the log


/*** inform of wich pictures were not processed in the log ***/
	for ( o=0; o<n; o++ ) { //loop 6 - inform of non analysed files
		non_analysed_id=nArray[o];
		print("Calibration problem with ",NonAnalysed[non_analysed_id],". Wrong calibration circle detected. Image will not be analysed "); //inform user that the file will not be analysed	
	} //close loop6
} //close if auto mode

/****************************************************
 * 9. No guide mode (need to work on it)
****************************************************/


if (AnalysisMode=="no Guide pics"){ // if analysis mode is "no Guide pics"
	run("Set Measurements...", "area centroid perimeter redirect=None decimal=3"); //define mesure conditions

/***  Open image, get titles ***/
	print(" Guide Auto crop (0%)");
	for (am=0; am<AnalysedFileNb; am++) { //Loop 27
		//showProgress(-j/AnalysedFileNb); Show a progession bar in the ImageJ menu
		path=dir+AnalysedFile[am]; //get path of first analysed image
		open(path); //Open picture
		nameshort = File.nameWithoutExtension; //get file name without extension
		picname=getTitle(); //get current image title
		//toUnscaled(PetriArea);
		//run("Set Scale...", "distance="+CalibLenght+" known="+CalibScaleUser+" unit=mm global"); //set scale
		run("Duplicate...", "title=Cropping");
		run("Select None"); //make sure that no other select were made
		run("HSB Stack");
		run("Stack to Images");
		close("Hue");
		close("Brightness");
		selectWindow("Saturation");
		setAutoThreshold("Percentile");
		run("Convert to Mask");
		run("Dilate");
		run("Analyze Particles...", "size=100-Infinity show=Overlay clear include");
//		run("Analyze Particles...", "size=100-Infinity show=Overlay display clear include");
		/*** Sort results table (under process issue with ); ***/ 	
		inc=nResults;
		Indexes=newArray();
		for (an = 0; an < (inc); an++) Indexes=Array.concat(Indexes,an);
		Table.setColumn("Indexes", Indexes);
		Table.sort("Area");
	  	for (ao=inc; ao>0; ao--) {
    		roiManager("reset");
    		indexMaxArea=Table.get("Indexes",(inc-1));
    		Overlay.activateSelection(indexMaxArea);
    		toUnscaled(PetriSize);
    		//print("PetriSize",PetriSize);
    		//run("Max Inscribed Circles", "minimum="+PetriSize+" use minimum_0=0.50 closeness=5");
			run("Max Inscribed Circles", "minimum=0 use minimum_0=0.50 closeness=5");
			//Roi.getBounds(x, y, width, height);
			if(roiManager("count")>0){
				run("From ROI Manager");
				Overlay.add;
				last=Overlay.size;
				last--;
				Overlay.activateSelection(last);
    			run("Measure");
    			AutoSize=Table.get("Area",(nResults-1));    
    			if (AutoSize>PetriArea){
    				i=0; //exit loop 
    				PetriCenterX=getResult("X", (nResults-1));
    				PetriCenterY=getResult("Y", (nResults-1));
    			}
			}
    		inc--;
  		}
		//print("x=",PetriCenterX,"-Y:",PetriCenterY);
		//  run("Labels...", "color=white font=14 show use bold");
		//roiManager("Deselect");
		//waitForUser;
		//Overlay.copy;
		//last=Overlay.size;
		//last--;
		//Overlay.activateSelection(last);
		selectWindow(picname);
		toUnscaled(PetriRadius);
		toUnscaled(PetriCenterX,PetriCenterY);
		makeEllipse((PetriCenterX-PetriRadius),PetriCenterY, (PetriCenterX+PetriRadius), PetriCenterY, 1);
		toScaled(PetriRadius);
		//Overlay.paste;
		run("Crop");
		run("Make Inverse"); //select everything but the ellipse
		setBackgroundColor(255,255,255); //set background color to white
		run("Clear", "slice"); //deleted background
		PetriCropPath=PetriDir + nameshort+"_PetriCrop.jpg"; //define cropped picture path
		PetriCroplist=Array.concat(PetriCroplist,PetriCropPath);//add crop picture path in the area (to open them later)
		saveAs("jpg",PetriCropPath);//save scale pic
		close("*");//close all open images
		roiManager("reset");
		run("Clear Results");
		print("\\Update:No Guide Auto crop ("+(am+1)*(100/AnalysedFileNb)+"%)");//print the task progression in the log	
	} //close loop 27
} //close if analysis mode is "no Guide pics"


/****************************************************
 * 10. Save auto scaling Quality check (this section is to draw/save a scale on each picture individually . Maybe there will be a problem if the pic are read in different order than teh scale list) Need unbuug
***************************************************/

if ((AnalysisMode=="Auto")&&(ScaleQCchoice==1)){
	print("Scaling QC (0%)");
	
	Newlist=getFileList(CroppedDir); // get names of all cropped files
	for (p=0; p<Newlist.length; p++) { //Loop 7
		//showProgress(-j/AnalysedFileNb); Show a progession bar in the ImageJ menu
		path=CroppedDir+Newlist[p]; //get path of first analysed image
		open(path);
		nameshort = File.nameWithoutExtension; //get file name without extension
//		run("Set Scale...", "distance=0 known=0 unit=unit"); //Remove pre saved scale //not needed with Tif removed 22/04
//		run("Set Scale...", "distance="+(lengthBigtoSmallArray[p])+" known="+CalibScale+" unit=mm");//not needed with Tif removed 22/04
		ActivateOverlaySelectionByName("SmallCircle");
		X=getValue("X"); //get the new Center X in pix for the current picture
		Y=getValue("Y");//get the new Center y in pix for the current picture
		toUnscaled(X, Y);
		CalibScaleUsePix=CalibScaleUser;
		toUnscaled(CalibScaleUsePix);
		makeLine(X, Y, X-CalibScaleUsePix, Y);
		run("Rotate...", "  angle="+-AlphaDeltaArray[p]+"");
//		ScaleWidth=toUnscaled(1);
//		run("Properties... ", "name=ScaleBar group=27 width="+ScaleWidth+"");
		run("Properties... ", "name=ScaleBar group=27 width=1");
//		run("Properties... ", "name=ScaleBar group=5 stroke=Cyan width=1 fill=Cyan");
		Overlay.addSelection;
		Color.setForeground("Cyan");
//		Roi.setFillColor("Cyan");
//		Color.setBackground("Cyan");
//		Color.setForeground("Red");
		makeLine(X, Y, X-CalibScaleUsePix, Y);
		Roi.setStrokeWidth(1);
		run("Rotate...", "  angle="+-AlphaDeltaArray[p]+"");
		run("Draw");
		makeText(""+CalibScaleUser+"mm",(((X-CalibScaleUsePix)+(X+CalibScaleUsePix))/2), ((Y+Y+CalibScaleUsePix)/2));
		run("Properties... ", "name=ScaleBarText group=27 antialiased text1=["+CalibScaleUser+"mm]");
//		run("Properties... ", "name=ScaleBarText group=27 width=1");
		Overlay.addSelection;
		Color.setForeground("Cyan");
		FontSize=CalibScaleUser/2;
		toUnscaled(FontSize);
		setFont("SansSerif", FontSize);
		makeText(""+CalibScaleUser+"mm",(((X-CalibScaleUsePix)+(X+CalibScaleUsePix))/2), ((Y+Y+CalibScaleUsePix)/2));
		run("Properties... ", "name=ScaleBarText group=27 antialiased text1=["+CalibScaleUser+"mm]");
		run("Draw");
		run("Select None");
		saveAs("tif", CroppedDir+nameshort+".tif");//save scale pic
		run("Set Scale...", "distance=0 known=0 unit=unit"); //Reset scale and return to pixels size
//		ActivateOverlaySelectionByName("ScaleBar"); //reactivate to have a small pic of the scaling
//		run("To Bounding Box");//reactivate to have a small pic of the scaling
//		Overlay.hide;//reactivate to have a small pic of the scaling
//		run("Enlarge...", "enlarge="+CalibScaleUsePix+"");//reactivate to have a small pic of the scaling
//		run("Crop");//reactivate to have a small pic of the scaling
//		saveAs("jpg", ScaleDir+nameshort+"_Scale_QC.jpg");//reactivate to have a small pic of the scaling;//save scale pic
		
		pathROI=RoiFeaturesDir+File.nameWithoutExtension+"_RoiSet.zip";
		
//		pathROI=RoiDir+File.nameWithoutExtension+"_RoiSet.zip"; //define the ROI pathway (for saving detection)
	roiManager("reset");//26/04
		run("To ROI Manager");
		roiManager("save", pathROI);
		run("From ROI Manager");
		roiManager("reset");
		close("*"); //close scale picture
		print("\\Update:Scaling QC ("+(p+1)*(100/AnalysedFileNb)+"%)"); //print the task progression in the log
	}//Close Loop 7

/** Process time (To activate/deactivate add/remove "//" in front of the 3 lines below) **/
Time=getTime();
TaskTime=Time-TaskTime;
if (TaskTime>1000){
	TaskTimeSec=TaskTime/1000;
	print("\\Update:Scaling QC - Done (execution time",TaskTimeSec,"sec)"); //print the task progression in the log
} else print("\\Update:Scaling QC - Done (execution time",TaskTime,"msec)"); //print the task progression in the log

}//Close If Auto or scale choice QC=true

/****************************************************
 * 11. White balance Calibration
 ****************************************************/

print("Used memory:", call("ij.IJ.freeMemory")); //inform user of used memory
if (WhiteBalance==1){//if user asked for a white balancing of each images (see interface)
	
	//array with the color checker card known values
	Rarray=newArray(115,194,98,87,133,103,214,80,193,94,157,224,56,70,175,231,187,8,243,200,160,122,85,52);		
	Garray=newArray(82,150,122,108,128,189,126,91,90,60,188,163,61,148,54,199,86,133,243,200,160,122,85,52);
	Barray=newArray(68,130,157,67,177,170,44,166,99,108,64,46,150,73,60,31,149,161,243,200,160,122,85,52);
	
	run("Collect Garbage"); // soft reset of ImageJ memory

print("Used memory Before step:", call("ij.IJ.freeMemory")); //inform user of used memory
	
	run("Set Measurements...", "mean redirect=None decimal=5");
	print("White Balance (0%)");
	Newlist=getFileList(CroppedDir); // get names of all cropped files
	for (q=0; q<Newlist.length; q++) { //Loop 8
//		print("\\Update:White Balance ("+(q+1)*(100/Newlist.length)+"%)"); //print the task progression in the log
	run("Collect Garbage"); // soft reset of ImageJ memory

print("Used memory before WB:", call("ij.IJ.freeMemory")); //inform user of used memory
		print("White Balance ("+(q+1)*(100/Newlist.length)+"%)"); //print the task progression in the log
		path=CroppedDir+Newlist[q]; //get path of first analysed image
		open(path);
		nameshort=getTitle();
		run("Select None");
		print("\\Update:White Balance ("+(q+1)*(100/Newlist.length)+"%): "+nameshort+""); //print the task progression in the log
		run("Duplicate...", "title=WB-calibration");//creates a duplicate of the current image with the name "WB-calibration"
		if (bitDepth() != 24) run("RGB Color");//if active image is not an RGB, make it RGB
		run("RGB Stack");//make an RGB stack of "WB-calibration"
		
		R_Gray_Array=newArray();
		R_Mesured_Array=newArray();
		G_Gray_Array=newArray();
		G_Mesured_Array=newArray();
		B_Gray_Array=newArray();
		B_Mesured_Array=newArray();

		//get the mesured value and the corresponding color checker card value in array for the curve fitting
		for (r=1;r<=3;r++) {//loop9 - repeat for all three slices of the RGB stack
			selectWindow("WB-calibration");
			setSlice(r);//go to the s slice
			for (ae = 0; ae < Overlay.size; ae++) {
				Overlay.activateSelection(ae);
				testName=Roi.getName();
//				if ((startsWith(testName, "CC"))==true) { // get values only for all colors
				if (((startsWith(testName, "CC2"))==true)||((startsWith(testName, "CC19"))==true)) { // get values only for the white and black stuff
					Gray=getValue("Mean");
					ccNb=parseInt(testName.substring(2,4));
					if (r==1) {
						R_Mesured_Array=Array.concat(R_Mesured_Array,Gray);
						R_Gray_Array=Array.concat(R_Gray_Array,(Rarray[ccNb-1]));
					}
					else if (r==2){
						G_Mesured_Array=Array.concat(G_Mesured_Array,Gray);
						G_Gray_Array=Array.concat(G_Gray_Array,(Garray[ccNb-1]));
					}
					else if (r==3){
						B_Mesured_Array=Array.concat(B_Mesured_Array,Gray);
						B_Gray_Array=Array.concat(B_Gray_Array,(Barray[ccNb-1]));
					}	
				}
			}
		} //close loop 9
		run("Select None");
		run("Clear Results");
		print("\\Update:White Balance ("+(q+1)*(100/Newlist.length)+"%): "+nameshort+" Get CC info ok"); //print the task progression in the log

		//find the best curve fit 
		for (r=1;r<=3;r++) {//loop9 - repeat for all three slices of the RGB stack
		selectWindow("WB-calibration");
		setSlice(r);//go to the s slice
		if (r==1) {
			Fit.doFit(17,R_Mesured_Array,R_Gray_Array);	
    		Fit.getEquation(17, R_fit_name, formula); // Returns the name, formula and macro code of the specified equation.
			RmacroCode=FitGetMacro(17);
    	}
    	if (r==2) {
			Fit.doFit(17,G_Mesured_Array,G_Gray_Array);	
    		Fit.getEquation(17, G_fit_name, formula); // Returns the name, formula and macro code of the specified equation.
			GmacroCode=FitGetMacro(17);
    	}
    	if (r==3) {
  			Fit.doFit(17,B_Mesured_Array,B_Gray_Array);	
    		Fit.getEquation(17, B_fit_name, formula); // Returns the name, formula and macro code of the specified equation.
			BmacroCode=FitGetMacro(17);
    	}
		/*
		R_AiC_Best=1000000;
		G_AiC_Best=1000000;
		B_AiC_Best=1000000;
  			for (af=0; af<Fit.nEquations; af++) {
  				if (r==1) {
  					R_AiC=FitAIC(af,R_Mesured_Array,R_Gray_Array);
    				if (R_AiC<R_AiC_Best) {
    					R_AiC_Best=R_AiC;
    					Fit.getEquation(af, R_fit_name, formula); // Returns the name, formula and macro code of the specified equation.
    					Fit.getEquation(af, R_fit_name, formula); // Returns the name, formula and macro code of the specified equation.
						RmacroCode=FitGetMacro(af);
						RmacroCode=RmacroCode.replace("y = ","v=");
    				}
    			}
    			if (r==2) {
  				 	G_AiC=FitAIC(af,G_Mesured_Array,G_Gray_Array);
    				if (G_AiC<G_AiC_Best) {
    					G_AiC_Best=G_AiC;
    					Fit.getEquation(af, G_fit_name, formula); // Returns the name, formula and macro code of the specified equation.
						GmacroCode=FitGetMacro(af);
						GmacroCode=GmacroCode.replace("y = ","v=");
    				}
    			}
    			if (r==3) {
  					B_AiC=FitAIC(af,B_Mesured_Array,B_Gray_Array);
					if (B_AiC<B_AiC_Best) {
    					B_AiC_Best=B_AiC;
    					Fit.getEquation(af, B_fit_name, formula); // Returns the name, formula and macro code of the specified equation.
						BmacroCode=FitGetMacro(af);
						BmacroCode=BmacroCode.replace("y = ","v=");
    				}
    			}
  			}
  			*/
  		}//close loop 9
  		print("\\Update:White Balance ("+(q+1)*(100/Newlist.length)+"%): "+nameshort+" Get bets fit info ok"); //print the task progression in the log
			
		R_fit_name_Array=Array.concat(R_fit_name_Array,R_fit_name);
		G_fit_name_Array=Array.concat(G_fit_name_Array,G_fit_name);
		B_fit_name_Array=Array.concat(B_fit_name_Array,B_fit_name);
					
		R_fit_MacroCode_Array=Array.concat(R_fit_MacroCode_Array,RmacroCode);
		G_fit_MacroCode_Array=Array.concat(G_fit_MacroCode_Array,GmacroCode);
		B_fit_MacroCode_Array=Array.concat(B_fit_MacroCode_Array,BmacroCode);

		//Channel adjustment  
  		for (r=1;r<=3;r++) {//loop9 - repeat for all three slices of the RGB stack
  			selectWindow("WB-calibration");
			setSlice(r);//go to the s slice
			if (r==1) {
				print("\\Update:White Balance ("+(q+1)*(100/Newlist.length)+"%): "+nameshort+" Red Channel Adjustent (takes a while.. be patient)"); //print the task progression in the log
				run("Macro...", "code="+RmacroCode+" slice");
			}
			if (r==2) {
				print("\\Update:White Balance ("+(q+1)*(100/Newlist.length)+"%): "+nameshort+" Green Channel Adjustent (takes a while.. be patient)"); //print the task progression in the log
				run("Macro...", "code="+GmacroCode+" slice");
			}
			if (r==3) {
				print("\\Update:White Balance ("+(q+1)*(100/Newlist.length)+"%): "+nameshort+" Blue Channel Adjustent (takes a while.. be patient)"); //print the task progression in the log
				run("Macro...", "code="+BmacroCode+" slice");
			}
  		}
		Overlay.copy;
		run("Convert Stack to RGB");//combine R,G, and B-slice to corrected RGB-image
		Overlay.paste;
		nameshort=nameshort.replace(".tif","");
		
print("Used memory after WB:", call("ij.IJ.freeMemory")); //inform user of used memory
		rename(nameshort + "-WBcorrected");//renaming the corrected pictures based on the slice name
		close("WB-calibration");
//		setBatchMode("show");
		saveAs("tif", CroppedDir+nameshort+ "_WB.tif");//save scale pic
		Dummy_var=File.delete(path);
		close("*"); // close any window without returning any error
//		print("\\Update:White Balance ("+(q+1)*(100/Newlist.length)+"%): "+nameshort+" Done");//print the task progression in the log
	} //close Loop8

/** Process time (To activate/deactivate add/remove "//" in front of the 3 lines below) **/
Time=getTime();
TaskTime=Time-TaskTime;
if (TaskTime>1000){
	TaskTimeSec=TaskTime/1000;
	print("\\Update:White Balance - Done (execution time",TaskTimeSec,"sec)"); //print the task progression in the log
} else print("\\Update:White Balance - Done (execution time",TaskTime,"msec)"); //print the task progression in the log

}//close IF (WhiteBalance==1) 

/****************************************************
 * 12. Auto crop of the petri dish area
****************************************************/

//if ((AnalysisMode=="User defined based on 1st image")||(AnalysisMode=="Auto")){

	if (AnalysisMode=="User defined based on 1st image"){
		list=Array.copy(AnalysedFile); // get names of all files in input directory
		directory=dir;
	}

//	if ((AnalysisMode=="Auto")&&(WhiteBalance==1)){ //if user asked for a white balancing of each images (see interface)
//		list=getFileList(WBDir); // get names of all files in input directory
//		directory=WBDir;
//	}//close if
//	if ((AnalysisMode=="Auto")&&(WhiteBalance==0)){
//		list=getFileList(CroppedDir);
//		directory=CroppedDir;
//	}//close if
	
	if (AnalysisMode=="Auto"){
		list=getFileList(CroppedDir);
		directory=CroppedDir;
	}//close if
	
	print("Petri Selection Crop (0%)");

	for (u=0; u<list.length; u++) {//Loop 12
		path=directory+list[u]; //get path of first analysed image
		open(path);
		//selectWindow("Crop"); //select original picture
		nameshort = File.nameWithoutExtension; //get file name without extension
//		if (AnalysisMode=="Auto"){ //if auto mode selected
			/*petricrop */
//			if (AnalysisOnPetriOnly=="Petri only") {
		
			if (ActivateOverlaySelectionByName("QR")==true) {
				XorArray=newArray();
				XorArray2=newArray();
				for (ax = 0; ax < Overlay.size; ax++) {
					Overlay.activateSelection(ax);
					if (Roi.getName=="Petri") XorArray=Array.concat(XorArray,ax);
					if (Roi.getName=="Petri") XorArray2=Array.concat(XorArray2,ax);
					if (Roi.getName=="QR") XorArray=Array.concat(XorArray,ax);
				}
	roiManager("reset");//26/04
				run("To ROI Manager");
//				Overlay.clear;
				roiManager("Select", XorArray);
				roiManager("AND");
				roiManager("add");
	if (Overlay.size!=0)Overlay.clear;
				run("From ROI Manager");
				roiManager("reset");
//				run("Select None");
				Overlay.activateSelection(Overlay.size-1);
				Roi.setName("QR+Petri");
				Roi.setGroup(2);
//				roiManager("Select", roiManager("count")-1);
//				roiManager("Rename", "QR+Petri");
//				roiManager("Update");
	roiManager("reset");//26/04
				run("To ROI Manager");
				XorArray2=Array.concat(XorArray2,roiManager("count")-1);
				roiManager("Select", XorArray2);
				roiManager("XOR");
				roiManager("add");
//				run("Select None");
if (Overlay.size!=0)Overlay.clear;
				run("From ROI Manager");
				roiManager("reset");
//				run("Select None");
				Overlay.activateSelection(Overlay.size-1);
				Roi.setName("QR-Petri");
				Roi.setGroup(2);
//				roiManager("Select", roiManager("count")-1);
//				roiManager("Rename", "QR-Petri");
//				roiManager("Update");
//				if (AnalysisOnPetriOnly=="Petri only") {
				pathROI=RoiFeaturesDir+nameshort+"_RoiSet.zip";
//				} else pathROI=RoiDir+nameshort+"_RoiSet.zip";
roiManager("reset");//26/04
				run("To ROI Manager");
				roiManager("save", pathROI);
				if (Overlay.size!=0)Overlay.clear;

				run("From ROI Manager");
				roiManager("reset");
			}// CLOSE if (ActivateOverlaySelectionByName("QR")==true)
//		}// close if auto mode
//here rotation of the petri dish
			run("Select None");
			if ((RotationMode=="QR based")&&(ActivateOverlaySelectionByName("QR-Petri")==true)){
				run("Select None");
				run("Rotate... ", "angle="+AlphaDeltaQRArray[u]+" enlarge"); //correct for rotation
			}
			if ((RotationMode=="Guide Based")&&(ActivateOverlaySelectionByName("Petri")==true)){
				run("Select None");
				run("Rotate... ", "angle="+AlphaDeltaArray[u]+" enlarge");
			}
			
			if (ActivateOverlaySelectionByName("QR-Petri")==false) ActivateOverlaySelectionByName("Petri");
	

//			Xcorrection=CenterXbig-NewCenterX;
//			Ycorrection=CenterYbig-NewCenterY;
			run("Make Inverse");//select everything but the petri dish
//			setBackgroundColor(255,255,255);// make outside of the petri in white
			setBackgroundColor(0, 0, 0);// make outside of the petri in black
			run("Clear", "slice"); //trim everything but the petri dish
			run("Make Inverse");
			run("Crop");

			run("Select None");

			NewCenterX=getWidth()/2;
			NewCenterY=getHeight()/2;
			NewCenterXArray=Array.concat(NewCenterXArray,NewCenterX);
			NewCenterYArray=Array.concat(NewCenterYArray,NewCenterY);

			CropPicWidthArray=Array.concat(CropPicWidthArray,getWidth());
			CropPicHeightArray=Array.concat(CropPicHeightArray,getHeight());
			nameshort=nameshort+"_PetriCrop";
			
			PetriCropPath=PetriDir + nameshort+".tif"; //define cropped picture path
			PetriCroplist=Array.concat(PetriCroplist,PetriCropPath);//add crop picture path in the area (to open them later)

			setFont("SansSerif", (getWidth()/70));
			makeText("Annotations is an Overlay. To hide click on:Image>Overlay>Hide Overlay - To list click on:Image>Overlay>List Elements",0,0);
			run("Properties... ", "name=Overlay_info group=3 antialiased text1=[Annotations is an Overlay. To hide click on:Image>Overlay>Hide Overlay - To list click on:Image>Overlay>List Elements\n]");
			Overlay.addSelection;
			run("Select None");
			saveAs("tif",PetriCropPath);//save scale pic
			roiManager("reset");//26/04
			run("To ROI Manager");
			pathROI=RoiPetriDir+nameshort+"_RoiSet.zip";
//			pathROI=RoiDir+nameshort+"_RoiSet.zip"; //define the ROI pathway (for saving detection)
			run("From ROI Manager");
			roiManager("save", pathROI);
			roiManager("reset");
//			run("From ROI Manager");
//			}
			
//			run("Set Scale...", "distance="+lengthBigtoSmallArray[u]+" known="+CalibScale+" unit=mm"); //set scale
//			X=NewCenterXArray[u]; //get the new Center X in pix for the current picture
//			Y=NewCenterYArray[u];//get the new Center y in pix for the current picture
//			toScaled(X,Y); //change pixel to mm based on the scale
//			x1=(X-PetriRadius);
//			x2=(X+PetriRadius);
//			toUnscaled(x1,x2,Y);
//			makeEllipse(x1,Y,x2, Y, 1);
		
		
//		if (AnalysisMode=="User defined based on 1st image"){ //if user based selected
//			roiManager("reset");
//			pathROI=PetriDir+"PetriSelection_RoiSet.zip"; //define the ROI pathway (for saving detection)
//			roiManager("Open", pathROI); //save ROI selections
//			roiManager("Select", 0);
//		} //close if user based selected
/* 22/04 removed duplcated
		if (ActivateOverlaySelectionByName("QR-Petri")==false) ActivateOverlaySelectionByName("Petri");
		run("Crop"); //crop to petri dish size
		run("Make Inverse");//select everything but the petri dish
		setBackgroundColor(0, 0, 0);// make outside of the petir in black
		run("Clear", "slice"); //trim everything but the petri dish
		run("Select None");
		*/
//		PetriCropPath=PetriDir + nameshort+"_PetriCrop.jpg"; //define cropped picture path
//		PetriCroplist=Array.concat(PetriCroplist,PetriCropPath);//add crop picture path in the area (to open them later)
//		saveAs("jpg",PetriCropPath);//save scale pic
		close("*");//close all open images
		print("\\Update:Petri Selection Crop ("+(u+1)*(100/(AnalysedFileNb))+"%)"); //print the task progression in the log
}//close loop 12

/** Process time (To activate/deactivate add/remove "//" in front of the 3 lines below) **/
Time=getTime();
TaskTime=Time-TaskTime;
if (TaskTime>1000){
	TaskTimeSec=TaskTime/1000;
	print("\\Update:Petri Selection Crop - Done (execution time",TaskTimeSec,"sec)"); //print the task progression in the log
} else print("\\Update:Petri Selection Crop - Done (execution time",TaskTime,"msec)"); //print the task progression in the log
//}
/****************************************************
 * 13. Image processing - 
****************************************************/

/*** Open Picture, set scale, get titles ***/
print("Colonies detection/analysis (0%)");

//setBatchMode(false);

//listToProcess=getFileList(CroppedDir);
listToProcess=getFileList(PetriDir);

for (v=0; v<listToProcess.length; v++) {//Loop 13
//	path=CroppedDir+listToProcess[v]; //get path of first analysed image
	path=PetriDir+listToProcess[v]; //get path of first analysed image
	open(path);
	if (isOpen("ROI Manager")) roiManager("reset");
	nameshort = File.nameWithoutExtension; //get file name without extension
	ImageProcessID=getImageID();
	picname=getTitle(); //get current image title
//	if ((AnalysisMode=="User defined based on 1st image")||(AnalysisMode=="no Guide pics"))run("Set Scale...", "distance="+CalibLenght+" known="+CalibScaleUser+" unit=mm global"); //set scale (not needed if we used a tif file
//	if (AnalysisMode=="Auto")run("Set Scale...", "distance="+lengthBigtoSmallArray[v]+" known="+CalibScale+" unit=mm"); //set scale (not needed if we used a tif file
	
/*** Image processing - Thresholding (to get rid of blue background) ***/
	run("Select None");
	run("Duplicate...", "title=Thresholding"); //creates a duplicate of the current image with the name "Thresholding"
	Overlay.copy;
	
//	run("Gaussian Blur...", "sigma=2");
	
	if(ThresholdChoice=="HSB Method"){ //IF "Threshold on "HSB Method"	
		run("HSB Stack"); //transform the RGB to HSB
		run("Convert Stack to Images"); //extract all image from the HSB
		filter=newArray("stop","pass","pass"); //create Array for filter information
		selectWindow("Hue"); //get the Hue window
		rename("0"); //name the image 0
		selectWindow("Saturation"); //get the Saturation window
		rename("1"); //name the image 1
		selectWindow("Brightness"); //get the Brightness window
		rename("2"); //name the image 2
		for (w=0;w<3;w++){ //Loop14: Attirbution of threshold to each HSB window
  			selectWindow(w); //select HSB windows
  			setThreshold(min[w], max[w]); //set min max 
			run("Convert to Mask"); //create mask
			rename(w);
  			if (filter[w]=="stop")  run("Invert"); //if Filter says stop,only keep what is not included in between the thershold values
		} //close loop14
		imageCalculator("AND create", "0","1"); //merge Hue and Saturation
		imageCalculator("AND create", "Result of 0","2"); //merge resulting image with Brightness
		for (aa=0;aa<3;aa++){ //loop15
  			selectWindow(aa); //select each HSB window
 	 		close(); //close each HSB window
		} //close loop15
		close("Result of 0");//close the merged Hue and Saturation picture
		selectWindow("Result of Result of 0"); //select the new HSB picture
		rename("thresholded"); //rename picture with its original name
	} //close if HSB method
	


	if(ThresholdChoice=="Ylab Method"){ //IF "Threshold on "Ylab Method" //not working with Mark's
		//run("Subtract Background...", "rolling=30 light");
		
		run("Lab Stack"); //transform the RGB to Lab
		//run("RGB to L*a*b* Stack");
		run("Convert Stack to Images"); //extract all image from the HSB
		close("a*"); //close Saturation window
		close("L*"); //close Brightness window
		selectWindow("b*");  //select Hue Saturation window
		rename("thresholded");
		setOption("ScaleConversions", true);
		run("8-bit");
		setAutoThreshold("Otsu dark");
		
//		setAutoThreshold(""+ThresholdType_Ylab+" dark");
//		setAutoThreshold(""+ThresholdType_Ylab+" dark");
		//setAutoThreshold("Minimum dark");
		//run("8-bit");
		//setAutoThreshold("Triangle");
		//could use MaxEntropy or Intermodes or Triangle or Yen
		//setThreshold(minB,maxB); //set threshold based on interface entries
		run("Convert to Mask"); //create mask based on the thresholding values
		//run("Invert"); //only keep what is not included in between the thershold values
		rename("thresholded"); //rename picture with its original name
	} //close IF Ylab
	
	if (ThresholdChoice=="YCbCr Method") {
		run("RGB to YCbCr Stack");
		run("Convert Stack to Images"); //extract all image from the HSB
		selectWindow("Cr"); 
		setAutoThreshold("Triangle dark");
		setOption("BlackBackground", false);
		run("Convert to Mask");
		rename("thresholded"); //rename picture with its original name
	}
	

	if (ThresholdChoice=="All"){
		//threshold with RGB
//		if(ThresholdChoice=="HSB Method JA"){ //IF "Threshold on "HSB Method"
//		run("Gaussian Blur...", "sigma=2");	
//		selectWindow(picname);
selectWindow("Thresholding");
		run("Duplicate...", "title=HSB_Thresholding"); //creates a duplicate of the current image with the name "Thresholding"
		Overlay.copy;
		run("HSB Stack");
		run("Stack to Images");
		selectWindow("Hue");
//			setAutoThreshold("IJ_IsoData");
		setAutoThreshold("Mean");
		setOption("BlackBackground", false);
		run("Convert to Mask");
		rename("1");
//		setAutoThreshold("Triangle");
		selectWindow("Saturation");
//		setAutoThreshold("Minimum dark");
		setAutoThreshold("Mean");
		setOption("BlackBackground", false);
		run("Convert to Mask");
		rename("2");
//		} //close if HSB method

		//threshold with Ylab
//		if(ThresholdChoice=="Ylab Method JA"){ //IF "Threshold on "Ylab Method" //not working with Mark's
//		selectWindow(picname);
selectWindow("Thresholding");
		run("Duplicate...", "title=Ylab_Thresholding"); //creates a duplicate of the current image with the name "Thresholding"
		Overlay.copy;
		run("Lab Stack"); //transform the RGB to Lab
		//run("RGB to L*a*b* Stack");
		run("Convert Stack to Images"); //extract all image from the HSB
//		close("L*"); //close Brightness window
		selectWindow("b*");  //select Hue Saturation window
//		rename("thresholded");
//		setOption("ScaleConversions", true);
//		run("8-bit");
		setAutoThreshold("Otsu dark");
		setOption("BlackBackground", false);
		run("Convert to Mask");
		setOption("BlackBackground", false);
		run("Convert to Mask");
		rename("3");
		selectWindow("a*");  //select Hue Saturation window
//		setOption("ScaleConversions", true);
//		run("8-bit");
		setAutoThreshold("Otsu dark");
		setOption("BlackBackground", false);
		run("Convert to Mask");
			setOption("BlackBackground", false);
		run("Convert to Mask");
//		setAutoThreshold(""+ThresholdType_Ylab+" dark");
//		setAutoThreshold(""+ThresholdType_Ylab+" dark");
		//setAutoThreshold("Minimum dark");
		//run("8-bit");
		//setAutoThreshold("Triangle");
		//could use MaxEntropy or Intermodes or Triangle or Yen
		//setThreshold(minB,maxB); //set threshold based on interface entrie
		//run("Invert"); //only keep what is not included in between the thershold values
		rename("4"); //rename picture with its original name
//		} //close IF Ylab

		//threshold with YCbcr
//			if (ThresholdChoice=="YCbCr Method JA") {
//		selectWindow(picname);
selectWindow("Thresholding");
		run("Duplicate...", "title=YCbCr_Thresholding"); //creates a duplicate of the current image with the name "Thresholding"
		Overlay.copy;
		run("RGB to YCbCr Stack");
		run("Convert Stack to Images"); //extract all image from the HSB
		selectWindow("Cr"); 
//		setAutoThreshold("Triangle dark");
		setAutoThreshold("Otsu dark");
		setOption("BlackBackground", false);
		run("Convert to Mask");
		rename("5"); //rename picture with its original name
		/*
		//test adding cb
				selectWindow("Cb"); 
//		setAutoThreshold("Triangle dark");
		setAutoThreshold("Otsu dark");
		setOption("BlackBackground", false);
		run("Convert to Mask");
		rename("6"); //rename picture with its original name
//		}
*/
/*
run("Duplicate...", "title=YCbCr_Thresholding"); //creates a duplicate of the current image with the name "Thresholding"
		Overlay.copy;
		run("RGB to YCbCr Stack");
		run("Convert Stack to Images"); //extract all image from the HSB
		selectWindow("Cr"); 
//		setAutoThreshold("Triangle dark");
		setAutoThreshold("Otsu dark");
		setOption("BlackBackground", false);
		run("Convert to Mask");
		rename("5"); //rename picture wit
*/

		//make the sum of the 5 masks and get the 3 commun pixels stuffs
		
		imageCalculator("Add 32-bit", "1","2");
		imageCalculator("Add 32-bit", "Result of 1","3");
		imageCalculator("Add 32-bit", "Result of Result of 1","4");
		imageCalculator("Add 32-bit", "Result of Result of Result of 1","5");
//		imageCalculator("Add 32-bit", "Result of Result of Result of Result of 1","6"); //test adding Cd
		rename("thresholded");
		 
/*
		
		for (Allthreshold = 1; Allthreshold < 5; Allthreshold++) {
			print(Allthreshold+1);
//			waitForUser;

			imageCalculator("Add 32-bit", "1",Allthreshold+1);
			close("thresholded_pic");
			selectWindow("Result of 1");
			rename("1");
		}
		waitForUser;
*/
//		setThreshold(750, 4000);
		setThreshold(1000, 4000);
//		waitForUser;
		setOption("BlackBackground", false);
		run("Convert to Mask");
//		waitForUser;
		

	} //close "all"
	

//setThreshold(750, 4000);





//run("k-means Clustering ...", "number_of_clusters=4 cluster_center_tolerance=0.00010000 enable_randomization_seed randomization_seed=48 send_to_results_table");



/*** Image processing - Colony detection ***/



	selectWindow("thresholded"); //make sure that detection is made on the on the picture that was thresholded in the previous step
	Overlay.paste;

	run("Set Measurements...", "area mean standard modal min centroid fit shape feret's redirect=None decimal=3"); //run analysis on the image left open by the last step
	
	if (ActivateOverlaySelectionByName("QR-Petri")==false) ActivateOverlaySelectionByName("Petri");
//	Overlay.activateSelection(21);
	run("Make Inverse");//select everything but the petri dish
	setBackgroundColor(255,255,255);// make outside of the petri in white
//			setBackgroundColor(0, 0, 0);// make outside of the petri in black
	run("Clear", "slice"); //trim everything but the petri dish
	run("Make Inverse");
//	run("Select None");
	
	
	
//	roiManager("reset");
	if(watershedChoice==1){ //if watersheld selected
		run("Fill Holes");
		run("Watershed");
	} //close if watersheld selected
	//roiManager("Set Color", "red");
	//roiManager("Set Line Width", 0);
//	dim=getWidth(); //get pict dimention to draw the petri selection
//	CropPicWidthHeightArray=Array.concat(CropPicWidthHeightArray,dim); //save value in array
//	makeOval(0, 0, dim, dim); //draw the petri selection of the size of the cropped file so no background in detected
//	if (ActivateOverlaySelectionByName("QR-Petri")==false) ActivateOverlaySelectionByName("Petri"); //26/04
	

	/* main colonie detections process */
//	PredetectOverlaySize=Overlay.size;
	run("Analyze Particles...", "size="+MinColSize+"-infinity circularity="+CirMin+"-"+CirMax+" show=Overlay exclude clear include");
	
	//Rename Overlay
//	PredetectOverlaySize=Overlay.size;
	ColNb=0;
	run("Select None");
//	if (PredetectOverlaySize!=Overlay.size){
//		for (av = PredetectOverlaySize; av < Overlay.size; av++) {
	for (av = 0; av < Overlay.size; av++) {
		ColNb++;
		Overlay.activateSelection(av);
		Roi.setGroup(7);
		Roi.setName("C"+ColNb);
		}
	

//	run("List Elements");
	roiManager("reset");//26/04
	if (nResults!=0){
		run("To ROI Manager");
		pathROI=RoiDetectDir+nameshort+"_Detection_RoiSet.zip";
		roiManager("save", pathROI);
	}
	selectImage(ImageProcessID);
//	selectWindow(nameshort);

		
//		run("Labels...", "color=white font=20 show");
//		run("Flatten");
//	run("From ROI Manager");
//	roiManager("reset");
//	saveAs("tif",CroppedDir+nameshort+".tif"); //save as tif (V3-25)
//	Overlay.flatten;
//	saveAs("jpg",DetectDir+nameshort+"_Detection.jpg"); //save	
	
	

//	selectWindow(picname);	//maybe replace if mean issues 250
	
	
	if (nResults>0){ //if more than 1 colonie detected	
		//pathROI=RoiDir+nameshort+"_RoiSet.zip"; //define the ROI pathway (for saving detection)
		//roiManager("Save", pathROI); //save ROI selections
		//roiManager("draw");
		run("Clear Results");
		roiManager("measure");
		for (ac=0; ac<nResults; ac++){// loop17: add image name an colony number to the results tables 
			ResultsPic=Array.concat(ResultsPic,nameshort);//add crop picture path in the area (to open them later)
			ResultsID=Array.concat(ResultsID,(ac+1));
			ResultsArea=Array.concat(ResultsArea,getResult("Area", ac));
			ResultsMean=Array.concat(ResultsMean,getResult("Mean", ac));
			ResultsMin=Array.concat(ResultsMin,getResult("Min", ac));
			ResultsMax=Array.concat(ResultsMax,getResult("Max", ac));
			ResultsStdDev=Array.concat(ResultsStdDev,getResult("StdDev", ac));
			ResultsMode=Array.concat(ResultsMode,getResult("Mode", ac));
			//ResultFeret=Array.concat(ResultFeret,getResult("Feret",ac));
			//ResultFeretX=Array.concat(ResultFeretX,getResult("FeretX",ac));
			//ResultFeretY=Array.concat(ResultFeretY,getResult("FeretY",ac));
			//ResultFeretAngle=Array.concat(ResultFeretAngle,getResult("FeretAngle",ac));
			//ResultMinFeret=Array.concat(ResultMinFeret,getResult("MinFeret",ac));
			Xcolonie=getResult("X", ac);
//			toUnscaled(Xcolonie);
//			if (AnalysisOnPetriOnly=="Petri only") Xcolonie=Xcolonie-Xcorrection;
			ResultsX=Array.concat(ResultsX,Xcolonie);
			Ycolonie=getResult("Y", ac);
//			toUnscaled(Ycolonie);
//			if (AnalysisOnPetriOnly=="Petri only") Ycolonie=Ycolonie-Ycorrection;
			ResultsY=Array.concat(ResultsY,Ycolonie);
			ResultsMajor=Array.concat(ResultsMajor,getResult("Major", ac));
			ResultsMinor=Array.concat(ResultsMinor,getResult("Minor", ac));
			ResultsAngle=Array.concat(ResultsAngle,getResult("Angle", ac));
			ResultsCirc=Array.concat(ResultsCirc,getResult("Circ.", ac));
			ResultsAR=Array.concat(ResultsAR,getResult("AR", ac));
			ResultsRound=Array.concat(ResultsRound,getResult("Round", ac));
			ResultsSolidity=Array.concat(ResultsSolidity,getResult("Solidity", ac));
		} //close loop17
//		waitForUser;

		run("Summarize");
		if (nResults==1){ //if only one colonie detected get the value of the single colonie detected (index0)
			SummaryPic=Array.concat(SummaryPic,nameshort);//add crop picture path in the area (to open them later)
			SummaryLabel=Array.concat(SummaryLabel,"only one colone detected");
			SummaryArea=Array.concat(SummaryArea,getResult("Area", 0));
			SummaryMean=Array.concat(SummaryMean,getResult("Mean", 0));
			SummaryMin=Array.concat(SummaryMin,getResult("Min", 0));
			SummaryStdDev=Array.concat(SummaryStdDev,getResult("StdDev", 0));
			SummaryMode=Array.concat(SummaryMode,getResult("Mode", 0));
			//SummaryFeret=Array.concat(SummaryFeret,getResult("Feret",0));
			//SummaryFeretX=Array.concat(SummaryFeretX,getResult("FeretX",0));
			//SummaryFeretY=Array.concat(SummaryFeretY,getResult("FeretY",0));
			//SummaryFeretAngle=Array.concat(SummaryFeretAngle,getResult("FeretAngle",0));
			//SummaryMinFeret=Array.concat(SummaryMinFeret,getResult("MinFeret",0));
			SummaryMax=Array.concat(SummaryMax,getResult("Max", 0));
			//SummaryX=Array.concat(SummaryX,getResult("X", 0));
			//SummaryY=Array.concat(SummaryY,getResult("Y", 0));
			SummaryMajor=Array.concat(SummaryMajor,getResult("Major", 0));
			SummaryMinor=Array.concat(SummaryMinor,getResult("Minor", 0));
			SummaryAngle=Array.concat(SummaryAngle,getResult("Angle", 0));
			SummaryCirc=Array.concat(SummaryCirc,getResult("Circ.", 0));
			SummaryAR=Array.concat(SummaryAR,getResult("AR", 0));
			SummaryRound=Array.concat(SummaryRound,getResult("Round", 0));
			SummarySolidity=Array.concat(SummarySolidity,getResult("Solidity", 0));
		} //close if only 1 colonie detected
		else { //if more than one colonie detected - get summary data
			for (ad=(nResults-4); ad<nResults; ad++){ //loop 18
				SummaryPic=Array.concat(SummaryPic,nameshort);//add crop picture path in the area (to open them later)
				SummaryLabel=Array.concat(SummaryLabel,getResultString("Label", ad));
				SummaryArea=Array.concat(SummaryArea,getResult("Area", ad));
				SummaryMean=Array.concat(SummaryMean,getResult("Mean", ad));
				SummaryMin=Array.concat(SummaryMin,getResult("Min", ad));
				SummaryMax=Array.concat(SummaryMax,getResult("Max", ad));
				SummaryStdDev=Array.concat(SummaryStdDev,getResult("StdDev", ad));
				SummaryMode=Array.concat(SummaryMode,getResult("Mode", ad));
				//SummaryFeret=Array.concat(SummaryFeret,getResult("Feret",ad));
				//SummaryFeretX=Array.concat(SummaryFeretX,getResult("FeretX",ad));
				//SummaryFeretY=Array.concat(SummaryFeretY,getResult("FeretY",ad));
				//SummaryFeretAngle=Array.concat(SummaryFeretAngle,getResult("FeretAngle",ad));
				//SummaryMinFeret=Array.concat(SummaryMinFeret,getResult("MinFeret",ad));
				//SummaryX=Array.concat(SummaryX,getResult("X", ad));
				//SummaryY=Array.concat(SummaryY,getResult("Y", ad));
				SummaryMajor=Array.concat(SummaryMajor,getResult("Major", ad));
				SummaryMinor=Array.concat(SummaryMinor,getResult("Minor", ad));
				SummaryAngle=Array.concat(SummaryAngle,getResult("Angle", ad));
				SummaryCirc=Array.concat(SummaryCirc,getResult("Circ.", ad));
				SummaryAR=Array.concat(SummaryAR,getResult("AR", ad));
				SummaryRound=Array.concat(SummaryRound,getResult("Round", ad));
				SummarySolidity=Array.concat(SummarySolidity,getResult("Solidity", ad));
			}//close loop18
		} //if more than one colonie detected- get summary
		/*
		for (aw = 0; aw < Overlay.size; aw++) {
			Overlay.activateSelection(aw);
			if (Roi.getGroup()!=5) Overlay.removeSelection(aw);
		}
		*/
//		run("To ROI Manager");

//		Overlay.flatten;
//		saveAs("jpg",DetectDir+nameshort+"_Detection.jpg");//save scale pic
		
		
	}//if more than one colonie detected

	if (nResults==0){ //if "no colonie detected"
	//print("roi only 1"); 	
		ResultsPic=Array.concat(ResultsPic,nameshort);//add crop picture path in the area (to open them later)
		RemovePic=Array.concat(RemovePic,nameshort);
		ResultsID=Array.concat(ResultsID,"No colonies");
		ResultsArea=Array.concat(ResultsArea,"NA");
		ResultsMean=Array.concat(ResultsMean,"NA");
		ResultsStdDev=Array.concat(ResultsStdDev,"NA");
		ResultsMode=Array.concat(ResultsMode,"NA");
		ResultsMin=Array.concat(ResultsMin,"NA");
		ResultsMax=Array.concat(ResultsMax,"NA");
		ResultsX=Array.concat(ResultsX,"NA");
		ResultsY=Array.concat(ResultsY,"NA");
		ResultsMajor=Array.concat(ResultsMajor,"NA");
		ResultsMinor=Array.concat(ResultsMinor,"NA");
		ResultsAngle=Array.concat(ResultsAngle,"NA");
		//ResultFeret=Array.concat(ResultFeret,"NA");
		//ResultFeretX=Array.concat(ResultFeretX,"NA");
		//ResultFeretY=Array.concat(ResultFeretY,"NA");			
		//ResultFeretAngle=Array.concat(ResultFeretAngle,"NA");
		//ResultMinFeret=Array.concat(ResultMinFeret,"NA");
		ResultsCirc=Array.concat(ResultsCirc,"NA");
		ResultsAR=Array.concat(ResultsAR,"NA");
		ResultsRound=Array.concat(ResultsRound,"NA");
		ResultsSolidity=Array.concat(ResultsSolidity,"NA");
	//fill summary	
		SummaryPic=Array.concat(SummaryPic,nameshort);//add crop picture path in the area (to open them later)
		SummaryLabel=Array.concat(SummaryLabel,"No colonies");
		SummaryArea=Array.concat(SummaryArea,"NA");
		SummaryMean=Array.concat(SummaryMean,"NA");
		SummaryMin=Array.concat(SummaryMin,"NA");
		SummaryStdDev=Array.concat(SummaryStdDev,"NA");
		SummaryMode=Array.concat(SummaryMode,"NA");
		SummaryMax=Array.concat(SummaryMax,"NA");
		//SummaryX=Array.concat(SummaryX,"NA");
		//SummaryY=Array.concat(SummaryY,"NA");
		SummaryMajor=Array.concat(SummaryMajor,"NA");
		SummaryMinor=Array.concat(SummaryMinor,"NA");
		SummaryAngle=Array.concat(SummaryAngle,"NA");
		//SummaryFeret=Array.concat(SummaryFeret,"NA");
		//SummaryFeretX=Array.concat(SummaryFeretX,"NA");
		//SummaryFeretY=Array.concat(SummaryFeretY,"NA");
		//SummaryFeretAngle=Array.concat(SummaryFeretAngle,"NA");
		//SummaryMinFeret=Array.concat(SummaryMinFeret,"NA");
		SummaryCirc=Array.concat(SummaryCirc,"NA");
		SummaryAR=Array.concat(SummaryAR,"NA");
		SummaryRound=Array.concat(SummaryRound,"NA");
		SummarySolidity=Array.concat(SummarySolidity,"NA");
		//setFont("SansSerif" , 40, "antialiased");
		Overlay.hide;
		setFont("SansSerif" , 40, "bold");
  		setColor(255, 0, 0);
		drawString("!!  No Colony detected !!", 10, 40);
		roiManager("reset");	
	} //close "if no colonie detected
//	Overlay.show;
		if (Overlay.size!=0){
			Overlay.clear;
			if (roiManager("count")!=0) {//add if roi manager is not empty 26/04
				run("From ROI Manager");
				Overlay.drawLabels(true);
				Overlay.flatten;
			}


		}
		

//		roiManager("Show All");
//		FontCol=(getWidth()/100);
//				roiManager("Show All");
//		run("Labels...", "color=white font=20 show");
//		run("Flatten");
//		FontCol=toUnscaled(FontCol);
//		run("Labels...", "color=white font="+FontCol+" show");
//		run("Flatten");
//		DetectPic=getImageID();
//			waitForUser;
	//roiManager("Show All");// I moved those line up 30/10/2021
	//run("Flatten");// I moved those line up 30/10/2021
//	selectImage(DetectPic);
//saveAs("jpg", "/Users/aljulien/Desktop/test_ColonyDetect.jpg");
//waitForUser;

	saveAs("jpg", DetectDir+nameshort+ "_ColonyDetect.jpg");//save scale pic
	
	/**rename Roi with colonie names (caution: this renaming part could make the table incomplete) **
	if (nResults>0){//if there are some ROI
		nRoi = roiManager("count");
		for (ab = 0; ab < (nRoi); ab++) { //loop 16
   			roiManager("select", ab);
    		//RoiManager.setGroup(0);
			//RoiManager.setPosition(0);
			//roiManager("Set Line Width", 0);
    		RoiNewName="c"+(ab+1);
    		roiManager("rename",RoiNewName);
		} //close loop 16
		pathROI=RoiDir+nameshort+"_RoiSet.zip"; //define the ROI pathway (for saving detection)
		roiManager("Save", pathROI); //save ROI selections
		roiManager("reset"); //clear roi manager
	}//close if there are some ROI
	*/
	run("Clear Results"); //clear results table
//	setBatchMode("show");
	roiManager("reset");
	saveAs("results", ResultsDir+"Data.csv");
	close("*");// close all opened images
	
	
if (AnalysisMode=="Auto"){
	Table.create("Data");
	Table.setColumn("Picture", AnalysedFile);
	Table.setColumn("Scale (pixels/mm)", ScaleArray);
	Table.setColumn("Original pic - Picture Width (pixels)", PicWidthArray);
	Table.setColumn("Original pic - Picture Height (pixels)", PicHeightArray);
	Table.setColumn("Original pic - Calibration ring detection thresholding - lower threshold", lowerThreshold);
	Table.setColumn("Original pic - Calibration ring detection thresholding - upper threshold", upperThreshold);
	Table.setColumn("Original pic - Big Calib. ring - X coordinate (pixels)", CenterXbigArray);
	Table.setColumn("Original pic - Big Calib. ring - Y coordinate (pixels)", CenterYbigArray);
//	Table.setColumn("Original pic - Big Calib. ring - Mesured Perimeter (pixels)", CalibPerimBigArray);
//	Table.setColumn("Original pic - Big Calib. ring - Calculated Radious (pixels)", CalibRadiusBigArray);
//	Table.setColumn("Original pic - Small Calib. ring - X coordinate (pixels)", CenterXsmallArray);
//	Table.setColumn("Original pic - Small Calib. ring - Y coordinate (pixels)", CenterYsmallArray);
//	Table.setColumn("Original pic - Small Calib. ring - Mesured Perimeter (pixels)", CalibPerimSmallArray);
	Table.setColumn("Original pic - Distance in between calib. rings (pixels)", lengthBigtoSmallArray);
//	Table.setColumn("Original pic - Detected angle (Radian)", AlphaArray);
//	Table.setColumn("Original pic - Detected angle (Degres)", AlphaDegArray);
	Table.setColumn("Original pic - Angle Correction (Degres)", AlphaDeltaArray);
//	if (AnalysisOnPetriOnly=="Petri only") {
	Table.setColumn("Cropped Pic - Big Calib. ring - X coordinate (pixels)", NewCenterXArray);
	Table.setColumn("Cropped Pic - Big Calib. ring - Y coordinate (pixels)", NewCenterYArray);
	Table.setColumn("Cropped Pic - Picture Width (pixels)", CropPicWidthArray);
	Table.setColumn("Cropped Pic - Picture Height (pixels)", CropPicHeightArray);
	if (WhiteBalance==true){
		Table.setColumn("White Blance - R channel - correction function ", R_fit_name_Array);
		Table.setColumn("White Blance - G channel - correction function ", G_fit_name_Array);
		Table.setColumn("White Blance - B channel - correction function ", B_fit_name_Array);
		Table.setColumn("White Blance - R channel - correction equation ", R_fit_MacroCode_Array);
		Table.setColumn("White Blance - G channel - correction equation ", G_fit_MacroCode_Array);
		Table.setColumn("White Blance - B channel - correction equation ", B_fit_MacroCode_Array);
	}
//	}
	saveAs("results", ResultsDir+"Data.csv");
	run("Close");
}

Table.create("NonAnalysed");
Table.setColumn("NonAnalysed", NonAnalysed);
saveAs("results", ResultsDir+"NonAnalysed.csv");
run("Close");

 //create a result table
Table.create("Detailed_Results");
Table.setColumn("Analysed Picture", ResultsPic);
Table.setColumn("Colonie ID", ResultsID);
Table.setColumn("Area (mm2)", ResultsArea);
Table.setColumn("Mean Grey", ResultsMean);
Table.setColumn("Modal Grey", ResultsMode);
Table.setColumn("Min Grey", ResultsMin);
Table.setColumn("Max Grey", ResultsMax);
Table.setColumn("StdDev Grey", ResultsStdDev);
Table.setColumn("X coordinate",ResultsX);
Table.setColumn("Y coordinate",ResultsY);
Table.setColumn("Fit ellipse - max diameter",ResultsMajor);
Table.setColumn("Fit ellipse - min diameter",ResultsMinor);
Table.setColumn("Fit ellipse - angle",ResultsAngle);
Table.setColumn("Circularity - (1 is round/0 is a line) ",ResultsCirc);
Table.setColumn("Aspect ratio",ResultsAR);
Table.setColumn("Roundness",ResultsRound);
Table.setColumn("Solidity",ResultsSolidity);
//Table.setColumn("Feret",ResultFeret);
//Table.setColumn("Feret x coordinate",ResultFeretX);
//Table.setColumn("Feret y coordinate",ResultFeretY);
//Table.setColumn("Feret angle",ResultFeretAngle);
//Table.setColumn("Min Feret diameter",ResultMinFeret);
selectWindow("Detailed_Results");
saveAs("results", ResultsDir+"Detailed_Results.csv");
run("Close");

//save summary table
Table.create("Summary_Results");
Table.setColumn("Analysed Picture", SummaryPic);
Table.setColumn("Summary type", SummaryLabel);
Table.setColumn("Area (mm2)", SummaryArea);
Table.setColumn("Mean Grey Value", SummaryMean);
Table.setColumn("Modal Grey Value (Most represented)", SummaryMode);
//Table.setColumn("X coordinate",SummaryX);
//Table.setColumn("Y coordinate",SummaryY);
//Table.setColumn("Fit ellipse - max diameter",SummaryMajor);
//Table.setColumn("Fit ellipse - min diameter",SummaryMinor);
//Table.setColumn("Fit ellipse - angle",SummaryAngle);
Table.setColumn("Min Grey Value",SummaryMin);
Table.setColumn("Min Grey Value",SummaryMax);
Table.setColumn("Standard dev",SummaryStdDev);
Table.setColumn("Circularity - (1 is round/0 is a line) ",SummaryCirc);
Table.setColumn("Aspect ratio",SummaryAR);
Table.setColumn("Roundness",SummaryRound);
Table.setColumn("Solidity",SummarySolidity);
//Table.setColumn("Feret",SummaryFeret);
//Table.setColumn("Feret x coordinate",SummaryFeretX);
//Table.setColumn("Feret y coordinate",SummaryFeretY);
//Table.setColumn("Feret angle",SummaryFeretAngle);
//Table.setColumn("Min Feret diameter",SummaryMinFeret);
selectWindow("Summary_Results");
saveAs("results", ResultsDir+"Summary.csv");
run("Close");

	
	print("\\Update:Colonies detection/analysis ("+(v+1)*(100/(AnalysedFileNb))+"%)"); //print the task progression in the log
}// close Loop 13
//waitForUser;
/** Process time (To activate/deactivate add/remove "//" in front of the 3 lines below) **/
Time=getTime();
TaskTime=Time-TaskTime;
if (TaskTime>1000){
	TaskTimeSec=TaskTime/1000;
	print("\\Update:Colonies detection/analysis - Done (execution time",TaskTimeSec,"sec)"); //print the task progression in the log
} else print("\\Update:Colonies detection/analysis - Done (execution time",TaskTime,"msec)"); //print the task progression in the log


/****************************************************
 * Display and save results 
****************************************************/

/*** 3. SAVE THE FINAL SUMMARY TO A NEW FOLDER NAMED "SUMMARY"*/
/*
if (AnalysisMode=="Auto"){
	Table.create("Data");
	Table.setColumn("Picture", AnalysedFile);
	Table.setColumn("Scale (pixels/mm)", ScaleArray);
	Table.setColumn("Original pic - Picture Width (pixels)", PicWidthArray);
	Table.setColumn("Original pic - Picture Height (pixels)", PicHeightArray);
	Table.setColumn("Original pic - Calibration ring detection thresholding - lower threshold", lowerThreshold);
	Table.setColumn("Original pic - Calibration ring detection thresholding - upper threshold", upperThreshold);
	Table.setColumn("Original pic - Big Calib. ring - X coordinate (pixels)", CenterXbigArray);
	Table.setColumn("Original pic - Big Calib. ring - Y coordinate (pixels)", CenterYbigArray);
//	Table.setColumn("Original pic - Big Calib. ring - Mesured Perimeter (pixels)", CalibPerimBigArray);
//	Table.setColumn("Original pic - Big Calib. ring - Calculated Radious (pixels)", CalibRadiusBigArray);
//	Table.setColumn("Original pic - Small Calib. ring - X coordinate (pixels)", CenterXsmallArray);
//	Table.setColumn("Original pic - Small Calib. ring - Y coordinate (pixels)", CenterYsmallArray);
//	Table.setColumn("Original pic - Small Calib. ring - Mesured Perimeter (pixels)", CalibPerimSmallArray);
	Table.setColumn("Original pic - Distance in between calib. rings (pixels)", lengthBigtoSmallArray);
//	Table.setColumn("Original pic - Detected angle (Radian)", AlphaArray);
//	Table.setColumn("Original pic - Detected angle (Degres)", AlphaDegArray);
	Table.setColumn("Original pic - Angle Correction (Degres)", AlphaDeltaArray);
//	if (AnalysisOnPetriOnly=="Petri only") {
	Table.setColumn("Cropped Pic - Big Calib. ring - X coordinate (pixels)", NewCenterXArray);
	Table.setColumn("Cropped Pic - Big Calib. ring - Y coordinate (pixels)", NewCenterYArray);
	Table.setColumn("Cropped Pic - Picture Width (pixels)", CropPicWidthArray);
	Table.setColumn("Cropped Pic - Picture Height (pixels)", CropPicHeightArray);
//	}
	saveAs("results", ResultsDir+"Data.csv");
	run("Close");
}

Table.create("NonAnalysed");
Table.setColumn("NonAnalysed", NonAnalysed);
saveAs("results", ResultsDir+"NonAnalysed.csv");
run("Close");

 //create a result table
Table.create("Detailed_Results");
Table.setColumn("Analysed Picture", ResultsPic);
Table.setColumn("Colonie ID", ResultsID);
Table.setColumn("Area (mm2)", ResultsArea);
Table.setColumn("Mean Grey", ResultsMean);
Table.setColumn("Modal Grey", ResultsMode);
Table.setColumn("Min Grey", ResultsMin);
Table.setColumn("Max Grey", ResultsMax);
Table.setColumn("StdDev Grey", ResultsStdDev);
Table.setColumn("X coordinate",ResultsX);
Table.setColumn("Y coordinate",ResultsY);
Table.setColumn("Fit ellipse - max diameter",ResultsMajor);
Table.setColumn("Fit ellipse - min diameter",ResultsMinor);
Table.setColumn("Fit ellipse - angle",ResultsAngle);
Table.setColumn("Circularity - (1 is round/0 is a line) ",ResultsCirc);
Table.setColumn("Aspect ratio",ResultsAR);
Table.setColumn("Roundness",ResultsRound);
Table.setColumn("Solidity",ResultsSolidity);
//Table.setColumn("Feret",ResultFeret);
//Table.setColumn("Feret x coordinate",ResultFeretX);
//Table.setColumn("Feret y coordinate",ResultFeretY);
//Table.setColumn("Feret angle",ResultFeretAngle);
//Table.setColumn("Min Feret diameter",ResultMinFeret);
selectWindow("Detailed_Results");
saveAs("results", ResultsDir+"Detailed_Results.csv");
run("Close");
*/
/***create a table to identify the No colonies and produce Detailed_Results_Detect_Only ***/

Raw_Deleted=newArray();//create an array to save the index of "no colonies in data collection arrays
Deleted_Length=ResultsID.length; //get the maximum number of data collections
for (ae = 0; ae < Deleted_Length  ; ae++) { //loop19 (for all lignes of colonies data collection arrays
	test=ResultsID[ae]; //get the label registered in resultID array, if it is a colonie it should be a number 1-infinite, of no colonie were detected it should be "no colonies"
	if (test=="No colonies"){ //if test=="No colonies"
		Raw_Deleted=Array.concat(Raw_Deleted,ae); //save the index number corresponding to a no colonie data
	}//close if test=="No colonies"
}

//Duplicate data collection arrays with only the relevant values

decision=false; //default switch for filling the "only detected "arrays
for (af =0; af <ResultsID.length  ; af++) { //loop20
	number=af; //index of the tested array value
	for (ag = 0; ag < Raw_Deleted.length; ag++) { //loop21 compared the tested index to all the list of "no colonie" index
		if (number== Raw_Deleted[ag])	{ //if the index of the tested array value correspond to a "no colonie" index
		decision=true; //make the decision "true"> will not be copied to the new array in the next if loop
		} //close if
	} //close loop21
	if (decision==false){ //if the tested index does not correspond to a "no colonie" index, save the data in "only detected arrays".
		ResultsPicOnly=Array.concat(ResultsPicOnly,ResultsPic[af]);
		ResultsIDOnly=Array.concat(ResultsIDOnly, ResultsID[af]); 	
		ResultsMeanOnly=Array.concat(ResultsMeanOnly, ResultsMean[af]); 
		ResultsModeOnly=Array.concat(ResultsModeOnly, ResultsMode[af]); 
		ResultsMinOnly=Array.concat(ResultsMinOnly, ResultsMin[af]);
		ResultsMaxOnly=Array.concat(ResultsMaxOnly, ResultsMax[af]);
		ResultsStdDevOnly=Array.concat(ResultsStdDevOnly, ResultsStdDev[af]);
		ResultsAreaOnly=Array.concat(ResultsAreaOnly, ResultsArea[af]); 
		ResultsXOnly=Array.concat(ResultsXOnly, ResultsX[af]); 
		ResultsYOnly=Array.concat(ResultsYOnly, ResultsY[af]); 
		ResultsAngleOnly=Array.concat(ResultsAngleOnly, ResultsAngle[af]); 
		ResultsMajorOnly=Array.concat(ResultsMajorOnly, ResultsMajor[af]);
		ResultsMinorOnly=Array.concat(ResultsMinorOnly, ResultsMinor[af]); 
		ResultsCircOnly=Array.concat(ResultsCircOnly, ResultsCirc[af]); 
		ResultsAROnly=Array.concat(ResultsAROnly, ResultsAR[af]); 
		ResultsRoundOnly=Array.concat(ResultsRoundOnly, ResultsRound[af]); 
		ResultsSolidityOnly=Array.concat(ResultsSolidityOnly, ResultsSolidity[af]); 
		//ResultFeretOnly=Array.concat(ResultFeretOnly, ResultFeret[af]); 
		//ResultFeretXOnly=Array.concat(ResultFeretXOnly, ResultFeretX[af]);
		//ResultFeretYOnly=Array.concat(ResultFeretYOnly,ResultFeretY[af]); 
		//ResultFeretAngleOnly=Array.concat(ResultFeretAngleOnly, ResultFeretAngle[af]);  
		//ResultMinFeretOnly=Array.concat(ResultMinFeretOnly, ResultMinFeret[af]);
	} //close if the tested index does not correspond to a "no colonie" index
	else decision=false; //if the tested index correspond to a "no colonie" index, reset decision switch to default value "false"
} //close loop20
			
Table.create("Detailed_Results_Detected_Only");
Table.setColumn("Analysed Picture", ResultsPicOnly);
Table.setColumn("Colonie ID", ResultsIDOnly);
Table.setColumn("Area (mm2)", ResultsAreaOnly);
Table.setColumn("Mean Grey", ResultsMeanOnly);
Table.setColumn("Modal Grey", ResultsModeOnly);
Table.setColumn("Min Grey", ResultsMinOnly);
Table.setColumn("Max Grey", ResultsMaxOnly);
Table.setColumn("StdDev Grey", ResultsStdDevOnly);
Table.setColumn("X coordinate",ResultsXOnly);
Table.setColumn("Y coordinate",ResultsYOnly);
Table.setColumn("Fit ellipse - max diameter",ResultsMajorOnly);
Table.setColumn("Fit ellipse - min diameter",ResultsMinorOnly);
Table.setColumn("Fit ellipse - angle",ResultsAngleOnly);
Table.setColumn("Circularity - (1 is round/0 is a line) ",ResultsCircOnly);
Table.setColumn("Aspect ratio",ResultsAROnly);
Table.setColumn("Roundness",ResultsRoundOnly);
Table.setColumn("Solidity",ResultsSolidityOnly);
//Table.setColumn("Feret",ResultFeretOnly);
//Table.setColumn("Feret x coordinate",ResultFeretXOnly);
//Table.setColumn("Feret y coordinate",ResultFeretYOnly);
//Table.setColumn("Feret angle",ResultFeretAngleOnly);
//Table.setColumn("Min Feret diameter",ResultMinFeretOnly);
selectWindow("Detailed_Results_Detected_Only");
saveAs("results", ResultsDir+"Detailed_Results_Detection_Only.csv");
run("Close");
/*
//save summary table
Table.create("Summary_Results");
Table.setColumn("Analysed Picture", SummaryPic);
Table.setColumn("Summary type", SummaryLabel);
Table.setColumn("Area (mm2)", SummaryArea);
Table.setColumn("Mean Grey Value", SummaryMean);
Table.setColumn("Modal Grey Value (Most represented)", SummaryMode);
//Table.setColumn("X coordinate",SummaryX);
//Table.setColumn("Y coordinate",SummaryY);
//Table.setColumn("Fit ellipse - max diameter",SummaryMajor);
//Table.setColumn("Fit ellipse - min diameter",SummaryMinor);
//Table.setColumn("Fit ellipse - angle",SummaryAngle);
Table.setColumn("Min Grey Value",SummaryMin);
Table.setColumn("Min Grey Value",SummaryMax);
Table.setColumn("Standard dev",SummaryStdDev);
Table.setColumn("Circularity - (1 is round/0 is a line) ",SummaryCirc);
Table.setColumn("Aspect ratio",SummaryAR);
Table.setColumn("Roundness",SummaryRound);
Table.setColumn("Solidity",SummarySolidity);
//Table.setColumn("Feret",SummaryFeret);
//Table.setColumn("Feret x coordinate",SummaryFeretX);
//Table.setColumn("Feret y coordinate",SummaryFeretY);
//Table.setColumn("Feret angle",SummaryFeretAngle);
//Table.setColumn("Min Feret diameter",SummaryMinFeret);
selectWindow("Summary_Results");
saveAs("results", ResultsDir+"Summary.csv");
run("Close");
*/

/*** create setting file ***/

if (watershedChoice==1) watershedSetting="Yes";
else watershedSetting="No";
if (WhiteBalance==1) WhiteBalanceSetting="Yes";
else WhiteBalanceSetting="No";
if (ScaleQCchoice==1) ScaleQCchoiceSetting="Yes";
else ScaleQCchoiceSetting="No";
if (HistoChoice==1) HistoChoiceSetting="Yes";
else HistoChoiceSetting="No";

nameSetting = "[Settings]";
f = nameSetting;
run("New... ", "name="+nameSetting+" type=Table");
//run("Text Window...", "name="+nameSetting+" width=72 height=8");
print(f, "Macro \"Colony Analysis\" version "+Version+".\n");
print(f, " - Date: "+DayNames[dayOfWeek]+" "+dayOfMonth+"-"+MonthNames[month]+"-"+year+"\n - Time: "+hour+":"+minute+":"+second);

print(f, "\n*****************************************************\n");
print(f, "**************** Macro Settings *********************\n");
print(f, "Selected detection method: "+AnalysisMode+".\n");
print(f, "Selected Colonie detection Method: "+ThresholdChoice+".\n");
print(f, "Watershelding option (resolves touching colonies): "+watershedSetting+".\n");
print(f, "White balance option: "+WhiteBalanceSetting+"\n");
print(f, "Saving a Scale quality control image: "+ScaleQCchoiceSetting+".\n");
print(f, "Performing Histogram analysis: "+HistoChoiceSetting+".\n");
if (HistoChoice==1) print(f, "(histogram analysis draw a feret diameter of each colonie and measure the mean gray value of each pixels along this line.)\n");

print(f, "\n*****************************************************\n");
print(f, "********** Guide Settings ***************\n");

if ((AnalysisMode=="Auto")||(AnalysisMode=="User defined based on 1st image")){
	print(f, "Selected guide version: "+guide+".\n");
	if (AnalysisMode=="Auto"){
		print(f, "Radius of the big detection ring compare the the image size. At least 1/"+MinCalibRing+".\n");
		print(f, "Calibration angle (angle in between big and small calibration ring) : "+AlphaGuide+" degres.\n");
		print(f, "Scale calibration known sized (distance in between big and small calibration ring) "+CalibScale+" mm.\n");
		if ((guide=="V5.1")||(guide=="V5.2")||(guide=="V5.3")){
			print(f, "Distance in between the point X and Y of the guide :"+CalibScaleUser+" mm.\n");
		}
	}
	else {
		if ((guide=="V5.1")||(guide=="V5.2")||(guide=="V5.3")){
			print(f, "Distance in between the point X and Y of the guide"+CalibScaleUser+".\n");
			ScaleNonAuto=CalibLenght/CalibScaleUser;
			print(f, "Images scales"+ScaleNonAuto+".\n");
		}
	}
}
else print(f, "No guide seleted.\n");

print(f, "Defined diameter of the petri dish cropping (mm): "+PetriSize+".\n");

print(f, "\n*****************************************************\n");
print(f, "********** Colonie Detection Settings ***************\n");
print(f, "Minimum expected colony diameter "+MinColPerim+" mm.\n");
print(f, "Minimum calculated colony area "+MinColSize+" mm2.\n");
print(f, "Minimum expected colony circularity "+CirMin+" mm.\n");
print(f, "Maximum expected colony circularity "+CirMax+" mm.\n");
print(f, "Selected Colonie detection Method: "+ThresholdChoice+".\n");

if ((ThresholdChoice=="HSB Method")||(ThresholdChoice=="All")) {
	print(f, "Colony detection mode: Based on the Hue,Saturation,Brightness values.\n	The rationale is to only detect all particules that are not match the guide \"blue\" color background.");
	print(f, "	- Minimum Hue thresholding value: "+minHue+".\n");
	print(f, "	- Maximum Hue thresholding value: "+maxHue+".\n");
	print(f, "	- Minimum Saturation thresholding value: "+maxSat+".\n"); 
	print(f, "	- Maximum Saturation thresholding value: "+maxSat+".\n");
	print(f, "	- Minimum Brightness thresholding value: "+minBright+".\n");
	print(f, "	- Maximum Brightness thresholding value: "+maxBright+".\n");	
}

if ((ThresholdChoice=="Ylab Method")||(ThresholdChoice=="All")) {
	print(f, "Colony detection mode: Based on the Hue,Saturation,Brightness values.\n	The rationale is to only detect all particules that are not match the guide \"blue\" color background.");
	print(f, "	- Minimum Hue thresholding value: "+ThresholdType_Ylab+".\n");	
}
	
if ((ThresholdChoice=="YCbCr Method")||(ThresholdChoice=="All")) {
	print(f, "Colony detection mode: Based on the Hue,Saturation,Brightness values.\n	The rationale is to only detect all particules that are not match the guide \"blue\" color background.");
	print(f, "	- Minimum Hue thresholding value: "+ThresholdType_YCbCr+".\n");	
}

//selectWindow("Settings");
saveAs("Results", AnalysisDir+ "Settings.txt");
run("Close");

/****************************************************
 * 13. Histogram analysis
****************************************************/


if (HistoChoice==1){
	
	
print("Histogram analysis (0%)");
//loop IN: LAST:ag21 Do not use n,l,x,y
ProgressionCount=0; //test
Progressiontotal=ResultsIDOnly.length;
setOption("ExpandableArrays",true);// necessary to clear the arrays without error
	//setBatchMode(false); //exit work in Bash mode so roi manager does not crash
//	if (AnalysisOnPetriOnly=="Petri only") {
		roilist=getFileList(RoiDetectDir); 
//		} else roilist=getFileList(RoiDir); 
	ArrayHistoDistance=newArray();//test
	ArrayHistoGV=newArray();//test
	ColNumber=newArray();
	ArrayHistPic=newArray();
	ArrayMainHistoDistance=newArray();//test
	ArrayMainHistoGV=newArray();//test
	ColMainNumber=newArray();
	ArrayMainHistPic=newArray();
//add the right counter for the % probably the roilist number *the roi total detected number (analsed only total colonie of OnlyResed arrays) 
	for (ah=0; ah<roilist.length; ah++) {//Loop 22 - for saved ROI file (correspond to all the images that havecolonies detected)
		
		RoiName=roilist[ah]; //get the Roi saved name
		PetriName=replace(RoiName, "_Detection_RoiSet.zip", ".tif"); //guess the name of the associated image (the petri crop)
		//print("RoiName:",RoiName," _ PetriName-",PetriName);
		open(PetriDir+PetriName); //open the corresponding petri crop image
		Overlay.clear;
//		if ((AnalysisMode=="User defined based on 1st image")||(AnalysisMode=="no Guide pics"))run("Set Scale...", "distance="+CalibLenght+" known="+CalibScaleUser+" unit=mm global"); //set scale version 3.24 unbugged 22/03/2022
		//picname=getTitle(); //get image title
		picname=File.nameWithoutExtension;
		run("Select None"); //make sure that there are no selection
		roiManager("Open",RoiDetectDir+roilist[ah]); //open the Roi files (change open(RoiDir+roilist[ah])to roiManager("Open",...)
		//table1 = "Histogram_"+picname; //define a title to create a temp table to collect histogram plot values.
  		//Table.create(table1);//create a temp table to collect histogram plot values.	
  		run("From ROI Manager");
  		roiManager("reset");
		nRoi2 = Overlay.size; //get the number of Roi already present in the roi manager.
		for (ai = 0; ai < nRoi2; ai++) { //loop23 for all the roi value up to now (nRoi2)
			//important - ah represent the analysed image number - ai correspond to the currently analysed colonie
  			ProgressionCount++; //test
//  			Overlay.measure;
  			Overlay.activateSelection(ai);
//  			roiManager("select", ai); //select a roi from the manager - 
//    		List.setMeasurements;
//			roiManager("measure");
    		ID=getImageID();
//    		selectWindow("Results");
// 			x1 = List.getValue("FeretX");
// 			Overlay.activateSelection(0);
			x1 =getValue("FeretX");
// 			x1 =Table.get("FeretX", ai);
//  			y1 = List.getValue("FeretY");
//  			y1 = Table.get("FeretY", ai);
  			y1 =getValue("FeretY");
//  			length = List.getValue("Feret");
  			length= getValue("Feret");


  			toUnscaled(length);
  			
//  			degrees = List.getValue("FeretAngle");
//  			degrees= Table.get("FeretAngle", ai);
  			degrees= getValue("FeretAngle");
//  print (x1,"_",y1, "_",degrees,"_", length);//here
  			if (degrees>90) degrees -= 180; 
  			angle = degrees*PI/180;
  			x2 = x1 + cos(angle)*length;
  			y2 = y1 - sin(angle)*length;
  			//roiManager("Set Color", "red");
			//roiManager("Set Line Width", 0);
			//print(x1, y1, x2, y2);//test
			selectImage(ID);
  			makeLine(x1, y1, x2, y2);
//  			waitForUser;

  			Overlay.addSelection;
//  		roiManager("add");
  			run("Plot Profile");
  			Plot.getValues(x, y);
  			if (SaveHistoPLotChoice=="Yes") saveAs("PNG", HistoPlotDir+picname+"_colonie-"+(ai+1)+"_Histogram.png");
//			saveAs("PNG", HistoPlotDir+picname+"_colonie-"+(ai+1)+"_Histogram.png"); //to reactivate after test
			close(); //to reactivate after test
//     		Table.showArrays("Histo",x,y); //maybe having all the values in one big table?
//			HistoX= Table.getColumn("x", "Histo");
//			HistoY= Table.getColumn("y", "Histo");
			ArrayHistoDistance=Array.concat(ArrayHistoDistance,x);
			ArrayMainHistoDistance=Array.concat(ArrayMainHistoDistance,x);
			ArrayHistoGV=Array.concat(ArrayHistoGV,y);
			ArrayMainHistoGV=Array.concat(ArrayMainHistoGV,y);
//			ArrayHistoDistance=Array.concat(ArrayHistoDistance,HistoX);
//			ArrayMainHistoDistance=Array.concat(ArrayMainHistoDistance,HistoX);
//			ArrayHistoGV=Array.concat(ArrayHistoGV,HistoY);
//			ArrayMainHistoGV=Array.concat(ArrayMainHistoGV,HistoY);
//			for (al = 0; al < HistoX.length; al++) {//loop26
			for (al = 0; al < x.length; al++) {//
				ColNumber=Array.concat(ColNumber,(ai+1));
				ColMainNumber=Array.concat(ColMainNumber,(ai+1));
				ArrayHistPic=Array.concat(ArrayHistPic,picname);
				ArrayMainHistPic=Array.concat(ArrayMainHistPic,picname);
			}//close loop 26
			print("\\Update:Histogram analysis ("+(ProgressionCount)*(100/(Progressiontotal))+"%)"); //print the task progression in the log
		} //close loop23

		TableName=picname+"_Histogram";
		Table.create(TableName);
		Table.setColumn("Analysed Picture", ArrayHistPic);
		Table.setColumn("Colonie Number", ColNumber);
		Table.setColumn("Feret Diameter position (pixels)", ArrayHistoDistance);
		Table.setColumn("Grey Value", ArrayHistoGV);
		selectWindow(TableName);

 		saveAs("results",HistoResultsDir+picname+"_Histogram.csv"); //save (I could also save thath in the results folders if needed)
 		run("Close");
		//loop to rename the new ROIs 
//		nRoi3 = roiManager('count'); //get the latest roi number
		nRoi3 = Overlay.size; //get the latest roi number
		incrementRoi=1;//used to start the renaming at 1
		for (aj = (nRoi2); aj < (nRoi3); aj++) { //loop24 for all the new added roi (should be the feret lines)
    		Overlay.activateSelection(aj);
//    		roiManager("select", aj);
			RoiNewName="Feret_c"+(incrementRoi);
			run("Properties... ", "name="+RoiNewName+" position=none group=16 width=1 fill=none");
//    		RoiManager.setGroup(16);
//			RoiManager.setPosition(0);
//			roiManager("Set Line Width", 0);
//    		roiManager("rename",RoiNewName);
    		incrementRoi++;
		} //close loop 24
		//roiManager("Show All");
	roiManager("reset");//26/04
		run("To ROI Manager");
//		Overlay.flatten;
		
		roiManager("show all without labels"); //select all roi without having the labels
		run("Flatten");
		//roiManager("Save",HistoDir+picname+"_colonie-"+i+"_Histogram.zip"); //save ROI selections
//		if (AnalysisOnPetriOnly=="Petri only") {

		roiManager("Save",RoiDetectDir+RoiName); //save ROI selections
//		} else roiManager("Save",RoiDir+RoiName); //save ROI selections
		
		//if (SaveHistochoice==1) saveAs("jpg",HistoDir+picname+"_Histogram.jpg"); //save	
		saveAs("jpg",HistoOverlayDir+picname+"_Histogram.jpg"); //save	
		OpenWin=getList("window.titles");
		for (ak = 0; ak < OpenWin.length; ak++) { //loop 25 - close all non image windows except the log
			if (OpenWin[ak]!="Log"){ //if the open window is the log
				selectWindow(OpenWin[ak]);
				run("Close");
			} //close if the open window is the log
		}//close loop25
		roiManager("reset");
		close("*");	
		ArrayHistoDistance=newArray();//reset array
		ArrayHistoGV=newArray();//reset array
		ColNumber=newArray();//reset array
		ArrayHistPic=newArray();//reset array
	}//close loop 22
	//setBatchMode(true); //re-enter the bash mode

	//create and save a table with the resutls of all the picture in one single CSV files
	TableName2="Histogram_Results";
	Table.create(TableName2);
	Table.setColumn("Analysed Picture", ArrayMainHistPic);
	Table.setColumn("Colonie Number", ColMainNumber);
	Table.setColumn("Feret Diameter position (pixels)", ArrayMainHistoDistance);
	Table.setColumn("Grey Value", ArrayMainHistoGV);
	selectWindow(TableName2);
	
	saveAs("results",HistoDir+"Histogram_Results.csv"); //save the results of all the plates in one file
	run("Close");
}//close if histogram choice is selected


/** Process time (To activate/deactivate add/remove "//" in front of the 3 lines below) **/
Time=getTime();
TaskTime=Time-TaskTime;
if (TaskTime>1000){
	TaskTimeSec=TaskTime/1000;
	print("\\Update:Histogram analysis - Done (execution time",TaskTimeSec,"sec)"); //print the task progression in the log
} else print("\\Update:Histogram analysis - Done (execution time",TaskTime,"msec)"); //print the task progression in the log


/****************************************************
 * Display error message with non analysed pictures
****************************************************

if (NonAnalysedPic.length>0) {
	Dialog.create("Macro info/settings"); 
  	Dialog.addMessage("!!! The following images were not analysed !!!");
  	Dialog.addMessage("!!! Detection of the Calibration circle failed !!!");
	for (ao = 0; ao < NonAnalysedPic.length; ao++) Dialog.addMessage(NonAnalysedPic[ao]);
	Dialog.show();
}


****************************************************
 * end Macro
****************************************************/

Time=getTime();
FullTime=StartTime-Time;
print("Colony Analysis Macro Completed. (completed in ",FullTime,"ms)");
OpenWin=getList("window.titles");
for (zz = 0; zz < OpenWin.length; zz++) { //last loop- close all non image windows except the log
	if (OpenWin[zz]!="Log"){ //if the open window is the log
		selectWindow(OpenWin[zz]);
		run("Close");
	}//close if the open window is the log
}//close last loop
//beep();



} //end macro
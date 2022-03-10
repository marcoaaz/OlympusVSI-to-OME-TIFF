# OlympusVSI-to-OME-TIFF
Scripted (MatLab) Bioformat conversion of *.vsi files (data tree) to *.ome.tiff. As you probably know the Olympus *.vsi comes with your data (pyramids), a Label, an Overview, and a Macro image to reference you in the slide, which I think causes a mess with the -pyramid-levels and -scale arguments. So, I preferred to first extrude the *.vsi pyramid in flat images (intermediate folder) and then concatenate them (bfconvert, 2nd time)   

The script requires modifying the Java JDK MaxHeapSize to successfully convert 10X or 20X z-stack image pyramids. It replaces the need to do Image>Combine Frames (as Z-stack) in Olympus software (AWS or Olyvia).


![script snapshot](https://user-images.githubusercontent.com/61703106/156726824-ffddb024-e0fb-458a-94d7-7be46b6a5a06.png)

If using this script in your research papers, please cite the Bioformat community (links in the code), MatLab, and the author (Marco Andres Acevedo Zamora). A video can be provided showing how to use the code.

Enjoy.

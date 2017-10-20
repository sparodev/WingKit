// WaveTrimming.cpp : Defines the entry point for the console application.
// This is the main program file for the trimming logic based on amplitude
// data from an audio recording.  The program accepts a text file containting
// amplitude data from an audio recording.  The amplitude data is the maximum
// data value for each chunk of sound data.  The chunk size is typically 1024.
// Therefore, with respect to the recorded sound data, the amplitude data is an
// array of size 1/chunkSize with respect to the full sound data array.  The
// program then passes the amplitude data to a smoothing funciton.  The
// smoothed amplitude data is then passed to processing functions, wherein the
// points for trimming are calculated.  Implicitly, these points mark the
// boundary within which the sound data of interest lies.  In this case, this
// is the exhalation of a user through the sensor.
// the calculated trimming points is the sound data of interest, all other data
// can be discarded.  The trimming points are returned in a vector of two
// elements.  Data within the first and second element is the target data.
// usage WaveTrimming.exe <amplitude_data_file>
// Author: Rajeev Mehrotra (raj@sparolabs.com)
//

#include <iostream>
#include <vector>
#include <string>
#include <sstream>
#include <math.h>


#include "amparray.h"
#include "trimmingTerminalPoints.h"
#include "wavdata.h"

using namespace std;

// Outlines the process of the program.  This function accepts an amplitude data
// array (a vector of char*) then calls functions on the processing pathway to
// get from the input vector to the trimming points.  First the amplitude data
// is smoothed.  Next, using the calculated argmax of the data, the 'start'
// index of  the trimming points (the first timewise trimming point) is
// calculated from the amplitude data.  This point is then rescaled up to the
// size of the original sound data.  The same operations are performed to
// determine the 'end' point of the trimming.  These points are then pushed
// onto a vector and the vector is returned.
vector<int> getTrimmingPoints(vector<char*> ampData, int threshold = 100) {
	int chunkSize = 1024;
	vector<int> trimmingPoints;
	vector<char *> smoothedAmpData = smoothAmpData(ampData, threshold);

	int maxAmpInd = argMaxAmp(smoothedAmpData);

	int startIndex = determineStartIndex(smoothedAmpData, maxAmpInd);
	int sndStartPt = determineSndStartPoint(startIndex, smoothedAmpData,
                                            chunkSize);

	int endIndex = determineEndIndex(smoothedAmpData, maxAmpInd);
	int sndEndPt = determineSndEndPoint(endIndex, smoothedAmpData, chunkSize);

	trimmingPoints.push_back(sndStartPt);
	trimmingPoints.push_back(sndEndPt);
	return trimmingPoints;
}

// Main function of the program.  First parses the arguments passed to the
// program.  Creates an array of amplitude data read from a specified file, then
// passes this amplitude data to the function that calls the processing cascade.
int trim(string inputFileName, string outputFileName) {
	waveFileStruct waveFile;
	try {
		waveFile = readWaveData(inputFileName, true, true);
	}
	catch (const invalid_argument& e) {
		return 1;
	}
	vector<char*> rawAmpData = constructAmpData(waveFile);
	vector <int> soundTrimmingPoints = getTrimmingPoints(rawAmpData);
	waveFileStruct toBeTrimmed = readWaveData(inputFileName, false);
	writeWaveFile(outputFileName, toBeTrimmed, soundTrimmingPoints);
	return 0;
}

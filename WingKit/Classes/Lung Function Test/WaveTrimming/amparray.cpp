// The source file defining the functions that parse and perform caclulations
// based on the amplitude data.
// Author: Rajeev mehrotra
//

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <algorithm>

#include "amparray.h"

using namespace std;

// Read amplitude data from a file.  This function accepts the name of a text
// file to be read for ampitude data.  The input file should contain an
// amplitude data point on each line, one amplitude data point per line.
// The function creates and returns a vector containing the parsed amplitude
// data.
vector<char*> readAmpDataFile(string & fname){
	string line;
	vector< char *> ampData;
	ifstream myfile(fname);
	if (myfile.is_open()){
		while (getline(myfile, line)){
			char * cstr = new char[line.length() + 1];
			cstr[line.size()] = 0;
			memcpy(cstr, line.c_str(), line.size());
			ampData.push_back(cstr);
		}
		myfile.close();
	}
	return ampData;
}

// Smoothes the amplitude data.  This function iterates over the input amplitude
// data, setting elements that fall beneath a passed threshold to 0, unaltering
// elements that are greater than the threshold.  The smoothed amplitude data
// is a vector of char * that contains either 0 if the corresponding element
// of the amplitude data is beneath the threshold, or a copy of that value
// otherwise.
vector<char *> smoothAmpData(vector<char *> rawAmpData, int threshold){
	vector<char *> smoothedAmp(rawAmpData.size());
	for (unsigned int i = 0; i < rawAmpData.size(); ++i){
		int pt = atoi(rawAmpData[i]);
		if (pt > threshold){
			smoothedAmp[i] = rawAmpData[i];
		}
		else{
			string zero = to_string(0);
			char* cstr = new char[zero.length() + 1];
			cstr[zero.size()] = 0;
			memcpy(cstr, zero.c_str(), zero.size());
			smoothedAmp[i] = cstr;
		}
	}
	return smoothedAmp;
}

// Calculates and returns the index of the element of the input array that is
// the maximum value of the array.
int argMaxAmp(vector<char *> arr){
	int maxVal = atoi(arr[0]);
	int maxInd = 0;
	for (unsigned int i = 1; i < arr.size(); i++){
		int val = atoi(arr[i]);
		if (val > maxVal){
			maxVal = val;
			maxInd = i;
		}
	}
	return maxInd;
}

// Determines the 'start' point of the trimming.  Note that the data that falls
// between the start and end point of the trimming is the data of interest, and
// therefore is NOT discarded.  The 'start' and 'end' corresponds to the start
// and end of the target data area.  This function works by iterating backwards,
// starting from the point of maximum value of the array towards the first
// element of the array.  If the iteration finds that the point preceeding the
// point being currently inspected is larger, it returns the current point being
// inspected.  The logic here is that any jump or blip before the maximum point
// of the amplitude array is noise, and therefore any data leading up to that
// first found noise location can be trimmed. This function returns a 2D point
// of the start trimming point.  The xcoordinate and ycoordinate refer to the
// index and value (respectively) of the trimming start point.
xyPoint determineStartPoint(vector<char *> smoothedAmpData, int maxInd){
	xyPoint a;
	int j = maxInd;
	for (; j > 0 ; j--){
		int post = atoi(smoothedAmpData[j - 1]);
		int now = atoi(smoothedAmpData[j]);
		if (post > now){
			break;
		}
	}
	j = max(0, j);
	a.xCoord = j;
	a.yCoord = atoi(smoothedAmpData[j]);
	return a;
}

// Determines the 'start' point of the trimming.  Note that the data that falls
// between the start and end point of the trimming is the data of interest, and
// therefore is NOT discarded.  The 'start' and 'end' corresponds to the start
// and end of the target data area.  This function works by iterating backwards,
// starting from the point of maximum value of the array towards the first
// element of the array.  If the iteration finds that the point preceeding the
// point being currently inspected is larger, it returns the current point being
// inspected.  The logic here is that any jump or blip before the maximum point
// of the amplitude array is noise, and therefore any data leading up to that
// first found noise location can be trimmed. This function returns an integer
// that corresponds to the index of the trimming start point.
int determineStartIndex(vector<char *> smoothedAmpData, int maxInd){
	xyPoint startPoint = determineStartPoint(smoothedAmpData, maxInd);
	return startPoint.xCoord;
}

// Determines the 'end' point of the trimming.  Note that the data that falls
// between this point and the 'start' point of the trimming is the data of
// interest, therefore, data outside of these points is what is trimmed.  The
// 'start' and 'end' corresponds to the start and end of the target data area.
// This function works by iterating forwards, starting from the point of maximum
// value and iterating towards the last point of the data.  The function uses a
// percent paramter to calculate the threshold beneath which any data is
// considered 'silence'. The logic is that if a given number of consecutive
// points, specified by the 'allowedSilence' parameter, fall beneath the
// threshold (a percentage of the maximum amplitude data point), then the
// target data area is considered over, and that point is returned.  This
// function returns an xyPoint, a 2D point where the x coordinate is the index
// of the trimming end point, and the y coordinate is the amplitude value of the
// trimming end point.
xyPoint determineEndPoint(vector<char *> smoothedAmpData, int maxInd,
							double percent, int allowedSilence){
	int maxVal = atoi(smoothedAmpData[maxInd]);
	double threshold = percent * maxVal;
	int silentPts = 0;
	int i = maxInd;
	for (; i < smoothedAmpData.size(); i++){
		bool silent = atoi(smoothedAmpData[i]) < threshold;
		if (silent){
			silentPts += 1;
			if (silentPts >= allowedSilence){
				break;
			}
		}
		else{
			silentPts = 0;
		}
	}
	i = min(i, (int) (smoothedAmpData.size() - 1));
	xyPoint a;
	a.xCoord = i;
	a.yCoord = atoi(smoothedAmpData[i]);
	return a;
}

// Determines the 'end' point of the trimming.  Note that the data that falls
// between this point and the 'start' point of the trimming is the data of
// interest, therefore, data outside of these points is what is trimmed.  The
// 'start' and 'end' corresponds to the start and end of the target data area.
// This function works by iterating forwards, starting from the point of maximum
// value and iterating towards the last point of the data.  The function uses a
// percent paramter to calculate the threshold beneath which any data is
// considered 'silence'. The logic is that if a given number of consecutive
// points, specified by the 'allowedSilence' parameter, fall beneath the
// threshold (a percentage of the maximum amplitude data point), then the
// target data area is considered over, and that point is returned.  This
// function returns an integer index of the trimming end point.
int determineEndIndex(vector<char *> smoothedAmpData, int maxInd,
	double percent, int allowedSilence){
	xyPoint endPoint = determineEndPoint(smoothedAmpData, maxInd, percent,
                                         allowedSilence);
	return endPoint.xCoord;
}

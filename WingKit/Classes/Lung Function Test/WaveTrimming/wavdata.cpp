#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <algorithm>
#include "wavdata.h"

using namespace std;

// This function reads in a wave file.  In particular, it opens an input wave
// file and first extracts the information stored in the header (format,
// bitrate, etc.).  Then it parses the actual recorded audio and stores
// that data in one of two ways.  If 'initial_read' is true, the recorded
// data is stored in a vector of shorts.  This is later used to reverse
// engineer the amplitude data (the maximum data point at each chunk of the
// sound data array) which is then used to determine points by which to trim
// the wave file.  If 'initial_read is false, then the data is stored into a
// char * array, which makes it easier to be written back into a new wave
// file.  The function returns a waveFileStruct which is a struct that holds
// the header info as well as the stored data.
waveFileStruct readWaveData(string fname, bool initial_read, bool debug) {
	ifstream ifs(fname, ifstream::binary);
	waveFileStruct wav_file = {};
	if (ifs.is_open())
	{
		/*Read Header Info*/
		ifs.read(wav_file.chunkID, 4);

		ifs.read(reinterpret_cast<char*>(&wav_file.fileSize), 4);

        ifs.read(wav_file.format, 4);

		ifs.read(wav_file.subChunk1ID, 4);

		ifs.read(reinterpret_cast<char*>(&wav_file.subChunk1Size), 4);

		ifs.read(reinterpret_cast<char*>(&wav_file.audioFormat), 2);

		ifs.read(reinterpret_cast<char*>(&wav_file.numChannels), 2);

		ifs.read(reinterpret_cast<char*>(&wav_file.sampleRate), 4);

		ifs.read(reinterpret_cast<char*>(&wav_file.byteRate), 4);

		ifs.read(reinterpret_cast<char*>(&wav_file.blockAlign), 2);

		ifs.read(reinterpret_cast<char*>(&wav_file.bitsPerSample), 2);

		ifs.read(wav_file.subChunk3ID, 4);

		ifs.read(reinterpret_cast<char*>(&wav_file.subChunk3Size), 4);

		//Some wave recordings contain filler data.  If this one does, skip it
		//and update the data being read in
		if (string(wav_file.subChunk3ID).compare("FLLR") == 0){
			wav_file.fileSize -= wav_file.subChunk3Size;
			ifs.seekg(wav_file.subChunk3Size + ifs.tellg());
			ifs.read(wav_file.subChunk3ID, 4);
			ifs.read(reinterpret_cast<char*>(&wav_file.subChunk3Size), 4);
		}

		// Check to ses if any data exists
		if (wav_file.subChunk3Size == 0) {
			throw invalid_argument("No data");
		}

		/*Read in the audio data*/
		if (initial_read){
			//Data being read into a short vector
			int raw_data_size = (int) wav_file.subChunk3Size / 2; //Only need one channel
			short * raw_data = new short[raw_data_size];
			ifs.read(reinterpret_cast<char*>(raw_data), wav_file.subChunk3Size);

			//parse the read in data file into a vector
			int i = 0;
			while (i < raw_data_size){
				wav_file.data.push_back(raw_data[i]);
				i += 2;
			}
			//clean up
			delete[] raw_data;
		}
		else{
			// data being read in to a char array
			wav_file.raw_data = new char[wav_file.subChunk3Size];
			ifs.read(wav_file.raw_data, wav_file.subChunk3Size);
		}

		//If debug flag is true, print out info about the wave file
		if (debug){

			cout << "Chunk Descriptor : " << wav_file.chunkID << endl
				<< "File_Size : " << wav_file.fileSize << endl
				<< "format : " << wav_file.format << endl
				<< "fmt subchunk name : " << wav_file.subChunk1ID << endl
				<< "subChunk1Size : " << wav_file.subChunk1Size << endl
				<< "audio format (pcm=1): " << wav_file.audioFormat << endl
				<< "num channels: " << wav_file.numChannels << endl
				<< "sampleRate : " << wav_file.sampleRate << endl
				<< "byteRate : " << wav_file.byteRate << endl
				<< "blockAlign :" << wav_file.blockAlign << endl
				<< "bits per sample: " << wav_file.bitsPerSample << endl
				<< "subChunk3ID : " << wav_file.subChunk3ID << endl
				<< "subChunk3Size : " << wav_file.subChunk3Size << endl
				<< "Data gcount : " << ifs.gcount() << endl << endl;
		}
	}
	return wav_file;
}


// This function reverse engineers the 'amplitude data', the maximum value in
// of each chunk_size slice of the audio data array.  In particular, the
// audio data is broken up into discrete, non-overlapping, continuous chunks
// of each of size specified by chunk_size.  For example if the sound data
// is in a container of size 120 and the chunk size is 10, there will be 12
// chunks each of size 10 parsed.  For each of the chunks, the maximum value
// is found and stored in a new vector which is returned by the function.
vector<char *> constructAmpData(waveFileStruct &wave_file, int chunk_size){
	vector<char *> ampData; //new vector that will hold the amplitude data
	//create two iterators
	vector<short>::iterator start_ind = wave_file.data.begin();
	vector<short>::iterator end_ind = start_ind + chunk_size;
	//determine the number of chunks
	int nchunks = int(wave_file.data.size() / chunk_size);
	//iterate through the number of chunks, determing the max of each chunk
	while (end_ind != (wave_file.data.begin() + nchunks * chunk_size)){
		vector<short>::iterator max_val_iterator = max_element(start_ind, end_ind);
		//convert stored short value to char*
		string val = to_string(*max_val_iterator);
		char* cstr = new char[val.length() + 1];
		cstr[val.size()] = 0;
		memcpy(cstr, val.c_str(), val.size());
		//push value onto amplitude vector
		ampData.push_back(cstr);
		//update pointers
		start_ind = end_ind;
		end_ind += chunk_size;
		//edge case handling
		if (end_ind == (wave_file.data.begin() + nchunks * chunk_size)){
			vector<short>::iterator max_val_iterator = max_element(start_ind, end_ind);
			string val = to_string(*max_val_iterator);
			char* cstr = new char[val.length() + 1];
			cstr[val.size()] = 0;
			memcpy(cstr, val.c_str(), val.size());
			ampData.push_back(cstr);
		}
	}
	//if the sound data cannot be evenly divided into chunks, handle overflow
	if (chunk_size * nchunks != wave_file.data.size()){
		vector<short>::iterator max_val_iterator = max_element(end_ind, wave_file.data.end());
		string val = to_string(*max_val_iterator);
		char* cstr = new char[val.length() + 1];
		cstr[val.size()] = 0;
		memcpy(cstr, val.c_str(), val.size());
		ampData.push_back(cstr);
	}
	//return amplitude data
	return ampData;
}


// Writes a new wave file.  This function takes in a name (which will be used
// as the file name that will be saved, a waveFileStruct that holds the
// relevant wave file information, and a vector of two trimming points, which
// will be used to trim the data.  Using the data stored in the waveFileStruct,
// the function then creates a new array that contains only data between the
// trimming points.  Then it updates the information regarding file sizes in
// waveFileStruct and writes that info to a new wave file.
int writeWaveFile(string fname, waveFileStruct &wav_file, vector<int> wave_trim_points){

	//start and end points need to be multiplied by 4 to scale from
	//sound data stored as shorts to sound data stored as char *
	// in 2 channels.
	int start_point = wave_trim_points[0] * 4;
	int end_point = wave_trim_points[1] * 4;
	//new array to hold trimmed data
	char * trimmed_data = new char[end_point - start_point];
	//store trimmed data to new array
	for (int i = start_point; i < end_point; i++){
		trimmed_data[i - start_point] = wav_file.raw_data[i];
	}

	//calculate amount to subtract from file size stored in
	//wave file struct that will be written to new wave file
	int pre_start = start_point;
	int post_end = (int) wav_file.subChunk3Size - end_point;
	wav_file.fileSize = wav_file.fileSize - (pre_start + post_end);
	//update size of sound data to match size of trimmed data
	wav_file.subChunk3Size = end_point - start_point;
	//create save name to save new wave file as
	char* bname = new char[fname.size() - 3];
	bname[fname.size() - 4] = 0;
	memcpy(bname, fname.c_str(), fname.size() - 4);
	string wavename(bname);
	wavename += "-trimmed.wav";

	//open the output stream for writing
	ofstream ofs(wavename, ofstream::binary);

	if (ofs.is_open()){
		/*Write wave file header info*/
		ofs.write(wav_file.chunkID, 4);

		ofs.write(reinterpret_cast<char*>(&wav_file.fileSize), 4);

        ofs.write(wav_file.format, 4);

		ofs.write(wav_file.subChunk1ID, 4);

		ofs.write(reinterpret_cast<char*>(&wav_file.subChunk1Size), 4);

		ofs.write(reinterpret_cast<char*>(&wav_file.audioFormat), 2);

		ofs.write(reinterpret_cast<char*>(&wav_file.numChannels), 2);

		ofs.write(reinterpret_cast<char*>(&wav_file.sampleRate), 4);

		ofs.write(reinterpret_cast<char*>(&wav_file.byteRate), 4);

		ofs.write(reinterpret_cast<char*>(&wav_file.blockAlign), 2);

		ofs.write(reinterpret_cast<char*>(&wav_file.bitsPerSample), 2);

		ofs.write(wav_file.subChunk3ID, 4);

		ofs.write(reinterpret_cast<char*>(&wav_file.subChunk3Size), 4);
		/*Write trimmed data to file*/
		ofs.write(trimmed_data, wav_file.subChunk3Size);
	}
	//close the stream
	ofs.close();

	return 0;
}

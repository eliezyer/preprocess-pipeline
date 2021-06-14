# Preprocess-pipeline
Code for preprocessing electrophysiology and behavior video data files collected.

This pipeline is to use Kilosort 2 through KS2wrapper to spike sort automatically,

The steps I'm working with are to:

[x] Robocopy all the files from my local folder to the subject NAS folder.

[x] Create a session folder and put concatenated files there. Test if file has same size as its components

[x] Run Kilosort2 automatically (based on the .xml) on the concatenated .dat file

[ ] Run DeepLabCut on video, extract data

[x] Extract behavior inputs from the intan digital input

[x] Synchronize behavior with electrophysiology

[ ] Synchronize video with electrophysiology

## Dependencies

If you want to use automatic spike sorting with kilosort2 using the provided code you have to have the following repository
- [KS2Wrapper](https://github.com/SjulsonLab/Kilosort2Wrapper)

Developed by Eliezyer de Oliveira - 2019/2020

## Tutorial

The main function to use is *preprocess_master.m*. You should just change two variables in the script:
1) the variable original_path should be the path of your files on the storage on the network (NAs, recording probox and etc)
2) the variable local_path is where you want to put these files on your computer for pre-processing (make sure you set up to your SSD to speed up)

More information on the preprocessing steps and functions, see [preprocessing steps](tutorial/steps_preprocessing.md)

That's it, if you have any problems please open an issue on the repository.

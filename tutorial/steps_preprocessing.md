#Preprocessing steps for ephys and video data.

# Introduction
 The preprocess pipeline developed here is to automatize the maximum we can and still allow a customization for each person type of recordings/experiments. You can use and alter it for your purposes with no guarantee that it will work.
 Unfortunately, there is a trade-off between automatizing vs customization, to be able to use the scripts here provided you have to stick to some tools that help the script to run smoothly.

*Dependencies for this pipeline*
- Intan recordings as binary files
- Neuroscope .xml files
- Matlab
- Specific organization of folder recording
- Kilosort2
- Kilosort2 Wrapper



### To do in the future
  [] Copy video to the session folder and run DeepLabCut.
  [] Copy any other file (behavior or microphone for example) into the session folder of a specific animal.

## Automatic preprocessing description
This automatic preprocessing pipeline is all controlled by the function preprocess_master.m. Inside preprocess_master.m you can control which functions you want to run and adapt them to your own experiments/needs. preprocessing_master.m call the following functions:

- remote_data_copying
- ConcatenatingDats
- KS2Wrapper
- ResampleBinary (from FMA toolbox)

Feel free to use and modify these functions to your own need.

### Input parameters
  - remote_path: matlab cell array that can have multiple inputs, this is the address to the remote computers (for instance recording computer for sleep and another computer for task). Be careful, if one of the remote_path is not accessible the script will throw an error and not run the next steps

  - local_path: an string array with the local address of analysis computer where to copy the data

### Required folder organization

 In order to use the scripts for automatic preprocessing of data (spike sort and)
  +-- _Project_folder
  |     +-- animal_folder
  |     |   +-- session_folder
  |     |   |   +-- basename.dat
  |     |   |   +-- basename.xml
  |     |   |   +-- _Kilosort_date_time
  |     |   |   |   +-- spike_clusters.npy
  |     |   |   |   +-- spike_times.npy
  |     |   |   |   +-- cluster_group.tsv
  |     |   |   |   +-- pc_features.npy
  |     |   |   |   +-- templates.npy
  |     |   |   |   +-- rez.mat
  |     |   |   |   +-- cluster_info.tsv

 *ADD SCREENSHOTS TO BETTER EXPLAIN?*

### Script steps

(1) Script check all the remote paths and collect all folders' temp_names. *If one of the paths can't be accessed, throw and error*
(2) Script compare remote_path with local_path animals' folders.
(3) Script only copies remote_pat folders if that session wasn't copied yet OR a session folder wasn't created
(X) A step here would be necessary to auto copy the video and other Files
(4) After data is copied, concatenate everything and verify if size matches
(5) Copy .xml from last folder concatenated and run automatic KS2_wrapper

Developed by Eliezyer de Oliveira, 2020

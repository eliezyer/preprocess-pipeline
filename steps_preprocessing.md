#Preprocessing steps for ephys and video data.

# Introduction
 At this point, we want to have data copied from multiple recording remote computers to a local analysis computer. The script will copy the data from the remotes to local only in case a session folder wasn't already created. After copying the data over to the local computer the data will be concatenated and then automatic spike sorting will be done.

### To do in the future
  [] Copy video to the session folder and run DeepLabCut.
  [] Copy any other file (behavior or microphone for example) into the session folder of a specific animal.

## Script description

### Input parameters
  - remote_path: matlab cell array that can have multiple inputs, this is the address to the remote computers (for instance recording computer for sleep and another computer for task). Be careful, if one of the remote_path is not accessible the script will throw an error and not run the next steps

  - local_path: an string array with the local address of analysis computer where to copy the data

### Organization of the folder

### Script steps

(1) Script check all the remote paths and collect all folders' temp_names. *If one of the paths can't be accessed, throw and error*
(2) Script compare remote_path with local_path animals' folders.
(3) Script only copies remote_pat folders if that session wasn't copied yet OR a session folder wasn't created
(X) A step here would be necessary to auto copy the video and other Files
(4) After data is copied, concatenate everything and verify if size matches
(5) Copy .xml from last folder concatenated and run automatic KS2_wrapper

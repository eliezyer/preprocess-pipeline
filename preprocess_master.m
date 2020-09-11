%% script to preprocess all data locally

%developed by Eliezyer de Oliveira, 2020
%TO DO:
% [ ] Compare folders from your local preprocessing folder with over the
% network
%% copy unprocessed data over the network locally

%path where the original unprocessed is stored (switch to yours)
%remember to ommit the last slash!
original_path = '/mnt/dreaddELIE/Recordings/Elie/D1R114M835/D1R114M835_191122_103106'; 

%path where to copy the data for concatenation and processing (spike sort and etc)
local_path = '/media/eliezyer/SSD/Preprocessing/'; %better with SSD

if isunix
     copystring = ['! rsync -a -v -W -c -r ', original_path, ' ',local_path];
elseif ispc
    copystring = ['! xcopy /e /v', original_path, ' ',local_path];
end

%execute comand in catstring
eval(copystring)
    
%% Run concatenating dats, even if you don't need to concatenate, it will
%make a new folder and prevent of re-running the same files a second time
outputStruct = ConcatenatingDats(local_path);


%% Run spike sorting (Kilosort 2 using KS2Wrapper)
%if you don't use KS2Wrapper or .xml, skip/comment this part

%Here is necessary to have .xml in the folder from your original recordings
%This part of the code copies it to the new folder created
for b = 1:length(outputStruct) %looping through the sessions concatenated
    
    rec_folder = fullfile(local_path,outputStruct(b).recording_folders{1});
    new_folder = fullfile(local_path,outputStruct(b).sessionName);
    new_name   = outputStruct(b).sessionName;
    if isunix
        copystring = ['! rsync -a -v -W -c -r ', ...
            fullfile(rec_folder,'amplifier_analogin_auxiliary_int16.xml'), ' ',...
            fullfile(new_folder,[new_name '.xml'])];
    elseif ispc %not tested yet (2020/09/11)
        copystring = ['! xcopy /e /v', ...
            fullfile(rec_folder,'amplifier_analogin_auxiliary_int16.xml'), ' ',...
            fullfile(new_folder,[new_name '.xml'])];
    end
    eval(copystring)
    
    %Running KS2Wrapper on the new files
    KS2Wrapper(fullfile(local_path,outputStruct(b).sessionName))
end

%% Generate .lfp files from original .dat files

for b = 1:length(outputStruct) %looping through the sessions concatenated
    
    new_folder = fullfile(local_path,outputStruct(b).sessionName);
    new_name   = outputStruct(b).sessionName;
    par = LoadXml(fullfile(new_folder,[new_name '.xml']));
    
    %Running KS2Wrapper on the new files
    inputName  = fullfile(local_path,outputStruct(b).sessionName,[new_name '.dat']);
    outputName = fullfile(local_path,outputStruct(b).sessionName,[new_name '.lfp']);
    const_up   = 1;
    %this works for 20 kHz or 30 kHz to 1250 Hz or 2000 Hz
    const_down = par.SampleRate/par.lfpSampleRate; 
    ResampleBinary(inputName,outputName,par.nChannels,const_up,const_down)
end
%% Run set of heuristics to automatically merge/exclude clusters from KS output



%% Run DeepLabCut on video, extract data



%% Extract behavior inputs from the intan digital input


%% Synchronize behavior with electrophysiology


%% Synchronize video with electrophysiology

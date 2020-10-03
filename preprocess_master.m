%% script to preprocess all data locally

%developed by Eliezyer de Oliveira, 2020
%TO DO:
% [ ] Compare folders from your local preprocessing folder with over the
% network
%% copy unprocessed data over the network to locally analyze

%path where the original unprocessed is stored (switch to yours)
%remember to ommit the last slash!
remote_path = {'/mnt/dreaddELIE/Recordings/rewardPrediction';
    };

%path where to copy the data for concatenation and processing (spike sort and etc)
local_path = '/media/eliezyer/SSD/Preprocessing/rewardPrediction/'; %better with SSD


[animal_folders] = remote_data_copying(remote_path,local_path);

for b = 1:length(animal_folders)
    for bb = 1:length(animal_folders{b})
        %% Run concatenating dats, even if you don't need to concatenate, it will
        %make a new folder and prevent of re-running the same files a second time
        %or even copying the data again.
        %% NEED TO ADD LINE FOR VERIFICATION OF CONCATENATION
        outputStruct = ConcatenatingDats(fullfile(local_path,animal_folders{b}{bb}));
        
        
        %% Run spike sorting (Kilosort 2 using KS2Wrapper)
        %if you don't use KS2Wrapper or .xml, skip/comment line 52 (KS2Wrapper)
        
        %Here is necessary to have .xml in the folder from your original recordings
        %This part of the code copies it to the new folder created
        for bbb = 1:length(outputStruct) %looping through the sessions concatenated
            
            rec_folder = fullfile(local_path,animal_folders{b}{bb},outputStruct(bbb).recording_folders{end});
            new_folder = fullfile(local_path,animal_folders{b}{bb},outputStruct(bbb).sessionName);
            new_name   = outputStruct(bbb).sessionName;
            if isunix
                copystring = ['! rsync -a -v -W -c -r ', ...
                    fullfile(rec_folder,'*.xml'), ' ',...
                    fullfile(new_folder,[new_name '.xml'])];
            elseif ispc %not tested yet (2020/09/11)
                copystring = ['! xcopy /e /v', ...
                    fullfile(rec_folder,'*.xml'), ' ',...
                    fullfile(new_folder,[new_name '.xml'])];
            end
            eval(copystring)
            
            %Running KS2Wrapper on the new files
            KS2Wrapper(fullfile(local_path,animal_folders{b}{bb},outputStruct(bbb).sessionName))
        end
        
        %% Generate .lfp files from original .dat files
        
        for bbb = 1:length(outputStruct) %looping through the sessions concatenated
            
            new_folder = fullfile(local_path,outputStruct(bbb).sessionName);
            new_name   = outputStruct(bbb).sessionName;
            par = LoadXml(fullfile(new_folder,[new_name '.xml']));
            
            %Running KS2Wrapper on the new files
            inputName  = fullfile(local_path,outputStruct(bbb).sessionName,[new_name '.dat']);
            outputName = fullfile(local_path,outputStruct(bbb).sessionName,[new_name '.lfp']);
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
        
    end
end
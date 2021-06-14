function remote_data_copying_single_day(remote_path,local_path,date_str)
%function to copy data remotely from recording computers to local
%computers, it will copy all the folder recordings of a specific day
%
% INPUT: remote_path - cell array with the string name of the remote paths
% you want to copy data from.
%        local_path - string array with the local path to copy data to
%        date_str   - date str to identify remote folders to be copied, it
%        must follow format from default intan recordings (YYMMDD)
% developed by Eliezyer de Oliveira, 2021
%
% TO DO:
% [x] put an error message if remote_path doesn't exist
% [ ] identify folders by date, check if matches date entered by user
%
for a = 1:length(remote_path)
    if ~isfolder(remote_path{a})
        error(['The path ' remote_path{a} ' cannot be reached/does not exist, aborting...'])
    end
end
%loop through remote paths to get animal folders and session folders
for a = 1:length(remote_path)
    %getting all the folders inside remote_path
    temp_remote = dir(remote_path{a});
    %all folders on the remote path are collected in the next line,
    %assuming every folder is a session folder
    aux_dir = [temp_remote(3:end).isdir];
    temp_session = {temp_remote(3:end).name};
    temp_session = temp_session(aux_dir);
    
    %% separating potential folders from remote
    potential_folders = temp_session;
    
    %selecting only folders that have more than 14 characters,
    %this is because of intan default of saving date as _yymmdd_hhmmss.
    temp_idx = cellfun(@(x) length(x),potential_folders)>14;
    potential_folders   = potential_folders(temp_idx);
    
    
    %checking which folders have the same date as datestr
    temp_dates = cellfun(@(x) x(end-12:end-7),potential_folders,'UniformOutput',false);
    keep_folders = ismember(temp_dates,date_str);
    
    %these are the folders to copy
    folders2copy = potential_folders(keep_folders);
    
    if ~isempty(folders2copy)
        %preparing command to copy
        for aaa = 1:length(folders2copy)
            if isunix
                copystring = ['! rsync -a -v -W -c -r ', ...
                    fullfile(remote_path{a},folders2copy{aaa}), ' ',...
                    fullfile(local_path{1})];
            elseif ispc
                copystring = ['! xcopy /e /v', ...
                    fullfile(remote_path{a},folders2copy{aaa}), ' ',...
                    fullfile(local_path{1})];
            end
            
            %execute comand in catstring
            eval(copystring)
        end
    end
end
end


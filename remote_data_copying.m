function [animal_folders,out_msg] = remote_data_copying(remote_path,local_path)
%function to copy data remotely from recording computers to local computers
%only if the local_path don't have concatenated versions of it
%
% developed by Eliezyer de Oliveira, 2020
%
% TO DO:
% [ ] put an error message if remote_path can't be accessed
%

%loop through remote paths to get animal folders and session folders
for a = 1:length(remote_path)
    %getting all the folders inside remote_path
    temp_remote = dir(remote_path{a});
    %all folders on the remote path are collected in the next line, 
    %assuming every folder is an animal folder
    aux_dir = [temp_remote(3:end).isdir];
    temp_animal = {temp_remote(3:end).name};
    temp_animal = temp_animal(aux_dir);
    
    %loop through every animal folder to get all the sessions folders
    aux_animal = [];
    for aa = 1:length(temp_animal)
        %% separating potential folders from remote
        temp_ses = dir(fullfile(remote_path{a},temp_animal{aa}));
        aux_dir = [temp_ses(3:end).isdir];
        %folders that can be potentially copied
        potential_folders  = {temp_ses(3:end).name};
        potential_folders = potential_folders(aux_dir);
        
        %selecting only folders that have more than 14 characters, 
        %this is because of intan default of saving date as _yymmdd_hhmmss.
        temp_idx = cellfun(@(x) length(x),potential_folders)>14;
        potential_folders   = potential_folders(temp_idx);
        
        %% checking if local folder has sessions to copy 
        %checkig whether local folder has that animal folder
        if ~isfolder(fullfile(local_path,temp_animal{aa}))
            mkdir(fullfile(local_path,temp_animal{aa}))
        end
        
        %checking if the potential folder to copy was not already
        %concatenated in that folder
        
        %get the folders on the local folder to check what we have copied
        %already
        temp_ses = dir(fullfile(local_path,temp_animal{aa}));
        aux_dir = [temp_ses(3:end).isdir];
        
        existing_folders  = {temp_ses(3:end).name};
        existing_folders = existing_folders(aux_dir);
        
        %selecting only folders that have 6 characters (yymmdd)
        temp_idx = cellfun(@(x) length(x),existing_folders)==6;
        existing_folders   = existing_folders(temp_idx);
        
        %going back to remote folder, check if any of the folders have the
        %same date as the local one
        temp_dates = cellfun(@(x) x(end-12:end-7),potential_folders,'UniformOutput',false);
        keep_folders = ~ismember(temp_dates,existing_folders);

        %these are the folders to concatenate
        folders2copy = potential_folders(keep_folders);
        
        if ~isempty(folders2copy)
            %preparing command to copy
            for aaa = 1:length(folders2copy)
                if isunix
                    copystring = ['! rsync -a -v -W -c -r ', ...
                        fullfile(remote_path{a},temp_animal{aa},folders2copy{aaa}), ' ',...
                        fullfile(local_path,temp_animal{aa})];
                elseif ispc
                    copystring = ['! xcopy /e /v', ...
                        fullfile(remote_path{a},temp_animal{aa},folders2copy{aaa}), ' ',...
                        fullfile(local_path,temp_animal{aa})];
                end
                
                %execute comand in catstring
                eval(copystring)
            end
        else
            %this is just so we don't try to concatenate or run KS on
            %folders that didn't have new additions.
            aux_animal = [aux_animal;aa];
        end
    end
    animal_folders{a} = temp_animal(aux_animal);
end


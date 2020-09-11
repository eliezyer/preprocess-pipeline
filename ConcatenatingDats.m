function outputStruct = ConcatenatingDats(basepath)
%% This function checks if recordings are missing their respectively session
% folder, %creates them and copy all the binary files for that sessions
% concatenated into the session folder.
%
% inputs: bsaepath: animal folder to check for new recordings in the NAS;
%
%developed by Eliezyer de Oliveira 2018
%updated: EFO 2020
%% getting all the folder from basepath and selecting which ones need to be concatenated
outputStruct = [];
d_init = dir(basepath);
temp_idx = [d_init.isdir];
temp_names = {d_init.name};

temp_names = temp_names(temp_idx);

%process of exclusion (1): folder name has to have more than 14 characters.
%this is because of intan default of saving date as _yymmdd_hhmmss.

temp_idx = cellfun(@(x) length(x),temp_names)>14;
temp_names2   = temp_names(temp_idx);



%right now, temp_names has the names of all your recording folders, if it's
%different for any reason, something went wrong.

%process of exclusion(2): removing recording folders that were already
%concatenated and saved inside a session folder, this is done by checking
%if there's a session folder with the date of that recording

%first: identifying if there are session folders, they should be the only
%folders with character size 6 (yymmdd)
temp_idx2 = cellfun(@(x) length(x),temp_names)==6;
temp_session_names = temp_names(temp_idx2);

%second: identify which sessions doesn't need to be concatenated
temp_dates = cellfun(@(x) x(end-12:end-7),temp_names2,'UniformOutput',false);
keep_folders = ~ismember(temp_dates,temp_session_names);

%these are the folders to concatenate
folders2cat = temp_names2(keep_folders);

%% Now identifying which folder belong to which session and creating a structure to easily navigate through it
temp_dates = cellfun(@(x) x(end-12:end-7),folders2cat,'UniformOutput',false);

if ~isempty(temp_dates)
    sessions = unique(temp_dates);
    
    for a = 1:length(sessions)
        sessionsStructure(a).sessionName = sessions{a};
        temp = ismember(temp_dates,sessions{a});
        temp_folders = folders2cat(temp);
        
        temp_hours = cellfun(@(x) x(end-5:end),temp_folders,'UniformOutput',false);
        [~,I] = sort(temp_hours);
        folders_order = temp_folders(I);
        
        sessionsStructure(a).recording_folders = folders_order;
    end
end

%% running data concatenation only if there is data to concatenate

original_dat_name = 'amplifier_analogin_auxiliary_int16.dat';
if exist('sessionsStructure','var')
    for a = 1:length(sessionsStructure)
        basename = sessionsStructure(a).sessionName;
        
        %checking if the session directory exists, but it shouldn't
        session_path = fullfile(basepath,basename);
        if ~exist(session_path,'dir')
           mkdir(session_path)
        end
        
        newdatpath = fullfile(session_path,[basename,'.dat']);
       
        fid = fopen(fullfile(session_path,'concatenation_order.txt'),'w');
        for idx = 1:length(sessionsStructure(a).recording_folders)
            
            fprintf(fid,[sessionsStructure(a).recording_folders{idx} '\n']);
            
        end
        fclose(fid);
        
        datpaths = fullfile(basepath,sessionsStructure(a).recording_folders,original_dat_name);
        %% concatenating main dat file
        
        if isunix
            cs = strjoin(datpaths);
            catstring = ['! cat ', cs, ' > ',newdatpath];
        elseif ispc%As of 4/9/2017 - never tested
            if length(datpaths)>1
                for didx = 1:length(datpaths);
                    datpathsplus{didx} = [datpaths{didx} '+'];
                end
            else
                datpathsplus = datpaths;
            end
            cs = strjoin(datpathsplus);
            catstring = ['! copy /b ', cs(1:end-1), ' ',newdatpath];
        end
        
        eval(catstring)%execute concatention
        disp(['Done concatenating ' basename '.dat file'])
        % Check that size of resultant .dat is equal to the sum of the components
        % t = dir(newdatpath);
        % recordingbytes = SessionMetadata.ExtracellEphys.Files.Bytes;
        % if t.bytes ~= sum(recordingbytes)
        %     error('New .dat size not right.  Exiting')
        %     return
        % else
        %     disp(['Primary .dats concatenated successfully'])
        % end
        
        %% concatenating other dat types
        otherdattypes = {'analogin';'digitalin';'auxiliary';'time';'supply'};
        for odidx = 1:length(otherdattypes)
            
            tdatpaths = fullfile(basepath,sessionsStructure(a).recording_folders,[otherdattypes{odidx} '.dat']);
            tnewdatpath = fullfile(session_path,[otherdattypes{odidx} '.dat']);
            
            if isunix
                cs = strjoin(tdatpaths);
                catstring = ['! cat ', cs, ' > ',tnewdatpath];
            elseif ispc%As of 4/9/2017 - never tested
                if length(tdatpaths)>1
                    for didx = 1:length(tdatpaths)
                        datpathsplus{didx} = [tdatpaths{didx} '+'];
                    end
                else
                    datpathsplus = tdatpaths;
                end
                cs = strjoin(datpathsplus);
                catstring = ['! copy /b ', cs(1:end-1), ' ',tnewdatpath];
            end
            
            eval(catstring)%execute concatenation
            disp(['Done concatenating ' basename ' ' otherdattypes{odidx} '.dat'])
            % Check that size of resultant .dat is equal to the sum of the components
            %     t = dir(tnewdatpath);
            %     eval(['recordingbytes = ' otherdattypes{odidx} 'datsizes;'])
            %     if t.bytes ~= sum(recordingbytes)
            %         error(['New ' otherdattypes{odidx} '.dat size not right.  Exiting after .dats converted.  Not deleting'])
            %         deleteoriginaldatsbool = 0;
            %     else
            
            %     end
        end
        
        %copying the xml from the last folder to the session folder so we
        %can run spike sort on it
        outputStruct = sessionsStructure;
    end
    
end
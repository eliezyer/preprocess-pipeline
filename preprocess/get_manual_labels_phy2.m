function phy2_labels = get_manual_labels_phy2(basepath)
%function to get the manual labels inserted in phy2.
%this function assumes KS2Wrapper has been used and the files/folders are
%organized as explained in the KS2Wrapper script
%(https://github.com/eliezyer/KS2wrapper)
%
% Eliezyer de Oliveira 2020

%checking inputs
if nargin<1
    basepath = pwd;
end
[~,basename] = fileparts(basepath);
%% function starts here
%Finding kilosort folder, case insensitive
temp = dir(basepath);
aux  = strfind(lower({temp.name}),lower('kilosort'));
fold_idx = find(cellfun(@(x) ~isempty(x),aux));
%in case of multiple folders, it's going to take the first one in the
%list
if ~isempty(fold_idx)
    kilosort_path = temp(fold_idx(1));
else
    error('Couldnt find kilosort files folder')
end


disp('loading manual labels from Phy2 on good clusters ')
spike_cluster_index = readNPY(fullfile(kilosort_path.name, 'spike_clusters.npy'));
cluster_group = tdfread(fullfile(kilosort_path.name,'cluster_group.tsv'));

%extracting shank information if it's kilosort2/phy2 output
if exist(fullfile(kilosort_path.name,'cluster_info.tsv'),'file')
    cluster_info = tdfread(fullfile(kilosort_path.name,'cluster_info.tsv'));
    
phy2_labels.sessionName = basename;
jj = 1;
for ii = 1:length(cluster_group.group)
    if strcmpi(strtrim(cluster_group.group(ii,:)),'good')
        ids = find(spike_cluster_index == cluster_group.cluster_id(ii)); % cluster id
        phy2_labels.cluID(jj) = cluster_group.cluster_id(ii);
        phy2_labels.UID(jj) = jj;
        phy2_labels.labels(jj) = cluster_info.Var2(ii);
        jj = jj + 1;
    end
end
end

%% saving the structure
save(fullfile(basepath,[basename '.phy2_labels.mat']),'phy2_labels')

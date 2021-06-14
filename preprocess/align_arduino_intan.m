%intan records channels 0-indexed, the list below is already summed 1
%init poke enter:       ch 02
%left poke enter:       ch 03
%right poke enter:      ch 04
%trial available:       ch 10
%cue 1:                 ch 11
%cue 2:                 ch 12
%reward TTL:            ch 15

function align_arduino_intan(basepath)


%% loading essentials
load(fullfile(basepath,'digital_input_ts'))
load(fullfile(basepath,'recording_intervals.mat'))
aux_dir = dir(fullfile(basepath,'arduino_2afc.*'));
for a = 1:length(aux_dir)
    load(fullfile(basepath,aux_dir(a).name))
    
    %important parameters
    binSize = 0.01; %in seconds
    
    %% getting trial available information from both systems
    %getting trial available on intan
    bins_intan = linspace(0,recording_intervals.stop_times(end),recording_intervals.stop_times(end)/binSize);
    trial_start_intan = histcounts(digital_input_ts.channel(10).stop,bins_intan);
    
    %now getting trial start on arduino
    temp = arduino_2afc.pokes.trial_starts/1000; %converting to seconds
%     temp = arduino_2afc.pokes.Ipokes_correct/1000; %converting to seconds
    %% DO CROSS CORRELATION OF TRIAL AVAILABLE (INTAN) VS TRIAL_START (ARD)
    %% DO CASE BY CASE ALIGNMENT AFTER YOU DO THAT, EXCLUDE TRIALS THAT DON'T HAVE TTL ASSOCIATED WITH IT
    %% trying to first analyze the behavior of intan to then align with arduino
    %first debounce the data from init, left and side poke %min diff of
    %peaks is 15 ms
    
    %using merge from buzcode to debounce
    int_right_pokes = [digital_input_ts(1).channel(4).start; digital_input_ts(1).channel(4).stop]';
    deb_right_pokes = MergeSeparatedInts(int_right_pokes,0.007);
    %left pokes
    int_left_pokes = [digital_input_ts(1).channel(3).start; digital_input_ts(1).channel(3).stop]';
    deb_left_pokes = MergeSeparatedInts(int_left_pokes,0.007);
    %init pokes
    int_init_pokes = [digital_input_ts(1).channel(2).start; digital_input_ts(1).channel(2).stop]';
    deb_init_pokes = MergeSeparatedInts(int_init_pokes,0.007);

    %reward TTL (this TTL goes LOW when the pump delivers reward)
    rew_temp_start = digital_input_ts(1).channel(15).start;
    rew_temp_stop  = digital_input_ts(1).channel(15).stop;
    if length(rew_temp_start)>length(rew_temp_stop)
        rew_temp_start = rew_temp_start(1:end-1);
    elseif length(rew_temp_stop)>length(rew_temp_start)
        rew_temp_stop =  rew_temp_stop(1:end-1);    
    end
    int_reward_ttl = [rew_temp_start; rew_temp_stop]';
    deb_reward_ttl = MergeSeparatedInts(int_reward_ttl,0.025); %debounced reward ttl
%     %identify trial start and stop by looking at trial avail stop (white
%     %noise end) and trial avail start (white noise start)
%     %remember that last stop is end of session, and first start is start of
%     %the session
%     int_trials=[digital_input_ts(1).channel(10).stop(1:end-1);digital_input_ts(1).channel(10).start(2:end)]';
%     
%     for aa = 1:length(int_trials)
%         %identify if there were cue stops inside the trial
%         leftCue = Restrict(digital_input_ts(1).channel(12).stop,int_trials(aa,:));
%         rightCue = Restrict(digital_input_ts(1).channel(11).stop,int_trials(aa,:));
%         if ~isempty(leftCue) && ~isempty(rightCue)
%             %identify if it's free choice or not by having both cues active
%             trialLRtype(aa) = 6;
%         elseif ~isempty(leftCue) && isempty(rightCue)
%             trialLRtype(aa) = 1;
%         elseif isempty(leftCue) && ~isempty(rightCue)
%             trialLRtype(aa) = 3;
%         end
%         
%         %getting the amount and type of pokes inside each trial
%         num_init(aa) =  length(Restrict(deb_init_pokes(:,1),int_trials(aa,:)));
%         num_left(aa) =  length(Restrict(deb_left_pokes(:,1),int_trials(aa,:)));
%         num_right(aa) =  length(Restrict(deb_right_pokes(:,1),int_trials(aa,:)));
%     end
%     
%     %
%     %% trying new synchronization using pokes trial types THIS DIDNT WORK BETTER
%     %tested the number of ttl on channel for cue 1 (right) and the number
%     %of trials that were type 3,4,5 and 6 (all with right cue), and got 1
%     %TTL difference, checking for cue 2 I also got a 1 TTL difference only
%     %checking for right side
%     %arduino right cue
%     sum(ismember(pokes.trialLR_types,[3,4,5,6]))  
%     %intan right cue
%     intan_cue1 = digital_input_ts(1).channel(11).start;
%     cue1_bnd = histcounts(intan_cue1,bins_intan);
%     size(intan_cue1)
%     %checking for left side
%     %arduino left cue
%     sum(ismember(pokes.trialLR_types,[1,2,5,6]))  
%     %intan left cue
%     intan_cue2 = digital_input_ts(1).channel(12).start;
%     cue2_bnd = histcounts(intan_cue2,bins_intan);
%     size(intan_cue2)
%     
%     %giving a try with init poke and all the cues
% %     auxcue = cue1_bnd.*cue2_bnd;
% %     tempcue = cue1_bnd+cue2_bnd;
% %     tempcue(logical(auxcue)) = 1;
%       tempcue = cue1_bnd;
%       aux = ismember(pokes.trialLR_types,[3,4,5,6]);
%       temp = arduino_2afc.pokes.Ipokes_correct(aux)/1000; %converting to seconds
    %% getting the offset from intan recording behavior and arduino log file
    %first identify which intan recording is the closest to arduino
    time_intan = cellfun(@(x) str2num(x(end-5:end)),recording_intervals.folders_name);
    %identify the folder
    [~,I] = sort(abs(str2num(arduino_2afc.time)-time_intan));
    %calculate the difference in time between arduino and intan based on the
    %time recorded on their filename
    temp_intan = recording_intervals.folders_name{I(1)}(end-5:end);
    temp_ard = arduino_2afc.time;
    
    %getting hour, minute and seconds of intan and arduino recoridngs
    h_intan = str2num(temp_intan(1:2));m_intan = str2num(temp_intan(3:4));s_intan = str2num(temp_intan(5:6));
    h_ard = str2num(temp_ard(1:2));m_ard = str2num(temp_ard(3:4));s_ard = str2num(temp_ard(5:6));
    
    %estimating absolute time, there must be a smarter way to do this.
    temp_intan = h_intan*3600 + m_intan*60 + s_intan;
    temp_ard = h_ard*3600 + m_ard*60 + s_ard;
    
    time_offset = temp_ard-temp_intan;
    %dealing with the fact that this might be performed in one single session
    if (length(recording_intervals.stop_times)==1) || (I(1) == 1)
        arduino_offset = time_offset;
    else
        arduino_offset = recording_intervals.stop_times(I(1)-1)+time_offset;
    end
    
    %use this variable to cross-correlate with the intan, repeat for smaller
    %timescales once you find the correct peak
    trial_start_arduino = histcounts(temp+arduino_offset,bins_intan);
    
    [rho,lags] = xcorr(trial_start_intan,trial_start_arduino);
    %getting the index of maximum lag
    [~,I] = max(rho);
    %identify the lag and fix
    arduino_offset2 = arduino_offset+(lags(I)*binSize);
    
    
    %insert in the arduino structure the offset and info
    arduino_2afc.offset_2_intan = arduino_offset2;
    arduino_2afc.offset_2_intan_info = 'offset of arduino pokes timestamp in comparison to the intan, in seconds. Calculated by adding the offset of time/hour of each file (intan and arduino log files) and cross correlating the binned start times of trial available';
    save(fullfile(basepath,aux_dir(a).name),'arduino_2afc')
    
    %now calculating what are the arduino trial starts closest to the intan
    %trial available stops
    ard_trial_start = temp+arduino_offset2;
    %check the difference of arduino to intan
    intan_trial_start = digital_input_ts.channel(10).stop;
    intan2keep = [];
    ard_associated = [];
    ard_intan_diff = [];
    for aa = 1:length(intan_trial_start)
        [aux_diff,aux_trial] = min(abs(intan_trial_start(aa) -ard_trial_start));
        if aux_diff<0.12 %if intan trial to ard trial have a difference smaller than 120 ms
            %save parameters to use later
            ard_intan_diff = [ard_intan_diff aux_diff];
            intan2keep = [intan2keep aa]; %save the intan trial recorded
            ard_associated = [ ard_associated aux_trial]; %arduino trial associated so we can
        end
    end
    
    %start building a structure based on the intan2keep trials
    
    %make intervals of start stop of trial available
    start = digital_input_ts.channel(10).stop(intan2keep);
    if intan2keep(end)<length(digital_input_ts.channel(10).start)
        stop  = digital_input_ts.channel(10).start(intan2keep+1);
    else
        auxstop = arduino_2afc.pokes.trial_stops(ard_associated(end))/1000 + arduino_2afc.offset_2_intan;
        stop  = [digital_input_ts.channel(10).start(intan2keep(1:end-1)+1) auxstop];
    end
    afc_intan.trial_intervals = [start' stop'];
    afc_intan.trial_intervals_info = 'start stop in seconds of trial start and stop (intan based)';
    %save if what kind of trialLRtype it was too
    afc_intan.trial_LR_type = arduino_2afc.pokes.trialLR_types(ard_associated);
    afc_intan.trial_LR_type_info = 'type of trial, codes 1,2 are for left rewarded trials, 3,4 for right rewarded trials, 5 and 6 for free trials (left and right give reward)';
    %get the size of reward on both sides
    afc_intan.rewards_size = [arduino_2afc.pokes.L_size(ard_associated)' arduino_2afc.pokes.R_size(ard_associated)'];
    afc_intan.rewards_size_info = 'reward sizes on the trials, first index is left size, second is right reward size';
    %get whether was a valid trial or not (hold enough)
    
    
    %PUT AN IF HERE TO DO ONLY WHEN IT MATTERED
    if arduino_2afc.session_info.cueWithdrawalPunishYN
        aux_valid_start = arduino_2afc.pokes.I_hold_time>arduino_2afc.pokes.requiredInitHold(ard_associated);
        afc_intan.valid_start = aux_valid_start(ard_associated);
        afc_intan.valid_start_info = 'logical vector on whether it was a valid trial (init poke holded long enough)';
    end
    %get whether the trial was rewarded or not, get whether it was left or
    %right poke, also what intan poke correspond to the rewarded one
    aux_ard = [arduino_2afc.pokes.trial_starts' arduino_2afc.pokes.trial_stops'];
    aux_ard = aux_ard(ard_associated,:);
    aux_pokes = [arduino_2afc.pokes.Lreward_pokes arduino_2afc.pokes.Rreward_pokes ];
    aux_rewarded = [];
    poke_rewarding = [];
    intan_Lrewarded_poke = [];
    intan_Rrewarded_poke = [];
    for aa = 1:length(aux_ard)
       aux = ismember(aux_pokes,Restrict(aux_pokes,aux_ard(aa,:))); 
       if sum(aux)~=0
           %saving whether trial was rewarded or not
           aux_rewarded = [aux_rewarded true];
           
           %this is to define if it was left or right rewarded poke
           temp_poke = find(aux);
           if length(temp_poke)>1
               keyboard
           else
           if temp_poke<=length(arduino_2afc.pokes.Lreward_pokes)
                poke_rewarding = [poke_rewarding 1]; %left code
                %now identifying which poke on intan is closest to the
                %rewarded
                [garbage,temp_intan] = min(abs( ((aux_pokes(temp_poke)/1000)+ ...
                    arduino_2afc.offset_2_intan)-deb_left_pokes(:,1)));
                intan_Lrewarded_poke = [intan_Lrewarded_poke temp_intan];
           elseif temp_poke>length(arduino_2afc.pokes.Lreward_pokes)
                poke_rewarding = [poke_rewarding 3]; %right code
                %now identifying which poke on intan is closest to the
                %rewarded
                [garbage,temp_intan] = min(abs( ((aux_pokes(temp_poke)/1000)+ ...
                    arduino_2afc.offset_2_intan)-deb_right_pokes(:,1)));
                intan_Rrewarded_poke = [intan_Rrewarded_poke temp_intan];
           end
           end

       else
           aux_rewarded = [aux_rewarded false];
       end
    end
    afc_intan.rewarded_trial = aux_rewarded;
    afc_intan.rewarded_trial_info = 'logical vector whether that trial was rewarded or not';
    %%
    aux_rew = [];
    temp_intervals2use = afc_intan.trial_intervals(logical(afc_intan.rewarded_trial),:);
    for b  = 1:length(temp_intervals2use)
        temp = Restrict(deb_reward_ttl(:,1), temp_intervals2use(b,:));
        if ~isempty(temp)
            aux_rew = [aux_rew temp(1)]; %time that reward TTL was triggered
        end
    end
    afc_intan.reward_TTL_start_time = aux_rew;
    afc_intan.reward_TTL_start_time_info = 'Time in which the TTL for the syringe pumps is sent, this TTL is a better indication that the trial might be over. Before the first reward is sent in the session sometimes this TTL channel keeps flickering up and down, so you may want to discard the first reward trial';
    %%
    %save which poke was the one rewarding
    afc_intan.rewarding_poke_type = poke_rewarding;
    afc_intan.rewarding_poke_type_info = 'type of poke that triggered reward, 1 is a left poke, 3 is a right poke';
    %save intan left and right pokes that triggered reward
    afc_intan.Lreward_poke = intan_Lrewarded_poke;
    afc_intan.Lreward_poke_info = 'index of the intan left poke that was rewarded, it belongs to the trial in the same order as in rewarding_poke_type field. As in find(rewarding_poke_type==1)';
    
    afc_intan.Rreward_poke = intan_Rrewarded_poke;
    afc_intan.Rreward_poke_info = 'index of the intan right poke that was rewarded, it belongs to the trial in the same order as in rewarding_poke_type field. As in find(rewarding_poke_type==3)';
    
    %save all the pokes after debouncing them in a single row (i.e., do not
    %save them as in restricted by the trials, that would make the analysis
    %scripts hard)
    afc_intan.I_pokes = deb_init_pokes;
    afc_intan.I_pokes_info = 'init poke intervals (start stop) extracted from intan, after debouncing using MergeSeparatedInts function from buzcode and minseparation = 7ms ';
    afc_intan.L_pokes = deb_left_pokes;
    afc_intan.L_pokes_info = 'left poke intervals (start stop) extracted from intan, after debouncing using MergeSeparatedInts function from buzcode and minseparation = 7ms ';
    afc_intan.R_pokes = deb_right_pokes;
    afc_intan.R_pokes_info = 'right poke intervals (start stop) extracted from intan, after debouncing using MergeSeparatedInts function from buzcode and minseparation = 7ms ';
    afc_intan.arduino_equivalent = ard_associated;
    afc_intan.arduino_equivalent_info = 'equivalent trial number in the arduino structure';
    save(fullfile(basepath,['afc_intan' aux_dir(a).name(end-17:end)]),'afc_intan');
%     %create a folder to save alignment plots of random examples if there is none
%     if ~exist(fullfile(basepath,'arduino_intan_alignment_results'),'dir')
%         mkdir('arduino_intan_alignment_results')
%     end
%     
%     %create plots of random left and right pokes with the corrected arduino
%     %plot and intan plot on top of each other
%     %plots are with 1 ms bin
%     new_binSize = 0.001;
%     new_bins = linspace(0,recording_intervals.stop_times(end),recording_intervals.stop_times(end)/new_binSize);
%     
%     
%     %pick a random left and right poke
%     temp_pokes = arduino_2afc.pokes;
%     rand_left  = temp_pokes.Lpokes(randperm(length(temp_pokes.Lpokes),1));
%     rand_right = temp_pokes.Rpokes(randperm(length(temp_pokes.Rpokes),1));
%     %correct with the offset
%     rand_left  = (rand_left/1000) + arduino_offset2;
%     rand_right  = (rand_right/1000) + arduino_offset2;
%     
%     rand_left_binned    = histcounts(rand_left,new_bins);
%     rand_right_binned   = histcounts(rand_right,new_bins);
%     intan_left   = histcounts(digital_input_ts.channel(3).start,new_bins);
%     intan_right  = histcounts(digital_input_ts.channel(4).start,new_bins);
%     
%     
%     %plotting left figure
%     figLeft = figure;
%     plot(new_bins(1:end-1),intan_left,'color',[0 0 0.6])
%     hold on
%     plot(new_bins(1:end-1),rand_left_binned,'--','color',[0.2 0.8 1])
%     xlim([rand_left-0.5 rand_left+0.5])
%     
    %checking the plots I realize that not all TTLs in intan can be synchro
    %nized with the arduino. I think the TTL in the intan is more reliable 
    %than the timing with the synchronization
end
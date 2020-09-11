basepath = '/mnt/dreaddELIE/Recordings/ADRAI32001M296';
names = {'ADRAI32001M296_200315_094142';
'ADRAI32001M296_200315_140433';
'ADRAI32001M296_200315_150916';
'ADRAI32001M296_opto_200315_170532';
'ADRAI32001M296_opto2_200315_171856'};
filePaths = fullfile(basepath,names,'amplifier_analogin_auxiliary_int16.dat');

for a = 1:length(filePaths)
   d = dir(filePaths{a});
   datSize_s(a) = d.bytes/106/20000/2;
end

recordingIntervals = cumsum(datSize_s);
# preprocess-pipeline
Code for preprocessing data in brito-sjulson lab.

This pipeline is to use Kilosort 2 through KS2wrapper to spike sort automatically,

The steps I'm working with are to:

[x] Robocopy all the files from my local folder to the subject NAS folder.

[almost] Create a session folder and put concatenated files there. Test if file has same size as its components

[x] Run Kilosort2 automatically (based on the .xml) on the concatenated dataset

[ ] Run set of heuristics to automatically merge/exclude clusters from output of kilosort

[ ] Run DeepLabCut on video, extract data

[almost] Synchronize behavior with electrophysiology

[ ] Synchronize video with electrophysiology



Developed by Eliezyer de Oliveira - 2019/2020


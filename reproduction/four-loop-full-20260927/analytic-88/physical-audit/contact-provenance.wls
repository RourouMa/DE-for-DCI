r="/home/april/Documents/ChatGPT/DE for DCI";d=DirectoryName[$InputFileName];
Get[r<>"/DE-for-DCI-publish/Kernel/ConformalIBP.wl"];
a=Get[r<>"/four-loop-relative-cover-20260927/epoch0/Campaign.wl"];
Print["CampaignKeys ",Keys[a]];Print["CampaignProvenance ",InputForm[Lookup[a,"Provenance",None]]];
Get[r<>"/four-loop-full-closure-20260927/epoch3/SourceManifest.mx"];
Print["Manifest ",InputForm[ConformalIBP`Private`sourceManifest]];
Quit[];

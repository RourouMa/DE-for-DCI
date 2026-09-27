r="/home/april/Documents/ChatGPT/DE for DCI";d=DirectoryName[$InputFileName];Get[r<>"/DE-for-DCI-publish/Kernel/ConformalIBP.wl"];
Get[r<>"/four-loop-relative-cover-20260927/epoch0/full-pool-cache/CanonicalPool.mx"];
Print["PrivateMetadata ",InputForm[ConformalIBP`Private`poolMetadata]];Print["GlobalMetadata ",InputForm[Global`poolMetadata]];
Put[<|"Private"->ConformalIBP`Private`poolMetadata,"Global"->Global`poolMetadata|>,d<>"/HighPoolMetadata.wl"];
Quit[];

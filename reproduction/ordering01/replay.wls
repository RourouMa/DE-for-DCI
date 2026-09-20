(* Fresh differentiation and finite construction, using the frozen solved rules. *)
handoffHome=DirectoryName[$InputFileName];
handoffData=Environment["DCI_SNAPSHOT_DATA"];
If[!StringQ[handoffData] || handoffData==="",handoffData=FileNameJoin[{handoffHome,"data"}]];
handoffWork=Environment["DCI_REPLAY_OUT"];
If[!StringQ[handoffWork] || handoffWork==="",handoffWork=FileNameJoin[{handoffHome,"work","replay"}]];
If[DirectoryQ[handoffWork],Print["Refusing to reuse an existing output directory: ",handoffWork];Quit[1]];
handoffReduction=Environment["DCI_REDUCTION_DIR"];
If[!StringQ[handoffReduction] || handoffReduction==="",handoffReduction=FileNameJoin[{handoffData,"reduction"}]];
If[!FileExistsQ[FileNameJoin[{handoffReduction,"IBP4ReductionRules.txt"}]],
 Print["Run fetch.py first."];Quit[1]];
SingularInterfacePath=""; (* Not needed for differentiation or solved-rule replay. *)
IBP4RunOutputDirectory=handoffWork;
IBP4RunReductionDirectory=handoffReduction;
IBP4MaxPasses=4;IBP4StopWhenClosed=True;
Get[FileNameJoin[{handoffHome,"legacy","ClosureOutputAdmission.wl"}]];
Get[FileNameJoin[{handoffHome,"legacy","IBP4ConstantFromTop.wl"}]];

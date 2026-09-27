r="/home/april/Documents/ChatGPT/DE for DCI";d=DirectoryName[$InputFileName];Get[r<>"/DE-for-DCI-publish/Kernel/ConformalIBP.wl"];Get[r<>"/DE-for-DCI-publish/Examples/kinematics.wl"];
f=LadderFamily[2,kinematics,{x,y}];g=G[2,0,0,0,0,2,0,0,2,1,1];ops=GenerateOperators[f];op=First[Select[ops,#["Loop"]===1&&#["A"]===X1&&#["B"]===X2&]];
ct=ConformalIBP`Private`contacts[f,op,g];rej=IBPRelation[f,op,g];
Print["ExternalExternalRawContact ",InputForm[ct]];Print["ExternalExternalRejected ",InputForm[rej]];
safe=G[2,0,0,0,0,3,0,0,2,1,1];safeop=First[Select[ops,#["Loop"]===1&&#["A"]===X1&&#["B"]===Y2&]];
safect=ConformalIBP`Private`contacts[f,safeop,safe];safeeq=IBPRelation[f,safeop,safe];Print["SafeContact ",InputForm[safect]];Print["SafeEquation ",InputForm[safeeq]];
c=FindCoupledIBPRelations[f,{g}];Print["CoupledSummary ",InputForm[KeyDrop[c,{"Equations","Certificates","BlockedApplications","RejectedCandidates"}]]];Print["CoupledCertificates ",InputForm[c["Certificates"]]];
Put[<|"Family"->f,"ExternalSeed"->g,"ExternalOperator"->op,"ExternalContact"->ct,"ExternalRejection"->rej,"SafeSeed"->safe,"SafeOperator"->safeop,"SafeContact"->safect,"SafeRelation"->safeeq,"Coupled"->c|>,d<>"/LowContactWitness.wl"];
Quit[];

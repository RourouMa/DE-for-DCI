(* Memoize only previously constructed physical derivatives and canonical
   physical rows. Pool, family, implementation and exact basis must match.
   This cache does not assert any reduction or closure. *)
preparePhysicalConstruction[f_Association,basis_List,dir_String,fullMeta_Association]:=Module[
 {key,file,record,prior,derivative,raw,input,de,required,origin,started=AbsoluteTime[]},
 key=Hash[{f["Hash"],ConformalIBP`Private`$implementationHash,fullMeta["FullPoolHash"],basis},"SHA256"];
 If[!DirectoryQ[dir],CreateDirectory[dir,CreateIntermediateDirectories->True]];
 file=FileNameJoin[{dir,"PhysicalConstruction-"<>IntegerString[key,16]<>".mx"}];
 If[FileExistsQ[file],
  Get[file];record=physicalConstructionRecord;
  If[!AssociationQ[record]||record["Key"]=!=key||record["Basis"]=!=basis||record["FullPoolHash"]=!=fullMeta["FullPoolHash"],
   Return[Failure["PhysicalConstructionCacheMismatch",<|"File"->file|>]]];
  Return[Join[record,<|"Reused"->True,"LoadSeconds"->N[AbsoluteTime[]-started]|>]]];
 prior=If[FileExistsQ[FileNameJoin[{dir,"PhysicalInput.wl"}]],Get[FileNameJoin[{dir,"PhysicalInput.wl"}]],<||>];
 If[AssociationQ[prior]&&Lookup[prior,"FullPoolHash",None]===fullMeta["FullPoolHash"]&&Lookup[prior,"PhysicalInput",None]===basis&&AssociationQ[Lookup[prior,"PhysicalDerivatives",None]],
  derivative=prior["PhysicalDerivatives"];
  origin=<|"Method"->"Reuse same-pool physical derivative artifact","File"->FileNameJoin[{dir,"PhysicalInput.wl"}],"SHA256"->FileHash[FileNameJoin[{dir,"PhysicalInput.wl"}],"SHA256"]|>,
  derivative=ConformalIBP`DifferentiateIntegrals[f,basis];origin=<|"Method"->"Differentiate complete physical expressions"|>];
 If[FailureQ[derivative],Return[derivative]];
 If[!AssociationQ[derivative]||!AssociationQ[Lookup[derivative,"Rows",None]]||Keys[derivative["Rows"]]=!=f["Variables"],
  Return[Failure["PhysicalDerivativeShape",<||>]]];
 raw=Flatten[Values[derivative["Rows"]],1];
 If[Length[raw]=!=Length[basis]Length[f["Variables"]],Return[Failure["PhysicalDerivativeCount",<||>]]];
 input=ConformalIBP`Private`canonExpr[f,#]& /@ basis;de=ConformalIBP`Private`canonExpr[f,#]& /@ raw;
 If[AnyTrue[Join[input,de],FailureQ],Return[Failure["PhysicalCanonicalization",<||>]]];
 required=ConformalIBP`Private`support[{input,de}];
 physicalConstructionRecord=<|"Key"->key,"Basis"->basis,"FullPoolHash"->fullMeta["FullPoolHash"],
  "FamilyHash"->f["Hash"],"ImplementationHash"->ConformalIBP`Private`$implementationHash,
  "PhysicalDerivative"->derivative,"RawDerivative"->raw,"PhysicalInput"->input,"PhysicalDE"->de,"Required"->required,"Origin"->origin|>;
 DumpSave[file,physicalConstructionRecord];
 Join[physicalConstructionRecord,<|"Reused"->False,"LoadSeconds"->N[AbsoluteTime[]-started]|>]];

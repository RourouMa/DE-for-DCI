(* FiniteFlow symbolic row spaces with exact reconstruction and a modular rank witness. *)
$fastRowSpaceCache=<||>;
fastRowSpace[m_List]:=Module[{started=AbsoluteTime[],cols,rules,r,p,params,point,prime=1000003,nm,rank,coverage,mod,key},
 key=Hash[m,"SHA256"];If[KeyExistsQ[$fastRowSpaceCache,key],Return[$fastRowSpaceCache[key]]];
 cols=G /@ (-Range[Length[First[m]]]);
 Print[<|"At"->DateString[Now,"ISODateTime"],"Action"->"Fast rational row-space solve","Dimensions"->Dimensions[m]|>];
 If[AllTrue[Flatten[m],zero],Return[{}]];
 rules=FiniteFlow`FFSparseSolve[(#==0& /@ DeleteCases[m.cols,0]),cols];
 If[!ListQ[rules]||!And@@(MatchQ[#,_Rule]& /@ rules),Print["Fast row-space solve failed"];Abort[]];
 r=coeff[(First /@ rules)-(Last /@ rules),cols];
 r=SortBy[r,First[FirstPosition[#,a_/;!zero[a],Missing[],{1},Heads->False]]&];
 p=pivots[r];
 If[r==={}||r[[All,p]]=!=IdentityMatrix[Length[r]],Print["Invalid pivot normalization"];Abort[]];
 params=Union[Cases[m,z_Symbol/;Context[z]=!="System`",Infinity]];
 point=Thread[params->If[Length[params]===2,{11,17},Prime[Range[Length[params]]+4]]];
 mod[v_]:=With[{q=Together[v]},If[!MatchQ[q,_Integer|_Rational]||Mod[Denominator[q],prime]===0,Return[$Failed]];Mod[Numerator[q]PowerMod[Denominator[q],-1,prime],prime]];
 nm=Map[mod,m/.point,{2}];If[!MatrixQ[nm,IntegerQ],Print["Row-space rank witness was singular"];Abort[]];
 rank=Length[Select[RowReduce[nm,Modulus->prime],!AllTrue[#,SameQ[#,0]&]&]];
 If[rank=!=Length[r],Print["Row-space rank witness mismatch"];Abort[]];
 coverage=And@@(zero /@ Flatten[m-m[[All,p]].r]);
 If[!coverage,Print["Exact row-space reconstruction failed"];Abort[]];
 Print[<|"At"->DateString[Now,"ISODateTime"],"Action"->"Fast rational row-space certified","Rank"->rank,"ExactReconstruction"->True,"NonsingularMinorWitness"->True,"Seconds"->AbsoluteTime[]-started|>];AssociateTo[$fastRowSpaceCache,key->r];r];
rr[m_List]:=If[m==={}||First[m]==={},{},If[MemberQ[$Packages,"FiniteFlow`"]&&!FreeQ[m,_Symbol?(Context[#]=!="System`"&)],fastRowSpace[m],Select[RowReduce[m],!And@@(zero /@ #)&]]];
linearInverse[m_List]:=Module[{n=Length[m],r,answer},
 If[!MemberQ[$Packages,"FiniteFlow`"]||FreeQ[m,_Symbol?(Context[#]=!="System`"&)],Return[Inverse[m]]];
 If[Dimensions[m]=!={n,n},Print["Nonsquare inverse requested"];Abort[]];
 r=fastRowSpace[MapThread[Join,{m,IdentityMatrix[n]}]];
 If[Length[r]=!=n||r[[All,Range[n]]]=!=IdentityMatrix[n],Print["Singular matrix in inverse reconstruction"];Abort[]];
 answer=r[[All,Range[n+1,2 n]]];
 If[!And@@(zero /@ Flatten[answer.m-IdentityMatrix[n]]),Print["Exact inverse check failed"];Abort[]];answer];

root=DirectoryName[DirectoryName[$InputFileName]];Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
assert[q_,name_]:=If[TrueQ[q],Print["PASS ",name],Print["FAIL ",name];Quit[1]];
legacy[c_,vars_]:=Module[{atoms={},den,poly,mons,failed=False},
 Do[den=If[vars==={},LCM@@(Denominator /@ row),PolynomialLCM@@(Denominator /@ row)];poly=Expand[Cancel[den #]]& /@ row;
 If[vars==={},AppendTo[atoms,poly],If[!And@@(PolynomialQ[#,vars]& /@ poly),failed=True;Break[]];mons=Union[Flatten[First /@ CoefficientRules[#,vars]& /@ poly,1]];
 Do[AppendTo[atoms,Fold[Coefficient[#1,First[#2],Last[#2]]&,#,Transpose[{vars,mon}]]& /@ poly],{mon,mons}]],{row,c}];If[failed,$Failed,atoms]];
cases={{{1/(x-y),x/(x-y),0},{x+y,x-y,2}},{{0,0},{1,0}},{{1/x,1/y,1/(x y)}},{{x^2+y^2,2x y,x+y}},{{Sin[x],x,1}}};
assert[AllTrue[cases,ConformalIBP`Private`constantAtoms[#,{x,y}]===legacy[#,{x,y}]&],"coefficient-rule extraction exactly preserves the legacy constant blocks and order"];
assert[ConformalIBP`Private`constantAtoms[{{1/2,1/3},{0,0}},{}]===legacy[{{1/2,1/3},{0,0}},{}],"constant coefficients and zero rows preserve their behavior"];
assert[ConformalIBP`Private`constantAtoms[{},{x,y}]==={},"empty input is preserved"];
assert[$MessageList==={},"no unexpected messages"];Quit[0];

root=DirectoryName[$InputFileName];repo=DirectoryName[DirectoryName[root]];
Get[FileNameJoin[{repo,"Kernel","ConformalIBP.wl"}]];
{name,si,sn,out}=Take[$CommandLine,-4];i=ToExpression[si];workers=ToExpression[sn];
a=Get[FileNameJoin[{root,name<>"-DifferentialEquations.wl"}]];
n=Length[a["Basis"]];inds=Range[i,n,workers];v=a["Variables"];ax=a["Matrices"][v[[1]]];ay=a["Matrices"][v[[2]]];
res=Table[Together[D[ax[[j,k]],v[[2]]]-D[ay[[j,k]],v[[1]]]+Sum[ax[[j,h]]ay[[h,k]]-ay[[j,h]]ax[[h,k]],{h,n}]],{j,inds},{k,n}];
passed=AllTrue[Flatten[res],#===0&]&&$MessageList==={};
Export[out,<|"Name"->name,"Worker"->i,"Rows"->inds,"Entries"->Length[inds] n,"Passed"->passed,"SavedDimension"->n|>,"RawJSON"];
Quit[If[passed,0,1]];

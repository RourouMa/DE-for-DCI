root=DirectoryName[DirectoryName[$InputFileName]];Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
InitializeFiniteFlow["/home/april/Packages/finiteflow","/home/april/Packages/finiteflow/mathlink"];
cols={G[1],G[2],G[-1],G[-2]};eq={G[1]-G[-1],G[2]-G[-2]};q={G[-1],G[-2]};
Print[FiniteFlow`FFNewGraph[gr]];Print[FiniteFlow`FFGraphInputVars[gr,inn,{x,y}]];
Print[FiniteFlow`FFAlgSparseSolver[gr,node,{inn},{x,y},#==0& /@ eq,cols,"NeededVars"->q]];
Print[FiniteFlow`FFSolverSparseOutput[gr,node]];Print[FiniteFlow`FFGraphOutput[gr,node]];
Print[FiniteFlow`FFSparseSolverLearn[gr,cols]];Print[FiniteFlow`FFGraphEvaluateMany[gr,{{7338376896737913617,7718278679044643367}}]];FiniteFlow`FFDeleteGraph[gr];Quit[0];

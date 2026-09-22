(* Load ConformalIBP and kinematics.wl first. Only topology metadata is defined here. *)
top=G[1,1,-1,1,0,1,1,0,0,0,1,1,1,1,1,1,1,1];
f=CreateFamily[<|"Name"->"TennisCourt3TopologySectors","External"->{X1,X2,X3,X4},"Loops"->{Y1,Y2,Y3},"Kinematics"->kinematics,"Variables"->{x,y},"TopSector"->(Boole[#>0]& /@ Take[List@@top,15]),"Completion"->"FamilyOnly","SuperSectors"->{{1,2,4,6,7,8,9,10,11,12,13},{1,2,4,5,6,7,8,10,11,12,15},{1,2,3,4,5,6,7,9,11,12,14},Range[12]}|>];
<|"Family"->f,"Input"->top,"CampaignOptions"->{"SeedDomain"->"Extended","Solver"->"FiniteFlow","Workers"->24,"VerificationWorkers"->24,"BasisPreference"->"None"}|>

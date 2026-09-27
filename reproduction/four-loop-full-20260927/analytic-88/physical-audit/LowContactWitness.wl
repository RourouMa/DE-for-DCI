<|"Family" -> <|"Name" -> "Ladder2", "Variables" -> {x, y}, 
   "Kinematics" -> {SP[X1, X1] -> 2*x, SP[X3, X3] -> 2*x, SP[X2, X2] -> 2*y, 
     SP[X4, X4] -> 2*y, SP[X1, X3] -> 1 + x^2, SP[X2, X4] -> 1 + y^2, 
     SP[X1, X2] -> 0, SP[X1, X4] -> 0, SP[X2, X3] -> 0, SP[X3, X4] -> 0}, 
   "Propagators" -> {SP[X1, Y1], SP[X2, Y1], SP[X3, Y1], SP[X4, Y1], 
     SP[X1, Y2], SP[X2, Y2], SP[X3, Y2], SP[X4, Y2], SP[Y1, Y2]}, 
   "ExternalDerivatives" -> <|x -> {{x/(-1 + x^2), 0, -(-1 + x^2)^(-1), 0}, 
       {0, 0, 0, 0}, {-(-1 + x^2)^(-1), 0, x/(-1 + x^2), 0}, {0, 0, 0, 0}}, 
     y -> {{0, 0, 0, 0}, {0, y/(-1 + y^2), 0, -(-1 + y^2)^(-1)}, 
       {0, 0, 0, 0}, {0, -(-1 + y^2)^(-1), 0, y/(-1 + y^2)}}|>, 
   "ExternalPermutations" -> {{1, 2, 3, 4}, {1, 4, 3, 2}, {3, 2, 1, 4}, {3, 
    4, 1, 2}}, "SuperSectors" -> {}, "Completion" -> "LadderBlocks", 
   "IntegralOrdering" -> "TierReference", "MaxLoopPower" -> 2, 
   "Dimension" -> 4, "FiniteValidator" -> Automatic, 
   "External" -> {X1, X2, X3, X4}, "Loops" -> {Y1, Y2}, 
   "TopSector" -> {1, 1, 0, 1, 0, 1, 1, 1, 1}, "DeltaPropagators" -> 
    {SP[Y1, Y1], SP[Y2, Y2]}, "Gram" -> {{2*x, 0, 1 + x^2, 0}, 
     {0, 2*y, 0, 1 + y^2}, {1 + x^2, 0, 2*x, 0}, {0, 1 + y^2, 0, 2*y}}, 
   "Supports" -> {{1}, {1}, {1}, {1}, {2}, {2}, {2}, {2}, {1, 2}}, 
   "LoopLoopIDs" -> {9}, "Templates" -> {{1, 2, 4, 6, 7, 8, 9}}, 
   "LoopCount" -> 2, "Hash" -> 4848915201901409628300458425626466819762652743\
7915110617693077895422493660915|>, "ExternalSeed" -> 
  G[2, 0, 0, 0, 0, 2, 0, 0, 2, 1, 1], "ExternalOperator" -> 
  <|"Loop" -> 1, "A" -> X1, "B" -> X2, "Degree" -> {0, 0}|>, 
 "ExternalContact" -> (-2*(SP[ConformalIBP`Private`infinity, X2]*SP[X1, Y1] - 
     SP[ConformalIBP`Private`infinity, X1]*SP[X2, Y1]))/
   (SP[ConformalIBP`Private`infinity, Y1]*SP[X1, Y1]^2*SP[X2, Y1]^2), 
 "ExternalRejection" -> Failure["OutsideScalarProducts", 
   <|"MessageTemplate" -> 
     "Uncancelled infinity or out-of-family scalar products remain."|>], 
 "SafeSeed" -> G[2, 0, 0, 0, 0, 3, 0, 0, 2, 1, 1], 
 "SafeOperator" -> <|"Loop" -> 1, "A" -> X1, "B" -> Y2, 
   "Degree" -> {0, -1}|>, "SafeContact" -> -2/(SP[X1, Y1]*SP[X2, Y1]^3), 
 "SafeRelation" -> -2*BoundaryIntegral[1, {1, 3, 0, 0, 1}] + 
   4*x*G[0, 0, 0, 3, 0, 0, 3, 0, 1, 1, 1], 
 "Coupled" -> <|"Equations" -> {}, "Certificates" -> {}, 
   "BlockedApplications" -> {}, "RejectedCandidates" -> {}, 
   "PrimitiveApplications" -> 12, "SupportedApplications" -> 12, 
   "ContactKernelDimension" -> 0, "FiniteKernelDimension" -> 0, 
   "SearchScope" -> "Constant rational combinations of supplied seeds and \
degree-matched rotations; no completeness claim", 
   "NoInfinityTermsDiscarded" -> True|>|>

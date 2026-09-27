(* Options for RunPhysicalCoordinateDE with a validated source-retaining
   four-loop physical equation pool. These are not RunDE options.
   First close a low-pole simple finite covering set; compress after closure.
   Selected denominator powers: external-loop <=3, loop-loop <=2 (hard limits).
   Three-loop valid history: maximum relative excess 1; 150% * 1 = 3/2. *)
fourLoopPhysicalClosureOptions={
 "MasterCountUserUpperBound"->70,
 "GrowthChainThreshold"->3,
 "FiniteCoverPolicy"->"LowPoleClosureFirst",
 "MaxRelativeCoverExcess"->3/2
};

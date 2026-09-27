# Special-point boundary value and validation

The common regular boundary value has been derived in exact classical constants and checked against two independent original four-loop parametric integrations. The full four-loop DE remains the current priority. A boundary value at a singular point does not by itself determine all initial Taylor data.

At x=y=1, use X1=e+ + x e-, X3=x e+ + e-, X2=f+ + y f-, X4=y f+ + f-, with e+.e-=f+.f-=1 and other pairings zero. The complete supplied external Gram matrix is reproduced. All 53 selected four-loop integrands then coincide exactly, as recorded in FourBoundaryCoalescence.wl/json. Their common limit is B4, the top ladder at (1,1). Equality of values does not determine all initial Taylor data for a singular DE.

## Spectral candidate

In the positive-propagator normalization already used for the lower-loop functions, stereographic compactification of the coalesced L-loop chain suggests the following S^4 bilinear form. The conformal scalar operator D=-Delta(S^4)+2 has eigenvalues (l+1)(l+2). The external endpoint function at the orthogonal massive point is the continued distribution f(t)=pi delta(t)-i PV(1/t). Its Gegenbauer C_l^(3/2) coefficients obey

I_(2m)=pi (-1)^m (3/2)_m/m!,

I_(2m+1)=-4 i (-1)^m (2)_m/(3/2)_m.

Then, for L>=2,

B_L = (1/8) sum_(l>=0) (l+3/2) I_l^2 / [(l+1)(l+2)]^L.

The two parity sums are absolutely convergent for L>=2. The ordinary S^4 measure normalization is area(S^4)/(16 pi^2)=1/6; each internal conformal propagator contributes an inverse eigenvalue. The continuation and normalization must be documented and independently checked before adoption.

For L=4 the exact candidate is

B4 = (3 pi^2/256) * HypergeometricPFQ[{7/4,1/2,1/2,1/2,1/2,1,1,1},{3/4,3/2,3/2,2,2,2,2},1]
     - (5/1296) * HypergeometricPFQ[{9/4,1,1,1,1,1,3/2,3/2},{5/4,2,2,5/2,5/2,5/2,5/2},1].

special-point-spectral.py evaluates the parity sums by gamma-ratio asymptotics and Hurwitz-zeta tails, comparing (N,K,dps)=(80,40,75) and (120,56,90). Candidate B4:

0.112191776061148584806907917063711491366115773524831718119745587901146470366534913532859188

The same construction reproduces the independently extracted known two- and three-loop boundaries to about 70 digits:

B2=(pi^2-4)/16,

B3=[8+pi^2(-1+2 log 2)-7 zeta(3)]/16.

KnownThreeBoundary.wl obtains these independently via a regular Taylor recurrence of the legacy canonical three-loop DE along x=1-3s,y=1-s, with its exact boundary vector. It uses physical rows {1,27,34} of the original 34-dimensional representation for L={3,2,1}. B1=1/2.

## Radial reduction and explicit constant candidate

For an axisymmetric function, D=-(1-t^2) d_t^2+4t d_t+2. Substituting u=v/(1-t^2) gives D u=-v''. Let u_n=D^(-n) f and v_n=(1-t^2)u_n. On 0<t<1 write v_n=a_n+i b_n. The first solution is

a1=pi(1-t)/2, b1=t log t.

For n>=2, a_n''=-a_(n-1)/(1-t^2), b_n''=-b_(n-1)/(1-t^2), with a_n'(0)=0, a_n(1)=0, b_n(0)=b_n(1)=0.

B_L=pi a_(L-1)(0)/8+(1/4) integral_0^1 b_(L-1)(t)/t dt.

Explicitly a2=pi/2[(t-1)+2 log2-(1+t)log(1+t)] and a3(0)=pi(1-log2)^2.

b2'(t)=pi^2/8-1-(1/4) Li_2(1-t^2), and b2 vanishes at both endpoints. Integration by parts then gives the candidate

B4=pi^2(1-log2)^2/8-(1/4) integral_0^1 [pi^2/8-1-Li_2(1-t^2)/4]^2 dt.

This is a useful independent high-precision one-dimensional quadrature check and an avenue to an explicit HPL/classical-polylogarithm constant. In PolyLogTools conventions,

Li_2(1-t^2)=pi^2/6-2 G[1,0,t]-2 G[-1,0,t],

so b2'=pi^2/12-1+(G[1,0,t]+G[-1,0,t])/2. GIntegrate[ShuffleG[Expand[b2'^2]],t] can produce an explicit endpoint GPL expression. HPL 2.0 and PolyLogTools are already installed; see the legacy load_plt.wl. The GPL primitive has now been computed and its derivative residual is exactly zero. A fresh direct original boundary integral check is running.

Do not report the four-loop analytic function or all four-loop integration constants as solved on the basis of this boundary candidate.

## Classical constant expression obtained

The exact endpoint reduction gives

B4 = Li_4(1/2) + log(2)^4/24 - pi^4/720 + pi^2*(3-6*log(2)+2*log(2)^2)/24 + 7*zeta(3)/8 - 5/4.

Artifacts: B4RadialPrimitive.wl (exact derivative residual zero), B4GPLCandidate.wl, B4KnownConstantsCandidate.wl. Direct quadrature of the radial expression at 70 and 100 digits agrees with the independent spectral evaluation to about 90 digits (B4RadialCheck.json). These checks concern the derived representations; validation against the original four-loop parametric integral is still pending.

## Compactification normalization and continuation

For clarity, the coalesced L-loop chain has endpoint factors DA^(-1) DB^(-2), interior factors DB^(-2), and one ordinary massless propagator on each chain edge; for L=1 both endpoint factors combine to DA^(-2) DB^(-2). The ordinary integration normalization is d^4 k/pi^2, as in the independent parametric construction. Choose DB=k^2+1 and continue the squared external separation to q_E^2=-s, with s=2 at the requested point. Stereographic coordinates have Omega=2/(1+k^2), dOmega_4=Omega^4 d^4 k and |n_i-n_j|^2=Omega_i Omega_j |k_i-k_j|^2. The conformal scalar Green kernel on the unit S4 is [4 pi^2 |n_i-n_j|^2]^{-1} for D=-Delta+2. Thus all measure and propagator factors combine exactly to

B_L = (16 pi^2)^{-1} integral_(S4) f D^{-(L-1)} f dOmega_4,

with no complex conjugation, where f=DB/DA. Rotational invariance followed by analytic continuation takes f to [a+i sqrt(1-a^2) t]^{-1}, a=1-s/2. The limit a->0+ gives f=pi delta(t)-i PV(1/t). This continuation starts from positive a and fixes the branch. The original parametric integral at s=2 is below the two-mass threshold s=4 and is finite.

The axisymmetric measure is 2 pi^2(1-t^2) dt, and the Gegenbauer norm is h_l=(l+1)(l+2)/(l+3/2). These two facts give the spectral coefficient 1/8 and the denominator power L stated above. They also give the radial bilinear formula directly. The odd part is imaginary, so its square contributes with a minus sign; replacing the bilinear form by a Hermitian norm would be incorrect.

## Direct four-loop numerical checks completed

The original four-loop parametric integral was independently generated from the merged propagators, without reading the derived constant. Two randomized QMC runs at (1,1) returned:

- seed 20260927: 0.112192492323338319 +/- 0.000000960082532809187811;
- seed 918273: 0.112190040406717664 +/- 0.000000938986013127938195.

The exact expression differs by 0.746 and 1.848 reported errors, respectively. Both pass the stated three-error statistical comparison. See FourLoopBoundaryReport.json for the exact expression and full comparisons. The common boundary value for the selected 53 four-loop integrals is now available; the complete singular-system Taylor data and general four-loop analytic functions remain to be determined.

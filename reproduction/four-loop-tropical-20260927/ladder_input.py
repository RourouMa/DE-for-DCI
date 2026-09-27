"""Exact DCI ladder to momentum-graph mapping for feyntrop.

No analytic integral values or differential equations are read here.
The edge ordering follows active native external propagators, then chain edges.
"""
import itertools,json,math
from collections import defaultdict
from fractions import Fraction as Q

def ladder(loops,x,y,N,seed):
    x,y=Q(x),Q(y);L=loops;V=2*(L+1)
    graph=[];masses=[];powers=[];labels=[]
    for i in range(L):
        for a in range(4):
            present=(a in (1,3)) or (a==0 and i==0) or (a==2 and i==L-1)
            powers.append(int(present))
            if not present:continue
            edge={0:(0,L+1),1:(i,i+1),2:(L,2*L+1),3:(L+1+i,L+2+i)}[a]
            graph.append([list(edge),1]);masses.append((x,y,x,y)[a]);labels.append(f'X{a+1}Y{i+1}')
    for i in range(L-1):
        graph.append([[i+1,L+2+i],1]);masses.append(Q(0));labels.append(f'Y{i+1}Y{i+2}')
    pairs=[(i,i+1) for i in range(L-1)]
    pairs += [(i,j) for i in range(L) for j in range(i+1,L) if (i,j) not in pairs]
    powers += [int(j==i+1) for i,j in pairs]
    q3=-(1-x)**2
    gram=[[x+y,q3/2,x+y+(1-y)**2/2],[q3/2,q3,q3/2],[x+y+(1-y)**2/2,q3/2,x+y]]
    incoming=[[Q(0)]*3 for _ in range(V)]
    incoming[0]=[-1,0,0];incoming[L]=[1,-1,0]
    incoming[2*L+1]=[0,1,-1];incoming[L+1]=[0,0,1]
    P=[[sum(incoming[i][a]*gram[a][b]*incoming[j][b] for a in range(3) for b in range(3)) for j in range(V)] for i in range(V)]
    assert all(sum(row)==0 for row in P)
    assert len(graph)-V+1==L
    payload={'graph':graph,'dimension':4,'scalarproducts':[[float(v) for v in row] for row in P],
             'masses_sqr':list(map(float,masses)),'num_eps_terms':1,'lambda':0,'N':N,'seed':seed}
    exact={'Loops':L,'X':str(x),'Y':str(y),'Graph':graph,'MassesSquared':list(map(str,masses)),
           'ScalarProducts':[[str(v) for v in row] for row in P],'EdgeLabels':labels,
           'NativeIndices':powers+[1]*L,'Prefactor':math.factorial(sum(powers)-2*L-1),
           'PrefactorConvention':'Gamma(sum(nu)-L*D/2)/product Gamma(nu); all active nu=1; positive-propagator convention'}
    return payload,exact

def symanzik_from_forests(exact):
    edges=[e[0] for e in exact['Graph']];E=len(edges);V=max(max(e) for e in edges)+1
    P=[[Q(v) for v in row] for row in exact['ScalarProducts']];m=list(map(Q,exact['MassesSquared']))
    def forest(selected):
        parent=list(range(V))
        def find(i):
            while parent[i]!=i:i=parent[i]
            return i
        for k in selected:
            i,j=map(find,edges[k])
            if i==j:return None
            parent[i]=j
        return [find(i) for i in range(V)]
    U=defaultdict(Q);F=defaultdict(Q)
    for selected in itertools.combinations(range(E),V-1):
        c=forest(selected)
        if c is not None:
            mon=tuple(int(i not in selected) for i in range(E));U[mon]+=1
    for selected in itertools.combinations(range(E),V-2):
        c=forest(selected)
        if c is None:continue
        component=[i for i in range(V) if c[i]==c[0]]
        coefficient=-sum(P[i][j] for i in component for j in component)
        mon=tuple(int(i not in selected) for i in range(E));F[mon]+=coefficient
    for mon,coefficient in U.items():
        for i,mass in enumerate(m):
            powers=list(mon);powers[i]+=1;F[tuple(powers)]+=mass*coefficient
    return dict(U),{m:c for m,c in F.items() if c}

def merged_boundary(N,seed):
    # At x=y=1, q3=0 and q4=q2. Merge each repeated rail propagator.
    graph=[[[0,1],1],[[1,2],2],[[2,3],2],[[3,4],2],[[0,5],1],[[4,5],2],
           [[0,2],1],[[0,3],1],[[0,4],1]]
    masses=[1,1,1,1,1,1,0,0,0]
    P=[[0]*6 for _ in range(6)];P[1][1]=P[5][5]=2;P[1][5]=P[5][1]=-2
    payload={'graph':graph,'dimension':4,'scalarproducts':P,'masses_sqr':masses,
             'num_eps_terms':1,'lambda':0,'N':N,'seed':seed}
    exact={'Loops':4,'X':'1','Y':'1','Graph':graph,'MassesSquared':list(map(str,masses)),
           'ScalarProducts':[[str(v) for v in row] for row in P],
           'Prefactor':24,'PrefactorConvention':'Gamma(13-4*4/2)/Gamma(2)^4=24',
           'MergedEqualRailDenominators':True,'IntegrationDimension':8}
    return payload,exact

// Original, undecomposed four-loop 13-propagator Feynman parameter integral.
// No differential equations, analytic values, or boundary constants are read.
#include <cuba.h>
#include <cmath>
#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <chrono>

extern "C" double parametric(const double *a, double *out) {
  double W[4][4] = {{a[0],a[1],0,a[2]}, {0,a[3],0,a[4]},
                    {0,a[5],0,a[6]}, {0,a[7],a[8],a[9]}};
  double K[4][4]={}, inverse[4][4]={};
  double mass=0, qdiag=0;
  const double masses[4]={.25,.75,.25,.75};
  const double gram[4][4]={{0,0,0,0},{0,1,-.28125,1.03125},
                         {0,-.28125,-.5625,-.28125},{0,1.03125,-.28125,1}};
  for(int i=0;i<4;++i) {
    inverse[i][i]=1;
    for(int j=0;j<4;++j) {K[i][i]+=W[i][j]; mass+=W[i][j]*masses[j];qdiag+=W[i][j]*gram[j][j];}
  }
  for(int i=0;i<3;++i) {double b=a[10+i];K[i][i]+=b;K[i+1][i+1]+=b;K[i][i+1]=K[i+1][i]=-b;}
  // Positive definite matrix, no pivot needed. Simultaneously compute its inverse.
  double U=1;
  for(int p=0;p<4;++p) {
    double pivot=K[p][p];U*=pivot;
    for(int j=0;j<4;++j) {K[p][j]/=pivot;inverse[p][j]/=pivot;}
    for(int i=0;i<4;++i) if(i!=p) {
      double f=K[i][p];
      for(int j=0;j<4;++j) {K[i][j]-=f*K[p][j];inverse[i][j]-=f*inverse[p][j];}
    }
  }
  double contraction=0;
  for(int i=0;i<4;++i) for(int j=0;j<4;++j)
    for(int b=1;b<4;++b) for(int c=1;c<4;++c)
      contraction+=inverse[i][j]*W[i][b]*W[j][c]*gram[b][c];
  const double f_over_u=mass-qdiag+contraction;
  if(out) {out[0]=U;out[1]=U*f_over_u;}
  return 24/(U*U*std::pow(f_over_u,5));
}

int representation=0;
int integrand(const int *, const double *u, const int *, double *f, void *) {
  double a[13], jac=1;
  if(representation>=1) {
    // Exact partition into 13 primary sectors (largest parameter fixed to 1).
    // The same 12 cube coordinates enumerate the nonmaximal parameters.
    // Quadratic substitution suppresses endpoint singularities in each sector.
    double values[12];
    for(int i=0;i<12;++i) {
      if(representation==2) {values[i]=std::pow(u[i],4);jac*=4*u[i]*u[i]*u[i];}
      else {values[i]=u[i]*u[i];jac*=2*u[i];}
    }
    double sum=0;
    for(int anchor=0;anchor<13;++anchor) {
      int k=0;for(int i=0;i<13;++i) a[i]=i==anchor?1:values[k++];
      sum+=parametric(a,nullptr);
    }
    f[0]=sum*jac;
    return std::isfinite(f[0]) && f[0]>=0 ? 0 : -999;
  }
  // Cheng-Wu projective gauge a_12=1, other parameters on [0,infinity).
  for(int i=0;i<12;++i) {double t=1-u[i];a[i]=u[i]/t;jac/=t*t;}
  a[12]=1;
  f[0]=parametric(a,nullptr)*jac;
  return std::isfinite(f[0]) && f[0]>=0 ? 0 : -999;
}

int main(int argc,char **argv) {
  const int seed=argc>1?std::atoi(argv[1]):20260927;
  const long long budget=argc>2?std::atoll(argv[2]):50000000;
  representation=argc>3?std::atoi(argv[3]):0;
  long long neval=0;int fail=0;double val=0,err=0,prob=0;
  auto start=std::chrono::steady_clock::now();
  llVegas(12,1,integrand,nullptr,1,1e-4,1e-8,0,seed,
          1000000,budget,representation==2?100000:1000000,
          representation==2?100000:500000,10000,0,nullptr,nullptr,
          &neval,&fail,&val,&err,&prob);
  auto elapsed=std::chrono::duration<double>(std::chrono::steady_clock::now()-start).count();
  std::cout<<std::setprecision(17)<<"{\"Representation\":"<<representation<<",\"Seed\":"<<seed<<",\"MaxEval\":"<<budget
           <<",\"Evaluations\":"<<neval<<",\"CubaFail\":"<<fail
           <<",\"Value\":"<<val<<",\"ReportedError\":"<<err
           <<",\"CubaProbability\":"<<prob<<",\"Seconds\":"<<elapsed<<"}\n";
}

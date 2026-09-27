// One Cuba call on the complete sector sum; child processes evaluate one immutable function.
#include "four_top_p1_integral.hpp"
#include <cuba.h>
#include <chrono>
#include <iostream>
#include <iomanip>
using IC=four_top_p1_integral::integrand_t;
static int evaluate(const int*,const double*x,const int*,double*f,void*data){f[0]=(*static_cast<IC*>(data))(x);return 0;}
int main(int argc,char**argv){
 if(argc<3)return 2;int seed=std::stoi(argv[1]);long long budget=std::stoll(argv[2]);
 auto start=std::chrono::steady_clock::now();auto ss=four_top_p1_integral::make_integrands({},{});std::vector<IC> fs;int dim=0;
 for(auto&s:ss){fs.push_back(s.at(0));dim=std::max(dim,fs.back().number_of_integration_variables);}double pref=four_top_p1_integral::prefactor({},{}).at(0);
 IC total(dim,[fs,pref](double const* const x,secdecutil::ResultInfo*){long double z=0;for(const auto&f:fs)z+=f(x);return pref*double(z);});
 long long neval;int fail;double val,err,prob;
 std::cerr<<"Predeclared full sum Vegas: seed="<<seed<<" mineval=maxeval="<<budget<<" nstart=10000 nincrease=10000 epsrel=0.001 dim="<<dim<<" sectors="<<fs.size()<<" prefactor="<<pref<<" CUBACORES="<<getenv("CUBACORES")<<"\n"<<std::flush;
 llVegas(dim,1,evaluate,&total,1,.001,1e-8,0,seed,budget,budget,10000,10000,1000,0,nullptr,nullptr,&neval,&fail,&val,&err,&prob);
 std::cout<<std::setprecision(17)<<"{\"Method\":\"Vegas-single-total-sum\",\"Seed\":"<<seed<<",\"MinEval\":"<<budget<<",\"MaxEval\":"<<budget<<",\"ActualEval\":"<<neval<<",\"CubaFail\":"<<fail<<",\"CubaChiSquareProbability\":"<<prob<<",\"Sectors\":"<<fs.size()<<",\"Dimension\":"<<dim<<",\"Prefactor\":"<<pref<<",\"Value\":"<<val<<",\"Error\":"<<err<<",\"Seconds\":"<<std::chrono::duration<double>(std::chrono::steady_clock::now()-start).count()<<",\"SingleTotalIntegrand\":true,\"ReferenceRead\":false}"<<std::endl;
}

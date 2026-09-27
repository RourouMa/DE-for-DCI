// Integrate the pointwise sum of all sectors exactly once.
// This avoids a statistical-independence assumption between separate sectors.
#include "four_top_p1_integral.hpp"
#include <secdecutil/integrators/cuba.hpp>
#include <secdecutil/integrators/qmc.hpp>
#include <chrono>
#include <iostream>
#include <iomanip>
#include <string>
using namespace four_top_p1_integral;
int main(int argc,char**argv){
 if(argc<4)return 2;
 setenv("CUBACORES","0",1);
 std::string method=argv[1];int seed=std::stoi(argv[2]);long long budget=std::stoll(argv[3]);
 auto start=std::chrono::steady_clock::now();auto ss=make_integrands({},{});
 std::vector<four_top_p1_integral::integrand_t> fs;int dim=0;for(auto&s:ss){fs.push_back(s.at(0));dim=std::max(dim,fs.back().number_of_integration_variables);}
 double pref=prefactor({},{}).at(0);
 four_top_p1_integral::integrand_t total(dim,[fs,pref](double const* const x,secdecutil::ResultInfo*){long double z=0;for(const auto& f:fs)z+=f(x);return pref*double(z);});
 std::cerr<<"Predeclared single total integrand: method="<<method<<" seed="<<seed<<" maxeval="<<budget<<" sectors="<<fs.size()<<" dimension="<<dim<<" prefactor="<<pref<<" epsrel=0.001\n"<<std::flush;
 secdecutil::UncorrelatedDeviation<double> r;
 if(method=="vegas"){
 secdecutil::cuba::Vegas<double> q;q.seed=seed;q.mineval=10000;q.maxeval=budget;q.nstart=10000;q.nincrease=10000;q.epsrel=.001;q.epsabs=1e-8;r=q.integrate(total);
 }else{
 secdecutil::integrators::Qmc<double,12,integrators::transforms::Korobov<3>::type> q;
 q.randomgenerator.seed(seed);q.minn=1000;q.minm=16;q.maxeval=budget;q.cputhreads=4;q.epsrel=.001;q.epsabs=1e-8;q.devices={-1};r=q.integrate(total);
 }
 std::cout<<std::setprecision(17)<<"{\"Method\":\""<<method<<"\",\"Seed\":"<<seed<<",\"MaxEval\":"<<budget<<",\"Sectors\":"<<fs.size()<<",\"Dimension\":"<<dim<<",\"Prefactor\":"<<pref<<",\"Value\":"<<r.value<<",\"Error\":"<<r.uncertainty<<",\"Seconds\":"<<std::chrono::duration<double>(std::chrono::steady_clock::now()-start).count()<<",\"SingleTotalIntegrand\":true,\"ReferenceRead\":false}"<<std::endl;
}

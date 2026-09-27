#include <secdecutil/integrators/cuba.hpp>
#include <secdecutil/integrand_container.hpp>
#include <thread>
#include <atomic>
#include <iostream>
#include <iomanip>
using IC=secdecutil::IntegrandContainer<double,double const* const>;
int main(){
 setenv("CUBACORES","0",1);
 IC f(2,[](double const* const,secdecutil::ResultInfo*){return 1.;});
 IC g(2,[](double const* const,secdecutil::ResultInfo*){return 3.;});
 secdecutil::cuba::Vegas<double> q;
 q.seed=271828;q.mineval=100000;q.maxeval=100000;q.nstart=100000;q.nincrease=100000;
 q.epsrel=0.;q.epsabs=0.;
 std::cout<<std::setprecision(17);
 auto s1=q.integrate(f),s2=q.integrate(g);
 std::cout<<"serial "<<s1.value<<" "<<s2.value<<" sum "<<s1.value+s2.value<<" expected 4\n"<<std::flush;
 for(int k=0;k<5;k++){
   std::atomic<int> ready{0};double a=0,b=0;
   auto call=[&](const IC& z,double& out){ready.fetch_add(1);while(ready.load()<2){};out=q.integrate(z).value;};
   std::thread t1(call,std::cref(f),std::ref(a)),t2(call,std::cref(g),std::ref(b));t1.join();t2.join();
   std::cout<<"parallel "<<k<<" "<<a<<" "<<b<<" sum "<<a+b<<" expected 4\n"<<std::flush;
 }
}

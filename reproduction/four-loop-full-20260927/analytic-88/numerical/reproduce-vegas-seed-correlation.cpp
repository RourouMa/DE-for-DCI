#include <secdecutil/integrators/cuba.hpp>
#include <secdecutil/integrand_container.hpp>
#include <cmath>
#include <iostream>
#include <iomanip>
int main(){
 setenv("CUBACORES","0",1);using IC=secdecutil::IntegrandContainer<double,double const* const>;
 IC f(2,[](double const* const x,secdecutil::ResultInfo*){return std::pow(x[0],-.3)*std::exp(x[1]);});
 secdecutil::cuba::Vegas<double> q;q.seed=271828;q.mineval=100000;q.maxeval=100000;q.nstart=100000;q.nincrease=100000;q.epsrel=0;q.epsabs=0;
 auto a=q.integrate(f),b=q.integrate(f);IC twice(2,[f](double const* const x,secdecutil::ResultInfo*){return 2*f(x);});auto c=q.integrate(twice);
 std::cout<<std::setprecision(17)<<"{\"FirstValue\":"<<a.value<<",\"SecondValue\":"<<b.value<<",\"FirstError\":"<<a.uncertainty<<",\"SecondError\":"<<b.uncertainty<<",\"UncorrelatedSumError\":"<<std::hypot(a.uncertainty,b.uncertainty)<<",\"SingleTwiceIntegralValue\":"<<c.value<<",\"SingleTwiceIntegralError\":"<<c.uncertainty<<",\"ExactSingleIntegral\":"<<(std::exp(1.)-1.)/.7<<",\"SameSeedRepeated\":true}"<<std::endl;
}

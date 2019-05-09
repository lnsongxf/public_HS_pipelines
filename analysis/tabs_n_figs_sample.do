global fname tabs_n_figs_sample
 
set more off
pause on
set matsize 10000
set seed 123456

cap ssc install reghdfe
cap ssc install estout
cap ssc install binscatter
cap ssc install parmest

global bdir "/home/sweeneri/Projects/Pipelines/build"
global adir "/home/sweeneri/Projects/Pipelines/analysis"
global Edir "${adir}/output/cross_section/estimates"
global ddir "/home/sweeneri/Projects/Pipelines/DraftFiles"

capture log close
log using "$ddir/output/logs/${fname}.txt", replace text
set linesize 255

global hedonics "lnsqft _X*"
 
use if insample == 1 & random_id < 0.05 using $ddir/generated_data/dd_regdata, clear
	replace km_to_ng =  km_to_ng_nodistr
	replace km_to_anyPGEng = km_to_ng_nodistr_pge
	replace ft_to_ng =  ft_to_ng_nodistr
	replace ft_to_anyPGEng = ft_to_ng_nodistr_pge
    keep if !mi(gasutility)

save tempdat, replace


*** GRAPH PRICE AND QUANTITY TRENDS
use tempdat, clear

gen pgroup = "far"
replace pgroup = "close" if ft_to_ng < 2000

gen nsales = 1 
collapse (mean) lnprice sr_val_transfer yr_since_transfer_al (sum) nsales, by(pgroup ym_sale)
save cdat, replace

use cdat, clear
separate lnprice, by(pgroup)
drop lnprice
twoway line lnprice* ym, ytitle("log(price)") ///
		legend(label(1 "Within 2000ft" ) label(2 "Greater than 2000ft")) ///
		xline(608, lcolor(black) lpattern(dash)) 
gr export "$ddir/output/price_trend_full_sample.eps", as(eps) replace

exit
log close

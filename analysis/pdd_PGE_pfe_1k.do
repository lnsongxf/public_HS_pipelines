global fname pdd_PGE_pfe_1k
 
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
global ddir "/home/sweeneri/Projects/Pipelines/DraftFiles"

capture log close
log using "$ddir/output/logs/${fname}.txt", replace text
set linesize 255

global hedonics "lnsqft _X* _Dage_bin* _Duse*"
 
use if insample == 1 & random_id < 1.01 using $ddir/generated_data/dd_regdata, clear
	replace km_to_ng =  km_to_ng_nodistr
	replace km_to_anyPGEng = km_to_ng_nodistr_pge
	replace ft_to_ng =  ft_to_ng_nodistr
	replace ft_to_anyPGEng = ft_to_ng_nodistr_pge
    keep if gasutility == "PGE"
    keep if ft_to_ng <= 4000
 
capture drop _T* PGE
do $ddir/analysis/pdd_prep_distance_defs_pfe.do
 
* For flexible time trends, split pre-period into bubble and crash
	gen trendsegs = 0
	replace trendsegs = 1 if sr_date_transfer > td(31dec2006)
	replace trendsegs = 2 if period == "PostCrash"
	replace trendsegs = 3 if period == "PostExp"
	replace trendsegs = 4 if period == "PostLetter" 

    * Keep only houses with multiple transactions in sample
    bys sr_property_id: gen insample_trans = _N
    keep if insample_trans > 1

* Tract FE
eststo: reghdfe lnprice _T1k* $hedonics distress_cat_* , ///
absorb(census_tract mo_post_exp) vce(cluster census_tract) poolsize(50) fast
estadd local tfes "Tr" , replace
estadd local pfes "N" , replace
estimates save /home/sweeneri/Projects/Pipelines/analysis/output/cross_section/estimates/${fname}_Tr, replace

* Property FE
eststo: reghdfe lnprice _T1k* $hedonics distress_cat_* , ///
absorb( sr_property_id mo_post_exp ) vce(cluster census_tract) poolsize(50) fast
estadd local tfes "" , replace
estadd local pfes "Y"
estimates save /home/sweeneri/Projects/Pipelines/analysis/output/cross_section/estimates/${fname}_P, replace

* Tract-period FE
eststo: reghdfe lnprice _T1k* $hedonics distress_cat_* , ///
absorb( census_tract#trendsegs mo_post_exp ) vce(cluster census_tract) poolsize(50) fast
estadd local tfes "Tr-Per" , replace
estadd local pfes "N" , replace
estimates save /home/sweeneri/Projects/Pipelines/analysis/output/cross_section/estimates/${fname}_TrPer, replace

* Property FE Tract-period FE
eststo: reghdfe lnprice _T1k* $hedonics distress_cat_* , ///
absorb(sr_property_id census_tract#trendsegs mo_post_exp) vce(cluster census_tract) poolsize(50) fast
estadd local tfes "Tr-Per" , replace
estadd local pfes "Y" , replace
estimates save /home/sweeneri/Projects/Pipelines/analysis/output/cross_section/estimates/${fname}_PTrPer, replace

* Property FE Tract-period trends, FE
eststo: reghdfe lnprice _T1k* $hedonics distress_cat_* , ///
absorb(sr_property_id i.census_tract#i.trendsegs##c.sr_date_transfer mo_post_exp) vce(cluster census_tract) poolsize(50) fast
estadd local tfes "Tr-Per Trends" , replace
estadd local pfes "Y" , replace
estimates save /home/sweeneri/Projects/Pipelines/analysis/output/cross_section/estimates/${fname}_PTrPerTrends, replace

* Property FE Tract-qtr FE
eststo: reghdfe lnprice _T1k* $hedonics distress_cat_* , ///
absorb(sr_property_id census_tract#qtr_post_exp mo_post_exp) vce(cluster census_tract) poolsize(50) fast
estadd local tfes "Tr-Q" , replace
estadd local pfes "Y" , replace
estimates save /home/sweeneri/Projects/Pipelines/analysis/output/cross_section/estimates/${fname}_PTrQtr, replace



esttab, keep(_T*) label se starlevels(* 0.10 ** 0.05 *** 0.01)  ///
	stats(pfes tfes N r2,  ///
	labels("Property FE" "Other FE" "Observations" "R-Squared")) ///
	b(a3) nonotes title("$fname") nomtitles

log close 
exit

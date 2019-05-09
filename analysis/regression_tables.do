/*compares treatment effect with and without county year fe's assuming
same effect pre letter for pge and non */

set more off
pause on
set matsize 10000
set seed 123456

global bdir "/home/sweeneri/Projects/Pipelines/build"
global adir "/home/sweeneri/Projects/Pipelines/analysis"
global ddir "/home/sweeneri/Projects/Pipelines/DraftFiles"
global Edir "${adir}/output/cross_section/estimates"

cd "$adir/temp"

global fname regression_tables

capture log close
log using "$ddir/output/logs/${fname}.txt", replace text
set linesize 255

*cd "$adir/temp"


**********************************************************
***MAIN PGE DD TABLE

use if random_id < 0.01 using $ddir/generated_data/dd_regdata_05pct, clear
*NEED TO REASSIGN LABELS FOR ESTOUT
capture drop _T* PGE
qui: do $ddir/analysis/pdd_prep_distance_defs.do

eststo clear
local r = 1
/*COMBINE ESTIMATES FROM DIFFERENT FILES TO CREATE TABLES */
qui{
estimates use "$Edir/pdd_PGE_xs_1k_Tr"
	estimates store m`r'
    local cols = "`cols' m`r'"
    local r = `r' + 1
estimates use "$Edir/pdd_PGE_xs_1k_TrDist"
	estimates store m`r'
    local cols = "`cols' m`r'"
    local r = `r' + 1
estimates use "$Edir/pdd_PGE_xs_1k_TrPer"
	estimates store m`r'
    local cols = "`cols' m`r'"
    local r = `r' + 1

estimates use "$Edir/pdd_PGE_xs_1k_TrQtr"
	estimates store m`r'
    local cols = "`cols' m`r'"
    local r = `r' + 1

estimates use "$Edir/pdd_BayArea_xs_1k_TrPer"
	estimates store m`r'
    local cols = "`cols' m`r'"
    local r = `r' + 1
	estadd local bayarea "X" , replace
	
estimates use "$Edir/pdd_BayArea_xs_1k_TrQtr"
	estimates store m`r'
    local cols = "`cols' m`r'"
    local r = `r' + 1
	estadd local bayarea "X" , replace

estimates use "$Edir/pdd_PGE_xs_1k_covars_TrPer"
	estimates store m`r'
    local cols = "`cols' m`r'"
    local r = `r' + 1
	estadd local foreclose "X" , replace
}
global klist _T1k_bin_1000 _T1k_bin_2000 _T1k_exp_1000 _T1k_exp_2000 ///
             _T1k_let_1000 _T1k_let_2000 


esttab `cols', keep($klist) order($klist) label se starlevels(* 0.10 ** 0.05 *** 0.01)  ///
stats(tfes bayarea foreclose N r2,  ///
labels("Tract FEs" "Bay Area" "Foreclose" "Observations" "R-Squared")) ///
b(a3)  ///
nonotes addnotes("All models contain year-month fe's") ///
nomtitles

esttab  `cols' using "$ddir/output/main_PGE_dd.tex", replace se starlevels(* 0.10 ** 0.05 *** 0.01)  ///
keep($klist) order($klist)  label ///
stats(tfes bayarea foreclose N r2,  ///
labels("Tract FEs" "Bay Area" "Add'l. Covars." "Observations" "R-Squared")) ///
b(a3) nonotes booktabs nomtitles

*SAVE SMALLER TABLE FOR PRESENTATION
esttab m1 m3 m4 m7, keep(_T1k_exp_1000 _T1k_exp_2000 _T1k_let_1000 _T1k_let_2000) order($klist) label se starlevels(* 0.10 ** 0.05 *** 0.01)  ///
stats(tfes foreclose N r2,  ///
labels("Tract FEs" "Foreclose" "Observations" "R-Squared")) ///
b(a3)  ///
nonotes addnotes("All models contain year-month fe's") ///
nomtitles

esttab m1 m3 m4 m7 using "$ddir/output/main_PGE_dd_prez.tex", replace se starlevels(* 0.10 ** 0.05 *** 0.01)  ///
keep(_T1k_exp_1000 _T1k_exp_2000 _T1k_let_1000 _T1k_let_2000) order($klist)  label ///
stats(tfes foreclose N r2,  ///
labels("Tract FEs" "Add'l. Covars." "Observations" "R-Squared")) ///
b(a3) nonotes booktabs nomtitles

************************************************************
*Triple diff


**SAME TABLE WITH ADDITIONAL COVARIATES
use if random_id < 0.01 using $ddir/generated_data/dd_regdata_05pct, clear
*NEED TO REASSIGN LABELS FOR ESTOUT
capture drop _T* PGE
qui: do $ddir/analysis/pdd_prep_distance_defs_ddd.do

estimates clear
eststo clear
local cols = ""
local r = 0
/*COMBINE ESTIMATES FROM DIFFERENT FILES TO CREATE TABLES */
estimates use "$Edir/pdd_PGE_xs_1k_ddd_TrPer"
	estimates store m`r'
    local cols = "`cols' m`r'"
    local r = `r' + 1
estimates use "$Edir/pdd_PGE_xs_1k_ddd_TrQtr"
	estimates store m`r'
    local cols = "`cols' m`r'"
    local r = `r' + 1
	
estimates use "$Edir/pdd_BayArea_xs_1k_ddd_TrPer"
	estimates store m`r'
    local cols = "`cols' m`r'"
    local r = `r' + 1
	estadd local bayarea "X" , replace
estimates use "$Edir/pdd_BayArea_xs_1k_ddd_TrQtr"
	estimates store m`r'
    local cols = "`cols' m`r'"
    local r = `r' + 1
	estadd local bayarea "X" , replace
	
global klist _T1k_exp_1000 _T1k_exp_2000 _T1k_exp_1000_PGE _T1k_exp_2000_PGE ///
             _T1k_let_1000 _T1k_let_2000 _T1k_let_1000_PGE _T1k_let_2000_PGE

esttab `cols', keep($klist) order($klist) label se starlevels(* 0.10 ** 0.05 *** 0.01)  ///
stats(tfes bayarea N r2,  ///
labels("Tract FEs" "Bay Area" "Observations" "R-Squared")) ///
b(a3)  ///
nonotes addnotes("All models contain year-month fe's") ///
nomtitles

esttab  `cols' using "$ddir/output/triple_diff.tex", replace se starlevels(* 0.10 ** 0.05 *** 0.01)  ///
keep($klist) order($klist)  label ///
stats(tfes bayarea  N r2,  ///
labels("Tract FEs" "Bay Area" "Observations" "R-Squared")) ///
b(a3) nonotes booktabs nomtitles

capture log close
exit

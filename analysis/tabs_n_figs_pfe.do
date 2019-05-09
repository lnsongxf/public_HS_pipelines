global fname tabs_n_figs_pfe

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

*cd "$adir/temp"

capture log close
log using "$ddir/output/logs/${fname}.txt", replace text
set linesize 255

/*COMBINE ESTIMATES FROM DIFFERENT FILES TO CREATE TABLES */

*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* COMPARE DIFFERENT TIME FE'S WITH 2K BIN

use if random_id < 0.01 using $ddir/generated_data/dd_regdata, clear
*NEED TO REASSIGN LABELS FOR ESTOUT
capture drop _T* PGE
do $ddir/analysis/pdd_prep_distance_defs_pfe.do
 
*MAKE SAME TABLE WITH 1000 FOOT BINS
eststo clear
estimates clear
local r = 1
local cols = ""

estimates use "$Edir/pdd_PGE_pfe_1k_Tr"
	estimates store m`r'
    local cols = "`cols' m`r'"
    local r = `r' + 1
estimates use "$Edir/pdd_PGE_pfe_1k_P"
	estimates store m`r'
    local cols = "`cols' m`r'"
    local r = `r' + 1
estimates use "$Edir/pdd_PGE_pfe_1k_TrPer"
	estimates store m`r'
    local cols = "`cols' m`r'"
    local r = `r' + 1
estimates use "$Edir/pdd_PGE_pfe_1k_PTrPer"
	estimates store m`r'
    local cols = "`cols' m`r'"
    local r = `r' + 1

global klist _T1k_exp_1000 _T1k_exp_2000  ///
             _T1k_let_1000 _T1k_let_2000 

esttab `cols', keep($klist) order($klist) label se starlevels(* 0.10 ** 0.05 *** 0.01)  ///
stats(pfes tfes N r2,  ///
labels("Property FE" "Other FE" "Observations" "R-Squared")) ///
b(a3)  ///
nonotes addnotes("All models contain year-month fe's") ///
nomtitles

esttab  `cols' using "$ddir/output/pdd_PGE_pfe_1k.tex", replace se starlevels(* 0.10 ** 0.05 *** 0.01)  ///
keep($klist) order($klist)  label ///
stats(pfes tfes N r2,  ///
labels("Property FE" "Other FE" "Observations" "R-Squared")) ///
b(a3) nonotes booktabs nomtitles

capture log close
exit

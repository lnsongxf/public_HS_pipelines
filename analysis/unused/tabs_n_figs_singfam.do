global fname tabs_n_figs_signfam

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
estimates use "$Edir/pdd_PGE_xs_1k_singfam_Tr"
	estimates store m`r'
    local cols = "`cols' m`r'"
    local r = `r' + 1
estimates use "$Edir/pdd_PGE_xs_1k_singfam_TrDist"
	estimates store m`r'
    local cols = "`cols' m`r'"
    local r = `r' + 1
estimates use "$Edir/pdd_PGE_xs_1k_singfam_TrPer"
	estimates store m`r'
    local cols = "`cols' m`r'"
    local r = `r' + 1
estimates use "$Edir/pdd_PGE_xs_1k_singfam_TrQtr"
	estimates store m`r'
    local cols = "`cols' m`r'"
    local r = `r' + 1

}
global klist _T1k_bin_1000 _T1k_bin_2000 _T1k_exp_1000 _T1k_exp_2000 ///
             _T1k_let_1000 _T1k_let_2000 


esttab `cols', keep($klist) order($klist) label se starlevels(* 0.10 ** 0.05 *** 0.01)  ///
stats(tfes foreclose N r2,  ///
labels("Tract FEs" "Foreclose" "Observations" "R-Squared")) ///
b(a3)  ///
nonotes addnotes("All models contain year-month fe's") ///
nomtitles

esttab  `cols' using "$ddir/output/single_family.tex", replace se starlevels(* 0.10 ** 0.05 *** 0.01)  ///
keep($klist) order($klist)  label ///
stats(tfes bayarea foreclose N r2,  ///
labels("Tract FEs" "Bay Area" "Add'l. Covars." "Observations" "R-Squared")) ///
b(a3) nonotes booktabs nomtitles

exit

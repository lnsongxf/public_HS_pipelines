/*NOTES
- this code just runs the letter rd in the letter period 
- for PGE and SCG
*/


global fname PGE_letter_RD_for_draft
 
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

global hedonics "lnsqft _X*"

/**************************************************************
PGE RD
**************************************************************/
global outdir "$ddir/output"

**SELECT DATA
** only using post crash obs for controls
use if insample == 1 & random_id < 1.01 using $ddir/generated_data/dd_regdata, clear 
keep if gasutility == "PGE" & sr_date_transfer >= td(01jun2009)


*CREATE PERIODS TO DO RD WITHIN
gen per_letter = sr_date_transfer >= td(20apr2011) 
gen per_letter_summer = sr_date_transfer >= td(01jun2011) & sr_date_transfer <= td(09sept2011) 
gen per_exp = sr_date_transfer < td(20apr2011) & sr_date_transfer >= td(09sept2010) 
gen per_pre_summer = sr_date_transfer < td(09sept2010) & sr_date_transfer >= td(01jun2010)
gen per_pre = sr_date_transfer < td(09sept2010) & sr_date_transfer >= td(09sept2009)

*DROP DISTRIBUTION LINES
** NOTE: COULD RESTRICT JUST TO PGE LINES
replace ft_to_ng = ft_to_ng_nodistr
*replace ft_to_ng = ft_to_ng_nodistr_pge
foreach v of varlist ft_* {
	replace `v' = `v' / 1000
}

*center distance measure at the letter cuttoff 
gen dist = (ft_to_ng - 2)

gen noletter = cond(dist >0,1,0) // DEFINE IT THIS WAY SO IT MATCHES THE PREPACKED RD PROGRAM OUTPUTS
gen dist_above = dist*noletter
gen dist_2 = dist^2
gen dist_above_2 = dist_above^2

gen RD_Estimate = -noletter //*THIS WILL HAVE THE OPPOSITE SIGN OF WHAT COMES OUT OF RDROBUST
*NOTE: THIS MEANS THAT WE EXPECT A POSITIVE COEFFICIENT IF THE LETTER HAD AN EFFECT IN RDROBUST

gen price_sf = price/sa_sqft
save regdat, replace


/* FOR DRAFT ***/


use regdat, clear
keep if period== "PostLetter"
gen inrd =0
global xvars i.bedrooms i.rbaths i.distress_indicator km_to_roads  lnsqft


global hedonics "lnsqft _X* _Dage_bin* _Duse*"
global extracovars "_RB* ln_foreclose"

global xvars $hedonics 

*main spec, 1000 ft, no donut 
replace inrd = abs(dist) < 1 & abs(dist) > .00 // & distress_indicator==0


rdplot lnprice dist if inrd, ci(95) shade graph_options(title() ytitle("ln(price)"))
*rdplot lnprice dist if abs(dist) < .5 & abs(dist) > .00 , ci(95) shade graph_options(title(RD Plot) ytitle("ln(price)"))

graph export "$outdir/rdplot_pge_lnprice.eps", replace
*graph export "$outdir/rdplot_pge_lnprice.png", replace

eststo clear

qui{
eststo: reg lnprice RD_Estimate dist dist_above i.mo_post_exp  if inrd, robust
	estadd local covars " " , replace
	estadd local bw "1000 ft" , replace

eststo: areg lnprice RD_Estimate dist dist_above i.mo_post_exp if inrd, absorb(tract_id) robust
	estadd local covars " " , replace
	estadd local bw "1000 ft" , replace
	estadd local FEs "X" , replace

eststo: areg lnprice RD_Estimate dist dist_above i.mo_post_exp $xvars if inrd, absorb(tract_id) robust
	estadd local covars "X" , replace
	estadd local bw "1000 ft" , replace
	estadd local FEs "X" , replace

eststo: areg lnprice RD_Estimate dist dist_above i.mo_post_exp if abs(dist) < .5 & abs(dist) > .00, absorb(tract_id) robust
	estadd local covars " " , replace
	estadd local bw "500 ft" , replace
	estadd local FEs "X" , replace
	
}
esttab, keep(RD*) label se starlevels(* 0.10 ** 0.05 *** 0.01) nomtitle ///
	stats(bw covars FEs N,  ///
	labels("Bandwidth" "Hedonics" "TractFEs" "Observations" )) ///
	b(a3) 
	
esttab using "$outdir/rd_linear_pge_letter.tex", ///
	replace se starlevels(* 0.10 ** 0.05 *** 0.01) label ///
	keep(RD*) ///
	stats(bw covars FEs N,  ///
	labels("Bandwidth" "Hedonics" "TractFEs" "Observations" )) ///
	b(a3) nonotes booktabs nomtitles
/*
*BINSCATTER
	binscatter lnprice dist if inrd, rd(0) linetype(lfit) title("Log(price)") saving(temp_lp, replace) nodraw
	binscatter resid_lnp_x_tr dist if inrd, rd(0) linetype(lfit) title("Residual - Log(price)") saving(temp_lp_res, replace)  nodraw	
graph combine temp_lp.gph temp_lp_res.gph, xsize(8) 


graph export "$outdir/pge_binscat_1k_2plot.eps", replace
*/

capture log close
exit
















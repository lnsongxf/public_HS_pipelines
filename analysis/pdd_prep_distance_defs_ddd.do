*define this in a separate do file so i can rerun the same code 
*after dropping distribution lines in other files

gen PGEterr = (gasutility == "PGE")
* Note: in current approach, all PGE pipe is in PGE territory, but there are some houses closest to non-PGE pipe
* That is PGEpipe == 1 => PGEterr == 1 but not the converse

replace period = "PostCrash" if period == "Pre" & sr_date_transfer > (td(09sept2010) - 450)

/*NAMING CONVENTION
_T*_PERIOD_DISTANCE_PGE
T - DENOTES HOW DISTANCE IS SPECIFIED (IE 2K OR 660 FOOT BINS)

- SO TO RUN WITH PROPERTY FES, SPECIFY _T*_EXP AND _T*_LET
---- FOR CROSS SECTION, ONLY NEED _T*
*/

* 1000 FOOT BIN REG SETUP
* Now a bit more complicated.  
* Want to make sure we get the letter coverage right, so go with territory?
capture drop bin1k _T1k* 
global blist 2000 1000 
gen bin1k = 9999
foreach b in $blist {
	replace bin1k = `b' if ft_to_ng < `b'
}

* Territory main effect
gen _T1k___PGE = PGEterr
label var _T1k___PGE "PGE"

* Period main effect (mostly picked up by month FE?)
gen _T1k_exp = period == "PostExp"
label var _T1k_exp "SanBruno"
gen _T1k_let = period == "PostLetter"
label var _T1k_let "Letter"

* Period-territory
gen _T1k_exp__PGE = period == "PostExp" & PGEterr
label var _T1k_exp__PGE "PostExp-PGE"
gen _T1k_let__PGE = period == "PostLetter" & PGEterr
label var _T1k_let__PGE "PostLetter-PGE"

* Bin-related variables
foreach b in $blist {
    * main effect in and out of PGE by bin
	gen _T1k_bin_`b' = bin1k == `b'
	label var _T1k_bin_`b' "`b'ft"
	gen _T1k__`b'_PGE = _T1k_bin_`b'==1 & PGEterr
	label var _T1k__`b'_PGE "`b'ft-PGE"

    * explosion period in and out of PGE by bin
	gen _T1k_exp_`b' = period == "PostExp" & bin1k == `b'
	label var _T1k_exp_`b' "PostExp-`b'ft"
	gen _T1k_exp_`b'_PGE = _T1k_exp_`b'==1 & PGEterr
	label var _T1k_exp_`b'_PGE "PostExp-`b'ft-PGE"

    * letter period in and out of PGE by bin
	gen _T1k_let_`b' = period == "PostLetter" & bin1k == `b'
	label var _T1k_let_`b' "PostLetter-`b'ft"
	gen _T1k_let_`b'_PGE = _T1k_let_`b'==1 & PGEterr
	label var _T1k_let_`b'_PGE "PostLetter-`b'ft-PGE"
	
}


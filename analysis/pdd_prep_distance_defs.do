*define this in a separate do file so i can rerun the same code 
*after dropping distribution lines in other files

gen PGEpipe = cond(km_to_ng == km_to_anyPGEng,1,0)
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

*1000 FOOT BIN REG SETUP
cap drop bin1k 
cap drop _T1k* 
global blist 2000 1000
gen bin1k = 9999
foreach b in $blist {
	replace bin1k = `b' if ft_to_ng < `b'
}

* Period main effect (mostly picked up by month FE?)
gen _T1k_exp = period == "PostExp"
label var _T1k_exp "SanBruno"
gen _T1k_let = period == "PostLetter"
label var _T1k_let "Letter"

* Bin-related variables
foreach b in $blist {
    * main effect in and out of PGE by bin
	gen _T1k_bin_`b' = bin1k == `b'
	label var _T1k_bin_`b' "`b'ft"

    * explosion period by bin
	gen _T1k_exp_`b' = period == "PostExp" & bin1k == `b'
	label var _T1k_exp_`b' "PostExp-`b'ft"

    * letter period in and out of PGE by bin
	gen _T1k_let_`b' = period == "PostLetter" & bin1k == `b'
	label var _T1k_let_`b' "PostLetter-`b'ft"
	
}


/* Road bins by period-territory */
capture drop rbin _RB* 
global blist 2000 1000
gen rbin = 9999
gen ft_to_roads = 3280.84*km_to_roads
foreach b in $blist {
	replace rbin = `b' if ft_to_roads < `b'
}

foreach b in $blist {
    * main effect in and out of PGE by road bin
	gen _RB_bin_`b' = rbin == `b'
	label var _RB_bin_`b' "Hwy `b'ft"

    * explosion period by road bin
	gen _RB_exp_`b' = period == "PostExp" & rbin == `b'
	label var _RB_exp_`b' "PostExp- hwy `b'ft"

    * letter period by road bin
	gen _RB_let_`b' = period == "PostLetter" & rbin == `b'
	label var _RB_let_`b' "PostLetter-hwy `b'ft"
	
}



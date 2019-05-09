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



summ qtr_group_exp
global firstm = r(min)
global lastm = r(max)
summ qtr_group_exp if mo_post_exp == 0
global event = r(min)
global eventminus1 = $event - 1
global eventminus2 = $event - 2

gen tempm = qtr_group_exp

* 1000 FOOT BIN REG SETUP
* Now a bit more complicated.  
* Want to make sure we get the letter coverage right, so go with territory?
capture drop bin1k
cap drop _T1k* 
global blist 2000 1000
gen bin1k = 9999
foreach b in $blist {
	replace bin1k = `b' if ft_to_ng < `b'
}

* Qtr main effect unnecessary (month FE)
* Qtr interaction vars
* Bin-related variables
foreach b in $blist {
    * main effect in and out of PGE by bin
    gen _T1k_bin_`b' = bin1k == `b'
    label var _T1k_bin_`b' "`b'ft"

    foreach m of numlist $firstm/$eventminus2 $event/$lastm {
        * Qtr in and out of PGE by bin
        gen _T1k_qtr_`m'_`b' = tempm == `m' & bin1k == `b'
        label var _T1k_qtr_`m'_`b' "Month `m'-`b'ft"
    }	
}




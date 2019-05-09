global fname clean_history_data

global bdir "/home/sweeneri/Projects/Pipelines/build"
cd "$bdir/temp"
global rawdir "/scratch/sweeneri/DataQuick/Cleaned/History-CA"
global ddir "/home/sweeneri/Projects/Pipelines/DraftFiles"

capture log close
log using "$ddir/build/logs/${fname}.txt", replace text
set linesize 255

*not keeping vars from assessor here. can merge with assessor file later
global keepvars sr_property_id  bad_* inact_shell dup_flag sr_unique_id sr_date_transfer sr_val_transfer ///
		  mm_fips_muni_code mm_fips_county_name sr_date_filing sr_tran_type  ///
		  sr_loan_val_1 sr_quitclaim sr_arms_length_flag sr_full_part_code  ///
		  sr_mult_apn_flag_keyed sr_mult_port_code sr_lndr_seller_flag  ///
		  origination_loan origination_ltv transfer corporation_buyer corporation_seller  ///
		  group_sale partial_sale split_property ///
		  sr_lndr_code* sr_lndr_first* sr_lndr_last_* sr_buyer* sr_seller* ///
		  sr_loan* sr_parcel_nbr_raw estimated_interest_rate_* distress_indicator* ///
		  foreclosure_start foreclosure_completion_notice auction_sale short_sale
		 	

/* BREAK COUNTIES UP IN TO GROUPS AND AGGREGATE
this .dta file copied manually from history_filelist.xlsx on db. 
*it just breaks the list of file names up into groups so that the master file
lists are more manageable
*group 1 is the subset of counties for testing code
*/
use "$bdir/input/history_filelist.dta", clear
sum group
local ngroups = `r(max)'
di `ngroups'
gen tk = strpos(filename,"extras")
drop if tk > 0
drop tk
save $ddir/temp/flist, replace

/*loop through each group and save a file with all valid obs*/
forval g = 1/`ngroups' {

	clear
	gen str80 tfile = ""
	save "$ddir/temp/apdat", replace
	cd "$rawdir"

	use $ddir/temp/flist, clear
	keep if group  == `g'
	local tng = _N
	di `tng'
	save $ddir/temp/tflist, replace

	forval i = 1/`tng' {
		use $ddir/temp/tflist, clear
		local f = filename[`i']
		di "`f'"
		use "`f'", clear
		*these files aren't in assessor, so we don't have locations
		drop if sr_property_id == . | sr_property_id == 0
		keep $keepvars
*		gen tfile = `"`f'"'
		append using "$ddir/temp/apdat"
		save "$ddir/temp/apdat", replace
	}

	gen year_transfer = year(sr_date_transfer)
	capture drop tfile
	compress
	save $ddir/temp/CA_history_group`g'.dta, replace

}

capture log close
exit


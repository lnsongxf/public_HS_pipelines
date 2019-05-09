/*This code takes the cleaned DQ files, merges them with other data, 
creates new variables and selects sample to be used in analysis

** need to run the clean_*.do files first to replicate
*/


set seed 123456
global fname create_sample

global bdir "/home/sweeneri/Projects/Pipelines/build"
global adir "/home/sweeneri/Projects/Pipelines/analysis"

cd "$bdir/temp"
global rawdir "/home/sweeneri/Projects/Pipelines/Data/DataQuick/Cleaned/History-CA"
global ddir "/home/sweeneri/Projects/Pipelines/DraftFiles"

capture log close
log using "$ddir/build/logs/${fname}.txt", replace text
set linesize 255


*This section combines the history files togther into single dataset (they are currently stored in 5)
* it also generates a randomid AT THE PROPERTY LEVEL for subsetting
** dropping equity loans and refis. 
** Could potentially drop based on other criteria here to save space

clear
gen hgroup = 0
save "$ddir/temp/apdat", replace

forval i = 1/5 {
	use $ddir/temp/CA_history_group`i' , clear
	drop if bad_history_t == . /*missing means equity loans or refis */
	gen hgroup = `i'
	append using $ddir/temp/apdat, force
	save $ddir/temp/apdat, replace
	
}
save "$ddir/temp/apdat", replace


use "$ddir/temp/apdat", clear
sort sr_property_id
gen random_id = runiform()
bys sr_property: replace random_id = . if _n > 1
replace random_id = random_id[_n-1] if random_id == .
save $ddir/generated_data/CA_hist_all, replace



***MERGE WITH OTHER DATA
use $bdir/output/CA_assess_to_sanbruno.dta, clear
merge 1:1 sr_property_id using $bdir/output/CA_assess_to_PGE.dta, nogen
merge 1:1 sr_property_id using $bdir/output/CA_assess_to_pipes_nodistr.dta, nogen
merge 1:1 sr_property_id using $bdir/output/CA_assess_to_pipes_nodistr_pge.dta, nogen
merge 1:1 sr_property_id using $bdir/output/CA_assess_to_highways.dta, nogen
merge 1:1 sr_property_id using $bdir/output/CA_assess_to_pipes.dta, nogen
merge 1:1 sr_property_id using $bdir/output/CA_assess_to_top100_lines.dta, nogen
merge 1:1 sr_property_id using $bdir/output/CA_assess_to_top100_pts.dta, nogen

keep sr_property_id km_* x_ctm y_ctm
save sbdata, replace

*2010 tract ids
use $bdir/output/CA_assess_to_2010tracts.dta, clear
destring GEOID10, gen(areakey)
format areakey %11.0f
drop GEOID10
tostring areakey, gen(GEOID10) format(%11.0f)
gen te = length(GEOID10)
gen tract_id = substr(GEOID10,5,6)
replace tract_id = substr(GEOID10,6,6) if te == 11
destring tract_id, replace
destring sr_property_id, replace
keep sr_property_id tract_id GEOID10
save geomap10, replace

use if random_id < 1.01 using $ddir/generated_data/CA_hist_all, clear

****** Here push the date back by 30 days to account for agreement vs signing date ******
clonevar sr_date_transfer_DQorig = sr_date_transfer
replace sr_date_transfer = sr_date_transfer - 30
label var sr_date_transfer "Recorded date of transfer, minus 30 days to approx. true agreement date"
label var sr_date_transfer_DQorig "Original value of sr_date_transfer, as entered by DataQuick"

gen year = year(sr_date_transfer )
gen month = month(sr_date_transfer )
gen ym_sale = ym(year,month)
format ym_sale %tm

* convert to real prices (2013 $)
merge m:1 year month using $bdir/input/deflator, nogen keep(match master)
gen price = sr_val_transfer*deflator
label var price "Transfer price (2013$)"

*merge in distances
merge m:1 sr_property_id using sbdata, keep(match master) nogen

*merge in assessor data
merge m:1 sr_property_id using $ddir/generated_data/CA_assess_all.dta, keep(match master) nogen

*first need to bring in 2010 geolytics tracts
merge m:1 sr_property_id using geomap10, keep(match master) nogen
replace tract_id = sa_census_tract if tract_id  == -99
rename mm_fips_muni_code county_id  

*CLEAN UP DATA 
*keeping combined address and zip, and dropping parts 
drop sa_site_house_nbr sa_site_fraction sa_site_dir sa_site_street_name sa_site_suf sa_site_post_dir ///
 sa_site_unit_pre sa_site_unit_val tfile
*dropping some property vars
drop sa_township sa_section sa_val_assd_prev sa_nbr_bath_1qtr sa_nbr_bath_half sa_nbr_bath_3qtr sa_nbr_bath_full sa_nbr_bath_bsmt_half sa_nbr_bath_bsmt_full sa_privacy_code sa_roof_code sa_sqft_dq sa_val_transfer sa_doc_nbr_noval sa_date_transfer sa_date_noval_transfer inact_shell

*construct months since last transfer (any or arm's length)
*these will be 30-day rounded months, not calendar months
sort sr_property_id sr_date_transfer
by sr_property_id: gen te = _n
tsset sr_property_id te
gen mo_since_transfer_any = floor((sr_date_transfer - L.sr_date_transfer)/30)
label var mo_since_transfer_any "Months since any transfer"
gen tb = sr_date_transfer if transfer ==0
replace tb = L.tb if tb == .
gen mo_since_transfer_al = floor((sr_date_transfer - L.tb)/30)
order mo_* tb sr_property_id sr_date_transfer ym_sale sr_arms_length_flag sr_quitclaim
label var  mo_since_transfer_al "Months since arm's length transfer"
drop tb te
gen age = year_transfer - sa_yr_blt
label var age "Years since built" 

*CREATE SAMPLE
/*Notes
Selecting valid observations:
- keep if bad history == 0 (1 means problem with transaction, missing means not an armslength sale)
- assessor files only exist for most recent assessment (check this)
- there is a bad assessor flag which cuts sample significantly
---- don't necessarily need to use this if we do property fe's
- not doing anything with dup_flag right now */
gen valid_sale = 1
replace valid_sale = 0 if transfer == 1 // (from adam "transfer is equal to one if the transaction appears to be a non-arms-length transfer")
replace valid_sale = 0 if use_code_std > 4 // drop mobile homes and missing residential types, non residential
replace valid_sale = 0 if bad_history_transaction != 0 // (1 means problem with transaction, missing means not an armslength sale)
replace valid_sale = 0 if sa_x_coord == 0
replace valid_sale = 0 if dup_flag != 0 & dup_flag != 1 // 0 for non-duplicates

*could drop properties with many sales
capture drop te
gen te = cond(transfer == 0,1,0)
egen total_trans = sum(te), by(sr_property_id)
replace te = . if dup_flag != 0 // 0 for non-duplicates
egen total_trans_nd = sum(te), by(sr_property_id)
drop te

egen tract_bg = group(county_id tract_id sa_census_block_group)
egen census_tract = group(county_id tract_id)

save $ddir/generated_data/CA_sample, replace

capture log close
exit

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

global fname prep_pdd_data

cd "$adir/temp"

capture log close
log using "$ddir/output/logs/${fname}.txt", replace text
set linesize 255

*** GET NUMBER OF OBSERVATIONS
use if random_id < 1.05 & year > 1995 & hgroup <= 5 & valid_sale==1 using $ddir/generated_data/CA_sample, clear

drop if sr_date_transfer == .

gen postexp = sr_date_transfer > td(09sep2010) & sr_date_transfer <= td(20apr2011)
gen postletter = sr_date_transfer > td(20apr2011)
gen period = cond(postexp==1,"PostExp","Pre")
replace period = "PostLetter" if postletter == 1
replace period = "PostCrash" if period == "Pre" & sr_date_transfer > (td(09sept2010) - 450)

/* Generate necessary variables */
foreach d in to_ng to_anyPGEng to_ng_nodistr to_ng_nodistr_pge {
	gen ft_`d' = 3280.84*km_`d'
}

gen days_post_exp = sr_date_transfer - td(09sep2010) - 1
gen mo_post_exp = floor(days_post_exp/30)
egen mo_group_exp = group(mo_post_exp)
gen qtr_post_exp = floor(mo_post_exp/3)
egen qtr_group_exp = group(qtr_post_exp)
gen yr_post_exp = floor(mo_post_exp/12)
egen yr_group_exp = group(yr_post_exp)

gen qtr = ceil(month/3)

gen lnsqft = ln(sa_sqft)
rename sa_pool pool
rename sa_garage_carport garage
rename sa_nbr_bath baths
rename sa_nbr_bed bedrooms

bys sr_property_id: gen sample_trans = _N
tab sample_trans

gen lnprice = ln(price)
label var lnprice "log(price) $2013"

egen minage = min(age), by(sr_property_id)
gen mybad = cond(minage <0, 1,0)

gen age_bin = 0
forval i = 1/5 {
	local ta = `i'*10
	replace age_bin = `ta' if age > `ta'
}


gen yr_since_transfer_al = floor(mo_since_transfer_al/12)
*DROP PROPERTIES SOLD ARMS LENGTH LESS THAN A YEAR AGO
*drop if yr_since_transfer_al <1
gen _Dyr_since1 = yr_since_transfer_al <1
gen _Dyr_since3 = cond(yr_since_transfer_al < 3 & yr_since_transfer_al >=1,1,0)
gen _Dyr_since5 = cond(yr_since_transfer_al < 5 & yr_since_transfer_al >=3,1,0)
gen _Dyr_since10 = cond(yr_since_transfer_al < 10 & yr_since_transfer_al >=5,1,0)

xi i.age_bin i.use_code_std /* i.mo_group_exp i.qtr_group */, pref(_D) noomit

*THIS IS MISSING FOR 1/3 OBS
replace garage = 99 if garage == .
gen rbaths = round(baths,1)

xi i.rbaths i.bedrooms, pref(_X) noomit
gen _Xpool = cond(pool > 0,1,0)
gen _Xgarage = cond(garage == 99, 0,1)

*MERGE IN GAS UTILITY TERRITORIES BY COUNTY
* SEE TEAMWORK THREAD "PGE SERVICE TERRITORY" 
*THIS DATASET CREATED IN CountiesByGasUtility.xlsx
merge m:1 county_id using $bdir/output/CountiesByGasUtility, nogen keep(match master)
drop utility_notes

replace gasutility = "" if inlist(sa_site_city,"PALO ALTO","LONG BEACH","VERNON")

*MERGE IN NEIGHBORING FORECLOSURES
merge 1:1 sr_unique_id using "$adir/output/foreclose_list.dta", nogen keep(match master)

*SAMPLE RESTRICTIONS
gen insample = valid_sale
* Drop bottom and top 1% of transaction prices by year
egen pmin = pctile(lnprice), by(year) p(1)
egen pmax = pctile(lnprice), by(year) p(99)
*drop if lnprice < pmin | lnprice > pmax
replace insample = 0 if lnprice < pmin | lnprice > pmax	

* Keep if sold 5 times or fewer
replace insample = 0 if sample_trans > 5

* drop properties with erroneous or strange ages
replace insample = 0 if mybad ==1 | bad_age == 1

replace insample = 0 if yr_since_transfer_al < 1
drop _Dyr_since1

*drop properties more than 2 mile away from any pipeline
replace insample = 0 if km_to_ng_nodistr > 3.21869
*drop if within 1 km of the blast site
replace insample = 0 if km_to_explosion < 1

*drop if more than 5 bedrooms or bathrooms
replace insample = 0 if rbaths > 5 | bedrooms > 5
replace insample = 0 if sa_sqft < 250 | sa_sqft > 10000

* Drop corporate buyer
replace insample = 0 if corporation_buyer != 0
* Drop non-sale foreclosure process observations (transfers to REO, etc.)
replace insample = 0 if inlist(distress_indicator,1,2,3,4,5)

* Recast distress indicator
replace distress_indicator = 0 if mi(distress_indicator)
tab distress_indicator, gen(distress_cat_)

save $ddir/generated_data/dd_regdata_allvars, replace

use $ddir/generated_data/dd_regdata_allvars, clear
drop bad_* sr_parcel_nbr_raw sr_date_filing sr_loan_val_1 sr_full_part_code sr_mult_apn_flag_keyed ///
	sr_mult_port_code sr_lndr_seller_flag sr_loan_id_1 sr_loan_type_1 sr_lndr_code_1 ///
	sr_lndr_first_name_1 sr_lndr_last_name_1 estimated_interest_rate_1 sr_loan_id_2 ///
	sr_loan_type_2 sr_lndr_code_2 sr_lndr_first_name_2 sr_lndr_last_name_2 estimated_interest_rate_2 ///
	 sr_buyer_2 sr_seller_2 distress_indicator_2 sr_loan_val_3 sr_loan_id_3 sr_loan_type_3 sr_lndr_code_3 ///
	 sr_lndr_first_name_3 sr_lndr_last_name_3 estimated_interest_rate_3 distress_indicator_3 sr_seller_3 ///
	 sr_buyer_3 sr_loan_id_1_ext sr_loan_id_2_ext sr_loan_id_3_ext hgroup ///
	 distress_indicator_1m sr_buyer_1m sr_seller_1m deflator sa_parcel_nbr_primary sa_parcel_nbr_previous ///
	 sa_parcel_nbr_change_yr sa_owner_1_trust_flag sa_owner_1_type sa_owner_2_type sa_company_flag ///
	 sa_site_state sa_site_crrt ///
	 sa_tract_nbr sa_yr_land_appraise sa_appraise_val sa_val_market sa_val_market_land sa_val_market_imprv ///
	 sa_val_full_cash sa_condition_code sa_construction_qlty sa_fireplace_code sa_foundation_code sr_unique_id_noval ///
	 fips_place_code sa_shell_parcel_flag sa_garage_carport_num GEOID10
	 
save $ddir/generated_data/dd_regdata, replace

keep if random_id < .05
save $ddir/generated_data/dd_regdata_05pct, replace

capture log close

exit

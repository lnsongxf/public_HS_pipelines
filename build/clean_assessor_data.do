global fname clean_assessor_data

global fdir "/home/sweeneri/Projects/Pipelines/build"
cd "$fdir/temp"
global rawdir "/scratch/sweeneri/DataQuick/Cleaned/Assessor-CA"
global ddir "/home/sweeneri/Projects/Pipelines/DraftFiles"

capture log close
log using "$ddir/build/logs/${fname}.txt", replace text
set linesize 255

global keepvars use_code_std sr_unique_id_noval sr_unique_id sa_yr_land_appraise ///
	sa_yr_blt_effect sa_yr_blt sa_y_coord sa_x_coord sa_view_code sa_val_transfer  ///
	sa_val_market_land sa_val_market_imprv sa_val_market sa_val_full_cash sa_val_assd_prev ///
	sa_tract_nbr sa_township sa_structure_nbr sa_structure_code sa_sqft_dq sa_sqft_assr_tot ///
	sa_sqft sa_site_zip sa_site_unit_val sa_site_unit_pre sa_site_suf sa_site_street_name ///
	sa_site_state sa_site_post_dir sa_site_plus_4 sa_site_mail_same sa_site_house_nbr  ///
	sa_site_fraction sa_site_dir sa_site_crrt sa_site_city sa_site_address sa_shell_parcel_flag  ///
	sa_section sa_roof_code sa_property_id sa_privacy_code sa_pool_code sa_patio_porch_code  ///
	sa_parcel_nbr_primary sa_parcel_nbr_previous sa_parcel_nbr_change_yr sa_owner_2_type  ///
	sa_owner_1_type sa_owner_1_trust_flag sa_nbr* bad_* ///
	sa_lotsize sa_heat_src_fuel_code sa_heat_code sa_grg_1_code sa_geo_qlty_code  ///
	sa_garage_carport_num sa_garage_carport sa_foundation_code sa_fireplace_code sa_fin_sqft_tot  ///
	sa_exterior_1_code sa_doc_nbr_noval sa_date_transfer sa_date_noval_transfer sa_cool_code  ///
	sa_construction_qlty sa_condition_code sa_company_flag sa_census_tract sa_census_block_group  ///
	sa_bldg_code sa_architecture_code sa_appraise_yr sa_appraise_val mm_fips_state_code  ///
	mm_fips_muni_code mm_fips_county_name inact_shell fips_place_code assr_year

clear
gen str80 tfile = ""
save "$ddir/temp/apdat", replace
cd "$rawdir"
fs 
foreach f in `r(files)' {
   di "`f'"
   local tk = strpos("`f'","extras")
   if `tk' == 0 {
	use "`f'", clear
	keep $keepvars
	gen tfile = `"`f'"'
	append using "$ddir/temp/apdat"
	save "$ddir/temp/apdat", replace
   }	
}

use "$ddir/temp/apdat", clear
compress
*not sure why adam named this sa_property_id here and sr_pro in the history files. 
rename sa_property_id sr_property_id
save $ddir/generated_data/CA_assess_all.dta, replace

use $ddir/generated_data/CA_assess_all.dta, clear
keep sr_property_id sa_y_coord sa_x_coord mm_fips_county_name sa_site_address sa_site_city sa_site_zip bad_address
save $ddir/generated_data/CA_property_xy_assess.dta, replace

capture log close

exit


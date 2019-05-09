* Just extract county codes to make mapping faster

use /home/sweeneri/Projects/Pipelines/build/output/CA_assess_all.dta, clear
keep sr_property_id mm_fips_muni_code mm_fips_county_name
save /home/sweeneri/Projects/Pipelines/build/temp/dq_CA_cty.dta, replace

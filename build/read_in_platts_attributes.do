* read_in_platts_attributes.do
* Evan Herrnstadt
* 12/16/2015

* Read in dbf files from Platts' shapefiles
* Create Stata datafiles

if "`c(username)'" == "Evan" {
	global path = "C:\Users\Evan\Dropbox\Pipelines\"
}

cd $path/Data/Platts_CA_maps

shp2dta using Crude_Oil_Pipelines.shp, database(dbf.dta) coordinates(temp.dta) replace
use dbf.dta, clear
foreach v of varlist * {
	local name = lower("`v'")
	rename `v' `name'
	}
gen segmentid = _n-1
gen pipecat = "Crude"
replace diameter = . if diameter == -99

foreach v of varlist * {
	qui count if !mi(`v')
	if r(N) == 0 drop `v'
	}

label var name "Common name of pipeline"
rename name pipeline
label var sys_name "Name of pipeline segment/location/system"
label var own_name "Name of primary pipeline owner"
rename own_name owner
label var diameter "Pipeline diameter in inches"
label var product "Product delivered through pipeline"
label var status "Operational status"
label var pos_rel "Positional reliability"
label var stlength__ "Length of feature in internal units"
rename stlength__ platts_gis_length
label var segmentid "Unique id (created by EH, the FID produced by GIS)"
label var pipecat "Pipeline category (Crude, NG, Products)"

save "$path/Build/Output/Platts_Crude_Attributes.dta", replace

shp2dta using Natural_Gas_Pipelines.shp, database(dbf.dta) coordinates(temp.dta) replace
use dbf.dta, clear
foreach v of varlist * {
	local name = lower("`v'")
	rename `v' `name'
	}
gen segmentid = _n-1
gen pipecat = "NG"
replace owner_id = "" if owner_id == "-99"
replace diameter = . if diameter == -99
replace ferc_code = . if ferc_code == 0
replace system1 = system1 + " " + system2 if !mi(system2)
drop system2 country

foreach v of varlist * {
	qui count if !mi(`v')
	if r(N) == 0 drop `v'
	}

label var pipeline "Common name of pipeline"
label var bentek_id "Bentek issued ID"
label var owner "Name of primary pipeline owner"
label var owner_id "Platts issued ID for the pipeline's owner"
label var type "Type of pipeline, i.e., Interstate, Intrastate, Gathering, etc."
label var zone "Pipeline rate zone"
label var status "Operational status"
label var insvcdate "Official in-service date"
label var announced "Date when a project was announced" 
label var docketnum "FERC filing docket number"
label var diameter "Pipeline diameter in inches"
label var system1 "Additional pipeline system information"
label var posrel "Positional reliability"
rename posrel pos_rel
label var gaspipe_id "Platts Issued ID for the record"
rename gaspipe_id platts_id
label var modified "Date modified"
label var stlength__ "Length of feature in internal units"
rename stlength__ platts_gis_length
label var shortname "Short version of owner name"
label var name "Full owner name"
label var segmentid "Unique id (created by EH, the FID produced by GIS)"
label var pipecat "Pipeline category (Crude, NG, Products)"
label var ferc_code "FERC code for pipeline owner"

save "$path/Build/Output/Platts_NG_Attributes.dta", replace

shp2dta using NGL_Pipelines.shp, database(dbf.dta) coordinates(temp.dta) replace
use dbf.dta, clear
foreach v of varlist * {
	local name = lower("`v'")
	rename `v' `name'
	}
gen segmentid = _n-1
gen pipecat = "Product/NGL"
replace charid = "" if charid == "-99"
replace diameter = . if diameter == -99
replace compid = . if compid == -99
foreach v of varlist * {
	qui count if !mi(`v')
	if r(N) == 0 drop `v'
	}

label var charid "Platts assigned ID"
label var compname "Owning company name"
label var compid "Platts issued ID for the pipeline's owner"
label var pipeid "Platts Issued ID for the record"
rename pipeid platts_id
label var diameter "Pipeline diameter in inches"
label var system "System name for a given group of pipelines"
label var product "Product delivered by the pipelines"
label var category "Product category"
label var projstatus "Operational status"
rename projstatus status
label var posrel "Positional reliability"
rename posrel pos_rel
label var stlength__ "Length of feature in internal units"
rename stlength__ platts_gis_length
label var segmentid "Unique id (created by EH, the FID produced by GIS)"
label var pipecat "Pipeline category (Crude, NG, Products)"

save "$path/Build/Output/Platts_ProductsNGL_Attributes.dta", replace

!rm temp.dta 
!rm dbf.dta


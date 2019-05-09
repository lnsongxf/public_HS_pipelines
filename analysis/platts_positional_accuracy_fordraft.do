global fname platts_positional_accuracy
* platts_positional_accuracy.do
* Evan Herrnstadt
* 7/13/2016

* How accurate is the pipeline location in the shapefiles?

global bdir = "/home/sweeneri/Projects/Pipelines/build/"
global adir = "/home/sweeneri/Projects/Pipelines/analysis/"
global ddir "/home/sweeneri/Projects/Pipelines/DraftFiles"

capture log close
log using "$ddir/output/logs/${fname}.txt", replace text
set linesize 255

use "$bdir/output/Platts_NG_Attributes.dta", clear

gen accuracy_ft = .
replace accuracy_ft = 165 if regexm(pos_rel,"165")
replace accuracy_ft = 40 if regexm(pos_rel,"40")
gen owner_cat = "Other"
replace owner_cat = "PG&E" if owner == "Pacific Gas and Electric Co."
replace owner_cat = "SoCal" if owner == "Southern California Gas Co."
replace owner_cat = "SDG&E" if owner == "San Diego Gas & Electric Co."
label var owner_cat "Pipeline Owner"

gen largediam = (diameter > 6)
gen missingdiam = (inlist(diameter,0,-99))
gen distrib = regexm(system1,"Dcust.*|Gcust.*|Dreg.*|Distribution.*")
gen misys1 = mi(system1)
gen mitype = mi(type)

gen trans_pipe = (distrib == 0 & (diameter > 6 | (inlist(diameter,0,-99) & ///
				!(misys1 == 1 & mitype == 1))))
label def translbl 0 "Distr./Unk." 1 "Trans." 
label values trans_pipe translbl
label var trans_pipe "Pipeline Type"

label def acclbl 40 "Within 40 ft." 165 "Within 165 ft." 
label values accuracy_ft acclbl
label var accuracy_ft "Minimum Positional Accuracy"

qui: tabout owner_cat trans_pipe [aw=platts_gis_length] using $ddir/output/platts_ng_accuracy_means.tex, ///
cells(mean accuracy_ft) format(1c 1c 1c) clab(_ _ _) ///
layout(rb) sum ///
style(tex) bt ///
topf($adir/code/top.tex) topstr(\textwidth) ptotal(none) botf($adir/code/bot.tex) ///
 h3(nil) replace

qui: tabout owner_cat accuracy_ft [aw=platts_gis_length] if trans_pipe == 1 using $ddir/output/platts_ng_accuracy_trans.tex, ///
cells(row) format(1c 1c 1c) clab(_ _ _) ///
layout(rb) ///
style(tex) bt ///
topf($adir/code/top.tex) topstr(\textwidth) ptotal(none) botf($adir/code/bot.tex) ///
 h3(Transmission lines only) replace


tabout owner_cat trans_pipe [aw=platts_gis_length] using $adir/temp/temp.txt, ///
cells(mean accuracy_ft) format(1c 1c 1c) clab(_ _ _) ///
layout(rb) sum ///
replace

tabout owner_cat accuracy_ft [aw=platts_gis_length] if trans_pipe == 1 using $ddir/output/temp/temp.txt, ///
cells(row) format(1c 1c 1c) clab(_ _ _) ///
layout(rb) replace

erase $adir/temp/temp.txt
capture log close
exit


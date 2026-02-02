/*******************************************************************************
* PROJECT:  		SimPaths EU 
* SECTION:			Validation
* OBJECT: 			Partnership
* AUTHORS:			Patryk Bronka, Ashley Burdett 
* LAST UPDATE:		06/2025 (AB)
* COUNTRY: 			Poland 
********************************************************************************
* NOTES: 			
*******************************************************************************/

********************************************************************************
* 1 : Mean values over time
********************************************************************************
********************************************************************************
* 1.1 : Mean values over time, All
********************************************************************************

* Prepare validation data
use year dwt valid_dcpst_p valid_dcpst_s  using ///
	"$dir_data/${country}-eusilc_validation_sample_long.dta", clear

	
collapse (mean) valid_dcpst_p valid_dcpst_s   [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year sim_dcpst_p sim_dcpst_s sim_has_partner using ///
	"$dir_data/simulated_data.dta", clear

collapse (mean) sim_dcpst_p sim_dcpst_s sim_has_partner, by(run year)
	
collapse (mean) sim_dcpst_p sim_dcpst_s sim_has_partner ///
		 (sd) sim_dcpst_p_sd = sim_dcpst_p ///
		 sim_dcpst_s_sd = sim_dcpst_s ///
		 sim_has_partner_sd = sim_has_partner ///
		 , by(year)
		 
foreach varname in sim_dcpst_p sim_dcpst_s  sim_has_partner {
	
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd

}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
twoway (rarea sim_dcpst_p_high sim_dcpst_p_low year, sort color(green%20) ///
	legend(label(1 "Simulated"))) ///
(line valid_dcpst_p year, sort color(green) ///
	legend(label(2 "SILC "))), ///
	title("Partnered") ///
	xtitle("Year", size(small)) ///
	ytitle("Share", size(small)) ///
	ylabel(0.5[0.1]0.7, labsize(small)) ///
	xlabel(,labsize(small)) ///
	graphregion(color(white)) ///
	note("Notes: Sample contains all individual ages ${min_age}-${max_age}.", size(vsmall))	

* Save figure
graph export ///
"$dir_output_files/partnership/validation_${country}_partnered_ts_${min_age}_${max_age}_both.jpg", ///
	replace width(2400) height(1350) quality(100)

	
twoway (rarea sim_dcpst_p_high sim_dcpst_p_low year, sort color(green%20) ///
	legend(label(1 "Partnered, simulated"))) ///
(line valid_dcpst_p year, sort color(green) ///
	legend(label(2 "Partnered, SILC "))) ///
(rarea sim_dcpst_s_high sim_dcpst_s_low year, sort color(red%20) ///
	legend(label(3 "Single, simulated"))) ///
(line valid_dcpst_s year, sort color(red) ///
	legend(label(4 "Single, SILC "))), ///
	title("Partnership Status") ///	
	xtitle("Year", size(small)) ///
	ytitle("Share", size(small)) ///
	ylabel(0.5[0.1]0.7, labsize(small)) ///
	xlabel(,labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white)) ///
	note("Notes: Sample contains all individual ages ${min_age}-${max_age}.", size(vsmall))	
	
graph export ///
"$dir_output_files/partnership/validation_${country}_partnership_ts_${min_age}_${max_age}_both.jpg", ///
	replace width(2400) height(1350) quality(100)	
	
graph drop _all	
	
********************************************************************************
* 1.2 : Mean values over time, All, By children 
********************************************************************************

* Load validation data
use year dwt valid_dcpst_p_children_0 valid_dcpst_p_children_1 ///
	valid_dcpst_p_children_2 valid_dcpst_p_children_3p ///
	valid_dcpst_s_children_0 valid_dcpst_s_children_1 ///
	valid_dcpst_s_children_2 valid_dcpst_s_children_3p ///
	using ///
	"$dir_data/${country}-eusilc_validation_sample_long.dta", clear

collapse (mean) valid_dcpst_p_children_0 valid_dcpst_p_children_1 ///
	 valid_dcpst_p_children_2 valid_dcpst_p_children_3p ///
	 valid_dcpst_s_children_0 valid_dcpst_s_children_1 ///
	 valid_dcpst_s_children_2 valid_dcpst_s_children_3p ///
	 [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace

* Load simulated data
use run year sim_dcpst_p_children_0 sim_dcpst_p_children_1 ///
	sim_dcpst_p_children_2 sim_dcpst_p_children_3p sim_dcpst_s_children_0 ///
	sim_dcpst_s_children_1 sim_dcpst_s_children_2 ///
	sim_dcpst_s_children_3p ///
	using "$dir_data/simulated_data.dta", clear

collapse (mean) sim_dcpst_p_children_0 sim_dcpst_p_children_1 ///
	sim_dcpst_p_children_2 sim_dcpst_p_children_3p ///
	sim_dcpst_s_children_0 sim_dcpst_s_children_1 ///
	sim_dcpst_s_children_2 sim_dcpst_s_children_3p, ///
	by(run year)
	
collapse (mean) sim_dcpst_p_children_0 sim_dcpst_p_children_1 ///
	 sim_dcpst_p_children_2 sim_dcpst_p_children_3p sim_dcpst_s_children_0 ///
	 sim_dcpst_s_children_1 sim_dcpst_s_children_2 ///
	 sim_dcpst_s_children_3p  ///
	(sd) sim_dcpst_p_children_0_sd = sim_dcpst_p_children_0 ///
		sim_dcpst_p_children_1_sd = sim_dcpst_p_children_1 ///
		sim_dcpst_p_children_2_sd = sim_dcpst_p_children_2 ///
		sim_dcpst_p_children_3p_sd = sim_dcpst_p_children_3p ///
		sim_dcpst_s_children_0_sd = sim_dcpst_s_children_0 ///
		sim_dcpst_s_children_1_sd = sim_dcpst_s_children_1 ///
		sim_dcpst_s_children_2_sd = sim_dcpst_s_children_2 ///
		sim_dcpst_s_children_3p_sd = sim_dcpst_s_children_3 ///
		, by(year)
		 
foreach varname in sim_dcpst_p_children_0 sim_dcpst_p_children_1 sim_dcpst_p_children_2 sim_dcpst_p_children_3p sim_dcpst_s_children_0 sim_dcpst_s_children_1 sim_dcpst_s_children_2 sim_dcpst_s_children_3p  {
	
	gen `varname'_h = `varname' + 1.96*`varname'_sd
	gen `varname'_l = `varname' - 1.96*`varname'_sd

}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figures

// Labels of simulated variables are used as titles for the graphs below
label var sim_dcpst_p_children_0 "Partnered, no children"
label var sim_dcpst_p_children_1 "Partnered, 1 child"
label var sim_dcpst_p_children_2 "Partnered, 2 children"
label var sim_dcpst_p_children_3p "Partnered, 3+ children"
label var sim_dcpst_s_children_0 "Not partnered, no children"
label var sim_dcpst_s_children_1 "Not partnered, 1 child"
label var sim_dcpst_s_children_2 "Not partnered, 2 children"
label var sim_dcpst_s_children_3p "Not partnered, 3+ children"

foreach varname in dcpst_p_children_0 dcpst_p_children_1 dcpst_p_children_2 dcpst_p_children_3p dcpst_s_children_0 dcpst_s_children_1 dcpst_s_children_2 dcpst_s_children_3p {
	
	local vtext : variable label sim_`varname'
	if `"`vtext'"' == "" local vtext "sim_`varname'" 
	twoway (rarea sim_`varname'_h sim_`varname'_l year, sort color(green%20) ///
		legend(label(1 "Simulated") position(6) rows(1))) ///
		(line valid_`varname' year, sort color(green) ///
		legend(label(2 "SILC"))), ///
		subtitle("`vtext'") ///
		name(`varname', replace) ///
		ytitle("Share", size(small)) ///
		xtitle("". size(small)) ///
		ylabel(,labsize(small)) ///
		xlabel(,labsize(small)) ///
		graphregion(color(white)) 

}

grc1leg dcpst_p_children_0 dcpst_p_children_1 dcpst_p_children_2 ///
	dcpst_p_children_3p dcpst_s_children_0 dcpst_s_children_1 ///
	dcpst_s_children_2 dcpst_s_children_3p, ///
title("Partnership and Number of Children") ///
	legendfrom(dcpst_p_children_0) ///
	graphregion(color(white)) ///
	note("Notes: Samples contains all individual ages 18-65. ", size(vsmall)) 
	
graph export ///
"$dir_output_files/partnership/validation_${country}_partnership_children_ts_${min_age}_${max_age}_both.jpg", ///
	replace width(2400) height(1350) quality(100)
	

	
********************************************************************************
* 1.3 : Mean values over time, All, By age group 
********************************************************************************
	
* Those in their 20s 	

* Validation data	
use year dwt valid_dcpst_p valid_dcpst_s ageGroup using ///
	"$dir_data/${country}-eusilc_validation_sample_long.dta", clear

keep if ageGroup == 2 | ageGroup == 3	
	
collapse (mean) valid_dcpst_p valid_dcpst_s  [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year sim_dcpst_p sim_dcpst_s sim_has_partner ageGroup using ///
	"$dir_data/simulated_data.dta", clear

keep if ageGroup == 2 | ageGroup == 3 	
	
collapse (mean) sim_dcpst_p sim_dcpst_s  sim_has_partner, by(run year)
	
collapse (mean) sim_dcpst_p sim_dcpst_s  sim_has_partner ///
		 (sd) sim_dcpst_p_sd = sim_dcpst_p ///
		 sim_dcpst_s_sd = sim_dcpst_s ///
		 sim_has_partner_sd = sim_has_partner ///
		 , by(year)
		 
foreach varname in sim_dcpst_p sim_dcpst_s  sim_has_partner {
	
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd

}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
twoway (rarea sim_dcpst_p_high sim_dcpst_p_low year, sort color(green%20) ///
	legend(label(1 "Partnered, simulated"))) ///
(line valid_dcpst_p year, sort color(green) ///
	legend(label(2 "Partnered, SILC "))) ///
(rarea sim_dcpst_s_high sim_dcpst_s_low year, sort color(red%20) ///
	legend(label(3 "Single, simulated"))) ///
(line valid_dcpst_s year, sort color(red) ///
	legend(label(4 "Single, SILC "))), ///
title("Partnership Status") ///
	subtitle("Ages 20-29") ///
	xtitle("Year", size(small)) ///
	ytitle("Share", size(small)) ///
	xlabel(,labsize(small)) ///
	ylabel(0[0.2]0.8, labsize(small)) ///
	graphregion(color(white)) ///
	legend(size(small)) ///
	note("Notes:", size(vsmall))	
	
graph export ///
"$dir_output_files/partnership/validation_${country}_partnership_ts_20_29_both.jpg", ///
	replace width(2400) height(1350) quality(100)	
	
	
* Those in their 30s 	
	
* Validation data 	
use year dwt valid_dcpst_p valid_dcpst_s ageGroup using ///
	"$dir_data/${country}-eusilc_validation_sample_long.dta", clear

keep if ageGroup == 4 | ageGroup == 5	
	
collapse (mean) valid_dcpst_p valid_dcpst_s [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year sim_dcpst_p sim_dcpst_s sim_has_partner ageGroup using ///
"$dir_data/simulated_data.dta", clear

keep if ageGroup == 4 | ageGroup == 5 	
	
collapse (mean) sim_dcpst_p sim_dcpst_s sim_has_partner, by(run year)
	
collapse (mean) sim_dcpst_p sim_dcpst_s sim_has_partner ///
		 (sd) sim_dcpst_p_sd = sim_dcpst_p ///
		 sim_dcpst_s_sd = sim_dcpst_s ///
		 sim_has_partner_sd = sim_has_partner ///
		 , by(year)
		 
foreach varname in sim_dcpst_p sim_dcpst_s  sim_has_partner {
	
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd

}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
twoway (rarea sim_dcpst_p_high sim_dcpst_p_low year, sort color(green%20) ///
	legend(label(1 "Partnered, simulated"))) ///
(line valid_dcpst_p year, sort color(green) ///
	legend(label(2 "Partnered, SILC "))) ///
(rarea sim_dcpst_s_high sim_dcpst_s_low year, sort color(red%20) ///
	legend(label(3 "Single, simulated"))) ///
(line valid_dcpst_s year, sort color(red) ///
	legend(label(4 "Single, SILC "))),  ///
	title("Partnership Status") ///
	subtitle("Ages 30-39") ///
	xtitle("Year", size(small)) ///
	ytitle("Share", size(small)) ///
	xlabel(,labsize(small)) ///
	ylabel(0[0.1]0.7, labsize(small)) ///
	graphregion(color(white)) ///
	legend(size(small)) ///
	note("Notes:", size(vsmall))	
	
graph export ///
"$dir_output_files/partnership/validation_${country}_partnership_ts_30_39_both.jpg", ///
	replace width(2400) height(1350) quality(100)	
	
	
* Those in their 40-59 	
	
* Validation data 	
use year dwt valid_dcpst_p valid_dcpst_s ageGroup using ///
	"$dir_data/${country}-eusilc_validation_sample_long.dta", clear

keep if ageGroup == 6
	
collapse (mean) valid_dcpst_p valid_dcpst_s [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year sim_dcpst_p sim_dcpst_s sim_has_partner ageGroup using ///
"$dir_data/simulated_data.dta", clear

keep if ageGroup == 6
	
collapse (mean) sim_dcpst_p sim_dcpst_s sim_has_partner, by(run year)
	
collapse (mean) sim_dcpst_p sim_dcpst_s sim_has_partner ///
		 (sd) sim_dcpst_p_sd = sim_dcpst_p ///
		 sim_dcpst_s_sd = sim_dcpst_s ///
		 sim_has_partner_sd = sim_has_partner ///
		 , by(year)
		 
foreach varname in sim_dcpst_p sim_dcpst_s sim_has_partner {
	
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd

}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
twoway (rarea sim_dcpst_p_high sim_dcpst_p_low year, sort color(green%20) ///
	legend(label(1 "Partnered, simulated"))) ///
(line valid_dcpst_p year, sort color(green) ///
	legend(label(2 "Partnered, SILC "))) ///
(rarea sim_dcpst_s_high sim_dcpst_s_low year, sort color(red%20) ///
	legend(label(3 "Single, simulated"))) ///
(line valid_dcpst_s year, sort color(red) ///
	legend(label(4 "Single, SILC "))), ///
	title("Partnership Status") ///
	subtitle("Ages 40-59") ///
	xtitle("Year", size(small)) ///
	ytitle("Share", size(small)) ///
	xlabel(,labsize(small)) ///
	ylabel(0[0.1]0.8, labsize(small)) ///	
	graphregion(color(white)) ///
	legend(size(small)) ///
	note("Notes:", size(vsmall))	
	
graph export ///
"$dir_output_files/partnership/validation_${country}_partnership_ts_40_59_both.jpg", ///
	replace width(2400) height(1350) quality(100)	
	
	
graph drop _all 


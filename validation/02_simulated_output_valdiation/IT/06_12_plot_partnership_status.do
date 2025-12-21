********************************************************************************
* PROJECT:  		ESPON 
* SECTION:			Validation
* OBJECT: 			Partnership plots
* AUTHORS:			Patryk Bronka, Ashley Burdett 
* LAST UPDATE:		06/2025 (AB)
* COUNTRY: 			Italy 

* NOTES: 			
********************************************************************************

********************************************************************************
* 1 : Mean values over time
********************************************************************************

* Prepare validation data
use year dwt valid_dcpst_p valid_dcpst_snm valid_dcpst_prvp ///
	valid_dcpst_snmprvp using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

	
collapse (mean) valid_dcpst_p valid_dcpst_snm valid_dcpst_prvp ///
	valid_dcpst_snmprvp [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year sim_dcpst_p sim_dcpst_snm sim_dcpst_prvp sim_dcpst_snmprvp ///
	sim_has_partner using "$dir_data/simulated_data.dta", clear

collapse (mean) sim_dcpst_p sim_dcpst_snm sim_dcpst_prvp sim_dcpst_snmprvp  ///
	sim_has_partner, by(run year)
	
collapse (mean) sim_dcpst_p sim_dcpst_snm sim_dcpst_prvp sim_dcpst_snmprvp ///
	sim_has_partner ///
		 (sd) sim_dcpst_p_sd = sim_dcpst_p ///
		 sim_dcpst_snm_sd = sim_dcpst_snm ///
		 sim_dcpst_prvp_sd = sim_dcpst_prvp ///
		 sim_dcpst_snmprvp_sd = sim_dcpst_snmprvp ///
		 sim_has_partner_sd = sim_has_partner ///
		 , by(year)
		 
foreach varname in sim_dcpst_p sim_dcpst_snm sim_dcpst_prvp sim_dcpst_snmprvp sim_has_partner {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
twoway (rarea sim_dcpst_p_high sim_dcpst_p_low year, sort color(green%20) ///
	legend(label(1 "Simulated"))) ///
(line valid_dcpst_p year, sort color(green) ///
	legend(label(2 "Observed "))), ///
	title("Partnered") xtitle("Year") ytitle("Share") ///
	xlabel(,labsize(small)) ///
	graphregion(color(white)) ///
	ylabel(0.5[0.1]0.7, labsize(small)) ///
	note("Notes: Sample contains all individual ages 18-65.", size(vsmall))	

* Save figure
graph export ///
"$dir_output_files/partnership/validation_${country}_partnered_ts_${min_age}_${max_age}_both.jpg", ///
	replace width(2400) height(1350) quality(100)

	
twoway (rarea sim_dcpst_p_high sim_dcpst_p_low year, sort color(green%20) ///
	legend(label(1 "Partnered, simulated"))) ///
(line valid_dcpst_p year, sort color(green) ///
	legend(label(2 "Partnered, observed "))) ///
(rarea sim_dcpst_snm_high sim_dcpst_snm_low year, sort color(red%20) ///
	legend(label(3 "Single, simulated"))) ///
(line valid_dcpst_snm year, sort color(red) ///
	legend(label(4 "Single, observed "))) ///
(rarea sim_dcpst_prvp_high sim_dcpst_prvp_low year, sort color(blue%20) ///
	legend(label(5 "Prev partnered, simulated"))) ///
(line valid_dcpst_prvp year, sort color(blue) ///
	legend(label(6 "Prev partnered, observed "))) , ///
	title("Partnership status") xtitle("Year") ytitle("Share") ///
	xlabel(,labsize(small)) ///
	graphregion(color(white)) ///
	ylabel(0[0.1]0.7, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Sample contains all individual ages 18-65.", size(vsmall))	
	
graph export ///
"$dir_output_files/partnership/validation_${country}_partnership_ts_${min_age}_${max_age}_both.jpg", ///
	replace width(2400) height(1350) quality(100)	
	
twoway (rarea sim_dcpst_prvp_high sim_dcpst_prvp_low year, sort color(red%20) ///
	legend(label(1 "Simulated"))) ///
(line valid_dcpst_prvp year, sort color(red) ///
	legend(label(2 "Observed "))), ///
	title("Previously partnered") xtitle("Year") ytitle("Share") ///
	xlabel(,labsize(small)) ///
	graphregion(color(white)) ///
	ylabel(, labsize(small)) ///
	note("Notes: Sample contains all individual ages 18-65.", size(vsmall))	
	
	
** Partnerhip by children 	

* Load validation data
use year dwt valid_dcpst_p_children_0 valid_dcpst_p_children_1 ///
	valid_dcpst_p_children_2 valid_dcpst_p_children_3p ///
	valid_dcpst_snm_children_0 valid_dcpst_snm_children_1 ///
	valid_dcpst_snm_children_2 valid_dcpst_snm_children_3p ///
	valid_dcpst_prvp_children_0 valid_dcpst_prvp_children_1 ///
	valid_dcpst_prvp_children_2 valid_dcpst_prvp_children_3p ///
	valid_dcpst_snmprvp_children_0 valid_dcpst_snmprvp_children_1 ///
	valid_dcpst_snmprvp_children_2 valid_dcpst_snmprvp_children_3p using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

collapse (mean) valid_dcpst_p_children_0 valid_dcpst_p_children_1 ///
	 valid_dcpst_p_children_2 valid_dcpst_p_children_3p ///
	 valid_dcpst_snm_children_0 valid_dcpst_snm_children_1 ///
	 valid_dcpst_snm_children_2 valid_dcpst_snm_children_3p ///
	 valid_dcpst_prvp_children_0 valid_dcpst_prvp_children_1 ///
	 valid_dcpst_prvp_children_2 valid_dcpst_prvp_children_3p ///
	 valid_dcpst_snmprvp_children_0 valid_dcpst_snmprvp_children_1 ///
	 valid_dcpst_snmprvp_children_2 valid_dcpst_snmprvp_children_3p ///
	 [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace

* Load simulated data
use run year sim_dcpst_p_children_0 sim_dcpst_p_children_1 ///
	sim_dcpst_p_children_2 sim_dcpst_p_children_3p sim_dcpst_snm_children_0 ///
	sim_dcpst_snm_children_1 sim_dcpst_snm_children_2 ///
	sim_dcpst_snm_children_3p sim_dcpst_prvp_children_0 ///
	sim_dcpst_prvp_children_1 sim_dcpst_prvp_children_2 ///
	sim_dcpst_prvp_children_3p sim_dcpst_snmprvp_children_0 ///
	sim_dcpst_snmprvp_children_1 sim_dcpst_snmprvp_children_2 ///
	sim_dcpst_snmprvp_children_3p ///
	using "$dir_data/simulated_data.dta", clear

collapse (mean) sim_dcpst_p_children_0 sim_dcpst_p_children_1 ///
	sim_dcpst_p_children_2 sim_dcpst_p_children_3p ///
	sim_dcpst_snm_children_0 sim_dcpst_snm_children_1 ///
	sim_dcpst_snm_children_2 sim_dcpst_snm_children_3p ///
	sim_dcpst_prvp_children_0 sim_dcpst_prvp_children_1 ///
	sim_dcpst_prvp_children_2 sim_dcpst_prvp_children_3p ///
	sim_dcpst_snmprvp_children_0 sim_dcpst_snmprvp_children_1 ///
	sim_dcpst_snmprvp_children_2 sim_dcpst_snmprvp_children_3p, ///
	by(run year)
	
collapse (mean) sim_dcpst_p_children_0 sim_dcpst_p_children_1 ///
	 sim_dcpst_p_children_2 sim_dcpst_p_children_3p sim_dcpst_snm_children_0 ///
	 sim_dcpst_snm_children_1 sim_dcpst_snm_children_2 ///
	 sim_dcpst_snm_children_3p sim_dcpst_prvp_children_0 ///
	 sim_dcpst_prvp_children_1 sim_dcpst_prvp_children_2 ///
	 sim_dcpst_prvp_children_3p sim_dcpst_snmprvp_children_0 ///
	 sim_dcpst_snmprvp_children_1 sim_dcpst_snmprvp_children_2 ///
	 sim_dcpst_snmprvp_children_3p ///
	(sd) sim_dcpst_p_children_0_sd = sim_dcpst_p_children_0 ///
		sim_dcpst_p_children_1_sd = sim_dcpst_p_children_1 ///
		sim_dcpst_p_children_2_sd = sim_dcpst_p_children_2 ///
		sim_dcpst_p_children_3p_sd = sim_dcpst_p_children_3p ///
		sim_dcpst_snm_children_0_sd = sim_dcpst_snm_children_0 ///
		sim_dcpst_snm_children_1_sd = sim_dcpst_snm_children_1 ///
		sim_dcpst_snm_children_2_sd = sim_dcpst_snm_children_2 ///
		sim_dcpst_snm_children_3p_sd = sim_dcpst_snm_children_3 ///
		sim_dcpst_prvp_children_0_sd = sim_dcpst_prvp_children_0 ///
		sim_dcpst_prvp_children_1_sd = sim_dcpst_prvp_children_1 ///
		sim_dcpst_prvp_children_2_sd = sim_dcpst_prvp_children_2 ///
		sim_dcpst_prvp_children_3p_sd = sim_dcpst_prvp_children_3p ///
		sim_dcpst_snmprvp_children_0_sd = sim_dcpst_snmprvp_children_0 ///
		sim_dcpst_snmprvp_children_1_sd = sim_dcpst_snmprvp_children_1 ///
		sim_dcpst_snmprvp_children_2_sd = sim_dcpst_snmprvp_children_2 ///
		sim_dcpst_snmprvp_children_3p_sd = sim_dcpst_snmprvp_children_3p ///
		, by(year)
		 
foreach varname in sim_dcpst_p_children_0 sim_dcpst_p_children_1 sim_dcpst_p_children_2 sim_dcpst_p_children_3p sim_dcpst_snm_children_0 sim_dcpst_snm_children_1 sim_dcpst_snm_children_2 sim_dcpst_snm_children_3p sim_dcpst_prvp_children_0 sim_dcpst_prvp_children_1 sim_dcpst_prvp_children_2 sim_dcpst_prvp_children_3p sim_dcpst_snmprvp_children_0 sim_dcpst_snmprvp_children_1 sim_dcpst_snmprvp_children_2 sim_dcpst_snmprvp_children_3p {
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
label var sim_dcpst_snmprvp_children_0 "Not partnered, no children"
label var sim_dcpst_snmprvp_children_1 "Not partnered, 1 child"
label var sim_dcpst_snmprvp_children_2 "Not partnered, 2 children"
label var sim_dcpst_snmprvp_children_3p "Not partnered, 3+ children"

foreach varname in dcpst_p_children_0 dcpst_p_children_1 dcpst_p_children_2 dcpst_p_children_3p dcpst_snmprvp_children_0 dcpst_snmprvp_children_1 dcpst_snmprvp_children_2 dcpst_snmprvp_children_3p {
	
	local vtext : variable label sim_`varname'
	if `"`vtext'"' == "" local vtext "sim_`varname'" 
	twoway (rarea sim_`varname'_h sim_`varname'_l year, sort color(green%20) ///
		legend(label(1 "Simulated") position(6) rows(1))) ///
		(line valid_`varname' year, sort color(green) ///
		legend(label(2 "Observed"))), ///
		subtitle("`vtext'") name(`varname', replace) ///
		ytitle("Share") ///
		xtitle("") ///
		ylabel(,labsize(small)) xlabel(,labsize(small)) ///
		graphregion(color(white)) 

}

grc1leg dcpst_p_children_0 dcpst_p_children_1 dcpst_p_children_2 ///
	dcpst_p_children_3p dcpst_snmprvp_children_0 dcpst_snmprvp_children_1 ///
	dcpst_snmprvp_children_2 dcpst_snmprvp_children_3p, ///
title("Partnership and number of children") ///
	legendfrom(dcpst_p_children_0) ///
	graphregion(color(white)) ///
	note("Notes: Samples contains all individual ages 18-65. ", size(vsmall)) 
	
graph export ///
"$dir_output_files/partnership/validation_${country}_partnership_children_ts_${min_age}_${max_age}_both.jpg", ///
	replace width(2400) height(1350) quality(100)
	

	
** By age group 	
	
* Those in their 20s 	

* Validation data	
use year dwt valid_dcpst_p valid_dcpst_snm valid_dcpst_prvp ///
	valid_dcpst_snmprvp ageGroup using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

keep if ageGroup == 2 | ageGroup == 3	
	
collapse (mean) valid_dcpst_p valid_dcpst_snm valid_dcpst_prvp ///
	valid_dcpst_snmprvp [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year sim_dcpst_p sim_dcpst_snm sim_dcpst_prvp sim_dcpst_snmprvp ///
	sim_has_partner ageGroup using "$dir_data/simulated_data.dta", clear

keep if ageGroup == 2 | ageGroup == 3 	
	
collapse (mean) sim_dcpst_p sim_dcpst_snm sim_dcpst_prvp sim_dcpst_snmprvp  ///
	sim_has_partner, by(run year)
	
collapse (mean) sim_dcpst_p sim_dcpst_snm sim_dcpst_prvp sim_dcpst_snmprvp ///
	sim_has_partner ///
		 (sd) sim_dcpst_p_sd = sim_dcpst_p ///
		 sim_dcpst_snm_sd = sim_dcpst_snm ///
		 sim_dcpst_prvp_sd = sim_dcpst_prvp ///
		 sim_dcpst_snmprvp_sd = sim_dcpst_snmprvp ///
		 sim_has_partner_sd = sim_has_partner ///
		 , by(year)
		 
foreach varname in sim_dcpst_p sim_dcpst_snm sim_dcpst_prvp sim_dcpst_snmprvp sim_has_partner {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure

twoway (rarea sim_dcpst_p_high sim_dcpst_p_low year, sort color(green%20) ///
	legend(label(1 "Simulated"))) ///
(line valid_dcpst_p year, sort color(green) ///
	legend(label(2 "Observed "))) , ///
	title("Partnered") ///
	subtitle("Ages 20-29") ///
	xtitle("Year") ytitle("Share") ///
	xlabel(,labsize(small)) ///
	graphregion(color(white)) ///
	ylabel(0[0.1]0.9, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: ", size(vsmall))	
	
graph export ///
"$dir_output_files/partnership/validation_${country}_partnered_ts_20_29_both.jpg", ///
	replace width(2400) height(1350) quality(100)	


twoway (rarea sim_dcpst_p_high sim_dcpst_p_low year, sort color(green%20) ///
	legend(label(1 "Partnered, simulated"))) ///
(line valid_dcpst_p year, sort color(green) ///
	legend(label(2 "Partnered, observed "))) ///
(rarea sim_dcpst_snm_high sim_dcpst_snm_low year, sort color(red%20) ///
	legend(label(3 "Single, simulated"))) ///
(line valid_dcpst_snm year, sort color(red) ///
	legend(label(4 "Single, observed "))) ///
(rarea sim_dcpst_prvp_high sim_dcpst_prvp_low year, sort color(blue%20) ///
	legend(label(5 "Prev partnered, simulated"))) ///
(line valid_dcpst_prvp year, sort color(blue) ///
	legend(label(6 "Prev partnered, observed "))) , ///
	title("Partnership status") ///
	subtitle("Ages 20-29") ///
	xtitle("Year") ytitle("Share") ///
	xlabel(,labsize(small)) ///
	graphregion(color(white)) ///
	ylabel(0[0.1]0.7, labsize(small)) ///
	legend(size(small)) ///
	note("Notes:", size(vsmall))	
	
graph export ///
"$dir_output_files/partnership/validation_${country}_partnership_ts_20_29_both.jpg", ///
	replace width(2400) height(1350) quality(100)	
	
	
* Those in their 30s 	
	
* Validation data 	
use year dwt valid_dcpst_p valid_dcpst_snm valid_dcpst_prvp ///
	valid_dcpst_snmprvp ageGroup using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

keep if ageGroup == 4 | ageGroup == 5	
	
collapse (mean) valid_dcpst_p valid_dcpst_snm valid_dcpst_prvp ///
	valid_dcpst_snmprvp [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year sim_dcpst_p sim_dcpst_snm sim_dcpst_prvp sim_dcpst_snmprvp ///
	sim_has_partner ageGroup using "$dir_data/simulated_data.dta", clear

keep if ageGroup == 4 | ageGroup == 5 	
	
collapse (mean) sim_dcpst_p sim_dcpst_snm sim_dcpst_prvp sim_dcpst_snmprvp  ///
	sim_has_partner, by(run year)
	
collapse (mean) sim_dcpst_p sim_dcpst_snm sim_dcpst_prvp sim_dcpst_snmprvp ///
	sim_has_partner ///
		 (sd) sim_dcpst_p_sd = sim_dcpst_p ///
		 sim_dcpst_snm_sd = sim_dcpst_snm ///
		 sim_dcpst_prvp_sd = sim_dcpst_prvp ///
		 sim_dcpst_snmprvp_sd = sim_dcpst_snmprvp ///
		 sim_has_partner_sd = sim_has_partner ///
		 , by(year)
		 
foreach varname in sim_dcpst_p sim_dcpst_snm sim_dcpst_prvp sim_dcpst_snmprvp sim_has_partner {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
twoway (rarea sim_dcpst_p_high sim_dcpst_p_low year, sort color(green%20) ///
	legend(label(1 "Simulated"))) ///
(line valid_dcpst_p year, sort color(green) ///
	legend(label(2 "Observed "))) , ///
	title("Partnered") ///
	subtitle("Ages 30-39") ///
	xtitle("Year") ytitle("Share") ///
	xlabel(,labsize(small)) ///
	graphregion(color(white)) ///
	ylabel(0[0.1]0.9, labsize(small)) ///
	legend(size(small)) ///
	note("Notes:", size(vsmall))	
	
graph export ///
"$dir_output_files/partnership/validation_${country}_partnered_ts_30_39_both.jpg", ///
	replace width(2400) height(1350) quality(100)	




twoway (rarea sim_dcpst_p_high sim_dcpst_p_low year, sort color(green%20) ///
	legend(label(1 "Partnered, simulated"))) ///
(line valid_dcpst_p year, sort color(green) ///
	legend(label(2 "Partnered, observed "))) ///
(rarea sim_dcpst_snm_high sim_dcpst_snm_low year, sort color(red%20) ///
	legend(label(3 "Single, simulated"))) ///
(line valid_dcpst_snm year, sort color(red) ///
	legend(label(4 "Single, observed "))) ///
(rarea sim_dcpst_prvp_high sim_dcpst_prvp_low year, sort color(blue%20) ///
	legend(label(5 "Prev partnered, simulated"))) ///
(line valid_dcpst_prvp year, sort color(blue) ///
	legend(label(6 "Prev partnered, observed "))) , ///
	title("Partnership status") ///
	subtitle("Ages 30-39") ///
	xtitle("Year") ytitle("Share") ///
	xlabel(,labsize(small)) ///
	graphregion(color(white)) ///
	ylabel(0[0.1]0.7, labsize(small)) ///
	legend(size(small)) ///
	note("Notes:", size(vsmall))	
	
graph export ///
"$dir_output_files/partnership/validation_${country}_partnership_ts_30_39_both.jpg", ///
	replace width(2400) height(1350) quality(100)	
	
	
* Those in their 40-59 	
	
* Validation data 	
use year dwt valid_dcpst_p valid_dcpst_snm valid_dcpst_prvp ///
	valid_dcpst_snmprvp ageGroup using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

keep if ageGroup == 6
	
collapse (mean) valid_dcpst_p valid_dcpst_snm valid_dcpst_prvp ///
	valid_dcpst_snmprvp [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year sim_dcpst_p sim_dcpst_snm sim_dcpst_prvp sim_dcpst_snmprvp ///
	sim_has_partner ageGroup using "$dir_data/simulated_data.dta", clear

keep if ageGroup == 6
	
collapse (mean) sim_dcpst_p sim_dcpst_snm sim_dcpst_prvp sim_dcpst_snmprvp  ///
	sim_has_partner, by(run year)
	
collapse (mean) sim_dcpst_p sim_dcpst_snm sim_dcpst_prvp sim_dcpst_snmprvp ///
	sim_has_partner ///
		 (sd) sim_dcpst_p_sd = sim_dcpst_p ///
		 sim_dcpst_snm_sd = sim_dcpst_snm ///
		 sim_dcpst_prvp_sd = sim_dcpst_prvp ///
		 sim_dcpst_snmprvp_sd = sim_dcpst_snmprvp ///
		 sim_has_partner_sd = sim_has_partner ///
		 , by(year)
		 
foreach varname in sim_dcpst_p sim_dcpst_snm sim_dcpst_prvp sim_dcpst_snmprvp sim_has_partner {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure

twoway (rarea sim_dcpst_p_high sim_dcpst_p_low year, sort color(green%20) ///
	legend(label(1 "Simulated"))) ///
(line valid_dcpst_p year, sort color(green) ///
	legend(label(2 "Observed "))), ///
	title("Partnered") ///
	subtitle("Ages 40-59") ///
	xtitle("Year") ytitle("Share") ///
	xlabel(,labsize(small)) ///
	graphregion(color(white)) ///
	ylabel(0[0.1]0.9, labsize(small)) ///
	legend(size(small)) ///
	note("Notes:", size(vsmall))	
	
graph export ///
"$dir_output_files/partnership/validation_${country}_partnered_ts_40_59_both.jpg", ///
	replace width(2400) height(1350) quality(100)	





twoway (rarea sim_dcpst_p_high sim_dcpst_p_low year, sort color(green%20) ///
	legend(label(1 "Partnered, simulated"))) ///
(line valid_dcpst_p year, sort color(green) ///
	legend(label(2 "Partnered, observed "))) ///
(rarea sim_dcpst_snm_high sim_dcpst_snm_low year, sort color(red%20) ///
	legend(label(3 "Single, simulated"))) ///
(line valid_dcpst_snm year, sort color(red) ///
	legend(label(4 "Single, observed "))) ///
(rarea sim_dcpst_prvp_high sim_dcpst_prvp_low year, sort color(blue%20) ///
	legend(label(5 "Prev partnered, simulated"))) ///
(line valid_dcpst_prvp year, sort color(blue) ///
	legend(label(6 "Prev partnered, observed "))) , ///
	title("Partnership status") ///
	subtitle("Ages 40-59") ///
	xtitle("Year") ytitle("Share") ///
	xlabel(,labsize(small)) ///
	graphregion(color(white)) ///
	ylabel(0[0.1]0.8, labsize(small)) ///
	legend(size(small)) ///
	note("Notes:", size(vsmall))	
	
graph export ///
"$dir_output_files/partnership/validation_${country}_partnership_ts_40_59_both.jpg", ///
	replace width(2400) height(1350) quality(100)	
	
	
	
* 40-65
* Validation data 	
use year dwt valid_dcpst_p valid_dcpst_snm valid_dcpst_prvp ///
	valid_dcpst_snmprvp ageGroup dag using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

keep if inrange(dag,40,65)
	
collapse (mean) valid_dcpst_p valid_dcpst_snm valid_dcpst_prvp ///
	valid_dcpst_snmprvp [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year sim_dcpst_p sim_dcpst_snm sim_dcpst_prvp sim_dcpst_snmprvp ///
	sim_has_partner ageGroup dag using "$dir_data/simulated_data.dta", clear

keep if inrange(dag,40,65)
	
collapse (mean) sim_dcpst_p sim_dcpst_snm sim_dcpst_prvp sim_dcpst_snmprvp  ///
	sim_has_partner, by(run year)
	
collapse (mean) sim_dcpst_p sim_dcpst_snm sim_dcpst_prvp sim_dcpst_snmprvp ///
	sim_has_partner ///
		 (sd) sim_dcpst_p_sd = sim_dcpst_p ///
		 sim_dcpst_snm_sd = sim_dcpst_snm ///
		 sim_dcpst_prvp_sd = sim_dcpst_prvp ///
		 sim_dcpst_snmprvp_sd = sim_dcpst_snmprvp ///
		 sim_has_partner_sd = sim_has_partner ///
		 , by(year)
		 
foreach varname in sim_dcpst_p sim_dcpst_snm sim_dcpst_prvp sim_dcpst_snmprvp sim_has_partner {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure

twoway (rarea sim_dcpst_p_high sim_dcpst_p_low year, sort color(green%20) ///
	legend(label(1 "Simulated"))) ///
(line valid_dcpst_p year, sort color(green) ///
	legend(label(2 "Observed "))), ///
	title("Partnered") ///
	subtitle("Ages 40-65") ///
	xtitle("Year") ytitle("Share") ///
	xlabel(,labsize(small)) ///
	graphregion(color(white)) ///
	ylabel(0[0.1]0.9, labsize(small)) ///
	legend(size(small)) ///
	note("Notes:", size(vsmall))	
	
graph export ///
"$dir_output_files/partnership/validation_${country}_partnered_ts_40_65_both.jpg", ///
	replace width(2400) height(1350) quality(100)	


	
	
	
	
	
graph drop _all 


** Prrtnership status and children 

** Activity status and children 

* Load validation data
use year dwt valid_dcpst_p_children_0 valid_dcpst_p_children_1 ///
	valid_dcpst_p_children_2 valid_dcpst_p_children_3p ///
	valid_dcpst_snm_children_0 valid_dcpst_snm_children_1 ///
	valid_dcpst_snm_children_2 valid_dcpst_snm_children_3p ///
	valid_dcpst_prvp_children_0 valid_dcpst_prvp_children_1 ///
	valid_dcpst_prvp_children_2 valid_dcpst_prvp_children_3p ///
	valid_dcpst_snmprvp_children_0 valid_dcpst_snmprvp_children_1 ///
	valid_dcpst_snmprvp_children_2 valid_dcpst_snmprvp_children_3p using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

collapse (mean) valid_dcpst_p_children_0 valid_dcpst_p_children_1 ///
	 valid_dcpst_p_children_2 valid_dcpst_p_children_3p ///
	 valid_dcpst_snm_children_0 valid_dcpst_snm_children_1 ///
	 valid_dcpst_snm_children_2 valid_dcpst_snm_children_3p ///
	 valid_dcpst_prvp_children_0 valid_dcpst_prvp_children_1 ///
	 valid_dcpst_prvp_children_2 valid_dcpst_prvp_children_3p ///
	 valid_dcpst_snmprvp_children_0 valid_dcpst_snmprvp_children_1 ///
	 valid_dcpst_snmprvp_children_2 valid_dcpst_snmprvp_children_3p ///
	 [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace

* Load simulated data
use run year sim_dcpst_p_children_0 sim_dcpst_p_children_1 ///
	sim_dcpst_p_children_2 sim_dcpst_p_children_3p sim_dcpst_snm_children_0 ///
	sim_dcpst_snm_children_1 sim_dcpst_snm_children_2 ///
	sim_dcpst_snm_children_3p sim_dcpst_prvp_children_0 ///
	sim_dcpst_prvp_children_1 sim_dcpst_prvp_children_2 ///
	sim_dcpst_prvp_children_3p sim_dcpst_snmprvp_children_0 ///
	sim_dcpst_snmprvp_children_1 sim_dcpst_snmprvp_children_2 ///
	sim_dcpst_snmprvp_children_3p ///
	using "$dir_data/simulated_data.dta", clear

collapse (mean) sim_dcpst_p_children_0 sim_dcpst_p_children_1 ///
	sim_dcpst_p_children_2 sim_dcpst_p_children_3p ///
	sim_dcpst_snm_children_0 sim_dcpst_snm_children_1 ///
	sim_dcpst_snm_children_2 sim_dcpst_snm_children_3p ///
	sim_dcpst_prvp_children_0 sim_dcpst_prvp_children_1 ///
	sim_dcpst_prvp_children_2 sim_dcpst_prvp_children_3p ///
	sim_dcpst_snmprvp_children_0 sim_dcpst_snmprvp_children_1 ///
	sim_dcpst_snmprvp_children_2 sim_dcpst_snmprvp_children_3p, ///
	by(run year)
	
collapse (mean) sim_dcpst_p_children_0 sim_dcpst_p_children_1 ///
	 sim_dcpst_p_children_2 sim_dcpst_p_children_3p sim_dcpst_snm_children_0 ///
	 sim_dcpst_snm_children_1 sim_dcpst_snm_children_2 ///
	 sim_dcpst_snm_children_3p sim_dcpst_prvp_children_0 ///
	 sim_dcpst_prvp_children_1 sim_dcpst_prvp_children_2 ///
	 sim_dcpst_prvp_children_3p sim_dcpst_snmprvp_children_0 ///
	 sim_dcpst_snmprvp_children_1 sim_dcpst_snmprvp_children_2 ///
	 sim_dcpst_snmprvp_children_3p ///
		 (sd) sim_dcpst_p_children_0_sd = sim_dcpst_p_children_0 ///
			  sim_dcpst_p_children_1_sd = sim_dcpst_p_children_1 ///
			  sim_dcpst_p_children_2_sd = sim_dcpst_p_children_2 ///
			  sim_dcpst_p_children_3p_sd = sim_dcpst_p_children_3p ///
			  sim_dcpst_snm_children_0_sd = sim_dcpst_snm_children_0 ///
			  sim_dcpst_snm_children_1_sd = sim_dcpst_snm_children_1 ///
			  sim_dcpst_snm_children_2_sd = sim_dcpst_snm_children_2 ///
			  sim_dcpst_snm_children_3p_sd = sim_dcpst_snm_children_3 ///
			  sim_dcpst_prvp_children_0_sd = sim_dcpst_prvp_children_0 ///
			  sim_dcpst_prvp_children_1_sd = sim_dcpst_prvp_children_1 ///
			  sim_dcpst_prvp_children_2_sd = sim_dcpst_prvp_children_2 ///
			  sim_dcpst_prvp_children_3p_sd = sim_dcpst_prvp_children_3p ///
			  sim_dcpst_snmprvp_children_0_sd = sim_dcpst_snmprvp_children_0 ///
			  sim_dcpst_snmprvp_children_1_sd = sim_dcpst_snmprvp_children_1 ///
			  sim_dcpst_snmprvp_children_2_sd = sim_dcpst_snmprvp_children_2 ///
			  sim_dcpst_snmprvp_children_3p_sd = sim_dcpst_snmprvp_children_3p ///
		 , by(year)
		 
foreach varname in sim_dcpst_p_children_0 sim_dcpst_p_children_1 sim_dcpst_p_children_2 sim_dcpst_p_children_3p sim_dcpst_snm_children_0 sim_dcpst_snm_children_1 sim_dcpst_snm_children_2 sim_dcpst_snm_children_3p sim_dcpst_prvp_children_0 sim_dcpst_prvp_children_1 sim_dcpst_prvp_children_2 sim_dcpst_prvp_children_3p sim_dcpst_snmprvp_children_0 sim_dcpst_snmprvp_children_1 sim_dcpst_snmprvp_children_2 sim_dcpst_snmprvp_children_3p {
	gen `varname'_h = `varname' + 1.96*`varname'_sd
	gen `varname'_l = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figures

// Labels of simulated variables are used as titles for the graphs below
la var sim_dcpst_p_children_0 "Partnered, no children"
la var sim_dcpst_p_children_1 "Partnered, 1 child"
la var sim_dcpst_p_children_2 "Partnered, 2 children"
la var sim_dcpst_p_children_3p "Partnered, 3+ children"
la var sim_dcpst_snmprvp_children_0 "Not partnered, no children"
la var sim_dcpst_snmprvp_children_1 "Not partnered, 1 child"
la var sim_dcpst_snmprvp_children_2 "Not partnered, 2 children"
la var sim_dcpst_snmprvp_children_3p "Not partnered, 3+ children"

// Validation graphs for share of individuals by partnership status and number of children
foreach varname in dcpst_p_children_0 dcpst_p_children_1 dcpst_p_children_2 dcpst_p_children_3p dcpst_snmprvp_children_0 dcpst_snmprvp_children_1 dcpst_snmprvp_children_2 dcpst_snmprvp_children_3p {
	
	local vtext : variable label sim_`varname'
	if `"`vtext'"' == "" local vtext "sim_`varname'" 
	twoway (rarea sim_`varname'_h sim_`varname'_l year, sort color(red%20) ///
		legend(label(1 "Simulated") position(6) rows(1))) ///
		(line valid_`varname' year, sort legend(label(2 "Observed"))), ///
		title("`vtext'") name(`varname', replace) ///
		ytitle("Share") ///
		xtitle("") ///
		ylabel(,labsize(small)) xlabel(,labsize(small)) ///
		graphregion(color(white)) 

}

grc1leg dcpst_p_children_0 dcpst_p_children_1 dcpst_p_children_2 ///
	dcpst_p_children_3p dcpst_snmprvp_children_0 dcpst_snmprvp_children_1 ///
	dcpst_snmprvp_children_2 dcpst_snmprvp_children_3p, ///
	subtitle("Share of individuals by partnership status and number of children") ///
	legendfrom(dcpst_p_children_0) ///
	graphregion(color(white)) ///
	note("Notes: Samples contains all individual ages 18-65. ", size(vsmall)) 
	
graph export ///
"$dir_output_files/partnership/validation_${country}_partnership_children_ts_${min_age}_${max_age}_both.jpg", ///
	replace width(2400) height(1350) quality(100)
	

graph drop _all 



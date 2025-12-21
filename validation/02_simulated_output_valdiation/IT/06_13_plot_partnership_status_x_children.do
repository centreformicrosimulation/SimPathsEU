/*
This do file plots simulated and observed activity status interacted with the number of children

Author: Patryk Bronka
Last modified: October 2023

*/

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

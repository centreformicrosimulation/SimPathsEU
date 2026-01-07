/*
This do file plots simulated and observed % of benefit units with a given 
number of children

Author: Patryk Bronka
Last modified: December 2023

Note: the statistic is calculated at the benefit unit level, but household 
weight is applied in the validation data

Need benefit unit weight 

*/

* Prepare validation data
use year idbenefitunit dwt children_* using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear
	
bys year idbenefitunit: keep if _n == 1

* Calculate weighted share of benefit units with 0, 1, 2, 3 or more children
collapse (mean) children_* [aw = dwt], by(year)

foreach varname in children_0 children_1 children_2 children_3p  {
	rename `varname' valid_`varname'
}

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year idbenefitunit children_*  using ///
	"$dir_data/simulated_data.dta", clear

bys run year idbenefitunit: keep if _n == 1

collapse (mean) children_*, by(run year)

rename children_3plus children_3p

collapse (mean) children_* ///
		 (sd) children_0_sd = children_0 ///
			  children_1_sd = children_1 ///
			  children_2_sd = children_2 ///
			  children_3p_sd = children_3p ///
		 , by(year)
		 
foreach varname in children_0 children_1 children_2 children_3p  {
	gen sim_`varname'_h = `varname' + 1.96*`varname'_sd
	gen sim_`varname'_l = `varname' - 1.96*`varname'_sd
	rename `varname' sim_`varname'
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figures
la var sim_children_0 "No children"
la var sim_children_1 "1 child"
la var sim_children_2 "2 children"
la var sim_children_3p "3+ children"

/*
// Validation graphs for share of individuals by partnership status and number of children
foreach varname in children_0 children_1 children_2 children_3p {
	local vtext : variable label sim_`varname'
	if `"`vtext'"' == "" local vtext "sim_`varname'" 
	twoway (rarea sim_`varname'_h sim_`varname'_l year, sort color(gs10) legend(label(1 "simulated") position(6) rows(1)))(line valid_`varname' year, sort legend(label(2 "observed"))), title("`vtext'") name(`varname', replace)
}
*/

twoway (rarea sim_children_0_h sim_children_0_l year, ///
	sort color(green%20) legend(label(1 "No children, simulated"))) ///
(line valid_children_0 year, sort color(green) ///
	legend(label(2 "No children, observed"))) ///
	(rarea sim_children_1_h sim_children_1_l year, sort color(blue%20) ///
	legend(label(3 "1 child, simulated"))) ///
(line valid_children_1 year, sort color(blue) ///
	legend(label(4 "1 child, observed"))) ///
(rarea sim_children_2_h sim_children_2_l year, sort color(red%20) ///
	legend(label(5 "2 children, simulated"))) ///
(line valid_children_2 year, sort color(red) ///
	legend(label(6 "2 children, observed"))) ///
(rarea sim_children_3p_h sim_children_3p_l year, sort color(grey%20) ///
	legend(label(7 "3+ children, simulated"))) ///
(line valid_children_3p year, sort color(grey) ///
	legend(label(8 "3+ children, observed"))), ///
	title("Number of children") xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes:Statistics computed at the benefit unit level.", size(vsmall))

* Save figure
graph export 	"$dir_output_files/children/validation_${country}_children_ts_all_both.jpg", ///
	replace width(2400) height(1350) quality(100)

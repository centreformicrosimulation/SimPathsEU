/*
This do file plots simulated and observed capital income, per benefit unit

Author: Patryk Bronka
Last modified: October 2023

*/

/*==============================================================================
1 : Mean values over time
==============================================================================*/

* Prepare validation data
use year dwt capital_income_bu using /// 
	"$dir_data/${country}-eusilc_validation_sample.dta", clear


* Trim outliers
if "$trim_outliers" == "true" {
	sum capital_income_bu, d
	replace capital_income_bu = . if ///
		capital_income_bu < r(p1) | capital_income_bu > r(p99)
}
*/

collapse (mean) capital_income_bu [aw = dwt], by(year)

gen l_capital_income_bu = capital_income_bu[_n+1]

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year sim_ypncp_lvl_bu using "$dir_data/simulated_data.dta", clear


* Trim outliers
if "$trim_outliers" == "true" {
	sum sim_ypncp_lvl_bu, d
	replace sim_ypncp_lvl_bu = . if ///
		sim_ypncp_lvl_bu < r(p1) | sim_ypncp_lvl_bu > r(p99)
}
*/

collapse (mean) sim_ypncp_lvl_bu, by(run year)
collapse (mean) sim_ypncp_lvl_bu ///
		 (sd) sim_ypncp_lvl_bu_sd = sim_ypncp_lvl_bu ///
		 , by(year)
		 
foreach varname in sim_ypncp_lvl_bu {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
twoway (rarea sim_ypncp_lvl_bu_high sim_ypncp_lvl_bu_low year, sort ///
	color(green%20) legend(label(1 "Simulated"))) ///
(line capital_income_bu year, sort color(green) ///
	legend(label(2 "Observed"))), ///
title("Capital income") xtitle("Year") ///
	ytitle("€ per year, in 2015 prices") ///
	ylabel(,labsize(small)) xlabel(,labsize(small)) ///
	graphregion(color(white)) ///
	note("Notes: Series represents average benefit unit capital income. Statistics computed by averaging benefit unit-level gross" "income for all persons ages 18-65.", size(vsmall))


* Save figure
graph export ///
"$dir_output_files/income/validation_${country}_capital_income_ts_${min_age}_${max_age}_both.jpg", ///
	replace width(2400) height(1350) quality(100)

 	
/*==============================================================================
2 : Histograms by year
==============================================================================*/

* Prepare validation data
use year dwt capital_income_bu using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear


* Trim outliers
if "$trim_outliers" == "true" {
	sum capital_income_bu, d
	replace capital_income_bu = . if ///
		capital_income_bu < r(p1) | capital_income_bu > r(p99)
}
*/
gen l_capital_income_bu = capital_income_bu[_n+1]

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year sim_ypncp_lvl_bu using "$dir_data/simulated_data.dta", clear

* Trim outliers
if "$trim_outliers" == "true" {
	sum sim_ypncp_lvl_bu, d
	replace sim_ypncp_lvl_bu = . if ///
		sim_ypncp_lvl_bu < r(p1) | sim_ypncp_lvl_bu > r(p99)
}

append using "$dir_data/temp_valid_stats.dta"

qui sum year
local min_year = r(min)  // Calculate the minimum value of the 'year' variable
local max_year = r(max)  // Calculate the maximum value of the 'year' variable

forval year = `min_year'/`max_year' {
	
    //Entire sample
	twoway (hist sim_ypncp_lvl_bu if year == `year'& sim_ypncp_lvl_bu < 100, ///
		color(green%30) legend(label(1 "Simulated"))) ///
	(hist capital_income_bu if year == `year' & capital_income_bu < 100, ///
		 color(red%30) legend(label(2 "Observed"))) , ///
	title("Capital income") ///
		subtitle("`year'") ///
		name(capital_inc_`year'_all, replace) ///
		xlabel(,labsize(vsmall) angle(forty_five)) ///
		graphregion(color(white)) ///
		note("Notes: Individual level observations plotted. All persons ages 18-65." "Values in € per year (2015 prices). X axis range limited to 100.", size(vsmall))
		
	graph export ///
		"$dir_output_files/income/validation_${country}_capital_income_dist_`year'.png", ///
		replace width(2560) height(1440) 
	
}
	
graph drop _all 	

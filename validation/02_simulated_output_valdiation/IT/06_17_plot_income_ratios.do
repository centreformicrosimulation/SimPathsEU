/*
This do file plots simulated and observed P90/P10 and P90/P50 income ratios 

Author: Patryk Bronka
Last modified: October 2023

*/

/*==============================================================================
1 : Mean values over time
==============================================================================*/

* Prepare validation data
use year dwt valid_y_eq_disp_yr_bu using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

* Trim outliers
if "$trim_outliers" == "true" {
	sum valid_y_eq_disp_yr_bu, d
	replace valid_y_eq_disp_yr_bu = . if ///
		valid_y_eq_disp_yr_bu < r(p1) | valid_y_eq_disp_yr_bu > r(p99)
}

collapse (p90) p90_disp = valid_y_eq_disp_yr_bu (p50) ///
	p50_disp = valid_y_eq_disp_yr_bu (p10) ///
	p10_disp = valid_y_eq_disp_yr_bu, by(year)
	
gen p90_p10_ratio_disp_obs = p90_disp/p10_disp
gen p90_p50_ratio_disp_obs = p90_disp/p50_disp

* Align reference years 
gen l_p90_p10_ratio_disp_obs = p90_p10_ratio_disp_obs[_n+1]
gen l_p90_p50_ratio_disp_obs = p90_p50_ratio_disp_obs[_n+1]

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year equivalisedincome using "$dir_data/simulated_data.dta", clear

* Trim outliers
if "$trim_outliers" == "true" {
	sum equivalisedincome, d
	replace equivalisedincome = . if ///
		equivalisedincome < r(p1) | equivalisedincome > r(p99)
}

collapse (p90) p90_disp = equivalisedincome (p50) ///
	p50_disp = equivalisedincome (p10) ///
	p10_disp = equivalisedincome, by(run year)
	
gen p90_p10_ratio_disp = p90_disp/p10_disp
gen p90_p50_ratio_disp = p90_disp/p50_disp

collapse (mean) p90_p10_ratio_disp p90_p50_ratio_disp ///
	(sd) sd_p90_p10_ratio_disp = p90_p10_ratio_disp ///
	 sd_p90_p50_ratio_disp = p90_p50_ratio_disp ///
	 , by(year)

 foreach var in  p90_p10_ratio_disp p90_p50_ratio_disp {
	gen `var'_HI = `var' + 1.96*sd_`var'
	gen `var'_LO = `var' - 1.96*sd_`var'
}
	 
merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen



* Plot figure
foreach var in p90_p10_ratio_disp  {
		twoway (rarea `var'_HI `var'_LO year, sort color(red%20) ///
			legend(label(1 "Simulated") position(6) rows(1))) ///
		(line `var'_obs year, sort legend(label(2 "Observed"))), ///
			title("P90/P10") name(`var', replace)  ///
		graphregion(color(white)) ///
		xtitle("")
}

foreach var in p90_p50_ratio_disp {
		twoway (rarea `var'_HI `var'_LO year, sort color(red%20) ///
			legend(label(1 "Simulated") position(6) rows(1))) ///
		(line `var'_obs year, sort legend(label(2 "Observed"))), ///
		title("P90/P50") name(`var', replace) ///
		graphregion(color(white)) ///
		xtitle("")
}

* Save figure
grc1leg p90_p10_ratio_disp p90_p50_ratio_disp, ///
	title("Inequality (decile ratios of disposable income)") ///
	legendfrom(p90_p10_ratio_disp) ///
	graphregion(color(white)) ///
	note("Notes: Samepl contains all individuals ages 18-65. Missing simulated amoutn due to 0 amount for P10 in simulated data.", size(vsmall))

	
graph export ///
"$dir_output_files/inequality/validation_${country}_disposable_income_ratio_ts_all_both.jpg", ///
	replace width(2400) height(1350)

	
graph drop _all 	

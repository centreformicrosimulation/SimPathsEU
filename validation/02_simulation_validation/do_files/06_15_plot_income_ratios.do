/*******************************************************************************
* PROJECT:  		SimPaths EU 
* SECTION:			Validation
* OBJECT: 			Income ratios
* AUTHORS:			Patryk Bronka, Ashley Burdett 
* LAST UPDATE:		11/2025 (AB)
* COUNTRY: 			Poland 
********************************************************************************
* NOTES: 			
*******************************************************************************/

********************************************************************************
* 1 : Time series
********************************************************************************

* Prepare validation data
use year dwt valid_y_eq_disp_bu_yr using ///
	"$dir_data/${country}-eusilc_validation_sample_long.dta", clear

* Trim outliers
if "$trim_outliers" == "true" {
	
	sum valid_y_eq_disp_bu_yr, d
	
	replace valid_y_eq_disp_bu_yr = . if ///
		valid_y_eq_disp_bu_yr < r(p1) | valid_y_eq_disp_bu_yr > r(p99)

}

collapse (p90) p90_disp = valid_y_eq_disp_bu_yr (p50) ///
	p50_disp = valid_y_eq_disp_bu_yr (p10) ///
	p10_disp = valid_y_eq_disp_bu_yr, by(year)
	
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
		(line `var'_obs year, sort legend(label(2 "SILC"))), ///
		title("P90/P10") ///
		name(`var', replace)  ///
		xtitle("", size(small)) ///
		ytitle("", size(small)) ///
		ylabel(,labsize(small)) ///
		xlabel(,labsize(small)) ///
		legend(size(small)) ///
		graphregion(color(white))
		
}

foreach var in p90_p50_ratio_disp {
		
	twoway (rarea `var'_HI `var'_LO year, sort color(red%20) ///
		legend(label(1 "Simulated") position(6) rows(1))) ///
		(line `var'_obs year, sort legend(label(2 "SILC"))), ///
		title("P90/P50") ///
		name(`var', replace)  ///
		xtitle("", size(small)) ///
		ytitle("", size(small)) ///
		ylabel(,labsize(small)) ///
		xlabel(,labsize(small)) ///
		legend(size(small)) ///
		graphregion(color(white))
		
}

* Save figure
grc1leg p90_p10_ratio_disp p90_p50_ratio_disp, ///
	title("Inequality") ///
	legendfrom(p90_p10_ratio_disp) ///
	graphregion(color(white)) ///
	note("Notes: Figures contain household income decile ratios. Sample contains all individuals ages ${min_age}-${max_age}. Individual observatioons plotted, beneift unit" "variable.", ///
	size(vsmall))
	
graph export ///
"$dir_output_files/inequality/validation_${country}_disposable_income_ratio_ts_all_both.jpg", ///
	replace width(2400) height(1350)

	
graph drop _all 	

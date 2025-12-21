********************************************************************************
* PROJECT:  		ESPON 
* SECTION:			Validation
* OBJECT: 			Risk of poverty 
* AUTHORS:			Patryk Bronka, Ashley Burdett 
* LAST UPDATE:		06/2025 (AB)
* COUNTRY: 			Poland 

* NOTES: 			This master do file organises do files used for validating 
* 					SimPaths model using EU-SILC data for Poland. 
********************************************************************************

********************************************************************************
* 1 : Mean values over time
********************************************************************************

* Prepare validation data
use year dwt valid_y_eq_disp_yr_bu using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

* Trim outliers
if "$trim_outliers" == "true" {
	sum valid_y_eq_disp_yr_bu, d
	replace valid_y_eq_disp_yr_bu = . if ///
		valid_y_eq_disp_yr_bu < r(p1) | valid_y_eq_disp_yr_bu > r(p99)
}

qui sum year
local min_year = r(min)  
local max_year = r(max)  

gen poverty_line = .
forval year = `min_year'/`max_year' {
	sum valid_y_eq_disp_yr_bu if year == `year', d
	replace poverty_line = 0.6*r(p50) if year == `year'
}

gen arop = (valid_y_eq_disp_yr_bu < poverty_line)

collapse (mean) arop [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year equivalisedincome using "$dir_data/simulated_data.dta", clear

* Trim outliers
if "$trim_outliers" == "true" {
	sum equivalisedincome, d
	replace equivalisedincome = . if ///
		equivalisedincome < r(p1) | equivalisedincome > r(p99)
}

bys run year: egen equivincome_median = median(equivalisedincome)
gen poverty_line = 0.6*equivincome_median
gen arop_sim = (equivalisedincome < poverty_line)

collapse (mean) arop_sim, by(run year)
collapse (mean) arop_sim ///
		 (sd) arop_sim_sd = arop_sim ///
		 , by(year)
		 
foreach varname in arop_sim {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
twoway (rarea arop_sim_high arop_sim_low year, sort color(green%20) ///
	legend(label(1 "Simulated"))) ///
(line arop year, sort color(green) legend(label(2 "Observed"))), ///
	title("At risk of poverty") xtitle("") ytitle("Share") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
		legend(size(small)) ///
		graphregion(color(white)) ///
	note("Note: Poverty line calculated within each year as equivalised disposable income of benefit unit < 60% of the median value.", ///
	size(vsmall))

* Save figure
graph export "$dir_output_files/poverty/validation_${country}_at_risk_of_poverty_EUSILC_age_${min_age}_${max_age}.jpg", ///
	replace width(2560) height(1440) quality(100)

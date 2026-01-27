/*******************************************************************************
* PROJECT:  		SimPaths EU 
* SECTION:			Validation
* OBJECT: 			Capital income
* AUTHORS:			Patryk Bronka, Ashley Burdett 
* LAST UPDATE:		06/2025 (AB)
* COUNTRY: 			Poland 
********************************************************************************
* NOTES: 			This do file plots simulated and SILC capital income, 
*					per benefit unit

*******************************************************************************/

********************************************************************************
* 1 : Mean values over time
********************************************************************************
********************************************************************************
* 1.1 : Mean values over time - By individual, benefit unit amounts
********************************************************************************

* Prepare validation data
use year dwt valid_y_gross_capital_bu_yr using /// 
	"$dir_data/${country}-eusilc_validation_sample_long.dta", clear


* Trim outliers
if "$trim_outliers" == "true" {
	
	sum valid_y_gross_capital_bu_yr, d
	
	replace valid_y_gross_capital_bu_yr = . if ///
		valid_y_gross_capital_bu_yr < r(p1) | ///
		valid_y_gross_capital_bu_yr > r(p99)

}

collapse (mean) valid_y_gross_capital_bu_yr [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year sim_ypncp_lvl_bu using "$dir_data/simulated_data.dta", clear


* Trim outliers
if "$trim_outliers" == "true" {
	
	sum sim_ypncp_lvl_bu, d
	
	replace sim_ypncp_lvl_bu = . if ///
		sim_ypncp_lvl_bu < r(p1) | sim_ypncp_lvl_bu > r(p99)

}


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
(line valid_y_gross_capital_bu_yr year, sort color(green) ///
	legend(label(2 "SILC"))), ///
title("Capital Income") ///
	xtitle("Year", size(small)) ///
	ytitle("€ per year", size(small)) ///
	ylabel(,labsize(small)) ///
	xlabel(,labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white)) ///
	note("Notes: Series represents average benefit unit capital income, annual. Statistics computed by averaging benefit unit-level gross" "income for all persons ages 18-65. Top and bottom percentiles trimmed. Amounts in 2015 prices. ", ///
	size(vsmall))

* Save figure
graph export ///
"$dir_output_files/income/capital_income/validation_${country}_capital_income_ts_${min_age}_${max_age}_both.jpg", ///
	replace width(2400) height(1350) quality(100)

	
********************************************************************************
* 1.2 : Share with no capital income 
********************************************************************************
* Prepare validation data
use year dwt valid_y_gross_capital_bu_yr using /// 
	"$dir_data/${country}-eusilc_validation_sample_long.dta", clear

* Trim outliers
if "$trim_outliers" == "true" {
	
	sum valid_y_gross_capital_bu_yr, d
	
	replace valid_y_gross_capital_bu_yr = . if ///
		valid_y_gross_capital_bu_yr < r(p1) | valid_y_gross_capital_bu_yr > r(p99)

}

gen valid_no_capital = (valid_y_gross_capital_bu_yr == 0)

collapse (mean) valid_no_capital [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year sim_ypncp_lvl_bu using "$dir_data/simulated_data.dta", clear

* Trim outliers
if "$trim_outliers" == "true" {
	
	sum sim_ypncp_lvl_bu, d
	
	replace sim_ypncp_lvl_bu = . if ///
		sim_ypncp_lvl_bu < r(p1) | sim_ypncp_lvl_bu > r(p99)

}

gen sim_no_capital = (sim_ypncp_lvl_bu == 0)

collapse (mean) sim_no_capital, by(run year)

collapse (mean) sim_no_capital ///
		 (sd) sim_no_capital_sd = sim_no_capital ///
		 , by(year)
		 
foreach varname in sim_no_capital {
	
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	
	gen `varname'_low = `varname' - 1.96*`varname'_sd

}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
twoway (rarea sim_no_capital_high sim_no_capital_low year, sort ///
	color(green%20) legend(label(1 "Simulated"))) ///
(line valid_no_capital year, sort color(green) ///
	legend(label(2 "SILC"))), ///
title("No Capital Income") ///
	xtitle("Year", size(small)) ///
	ytitle("Share", size(small)) ///
	ylabel(,labsize(small)) ///
	xlabel(,labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white)) ///
	note("Notes: Series represents share of individuals in benefit units that do not report receiving any capital income, annual. Statistics computed" "by averaging benefit unit-level gross income for all persons ages 18-65. Amounts in 2015 prices.", ///
	size(vsmall))

* Save figure
graph export ///
"$dir_output_files/income/capital_income/validation_${country}_no_capital_income_ts_${min_age}_${max_age}_both.jpg", ///
	replace width(2400) height(1350) quality(100)

********************************************************************************
* 2 : Histograms 
********************************************************************************
********************************************************************************
* 2.1 : Histograms by year, All
********************************************************************************

* All 
* Prepare validation data
use year dwt valid_y_gross_capital_bu_yr using ///
	"$dir_data/${country}-eusilc_validation_sample_long.dta", clear


* Trim outliers
if "$trim_outliers" == "true" {
	
	sum valid_y_gross_capital_bu_yr, d
	
	replace valid_y_gross_capital_bu_yr = . if ///
		valid_y_gross_capital_bu_yr < r(p1) | ///
		valid_y_gross_capital_bu_yr > r(p99)

}


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
local min_year = 2011  // Calculate the minimum value of the 'year' variable
local max_year = r(max)  // Calculate the maximum value of the 'year' variable

forval year = `min_year'/`max_year' {
	
    //Entire sample
	twoway (hist sim_ypncp_lvl_bu if year == `year' & sim_ypncp_lvl_bu < 100, ///
		width(1) color(green%30) legend(label(1 "Simulated"))) ///
	(hist valid_y_gross_capital_bu_yr if year == `year' & valid_y_gross_capital_bu_yr < 100, ///
		 width(1) color(red%30) legend(label(2 "SILC"))) , ///
	title("Capital Income") ///
		subtitle("`year'") ///
		name(capital_inc_`year'_all, replace) ///
		xlabel(,labsize(vsmall) angle(forty_five)) ///
		xtitle("€ per year", size(small)) ///
		ytitle(, size(small)) ///
		graphregion(color(white)) ///
		note("Notes: Individual level observations plotted. All persons ages 18-65. Values in € per year, 2015 prices. X axis range limited to 100." "Top and bottom percentails trimmed.", ///
		size(vsmall))
		
	graph export ///
	"$dir_output_files/income/capital_income/validation_${country}_capital_income_dist_`year'.png", ///
		replace width(2560) height(1440) 
	
}
	
********************************************************************************
* 2.1 : Histograms by year, Positive amount
********************************************************************************
* Prepare validation data
use year dwt valid_y_gross_capital_bu_yr using ///
	"$dir_data/${country}-eusilc_validation_sample_long.dta", clear


* Trim outliers
if "$trim_outliers" == "true" {
	
	sum valid_y_gross_capital_bu_yr, d
	
	replace valid_y_gross_capital_bu_yr = . if ///
		valid_y_gross_capital_bu_yr < r(p1) | valid_y_gross_capital_bu_yr > r(p99)

}

drop if valid_y_gross_capital_bu_yr == 0 

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year sim_ypncp_lvl_bu using "$dir_data/simulated_data.dta", clear

* Trim outliers
if "$trim_outliers" == "true" {
	
	sum sim_ypncp_lvl_bu, d
	
	replace sim_ypncp_lvl_bu = . if ///
		sim_ypncp_lvl_bu < r(p1) | sim_ypncp_lvl_bu > r(p99)

}

drop if sim_ypncp_lvl_bu == 0 

append using "$dir_data/temp_valid_stats.dta"

qui sum year
local min_year = 2011  // Calculate the minimum value of the 'year' variable
local max_year = r(max)  // Calculate the maximum value of the 'year' variable

forval year = `min_year'/`max_year' {
	
    //Entire sample
	twoway (hist sim_ypncp_lvl_bu if year == `year' & sim_ypncp_lvl_bu < 100, ///
		width(1) color(green%30) legend(label(1 "Simulated"))) ///
	(hist valid_y_gross_capital_bu_yr if year == `year' & valid_y_gross_capital_bu_yr < 100, ///
		 width(1) color(red%30) legend(label(2 "SILC"))) , ///
	title("Capital Income, Positive Amounts") ///
		subtitle("`year'") ///
		name(capital_inc_`year'_all, replace) ///
		xlabel(,labsize(vsmall) angle(forty_five)) ///
		xtitle("€ per year", size(small)) ///
		ytitle(, size(small)) ///
		graphregion(color(white)) ///
		note("Notes: Individual level observations plotted. All persons ages 18-65. Values in € per year, 2015 prices. X axis range limited to 100." "Top percentile trimmed", ///
		size(vsmall))
		
	graph export ///
	"$dir_output_files/income/capital_income/validation_${country}_positive_capital_income_dist_`year'.png", ///
		replace width(2560) height(1440) 
	
}
	
graph drop _all 	

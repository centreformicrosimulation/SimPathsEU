********************************************************************************
* PROJECT:  		ESPON 
* SECTION:			Validation
* OBJECT: 			Hourly wages
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
use year dwt les_c4 valid_wage_hour using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

* Keep only employed individuals
keep if les_c4 == 1


* Trim outliers
if "$trim_outliers" == "true" {
	sum valid_wage_hour, d
	replace valid_wage_hour = . if ///
		valid_wage_hour < r(p1) | valid_wage_hour > r(p99)
}
*/
collapse (mean) valid_wage_hour [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year les_c4 potential_earnings_hourly using ///
	"$dir_data/simulated_data.dta", clear

* Keep only employed individuals
keep if les_c4 == "EmployedOrSelfEmployed"

* Trim outliers
if "$trim_outliers" == "true" {
	sum potential_earnings_hourly, d
	replace potential_earnings_hourly = . if ///
		potential_earnings_hourly < r(p1) | potential_earnings_hourly > r(p99)
}

collapse (mean) potential_earnings_hourly, by(run year)
collapse (mean) potential_earnings_hourly ///
		 (sd) potential_earnings_hourly_sd = potential_earnings_hourly ///
		 , by(year)
		 
foreach varname in potential_earnings_hourly {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
twoway (rarea potential_earnings_hourly_high ///
	potential_earnings_hourly_low year, ///
	sort color(green%20) legend(label(1 "Simulated"))) ///
(line valid_wage_hour year, sort color(green) ///
	legend(label(2 "Observed"))), ///
title("Hourly wages") xtitle("Year") ytitle("€ per hour") ///
	ylabel(,labsize(small)) xlabel(,labsize(small)) ///
	graphregion(color(white)) ///
	note("Notes: Statistics calculated on sample of employed anf self-employed individuals. Values in 2015 prices.", ///
	size(vsmall))

* Save figure
graph export ///
"$dir_output_files/wages/validation_${country}_wages_ts_${min_age}_${max_age}_both.jpg", ///
	replace width(2560) height(1440) quality(100)
	
	
** By gender 	

* Prepare validation data
use year dwt les_c4 valid_wage_hour dgn using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

* Keep only employed individuals
keep if les_c4 == 1

* Trim outliers
if "$trim_outliers" == "true" {
	sum valid_wage_hour, d
	replace valid_wage_hour = . if ///
		valid_wage_hour < r(p1) | valid_wage_hour > r(p99)
}
*/
collapse (mean) valid_wage_hour [aw = dwt], by(year dgn)

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year les_c4 potential_earnings_hourly dgn using ///
	"$dir_data/simulated_data.dta", clear

* Keep only employed individuals
keep if les_c4 == "EmployedOrSelfEmployed"

gen dgn2 = 0 if dgn == "Female"
replace dgn2 = 1 if dgn == "Male"

drop dgn
rename dgn2 dgn 

* Trim outliers
if "$trim_outliers" == "true" {
	sum potential_earnings_hourly , d
	replace potential_earnings_hourly = . if ///
		potential_earnings_hourly < r(p1) | potential_earnings_hourly > r(p99)
}

collapse (mean) potential_earnings_hourly, by(run year dgn)
collapse (mean) potential_earnings_hourly ///
		 (sd) potential_earnings_hourly_sd = potential_earnings_hourly ///
		 , by(year dgn)
		 
foreach varname in potential_earnings_hourly {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year dgn using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure  
twoway (rarea potential_earnings_hourly_high ///
	potential_earnings_hourly_low year if dgn == 0, ///
	sort color(green%20) legend(label(1 "Simulated"))) ///
(line valid_wage_hour year if dgn == 0, sort color(green) ///
	legend(label(2 "Observed"))), ///
subtitle("Females") name(wages_female, replace) ///
	xtitle("Year") ytitle("€ per hour") ///
	ylabel(,labsize(small)) xlabel(,labsize(small)) ///
	graphregion(color(white)) 
	
twoway (rarea potential_earnings_hourly_high ///
	potential_earnings_hourly_low year if dgn == 1, ///
	sort color(green%20) legend(label(1 "Simulated"))) ///
(line valid_wage_hour year if dgn == 1, sort color(green) ///
	legend(label(2 "Observed"))), ///
subtitle("Males") name(wages_male, replace)	///
	xtitle("Year") ytitle("€ per hour") ///
	ylabel(,labsize(small)) xlabel(,labsize(small)) ///
	graphregion(color(white)) 
	
	
grc1leg wages_female wages_male, ///
	title("Hourly wage") ///
	legendfrom(wages_female) rows(1) ///
	graphregion(color(white)) ///
	note("Notes: Statistics calculated on sample of employed anf self-employed individuals. Values in 2015 prices.", ///
	size(vsmall))
	
* Save figure
graph export ///
"$dir_output_files/wages/validation_${country}_wages_ts_${min_age}_${max_age}_gender.jpg", ///
	replace width(2560) height(1440) quality(100)
	

********************************************************************************
* 2 : Histograms by year
********************************************************************************

* Prepare validation data
use year dwt les_c4 valid_wage_hour using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

* Keep only employed individuals
keep if les_c4 == 1

drop les_c4

* Trim outliers
if "$trim_outliers" == "true" {
	sum valid_wage_hour, d
	replace valid_wage_hour = . if ///
		valid_wage_hour < r(p1) | valid_wage_hour > r(p99)
}

* Prepare info needed for dynamic y axis labels 
qui sum year
local min_year = r(min)  
local max_year = r(max)  

forval year = `min_year'/`max_year' { 

	twoway__histogram_gen valid_wage_hour if year == `year' , ///
		bin(60) den gen(d_valid v2)

	qui sum d_valid
	gen max_d_valid_`year' = r(max) 
	
	drop d_valid v2

}

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year les_c4 potential_earnings_hourly using ///
	"$dir_data/simulated_data.dta", clear

* Keep only employed individuals
keep if les_c4 == "EmployedOrSelfEmployed"

drop les_c4

* Trim outliers
if "$trim_outliers" == "true" {
	sum potential_earnings_hourly, d
	replace potential_earnings_hourly = . if ///
		potential_earnings_hourly < r(p1) | potential_earnings_hourly > r(p99)
}

append using "$dir_data/temp_valid_stats.dta"

qui sum year
local min_year = r(min)  
local max_year = r(max)  

forval year = `min_year'/`max_year' {
	
	* Prepare info needed for dynamic y axis labels 
	twoway__histogram_gen potential_earnings_hourly if year == `year', ///
		bin(60) den gen(d_sim v1)

	qui sum d_sim 
	gen max_d_sim = r(max)

	gen max_value = max_d_valid_`year' if max_d_valid_`year' > max_d_sim 
	replace max_value = max_d_sim if max_value == . 

	sum max_value 
	local max_y = 1.25*r(max)
	local steps = `max_y'/2

	* Plot all hours
	twoway (hist potential_earnings_hourly if year == `year', ///
		color(green%30)  legend(label(1 "Simulated"))) ///
	(hist valid_wage_hour if year == `year', color(red%30) ///
		legend(label(2 "Observed"))) , ///
	title("Hourly wage") ///
		subtitle("`year'") ///
		name(hourly_wages_`year'_all, replace) ///
		xlabel(,labsize(vsmall) angle(forty_five)) ///
		ylabel(0(`steps')`max_y', labsize(vsmall)) ///
		graphregion(color(white)) ///
		note("Notes: Statistics calculated on subsample of employed and self-employed individuals. Values in €, 2015 prices.", size(vsmall))
	
	graph export ///
	"$dir_output_files/wages/validation_${country}_wages_dist_`year'.png", ///
		replace width(2400) height(1350) 

	drop d_sim v1 max_d_sim max_value
	
}

** By gender

* Females 
* Prepare validation data
use year dwt les_c4 valid_wage_hour dgn using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

* Keep only employed individuals
keep if les_c4 == 1
keep if dgn == 0 

drop les_c4 dgn 

* Trim outliers
if "$trim_outliers" == "true" {
	sum valid_wage_hour, d
	replace valid_wage_hour = . if ///
		valid_wage_hour < r(p1) | valid_wage_hour > r(p99)
}

* Prepare info needed for dynamic y axis labels 
qui sum year
local min_year = r(min)  
local max_year = r(max)  

forval year = `min_year'/`max_year' { 

	twoway__histogram_gen valid_wage_hour if year == `year' , ///
		bin(60) den gen(d_valid v2)

	qui sum d_valid
	gen max_d_valid_`year' = r(max) 
	
	drop d_valid v2

}

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year les_c4 potential_earnings_hourly dgn using ///
	"$dir_data/simulated_data.dta", clear

* Keep only employed individuals
keep if les_c4 == "EmployedOrSelfEmployed"
keep if dgn == "Female"
drop les_c4 dgn

* Trim outliers
if "$trim_outliers" == "true" {
	sum potential_earnings_hourly, d
	replace potential_earnings_hourly = . if ///
		potential_earnings_hourly < r(p1) | potential_earnings_hourly > r(p99)
}

append using "$dir_data/temp_valid_stats.dta"

qui sum year
local min_year = r(min)  
local max_year = r(max)  

forval year = `min_year'/`max_year' {
	
	* Prepare info needed for dynamic y axis labels 
	twoway__histogram_gen potential_earnings_hourly if year == `year', ///
		bin(60) den gen(d_sim v1)

	qui sum d_sim 
	gen max_d_sim = r(max)

	gen max_value = max_d_valid_`year' if max_d_valid_`year' > max_d_sim 
	replace max_value = max_d_sim if max_value == . 

	sum max_value 
	local max_y = 1.25*r(max)
	local steps = `max_y'/2

	* Plot all hours
	twoway (hist potential_earnings_hourly if year == `year', ///
		color(green%30)  legend(label(1 "Simulated"))) ///
	(hist valid_wage_hour if year == `year', color(red%30) ///
		legend(label(2 "Observed"))) , ///
	title("Hourly wage") ///
		subtitle("`year', females") ///
		name(hourly_wages_`year'_all, replace) ///
		xlabel(,labsize(vsmall) angle(forty_five)) ///
		ylabel(0(`steps')`max_y', labsize(vsmall)) ///
		graphregion(color(white)) ///
		note("Notes: Statistics calculated on subsample of employed and self-employed individuals. Values in €, 2015 prices.", size(vsmall))
	
	graph export ///
	"$dir_output_files/wages/validation_${country}_wages_dist_`year'_female.png", ///
		replace width(2400) height(1350) 

	drop d_sim v1 max_d_sim max_value
	
}


* Females 
* Prepare validation data
use year dwt les_c4 valid_wage_hour dgn using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

* Keep only employed individuals
keep if les_c4 == 1
keep if dgn == 1 

drop les_c4 dgn 

* Trim outliers
if "$trim_outliers" == "true" {
	sum valid_wage_hour, d
	replace valid_wage_hour = . if ///
		valid_wage_hour < r(p1) | valid_wage_hour > r(p99)
}

* Prepare info needed for dynamic y axis labels 
qui sum year
local min_year = r(min)  
local max_year = r(max)  

forval year = `min_year'/`max_year' { 

	twoway__histogram_gen valid_wage_hour if year == `year' , ///
		bin(60) den gen(d_valid v2)

	qui sum d_valid
	gen max_d_valid_`year' = r(max) 
	
	drop d_valid v2

}

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year les_c4 potential_earnings_hourly dgn using ///
	"$dir_data/simulated_data.dta", clear

* Keep only employed individuals
keep if les_c4 == "EmployedOrSelfEmployed"
keep if dgn == "Male"
drop les_c4 dgn

* Trim outliers
if "$trim_outliers" == "true" {
	sum potential_earnings_hourly, d
	replace potential_earnings_hourly = . if ///
		potential_earnings_hourly < r(p1) | potential_earnings_hourly > r(p99)
}

append using "$dir_data/temp_valid_stats.dta"

qui sum year
local min_year = r(min)  
local max_year = r(max)  

forval year = `min_year'/`max_year' {
	
	* Prepare info needed for dynamic y axis labels 
	twoway__histogram_gen potential_earnings_hourly if year == `year', ///
		bin(60) den gen(d_sim v1)

	qui sum d_sim 
	gen max_d_sim = r(max)

	gen max_value = max_d_valid_`year' if max_d_valid_`year' > max_d_sim 
	replace max_value = max_d_sim if max_value == . 

	sum max_value 
	local max_y = 1.25*r(max)
	local steps = `max_y'/2

	* Plot all hours
	twoway (hist potential_earnings_hourly if year == `year', ///
		color(green%30)  legend(label(1 "Simulated"))) ///
	(hist valid_wage_hour if year == `year', color(red%30) ///
		legend(label(2 "Observed"))) , ///
	title("Hourly wage") ///
		subtitle("`year', males") ///
		name(hourly_wages_`year'_all, replace) ///
		xlabel(,labsize(vsmall) angle(forty_five)) ///
		ylabel(0(`steps')`max_y', labsize(vsmall)) ///
		graphregion(color(white)) ///
		note("Notes: Statistics calculated on subsample of employed and self-employed individuals. Values in €, 2015 prices.", size(vsmall))
	
	graph export ///
	"$dir_output_files/wages/validation_${country}_wages_dist_`year'_male.png", ///
		replace width(2400) height(1350) 

	drop d_sim v1 max_d_sim max_value
	
}


graph drop _all 

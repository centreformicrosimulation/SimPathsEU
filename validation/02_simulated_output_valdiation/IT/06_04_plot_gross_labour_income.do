/*
This do file plots simulated and observed gross labour income, per benefit unit

Author: Patryk Bronka
Last modified: November 2024

Hours categories of work updated.
Plotted using individual level data => multiple observations per ben unit. 
*/

/*==============================================================================
1 : Mean values over time
==============================================================================*/

* Prepare validation data
use year dwt les_c4 valid_y_gross_labour_yr_bu using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

* Keep only employed individuals
keep if les_c4 == 1


* Trim outliers
if "$trim_outliers" == "true" {
	sum valid_y_gross_labour_yr_bu, d
	replace valid_y_gross_labour_yr_bu = . if ///
		valid_y_gross_labour_yr_bu < r(p1) | valid_y_gross_labour_yr_bu > r(p99)
}
*/
collapse (mean) valid_y_gross_labour_yr_bu [aw = dwt], by(year)

gen l_valid_y_gross_labour_yr_bu = valid_y_gross_labour_yr_bu[_n+1]

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year les_c4 sim_yplgrs_dv_lvl_bu using ///
	"$dir_data/simulated_data.dta", clear

* Keep only employed individuals
keep if les_c4 == "EmployedOrSelfEmployed"


* Trim outliers
if "$trim_outliers" == "true" {
	sum sim_yplgrs_dv_lvl_bu, d
	replace sim_yplgrs_dv_lvl_bu = . if ///
		sim_yplgrs_dv_lvl_bu < r(p1) | sim_yplgrs_dv_lvl_bu > r(p99)
}
*/
collapse (mean) sim_yplgrs_dv_lvl_bu, by(run year)
collapse (mean) sim_yplgrs_dv_lvl_bu ///
		 (sd) sim_yplgrs_dv_lvl_bu_sd = sim_yplgrs_dv_lvl_bu ///
		 , by(year)
		 
foreach varname in sim_yplgrs_dv_lvl_bu {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
twoway ///
(rarea sim_yplgrs_dv_lvl_bu_high sim_yplgrs_dv_lvl_bu_low year, ///
	sort color(green%20) legend(label(1 "Simulated"))) ///
(line valid_y_gross_labour_yr_bu year, sort color(green) ///
	legend(label(2 "Observed"))), ///
	title("Gross labour income") ///
	xtitle("Year") ///
	ytitle("€ per year") ///
	ylabel(,labsize(small)) xlabel(,labsize(small)) ///
	graphregion(color(white)) ///
	note("Note: Statistics calculated on the sample of employed individuals ages 18-65. Yearly amounts. 2019 X-sectional data used in underlying" "estimation. Amounts in 2015 prices.", size(vsmall))

* Save figure
graph export ///	
"$dir_output_files/income/validation_${country}_gross_labour_income_ts_${min_age}_${max_age}_both.jpg", ///
	replace width(2400) height(1350) quality(100)
	

* Males

* Prepare validation data
use year dwt les_c4 valid_y_gross_labour_yr_bu dgn using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

keep if dgn == 1	
	
* Keep only employed individuals
keep if les_c4 == 1


* Trim outliers
if "$trim_outliers" == "true" {
	sum valid_y_gross_labour_yr_bu, d
	replace valid_y_gross_labour_yr_bu = . if ///
		valid_y_gross_labour_yr_bu < r(p1) | valid_y_gross_labour_yr_bu > r(p99)
}

collapse (mean) valid_y_gross_labour_yr_bu [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year les_c4 sim_yplgrs_dv_lvl_bu dgn using ///
	"$dir_data/simulated_data.dta", clear

keep if dgn == "Male"	
	
* Keep only employed individuals
keep if les_c4 == "EmployedOrSelfEmployed"


* Trim outliers
if "$trim_outliers" == "true" {
	sum sim_yplgrs_dv_lvl_bu, d
	replace sim_yplgrs_dv_lvl_bu = . if ///
		sim_yplgrs_dv_lvl_bu < r(p1) | sim_yplgrs_dv_lvl_bu > r(p99)
}

collapse (mean) sim_yplgrs_dv_lvl_bu, by(run year)
collapse (mean) sim_yplgrs_dv_lvl_bu ///
		 (sd) sim_yplgrs_dv_lvl_bu_sd = sim_yplgrs_dv_lvl_bu ///
		 , by(year)
		 
foreach varname in sim_yplgrs_dv_lvl_bu {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
twoway ///
(rarea sim_yplgrs_dv_lvl_bu_high sim_yplgrs_dv_lvl_bu_low year, ///
	sort color(green%20) legend(label(1 "Simulated"))) ///
(line valid_y_gross_labour_yr_bu year, sort color(green) ///
	legend(label(2 "Observed"))), ///
	title("Gross labour income") subtitle("Males") ///
	xtitle("Year") ///
	ytitle("€ per year") ///
	ylabel(,labsize(small)) xlabel(,labsize(small)) ///
	graphregion(color(white)) ///
	note("Note: Statistics calculated on the sample of employed males ages 18-65. Yearly amounts. 2019 X-sectional data used in underlying" "estimation. Amounts in 2015 prices.", size(vsmall))

* Save figure
graph export ///	
"$dir_output_files/income/validation_${country}_gross_labour_income_ts_${min_age}_${max_age}_male.jpg", ///
	replace width(2400) height(1350) quality(100)
	
	
* Females

* Prepare validation data
use year dwt les_c4 valid_y_gross_labour_yr_bu dgn using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

keep if dgn == 0	
	
* Keep only employed individuals
keep if les_c4 == 1


* Trim outliers
if "$trim_outliers" == "true" {
	sum valid_y_gross_labour_yr_bu, d
	replace valid_y_gross_labour_yr_bu = . if ///
		valid_y_gross_labour_yr_bu < r(p1) | valid_y_gross_labour_yr_bu > r(p99)
}

collapse (mean) valid_y_gross_labour_yr_bu [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year les_c4 sim_yplgrs_dv_lvl_bu dgn using ///
	"$dir_data/simulated_data.dta", clear

keep if dgn == "Female"	
	
* Keep only employed individuals
keep if les_c4 == "EmployedOrSelfEmployed"


* Trim outliers
if "$trim_outliers" == "true" {
	sum sim_yplgrs_dv_lvl_bu, d
	replace sim_yplgrs_dv_lvl_bu = . if ///
		sim_yplgrs_dv_lvl_bu < r(p1) | sim_yplgrs_dv_lvl_bu > r(p99)
}

collapse (mean) sim_yplgrs_dv_lvl_bu, by(run year)
collapse (mean) sim_yplgrs_dv_lvl_bu ///
		 (sd) sim_yplgrs_dv_lvl_bu_sd = sim_yplgrs_dv_lvl_bu ///
		 , by(year)
		 
foreach varname in sim_yplgrs_dv_lvl_bu {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
twoway ///
(rarea sim_yplgrs_dv_lvl_bu_high sim_yplgrs_dv_lvl_bu_low year, ///
	sort color(green%20) legend(label(1 "Simulated"))) ///
(line valid_y_gross_labour_yr_bu year, sort color(green) ///
	legend(label(2 "Observed"))), ///
	title("Gross labour income") subtitle("Females") ///
	xtitle("Year") ///
	ytitle("€ per year") ///
	ylabel(,labsize(small)) xlabel(,labsize(small)) ///
	graphregion(color(white)) ///
	note("Note: Statistics calculated on the sample of employed females ages 18-65. Yearly amounts. 2019 X-sectional data used in underlying" "estimation. Amounts in 2015 prices.", size(vsmall))

* Save figure
graph export ///	
"$dir_output_files/income/validation_${country}_gross_labour_income_ts_${min_age}_${max_age}_female.jpg", ///
	replace width(2400) height(1350) quality(100)	
	
	
/*==============================================================================
2 : Histograms by year, and by category of weekly labour supply 
==============================================================================*/

* Males 

* Prepare validation data
use year dwt les_c4 valid_y_gross_labour_yr_bu ///
	laboursupplyweekly_hu dgn using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

keep if dgn == 1 
drop dgn 
	
* Keep only employed individuals
keep if les_c4 == 1
drop les_c4

* Trim outliers
if "$trim_outliers" == "true" {
	sum valid_y_gross_labour_yr_bu, d
	replace valid_y_gross_labour_yr_bu = . if ///
		valid_y_gross_labour_yr_bu < r(p1) | valid_y_gross_labour_yr_bu > r(p99)
}

/*
For males:
	0 as 0 hours; // ZERO
	[1, 35] as 30 hours; // CATEGORY_1
	[36, 39] as 36 hours; // CATEGORY_2
	[40, 49] as 40 hours; // CATEGORY_3
	[50, ∞) as 50 hours.  // CATEGORY_4
*/
replace laboursupplyweekly_hu = "THIRTY" if laboursupplyweekly_hu == "CATEGORY_1"
replace laboursupplyweekly_hu = "THIRTY_SIX" if ///
	laboursupplyweekly_hu == "CATEGORY_2"
replace laboursupplyweekly_hu = "FORTY" if laboursupplyweekly_hu == "CATEGORY_3"
replace laboursupplyweekly_hu = "FIFTY" if laboursupplyweekly_hu == "CATEGORY_4"

* Prepare info needed for dynamic y axis labels 
qui sum year
local min_year = r(min)  
local max_year = r(max)  

forval year = `min_year'/`max_year' { 

	twoway__histogram_gen valid_y_gross_labour_yr_bu if year == `year', ///
		bin(60) den gen(d_valid v2)

	qui sum d_valid
	gen max_d_valid_`year' = r(max) 
	
	drop d_valid v2

	foreach ls in THIRTY THIRTY_SIX FORTY FIFTY {
	
		twoway__histogram_gen valid_y_gross_labour_yr_bu if ///
		year == `year' & labour == "`ls'", bin(60) den gen(d_valid v2)

		qui sum d_valid
		gen max_d_valid_`year'_`ls' = r(max) 
		
		drop d_valid v2	
	
	}
	
}

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year les_c4 sim_yplgrs_dv_lvl_bu laboursupplyweekly dgn using ///
	"$dir_data/simulated_data.dta", clear

keep if dgn == "Male"
drop dgn		
	
* Keep only employed individuals
keep if les_c4 == "EmployedOrSelfEmployed"
drop les_c4


* Trim outliers
if "$trim_outliers" == "true" {
	sum sim_yplgrs_dv_lvl_bu, d
	replace sim_yplgrs_dv_lvl_bu = . if ///
		sim_yplgrs_dv_lvl_bu < r(p1) | sim_yplgrs_dv_lvl_bu > r(p99)
}

keep if run == 1

/*
For males:
	0 as 0 hours; // ZERO
	[1, 35] as 30 hours; // CATEGORY_1
	[36, 39] as 36 hours; // CATEGORY_2
	[40, 49] as 40 hours; // CATEGORY_3
	[50, ∞) as 50 hours.  // CATEGORY_4
*/
replace laboursupplyweekly = "THIRTY" if laboursupplyweekly == "CATEGORY_1"
replace laboursupplyweekly = "THIRTY_SIX" if ///
	laboursupplyweekly == "CATEGORY_2"
replace laboursupplyweekly = "FORTY" if laboursupplyweekly == "CATEGORY_3"
replace laboursupplyweekly = "FIFTY" if laboursupplyweekly == "CATEGORY_4"

append using "$dir_data/temp_valid_stats.dta"


* Plot sub-figures 
qui sum year
local min_year = r(min)  // Calculate the minimum value of the 'year' variable
local max_year = r(max)  // Calculate the maximum value of the 'year' variable

forval year = `min_year'/`max_year' {
	
	* Prepare info needed for dynamic y axis labels
	twoway__histogram_gen sim_yplgrs_dv_lvl_bu if year == `year', bin(60) ///
		den gen(d_sim v1)

	qui sum d_sim 
	gen max_d_sim = r(max)

	gen max_value = max_d_valid_`year' if max_d_valid_`year' > max_d_sim 
	replace max_value = max_d_sim if max_value == . 

	sum max_value 
	local max_y = 1.25*r(max)
	local steps = `max_y'/2	
	
	
    * Plot all hours
	twoway (hist sim_yplgrs_dv_lvl_bu if year == `year' , bin(60) ///
		color(green%30) legend(label(1 "Simulated"))) ///
	(hist valid_y_gross_labour_yr_bu if year == `year' , bin(60) ///
		color(red%30) legend(label(2 "Observed"))) , ///
	subtitle("ALL hours") name(gross_labour_inc_`year'_all, replace) ///
		xlabel(,labsize(vsmall) angle(forty_five)) ///
		ylabel(0(`steps')`max_y',labsize(vsmall)) ///
		graphregion(color(white)) 

	
	drop d_sim v1 max_d_sim max_value
	
	* Plot by weekly hours work
	foreach ls in THIRTY THIRTY_SIX FORTY FIFTY {
	
		* Prepare info needed for dynamic y axis labels 	
		twoway__histogram_gen sim_yplgrs_dv_lvl_bu if year == `year' & ///
			laboursupplyweekly == "`ls'", bin(60) den gen(d_sim v1)
		
		qui sum d_sim 
		gen max_d_sim = r(max)

		gen max_value = max_d_valid_`year'_`ls' if ///
			max_d_valid_`year'_`ls' > max_d_sim 
		replace max_value = max_d_sim if max_value == . 

		sum max_value 
		local max_y = 1.25*r(max)
		local steps = `max_y'/2	
	
		* Plot by weekly hours work
		twoway (hist sim_yplgrs_dv_lvl_bu if year == `year' & ///
			laboursupplyweekly == "`ls'", bin(60) color(green%30) ///
			legend(label(1 "Simulated"))) ///
		(hist valid_y_gross_labour_yr_bu if year == `year' & ///
			laboursupplyweekly_hu == "`ls'", bin(60) color(red%30) ///
			legend(label(2 "Observed"))) , ///
		subtitle("`ls' hours")  name(gross_labour_inc_`year'_`ls', replace) ///
		xlabel(,labsize(vsmall) angle(forty_five)) ///
		ylabel(0(`steps')`max_y',labsize(vsmall)) ///
		graphregion(color(white)) 
	
		drop d_sim v1 max_d_sim max_value
		
	}
}

* Combine plots by year 
forvalues year = `min_year'/`max_year' {
	
	grc1leg gross_labour_inc_`year'_all gross_labour_inc_`year'_THIRTY ///
		gross_labour_inc_`year'_THIRTY_SIX gross_labour_inc_`year'_FORTY ///
		gross_labour_inc_`year'_FIFTY, ///
		title("Gross labour income") ///
		subtitle("`year', Males") ///
		legendfrom(gross_labour_inc_`year'_all) rows(2) ///
		graphregion(color(white)) ///
		note("Notes: Series represents average benefit unit gross labour income through time. Statistics computed by averaging benefit unit" "level gross income for all males ages 18-65. Values in € per year, 2015 prices. Weekly hours worked categories:" "ZERO = 0, THIRTY = [1,35], THIRTY_SIX = [36, 39], FORTY = [40,49], FIFTY = 50+.", size(vsmall)) 
		
	graph export "$dir_output_files/income/validation_${country}_gross_labour_income_dist_`year'_male.png", ///
		replace width(2400) height(1350) 

		
}

graph drop _all


* Females 

* Prepare validation data
use year dwt les_c4 valid_y_gross_labour_yr_bu ///
	laboursupplyweekly_hu dgn using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

keep if dgn == 0 
drop dgn 
	
* Keep only employed individuals
keep if les_c4 == 1
drop les_c4

* Trim outliers
if "$trim_outliers" == "true" {
	sum valid_y_gross_labour_yr_bu, d
	replace valid_y_gross_labour_yr_bu = . if ///
		valid_y_gross_labour_yr_bu < r(p1) | valid_y_gross_labour_yr_bu > r(p99)
}

/*
For males:
For females:
	0 as 0 hours; // ZERO
	[1, 29] as 20 hours; // CATEGORY_1
	[30, 35] as 30 hours; // CATEGORY_2
	[36, 39] as 36 hours; // CATEGORY_3
	[40, ∞) as 40 hours. // CATEGORY_4
*/
replace laboursupplyweekly_hu = "TWENTY" if laboursupplyweekly_hu == "CATEGORY_1"
replace laboursupplyweekly_hu = "THIRTY" if ///
	laboursupplyweekly_hu == "CATEGORY_2"
replace laboursupplyweekly_hu = "THIRTY_SIX" if laboursupplyweekly_hu == "CATEGORY_3"
replace laboursupplyweekly_hu = "FORTY" if laboursupplyweekly_hu == "CATEGORY_4"

* Prepare info needed for dynamic y axis labels 
qui sum year
local min_year = r(min)  
local max_year = r(max)  

forval year = `min_year'/`max_year' { 

	twoway__histogram_gen valid_y_gross_labour_yr_bu if year == `year', ///
		bin(60) den gen(d_valid v2)

	qui sum d_valid
	gen max_d_valid_`year' = r(max) 
	
	drop d_valid v2

	foreach ls in TWENTY THIRTY THIRTY_SIX FORTY {
	
		twoway__histogram_gen valid_y_gross_labour_yr_bu if ///
		year == `year' & labour == "`ls'", bin(60) den gen(d_valid v2)

		qui sum d_valid
		gen max_d_valid_`year'_`ls' = r(max) 
		
		drop d_valid v2	
	
	}
	
}

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year les_c4 sim_yplgrs_dv_lvl_bu laboursupplyweekly dgn using ///
	"$dir_data/simulated_data.dta", clear

keep if dgn == "Female"
drop dgn		
	
* Keep only employed individuals
keep if les_c4 == "EmployedOrSelfEmployed"
drop les_c4


* Trim outliers
if "$trim_outliers" == "true" {
	sum sim_yplgrs_dv_lvl_bu, d
	replace sim_yplgrs_dv_lvl_bu = . if ///
		sim_yplgrs_dv_lvl_bu < r(p1) | sim_yplgrs_dv_lvl_bu > r(p99)
}

keep if run == 1

/*
For females:
	0 as 0 hours; // ZERO
	[1, 29] as 20 hours; // CATEGORY_1
	[30, 35] as 30 hours; // CATEGORY_2
	[36, 39] as 36 hours; // CATEGORY_3
	[40, ∞) as 40 hours. // CATEGORY_4
*/
replace laboursupplyweekly = "TWENTY" if laboursupplyweekly == "CATEGORY_1"
replace laboursupplyweekly = "THIRTY" if ///
	laboursupplyweekly == "CATEGORY_2"
replace laboursupplyweekly = "THIRTY_SIX" if laboursupplyweekly == "CATEGORY_3"
replace laboursupplyweekly = "FORTY" if laboursupplyweekly == "CATEGORY_4"

append using "$dir_data/temp_valid_stats.dta"


* Plot sub-figures 
qui sum year
local min_year = r(min)  // Calculate the minimum value of the 'year' variable
local max_year = r(max)  // Calculate the maximum value of the 'year' variable

forval year = `min_year'/`max_year' {
	
	* Prepare info needed for dynamic y axis labels
	twoway__histogram_gen sim_yplgrs_dv_lvl_bu if year == `year', bin(60) ///
		den gen(d_sim v1)

	qui sum d_sim 
	gen max_d_sim = r(max)

	gen max_value = max_d_valid_`year' if max_d_valid_`year' > max_d_sim 
	replace max_value = max_d_sim if max_value == . 

	sum max_value 
	local max_y = 1.25*r(max)
	local steps = `max_y'/2	
	
	
    * Plot all hours
	twoway (hist sim_yplgrs_dv_lvl_bu if year == `year' , bin(60) ///
		color(green%30) legend(label(1 "Simulated"))) ///
	(hist valid_y_gross_labour_yr_bu if year == `year' , bin(60) ///
		color(red%30) legend(label(2 "Observed"))) , ///
	subtitle("ALL hours") name(gross_labour_inc_`year'_all, replace) ///
		xlabel(,labsize(vsmall) angle(forty_five)) ///
		ylabel(0(`steps')`max_y',labsize(vsmall)) ///
		graphregion(color(white)) 

	
	drop d_sim v1 max_d_sim max_value
	
	* Plot by weekly hours work
	foreach ls in TWENTY THIRTY THIRTY_SIX FORTY {
	
		* Prepare info needed for dynamic y axis labels 	
		twoway__histogram_gen sim_yplgrs_dv_lvl_bu if year == `year' & ///
			laboursupplyweekly == "`ls'", bin(60) den gen(d_sim v1)
		
		qui sum d_sim 
		gen max_d_sim = r(max)

		gen max_value = max_d_valid_`year'_`ls' if ///
			max_d_valid_`year'_`ls' > max_d_sim 
		replace max_value = max_d_sim if max_value == . 

		sum max_value 
		local max_y = 1.25*r(max)
		local steps = `max_y'/2	
	
		* Plot by weekly hours work
		twoway (hist sim_yplgrs_dv_lvl_bu if year == `year' & ///
			laboursupplyweekly == "`ls'", bin(60) color(green%30) ///
			legend(label(1 "Simulated"))) ///
		(hist valid_y_gross_labour_yr_bu if year == `year' & ///
			laboursupplyweekly_hu == "`ls'", bin(60) color(red%30) ///
			legend(label(2 "Observed"))) , ///
		subtitle("`ls' hours")  name(gross_labour_inc_`year'_`ls', replace) ///
		xlabel(,labsize(vsmall) angle(forty_five)) ///
		ylabel(0(`steps')`max_y',labsize(vsmall)) ///
		graphregion(color(white)) 
	
		drop d_sim v1 max_d_sim max_value
		
	}
}

* Combine plots by year 
forvalues year = `min_year'/`max_year' {
	
	grc1leg gross_labour_inc_`year'_all gross_labour_inc_`year'_TWENTY ///
		gross_labour_inc_`year'_THIRTY ///
		gross_labour_inc_`year'_THIRTY_SIX gross_labour_inc_`year'_FORTY, ///
		title("Gross labour income") ///
		subtitle("`year', Females") ///
		legendfrom(gross_labour_inc_`year'_all) rows(2) ///
		graphregion(color(white)) ///
		note("Notes: Series represents average benefit unit gross labour income through time. Statistics computed by averaging benefit-unit level" "gross income for all females ages 18-65. Values in € per year, 2015 prices. Weekly hours worked categories:" "ZERO = 0, TWENTY = [1,29], THIRTY = [30,35], THIRTY_SIX = [36, 39]. FORTY = 40+.", size(vsmall)) 
		
	graph export "$dir_output_files/income/validation_${country}_gross_labour_income_dist_`year'_female.png", ///
		replace width(2400) height(1350) 

		
}

graph drop _all


/*
This do file plots simulated and observed gross income. 

Author: Patryk Bronka, Ashley Burdett
Last modified: March 2025

Set of labour supply options updated to align with HU estimates - 0, 20, 40, 50

Data details: The underlying variable is composed of 
	- wages
	- self-employment eanrings/losses
	- private pension income 
	- regular inter-hh transfers
	- child earnings (<16)*
	- Income from rental property of land*
	- Interest, dividends, profit from capital investment*
	
	* - underlying variable measured at the hh level and assumed to be spread 
	evenly among adult hh members. 


*/

/*==============================================================================
1.0 : Mean values over time (gross income of benefit unit)
==============================================================================*/

* Prepare validation data 
use year dwt valid_y_gross_nsbc_yr_bu using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear


* Trim outliers
if "$trim_outliers" == "true" {
	sum valid_y_gross_nsbc_yr_bu, d
	replace valid_y_gross_nsbc_yr_bu = . if ///
		valid_y_gross_nsbc_yr_bu < r(p1) | valid_y_gross_nsbc_yr_bu > r(p99)
}
*/

collapse (mean) valid_y_gross_nsbc_yr_bu [aw = dwt], by(year)

gen l_valid_y_gross_nsbc_yr_bu = valid_y_gross_nsbc_yr_bu[_n+1]

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year sim_y_gross_yr_bu using "$dir_data/simulated_data.dta", clear


* Trim outliers
if "$trim_outliers" == "true" {
	sum sim_y_gross_yr_bu, d
	replace sim_y_gross_yr_bu = . if sim_y_gross_yr_bu < r(p1) | ///
		sim_y_gross_yr_bu > r(p99)
}
*/
collapse (mean) sim_y_gross_yr_bu, by(run year)
collapse (mean) sim_y_gross_yr_bu ///
		 (sd) sim_y_gross_yr_bu_sd = sim_y_gross_yr_bu ///
		 , by(year)
		 
foreach varname in sim_y_gross_yr_bu {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen


* Plot figure
twoway ///
	(rarea sim_y_gross_yr_bu_high sim_y_gross_yr_bu_low year, ///
		sort color(green%20) legend(label(1 "Simulated"))) ///
	(line valid_y_gross_nsbc_yr_bu year, sort color(green) ///
		legend(label(2 "Observed"))), ///
	title("Gross income") xtitle("Year") ///
	ytitle("€ per year") ///
	ylabel(,labsize(small)) xlabel(,labsize(small)) ///
	graphregion(color(white)) ///
	note("Notes: Series represents average benefit unit gross income without benefits through time. Statistics computed by averaging benefit" "unit-level gross income for all persons ages 18-65. Amounts in 2015 prices.", size(vsmall))

graph export ///
"$dir_output_files/income/validation_${country}_gross_income_ts_${min_age}_${max_age}_both.jpg", ///
	replace width(2400) height(1350) quality(100)
	
	
* Male 

* Prepare validation data 
use year dwt valid_y_gross_nsbc_yr_bu dgn using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

keep if dgn == 1 	

* Trim outliers
if "$trim_outliers" == "true" {
	sum valid_y_gross_nsbc_yr_bu, d
	replace valid_y_gross_nsbc_yr_bu = . if ///
		valid_y_gross_nsbc_yr_bu < r(p1) | valid_y_gross_nsbc_yr_bu > r(p99)
}

collapse (mean) valid_y_gross_nsbc_yr_bu [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year sim_y_gross_yr_bu dgn using "$dir_data/simulated_data.dta", clear

keep if dgn == "Male"

* Trim outliers
if "$trim_outliers" == "true" {
	sum sim_y_gross_yr_bu, d
	replace sim_y_gross_yr_bu = . if sim_y_gross_yr_bu < r(p1) | ///
		sim_y_gross_yr_bu > r(p99)
}

collapse (mean) sim_y_gross_yr_bu, by(run year)
collapse (mean) sim_y_gross_yr_bu ///
		 (sd) sim_y_gross_yr_bu_sd = sim_y_gross_yr_bu ///
		 , by(year)
		 
foreach varname in sim_y_gross_yr_bu {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen


* Plot figure
twoway ///
	(rarea sim_y_gross_yr_bu_high sim_y_gross_yr_bu_low year, ///
		sort color(green%20) legend(label(1 "Simulated"))) ///
	(line valid_y_gross_nsbc_yr_bu year, sort color(green) ///
		legend(label(2 "Observed"))), ///
	title("Gross income") subtitle("Males") xtitle("Year") ///
	ytitle("€ per year") ///
	ylabel(,labsize(small)) xlabel(,labsize(small)) ///
	graphregion(color(white)) ///
	note("Notes: Series represents average benefit unit gross income without benefits through time. Statistics computed by averaging benefit" "unit-level gross income for all males aged 18-65. Amounts in 2015 prices.", size(vsmall))

graph export ///
"$dir_output_files/income/validation_${country}_gross_income_ts_${min_age}_${max_age}_male.jpg", ///
	replace width(2400) height(1350) quality(100)	
	

* Female 

* Prepare validation data 
use year dwt valid_y_gross_nsbc_yr_bu dgn using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

keep if dgn == 0 	

* Trim outliers
if "$trim_outliers" == "true" {
	sum valid_y_gross_nsbc_yr_bu, d
	replace valid_y_gross_nsbc_yr_bu = . if ///
		valid_y_gross_nsbc_yr_bu < r(p1) | valid_y_gross_nsbc_yr_bu > r(p99)
}

collapse (mean) valid_y_gross_nsbc_yr_bu [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year sim_y_gross_yr_bu dgn using "$dir_data/simulated_data.dta", clear

keep if dgn == "Female"

* Trim outliers
if "$trim_outliers" == "true" {
	sum sim_y_gross_yr_bu, d
	replace sim_y_gross_yr_bu = . if sim_y_gross_yr_bu < r(p1) | ///
		sim_y_gross_yr_bu > r(p99)
}

collapse (mean) sim_y_gross_yr_bu, by(run year)
collapse (mean) sim_y_gross_yr_bu ///
		 (sd) sim_y_gross_yr_bu_sd = sim_y_gross_yr_bu ///
		 , by(year)
		 
foreach varname in sim_y_gross_yr_bu {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen


* Plot figure
twoway ///
	(rarea sim_y_gross_yr_bu_high sim_y_gross_yr_bu_low year, ///
		sort color(green%20) legend(label(1 "Simulated"))) ///
	(line valid_y_gross_nsbc_yr_bu year, sort color(green) ///
		legend(label(2 "Observed"))), ///
	title("Gross income") subtitle("Females") xtitle("Year") ///
	ytitle("€ per year") ///
	ylabel(,labsize(small)) xlabel(,labsize(small)) ///
	graphregion(color(white)) ///
	note("Notes: Series represents average benefit unit gross income without benefits through time. Statistics computed by averaging benefit" "unit-level gross income for all females aged 18-65. Amounts in 2015 prices.", size(vsmall))

graph export ///
"$dir_output_files/income/validation_${country}_gross_income_ts_${min_age}_${max_age}_female.jpg", ///
	replace width(2400) height(1350) quality(100)	
	
	
	
/*==============================================================================
1.1 : Mean values over time (gross income of individual)
==============================================================================*/

* Prepare validation data 
use year dwt valid_y_gross_nsbc_person_yr using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear


* Trim outliers
if "$trim_outliers" == "true" {
	sum valid_y_gross_nsbc_person_yr, d
	replace valid_y_gross_nsbc_person_yr = . if ///
		valid_y_gross_nsbc_person_yr < r(p1) | ///
		valid_y_gross_nsbc_person_yr > r(p99)
}
*/
collapse (mean) valid_y_gross_nsbc_person_yr [aw = dwt], by(year)

gen l_valid_y_gross_nsbc_person_yr = valid_y_gross_nsbc_person_yr[_n+1]

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year sim_y_gross_yr using "$dir_data/simulated_data.dta", clear

* Trim outliers
if "$trim_outliers" == "true" {
	sum sim_y_gross_yr, d
	replace sim_y_gross_yr = . if ///
		sim_y_gross_yr < r(p1) | sim_y_gross_yr > r(p99)
}

collapse (mean) sim_y_gross_yr, by(run year)
collapse (mean) sim_y_gross_yr ///
		 (sd) sim_y_gross_yr_sd = sim_y_gross_yr ///
		 , by(year)
		 
foreach varname in sim_y_gross_yr {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
twoway ///
(rarea sim_y_gross_yr_high sim_y_gross_yr_low year, sort color(green%20) ///
	legend(label(1 "Simulated"))) ///
(line valid_y_gross_nsbc_person_yr year, sort color(green) ///
	legend(label(2 "Observed"))), title("Individual gross income") ///
	xtitle("Year") ///
	ytitle("€ per year") ///
	ylabel(,labsize(small)) xlabel(,labsize(vsmall)) ///
	graphregion(color(white)) ///
	note("Notes: Series represents average individual gross income without benefits through time. Statistics computed by averaging" "person-level gross income over all persons ages 18-65. Values in 2015 prices.", size(vsmall))
		
graph export ///
"$dir_output_files/income/validation_${country}_ind_gross_income_ts_${min_age}_${max_age}_both.jpg", ///
	replace width(2400) height(1350) quality(100)

	
/*==============================================================================
2 : Histograms of benefit unit gross income by year, and by category of weekly 
labour supply 
==============================================================================*/

* Both genders 

* Plot using male hours categories 

/*
For males:
	0 as 0 hours; // ZERO
	[1, 35] as 30 hours; // CATEGORY_1
	[36, 39] as 36 hours; // CATEGORY_2
	[40, 49] as 40 hours; // CATEGORY_3
	[50, ∞) as 50 hours.  // CATEGORY_4
*/

* Prepare validation data 
use year dwt valid_y_gross_nsbc_yr_bu laboursupplyweekly_hu dgn hours using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear
	
replace laboursupplyweekly_hu = "CATEGORY_1" if hours >= 1 & hours <= 35 & ///
	dgn == 0 
replace laboursupplyweekly_hu = "CATEGORY_2" if hours >= 36 & hours <= 39 & ///
	dgn == 0 
replace laboursupplyweekly_hu = "CATEGORY_3" if hours >= 40 & hours <= 49 & ///
	dgn == 0 
replace laboursupplyweekly_hu = "CATEGORY_4" if hours >= 50 & hours != . & ///
	dgn == 0  
	
replace laboursupplyweekly_hu = "THIRTY" if ///
	laboursupplyweekly_hu == "CATEGORY_1"
replace laboursupplyweekly_hu = "THIRTY_SIX" if ///
	laboursupplyweekly_hu == "CATEGORY_2"
replace laboursupplyweekly_hu = "FORTY" if laboursupplyweekly_hu == "CATEGORY_3"
replace laboursupplyweekly_hu = "FIFTY" if laboursupplyweekly_hu == "CATEGORY_4"

* Trim outliers
if "$trim_outliers" == "true" {
	
	sum valid_y_gross_nsbc_yr_bu, d
	replace valid_y_gross_nsbc_yr_bu = . if ///
		valid_y_gross_nsbc_yr_bu < r(p1) | valid_y_gross_nsbc_yr_bu > r(p99)
		
}

* Prepare info needed for dynamic y axis labels 
qui sum year
local min_year = r(min)  
local max_year = r(max)   

forval year = `min_year'/`max_year' {

	twoway__histogram_gen valid_y_gross_nsbc_yr_bu if year == `year', ///
		bin(60) den gen(d_valid v2)

	qui sum d_valid
	gen max_d_valid_`year' = r(max) 
	
	drop d_valid v2

	foreach ls in ZERO THIRTY THIRTY_SIX FORTY FIFTY {
	
		twoway__histogram_gen valid_y_gross_nsbc_yr_bu if ///
		year == `year' & labour == "`ls'", bin(60) den gen(d_valid v2)

		qui sum d_valid
		gen max_d_valid_`year'_`ls' = r(max) 
		
		drop d_valid v2	
	
	}
	
}

drop dgn 

save "$dir_data/temp_valid_stats.dta", replace

* Prepare simulated data
use run year sim_y_gross_yr_bu laboursupplyweekly dgn hoursworkedweekly using ///
	"$dir_data/simulated_data.dta", clear

* Trim outliers
if "$trim_outliers" == "true" {
	sum sim_y_gross_yr_bu, d
	replace sim_y_gross_yr_bu = . if ///
		sim_y_gross_yr_bu < r(p1) | sim_y_gross_yr_bu > r(p99)
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
recast double hoursworkedweekly

replace laboursupplyweekly = "CATEGORY_1" if hoursworkedweekly >= 1 & ///
	hoursworkedweekly <= 35 & dgn == "Female" 
replace laboursupplyweekly = "CATEGORY_2" if hoursworkedweekly >= 36 & ///
	hoursworkedweekly <= 39 & dgn == "Female" 
replace laboursupplyweekly = "CATEGORY_3" if hoursworkedweekly >= 40 & ///
	hoursworkedweekly <= 49 & dgn == "Female"  
replace laboursupplyweekly = "CATEGORY_4" if hoursworkedweekly >= 50 & ///
	hoursworkedweekly != . & dgn == "Female"   

replace laboursupplyweekly = "THIRTY" if laboursupplyweekly == "CATEGORY_1"
replace laboursupplyweekly = "THIRTY_SIX" if ///
	laboursupplyweekly == "CATEGORY_2"
replace laboursupplyweekly = "FORTY" if laboursupplyweekly == "CATEGORY_3"
replace laboursupplyweekly = "FIFTY" if laboursupplyweekly == "CATEGORY_4"

drop dgn 

append using "$dir_data/temp_valid_stats.dta"

* Plot sub-figures 
qui sum year
local min_year = r(min)  
local max_year = r(max) 

local year = 2023

forval year = `min_year'/`max_year' {
	
	* Prepare info needed for dynamic y axis labels
	twoway__histogram_gen sim_y_gross_yr if year == `year', bin(60) ///
		den gen(d_sim v1)

	qui sum d_sim 
	gen max_d_sim = r(max)

	gen max_value = max_d_valid_`year' if max_d_valid_`year' > max_d_sim 
	replace max_value = max_d_sim if max_value == . 

	sum max_value 
	local max_y = 1.25*r(max)
	local steps = `max_y'/3	
	
	
	twoway (hist sim_y_gross_yr_bu if year == `year', bin(60) ///
		color(green%30) legend(label(1 "Simulated"))) ///
	(hist valid_y_gross_nsbc_yr_bu if year == `year', bin(60) ///
		color(red%30) legend(label(2 "Observed"))) , ///
	title("ALL hours") name(gross_inc_`year'_all, replace) ///
		xlabel(,labsize(vsmall) angle(forty_five)) ///
		ylabel(0(`steps')`max_y',labsize(vsmall)) ///
		graphregion(color(white))		

	drop d_sim v1 max_d_sim max_value
	
	
	foreach ls in ZERO THIRTY THIRTY_SIX FORTY FIFTY {
	
		* Prepare info needed for dynamic y axis labels 	
		twoway__histogram_gen sim_y_gross_yr if year == `year' & ///
			laboursupplyweekly == "`ls'", bin(60) den gen(d_sim v1)
		
		qui sum d_sim 
		gen max_d_sim = r(max)

		gen max_value = max_d_valid_`year'_`ls' if ///
			max_d_valid_`year'_`ls' > max_d_sim 
		replace max_value = max_d_sim if max_value == . 

		sum max_value 
		local max_y = 1.25*r(max)
		local steps = `max_y'/3	
	
		* Plot by weekly hours work
		twoway (hist sim_y_gross_yr_bu if year == `year' & ///
			laboursupplyweekly == "`ls'", bin(60) color(green%30) ///
			legend(label(1 "Simulated"))) ///
		(hist valid_y_gross_nsbc_yr_bu if year == `year' & ///
			laboursupplyweekly_hu == "`ls'", bin(60) color(red%30) ///
			legend(label(2 "Observed"))) , ///
			title("`ls' hours")  name(gross_inc_`year'_`ls', replace) ///
			xlabel(,labsize(vsmall) angle(forty_five)) ///
			ylabel(0(`steps')`max_y',labsize(vsmall)) ///
			graphregion(color(white)) 
		
		drop d_sim v1 max_d_sim max_value
		
	}
}

* Combine plots by year 
qui sum year
local min_year = r(min)  
local max_year = r(max) 

forvalues year = `min_year'/`max_year' {
	
	grc1leg gross_inc_`year'_all gross_inc_`year'_ZERO ///
		gross_inc_`year'_THIRTY gross_inc_`year'_THIRTY_SIX ///
		gross_inc_`year'_FORTY gross_inc_`year'_FIFTY, ///
		title("Gross income by weekly hours of work") ///
		subtitle("`year'") ///
		legendfrom(gross_inc_`year'_all) rows(2) ///
		graphregion(color(white)) ///
		note("Notes: Series represents average benefit unit gross income without benefits through time. Statistics computed by averaging benefit" "unit-level gross income those aged 18-65. Values in € per year, 2015 prices. Weekly hours worked categories:" "ZERO = 0, THIRTY = [1,35], THIRTY_SIX = [36, 39], FORTY = [40,49], FIFTY = 50+.", size(vsmall)) 

	graph export "$dir_output_files/income/gross_income/validation_${country}_gross_income_dist_`year'.png", ///
		replace width(2400) height(1350) 
		
}

graph drop _all

* Males 

* Prepare validation data 
use year dwt valid_y_gross_nsbc_yr_bu laboursupplyweekly_hu dgn using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear
	
keep if dgn == 1	
drop dgn 

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

* Trim outliers
if "$trim_outliers" == "true" {
	
	sum valid_y_gross_nsbc_yr_bu, d
	replace valid_y_gross_nsbc_yr_bu = . if ///
		valid_y_gross_nsbc_yr_bu < r(p1) | valid_y_gross_nsbc_yr_bu > r(p99)
		
}
*/

* Prepare info needed for dynamic y axis labels 
qui sum year
local min_year = r(min)  
local max_year = r(max)   

forval year = `min_year'/`max_year' {

	twoway__histogram_gen valid_y_gross_nsbc_yr_bu if year == `year', ///
		bin(60) den gen(d_valid v2)

	qui sum d_valid
	gen max_d_valid_`year' = r(max) 
	
	drop d_valid v2

	foreach ls in ZERO THIRTY THIRTY_SIX FORTY FIFTY {
	
		twoway__histogram_gen valid_y_gross_nsbc_yr_bu if ///
		year == `year' & labour == "`ls'", bin(60) den gen(d_valid v2)

		qui sum d_valid
		gen max_d_valid_`year'_`ls' = r(max) 
		
		drop d_valid v2	
	
	}
	
}

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year sim_y_gross_yr_bu laboursupplyweekly dgn using ///
	"$dir_data/simulated_data.dta", clear

keep if dgn == "Male"	
drop dgn 

* Trim outliers
if "$trim_outliers" == "true" {
	sum sim_y_gross_yr_bu, d
	replace sim_y_gross_yr_bu = . if ///
		sim_y_gross_yr_bu < r(p1) | sim_y_gross_yr_bu > r(p99)
}
*/
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
local min_year = r(min)  
local max_year = r(max) 

local year = 2023

forval year = `min_year'/`max_year' {
	
	* Prepare info needed for dynamic y axis labels
	twoway__histogram_gen sim_y_gross_yr if year == `year', bin(60) ///
		den gen(d_sim v1)

	qui sum d_sim 
	gen max_d_sim = r(max)

	gen max_value = max_d_valid_`year' if max_d_valid_`year' > max_d_sim 
	replace max_value = max_d_sim if max_value == . 

	sum max_value 
	local max_y = 1.25*r(max)
	local steps = `max_y'/3	
	
	
	twoway (hist sim_y_gross_yr_bu if year == `year', bin(60) ///
		color(green%30) legend(label(1 "Simulated"))) ///
	(hist valid_y_gross_nsbc_yr_bu if year == `year', bin(60) ///
		color(red%30) legend(label(2 "Observed"))) , ///
	title("ALL hours") name(gross_inc_`year'_all, replace) ///
		xlabel(,labsize(vsmall) angle(forty_five)) ///
		ylabel(0(`steps')`max_y',labsize(vsmall)) ///
		graphregion(color(white))		

	drop d_sim v1 max_d_sim max_value
	
	
	foreach ls in ZERO THIRTY THIRTY_SIX FORTY FIFTY {
	
		* Prepare info needed for dynamic y axis labels 	
		twoway__histogram_gen sim_y_gross_yr if year == `year' & ///
			laboursupplyweekly == "`ls'", bin(60) den gen(d_sim v1)
		
		qui sum d_sim 
		gen max_d_sim = r(max)

		gen max_value = max_d_valid_`year'_`ls' if ///
			max_d_valid_`year'_`ls' > max_d_sim 
		replace max_value = max_d_sim if max_value == . 

		sum max_value 
		local max_y = 1.25*r(max)
		local steps = `max_y'/3	
	
		* Plot by weekly hours work
		twoway (hist sim_y_gross_yr_bu if year == `year' & ///
			laboursupplyweekly == "`ls'", bin(60) color(green%30) ///
			legend(label(1 "Simulated"))) ///
		(hist valid_y_gross_nsbc_yr_bu if year == `year' & ///
			laboursupplyweekly_hu == "`ls'", bin(60) color(red%30) ///
			legend(label(2 "Observed"))) , ///
			title("`ls' hours")  name(gross_inc_`year'_`ls', replace) ///
			xlabel(,labsize(vsmall) angle(forty_five)) ///
			ylabel(0(`steps')`max_y',labsize(vsmall)) ///
			graphregion(color(white)) 
		
		drop d_sim v1 max_d_sim max_value
		
	}
}

* Combine plots by year 
qui sum year
local min_year = r(min)  
local max_year = r(max) 

forvalues year = `min_year'/`max_year' {
	
	grc1leg gross_inc_`year'_all gross_inc_`year'_ZERO ///
		gross_inc_`year'_THIRTY gross_inc_`year'_THIRTY_SIX ///
		gross_inc_`year'_FORTY gross_inc_`year'_FIFTY, ///
		title("Gross income by weekly hours of work") ///
		subtitle("`year', Males") ///
		legendfrom(gross_inc_`year'_all) rows(2) ///
		graphregion(color(white)) ///
		note("Notes: Series represents average benefit unit gross income without benefits through time. Statistics computed by averaging benefit" "unit-level gross income for all males aged 18-65. Values in € per year, 2015 prices. Weekly hours worked categories:" "ZERO = 0, THIRTY = [1,35], THIRTY_SIX = [36, 39], FORTY = [40,49], FIFTY = 50+.", size(vsmall)) 

	graph export "$dir_output_files/income/validation_${country}_gross_income_dist_`year'_male.png", ///
		replace width(2400) height(1350) 
		
}

graph drop _all



* Females 

* Prepare validation data 
use year dwt valid_y_gross_nsbc_yr_bu laboursupplyweekly_hu dgn using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear
	
keep if dgn == 0 	
drop dgn 

* Trim outliers
if "$trim_outliers" == "true" {
	
	sum valid_y_gross_nsbc_yr_bu, d
	replace valid_y_gross_nsbc_yr_bu = . if ///
		valid_y_gross_nsbc_yr_bu < r(p1) | valid_y_gross_nsbc_yr_bu > r(p99)
		
}

/*
For females:
	0 as 0 hours; // ZERO
	[1, 29] as 20 hours; // CATEGORY_1
	[30, 35] as 30 hours; // CATEGORY_2
	[36, 39] as 36 hours; // CATEGORY_3
	[40, ∞) as 40 hours. // CATEGORY_4
*/

replace laboursupplyweekly = "TWENTY" if laboursupplyweekly == "CATEGORY_1"
replace laboursupplyweekly = "THIRTY" if laboursupplyweekly == "CATEGORY_2"
replace laboursupplyweekly = "THIRTY_SIX" if laboursupplyweekly == "CATEGORY_3"
replace laboursupplyweekly = "FORTY" if laboursupplyweekly == "CATEGORY_4"


* Prepare info needed for dynamic y axis labels 
qui sum year
local min_year = r(min)  
local max_year = r(max)   

forval year = `min_year'/`max_year' {

	twoway__histogram_gen valid_y_gross_nsbc_yr_bu if year == `year', ///
		bin(60) den gen(d_valid v2)

	qui sum d_valid
	gen max_d_valid_`year' = r(max) 
	
	drop d_valid v2

	foreach ls in ZERO TWENTY THIRTY THIRTY_SIX FORTY {
	
		twoway__histogram_gen valid_y_gross_nsbc_yr_bu if ///
		year == `year' & labour == "`ls'", bin(60) den gen(d_valid v2)

		qui sum d_valid
		gen max_d_valid_`year'_`ls' = r(max) 
		
		drop d_valid v2	
	
	}
	
}

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year sim_y_gross_yr_bu laboursupplyweekly dgn using ///
	"$dir_data/simulated_data.dta", clear

keep if dgn == "Female"	
drop dgn 

* Trim outliers
if "$trim_outliers" == "true" {
	sum sim_y_gross_yr_bu, d
	replace sim_y_gross_yr_bu = . if ///
		sim_y_gross_yr_bu < r(p1) | sim_y_gross_yr_bu > r(p99)
}
*/
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
replace laboursupplyweekly = "THIRTY" if laboursupplyweekly == "CATEGORY_2"
replace laboursupplyweekly = "THIRTY_SIX" if laboursupplyweekly == "CATEGORY_3"
replace laboursupplyweekly = "FORTY" if laboursupplyweekly == "CATEGORY_4"


append using "$dir_data/temp_valid_stats.dta"

* Plot sub-figures 
qui sum year
local min_year = r(min)  
local max_year = r(max) 

local year = 2023

forval year = `min_year'/`max_year' {
	
	* Prepare info needed for dynamic y axis labels
	twoway__histogram_gen sim_y_gross_yr if year == `year', bin(60) ///
		den gen(d_sim v1)

	qui sum d_sim 
	gen max_d_sim = r(max)

	gen max_value = max_d_valid_`year' if max_d_valid_`year' > max_d_sim 
	replace max_value = max_d_sim if max_value == . 

	sum max_value 
	local max_y = 1.25*r(max)
	local steps = `max_y'/3	
	
	
	twoway (hist sim_y_gross_yr_bu if year == `year', bin(60) ///
		color(green%30) legend(label(1 "Simulated"))) ///
	(hist valid_y_gross_nsbc_yr_bu if year == `year', bin(60) ///
		color(red%30) legend(label(2 "Observed"))) , ///
	title("ALL hours") name(gross_inc_`year'_all, replace) ///
		xlabel(,labsize(vsmall) angle(forty_five)) ///
		ylabel(0(`steps')`max_y',labsize(vsmall)) ///
		graphregion(color(white))		

	drop d_sim v1 max_d_sim max_value
	
	
	foreach ls in ZERO TWENTY THIRTY THIRTY_SIX FORTY {
	
		* Prepare info needed for dynamic y axis labels 	
		twoway__histogram_gen sim_y_gross_yr if year == `year' & ///
			laboursupplyweekly == "`ls'", bin(60) den gen(d_sim v1)
		
		qui sum d_sim 
		gen max_d_sim = r(max)

		gen max_value = max_d_valid_`year'_`ls' if ///
			max_d_valid_`year'_`ls' > max_d_sim 
		replace max_value = max_d_sim if max_value == . 

		sum max_value 
		local max_y = 1.25*r(max)
		local steps = `max_y'/3	
	
		* Plot by weekly hours work
		twoway (hist sim_y_gross_yr_bu if year == `year' & ///
			laboursupplyweekly == "`ls'", bin(60) color(green%30) ///
			legend(label(1 "Simulated"))) ///
		(hist valid_y_gross_nsbc_yr_bu if year == `year' & ///
			laboursupplyweekly_hu == "`ls'", bin(60) color(red%30) ///
			legend(label(2 "Observed"))) , ///
			title("`ls' hours")  name(gross_inc_`year'_`ls', replace) ///
			xlabel(,labsize(vsmall) angle(forty_five)) ///
			ylabel(0(`steps')`max_y',labsize(vsmall)) ///
			graphregion(color(white)) 
		
		drop d_sim v1 max_d_sim max_value
		
	}
}

* Combine plots by year 
qui sum year
local min_year = r(min)  
local max_year = r(max) 

forvalues year = `min_year'/`max_year' {
	
	grc1leg gross_inc_`year'_all gross_inc_`year'_ZERO ///
		gross_inc_`year'_TWENTY gross_inc_`year'_THIRTY ///
		gross_inc_`year'_THIRTY_SIX gross_inc_`year'_FORTY, ///
		title("Gross income by weekly hours of work") ///
		subtitle("`year', Females") ///
		legendfrom(gross_inc_`year'_all) rows(2) ///
		graphregion(color(white)) ///
		note("Notes: Series represents average benefit unit gross income without benefits through time. Statistics computed by averaging benefit" "unit-level gross income for all females aged 18-65. Values in €, 2015 prices. Weekly hours worked categories:" "ZERO = 0, TWENTY = [1,29], THIRTY = [30,35], THIRTY_SIX = [36, 39]. FORTY = 40+.", size(vsmall)) 

	graph export "$dir_output_files/income/validation_${country}_gross_income_dist_`year'_female.png", ///
		replace width(2400) height(1350) 
		
}

graph drop _all



/*==============================================================================
2.1 : Histograms of individual gross income by year, and by category of weekly 
labour supply 
==============================================================================*/

* Males 

* Prepare validation data 
use year dwt valid_y_gross_nsbc_person_yr laboursupplyweekly_hu dgn using ///
		"$dir_data/${country}-eusilc_validation_sample.dta", clear

keep if dgn == 1 
drop dgn 			
	
* Trim outliers
if "$trim_outliers" == "true" {
	sum valid_y_gross_nsbc_person_yr, d
	
	replace valid_y_gross_nsbc_person_yr = . if ///
		valid_y_gross_nsbc_person_yr < r(p1) | ///
		valid_y_gross_nsbc_person_yr > r(p99)
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

	twoway__histogram_gen valid_y_gross_nsbc_person_yr if year == `year' , ///
		bin(60) den gen(d_valid v2)

	qui sum d_valid
	gen max_d_valid_`year' = r(max) 
	
	drop d_valid v2

	foreach ls in ZERO THIRTY THIRTY_SIX FORTY FIFTY {
	
		twoway__histogram_gen valid_y_gross_nsbc_person_yr if ///
		year == `year' & labour == "`ls'", bin(60) den gen(d_valid v2)

		qui sum d_valid
		gen max_d_valid_`year'_`ls' = r(max) 
		
		drop d_valid v2	
	
	}
}

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year sim_y_gross_yr laboursupplyweekly dgn using ///
	"$dir_data/simulated_data.dta", clear

keep if dgn == "Male"
drop dgn	
	
* Trim outliers
if "$trim_outliers" == "true" {
	sum sim_y_gross_yr, d
	replace sim_y_gross_yr = . if sim_y_gross_yr < r(p1) | ///
		sim_y_gross_yr > r(p99)
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
local min_year = r(min)  
local max_year = r(max) 

forval year =  `min_year'/`max_year' { 

	* Prepare info needed for dynamic y axis labels 
	twoway__histogram_gen sim_y_gross_yr if year == `year', bin(60) ///
		den gen(d_sim v1)

	qui sum d_sim 
	gen max_d_sim = r(max)

	gen max_value = max_d_valid_`year' if max_d_valid_`year' > max_d_sim 
	replace max_value = max_d_sim if max_value == . 

	sum max_value 
	local max_y = 1.25*r(max)
	local steps = `max_y'/3	
	
	* Plot all hours
	twoway (hist sim_y_gross_yr if year == `year', bin(60) color(green%30) ///
		legend(label(1 "Simulated"))) ///
	(hist valid_y_gross_nsbc_person_yr if year == `year', bin(60) ///
		color(red%30) legend(label(2 "Observed"))) , ///
	title("ALL hours") name(ind_gross_inc_`year'_all, replace) ///
		xlabel(,labsize(vsmall) angle(forty_five)) ///
		ylabel(0(`steps')`max_y', labsize(vsmall)) ///
		graphregion(color(white)) 

	
	drop d_sim v1 max_d_sim max_value
	
	
	foreach ls in ZERO THIRTY THIRTY_SIX FORTY FIFTY {
	
		* Prepare info needed for dynamic y axis labels 
		twoway__histogram_gen sim_y_gross_yr if year == `year' & ///
			laboursupplyweekly == "`ls'", bin(60) den gen(d_sim v1)

		qui sum d_sim 
		gen max_d_sim = r(max)

		gen max_value = max_d_valid_`year'_`ls' if ///
			max_d_valid_`year'_`ls' > max_d_sim 
		replace max_value = max_d_sim if max_value == . 

		sum max_value 
		local max_y = 1.25*r(max)
		local steps = `max_y'/3	
		
		* Plot by weekly hours work
		twoway (hist sim_y_gross_yr if year == `year' & ///
			laboursupplyweekly == "`ls'", bin(60) color(green%30) ///
			legend(label(1 "Simulated"))) ///
		(hist valid_y_gross_nsbc_person_yr if year == `year' & ///
			laboursupplyweekly_hu == "`ls'", bin(60) color(red%30) ///
			legend(label(2 "Observed"))) , ///
		title("`ls' hours")  name(ind_gross_inc_`year'_`ls', replace) ///
			xlabel(,labsize(vsmall) angle(forty_five)) ///
			ylabel(0(`steps')`max_y', labsize(vsmall)) ///
			graphregion(color(white)) 
		
		drop d_sim v1 max_d_sim max_value

	}
}

* Combine plots by year 
qui sum year
local min_year = r(min)  
local max_year = r(max) 

forvalues year = `min_year'/`max_year' {
	
	grc1leg ind_gross_inc_`year'_all ind_gross_inc_`year'_ZERO  ///
		ind_gross_inc_`year'_THIRTY ind_gross_inc_`year'_THIRTY_SIX ///
		ind_gross_inc_`year'_FORTY ind_gross_inc_`year'_FIFTY, ///
		title("Individual gross income by weekly hours of work") ///
		subtitle("`year', Males") ///
		legendfrom(ind_gross_inc_`year'_all) rows(2) ///
		graphregion(color(white)) ///
		note("Notes: Series represents average individual gross income without benefits through time. Statistics computed by averaging individual" "level gross income for all males aged 18-65. Values in € per year, 2015 prices. Sample trimmed. Weekly hours worked categories:" "ZERO = 0, THIRTY = [1,35], THIRTY_SIX = [36, 39], FORTY = [40,49], FIFTY = 50+.", size(vsmall)) 
			
	graph export "$dir_output_files/income/validation_${country}_ind_gross_income_dist_`year'_male.png", ///
		replace width(2400) height(1350) 
		
}
	
graph drop _all


* Females 

* Prepare validation data 
use year dwt valid_y_gross_nsbc_person_yr laboursupplyweekly_hu dgn using ///
		"$dir_data/${country}-eusilc_validation_sample.dta", clear

keep if dgn == 0
drop dgn 			
	
* Trim outliers
if "$trim_outliers" == "true" {
	sum valid_y_gross_nsbc_person_yr, d
	
	replace valid_y_gross_nsbc_person_yr = . if ///
		valid_y_gross_nsbc_person_yr < r(p1) | ///
		valid_y_gross_nsbc_person_yr > r(p99)
}

/*
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

	twoway__histogram_gen valid_y_gross_nsbc_person_yr if year == `year' , ///
		bin(60) den gen(d_valid v2)

	qui sum d_valid
	gen max_d_valid_`year' = r(max) 
	
	drop d_valid v2

	foreach ls in ZERO TWENTY THIRTY THIRTY_SIX FORTY {
	
		twoway__histogram_gen valid_y_gross_nsbc_person_yr if ///
		year == `year' & labour == "`ls'", bin(60) den gen(d_valid v2)

		qui sum d_valid
		gen max_d_valid_`year'_`ls' = r(max) 
		
		drop d_valid v2	
	
	}
}

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year sim_y_gross_yr laboursupplyweekly dgn using ///
	"$dir_data/simulated_data.dta", clear

keep if dgn == "Female"
drop dgn	
	
* Trim outliers
if "$trim_outliers" == "true" {
	sum sim_y_gross_yr, d
	replace sim_y_gross_yr = . if sim_y_gross_yr < r(p1) | ///
		sim_y_gross_yr > r(p99)
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
local min_year = r(min)  
local max_year = r(max) 

forval year = `min_year'/`max_year' { 

	* Prepare info needed for dynamic y axis labels 
	twoway__histogram_gen sim_y_gross_yr if year == `year', bin(60) ///
		den gen(d_sim v1)

	qui sum d_sim 
	gen max_d_sim = r(max)

	gen max_value = max_d_valid_`year' if max_d_valid_`year' > max_d_sim 
	replace max_value = max_d_sim if max_value == . 

	sum max_value 
	local max_y = 1.25*r(max)
	local steps = `max_y'/3	
	
	* Plot all hours
	twoway (hist sim_y_gross_yr if year == `year', bin(60) color(green%30) ///
		legend(label(1 "Simulated"))) ///
	(hist valid_y_gross_nsbc_person_yr if year == `year', bin(60) ///
		color(red%30) legend(label(2 "Observed"))) , ///
	title("ALL hours") name(ind_gross_inc_`year'_all, replace) ///
		xlabel(,labsize(vsmall) angle(forty_five)) ///
		ylabel(0(`steps')`max_y', labsize(vsmall)) ///
		graphregion(color(white)) 

	
	drop d_sim v1 max_d_sim max_value
	
	
	foreach ls in ZERO TWENTY THIRTY THIRTY_SIX FORTY {
	
		* Prepare info needed for dynamic y axis labels 
		twoway__histogram_gen sim_y_gross_yr if year == `year' & ///
			laboursupplyweekly == "`ls'", bin(60) den gen(d_sim v1)

		qui sum d_sim 
		gen max_d_sim = r(max)

		gen max_value = max_d_valid_`year'_`ls' if ///
			max_d_valid_`year'_`ls' > max_d_sim 
		replace max_value = max_d_sim if max_value == . 

		sum max_value 
		local max_y = 1.25*r(max)
		local steps = `max_y'/3	
		
		* Plot by weekly hours work
		twoway (hist sim_y_gross_yr if year == `year' & ///
			laboursupplyweekly == "`ls'", bin(60) color(green%30) ///
			legend(label(1 "Simulated"))) ///
		(hist valid_y_gross_nsbc_person_yr if year == `year' & ///
			laboursupplyweekly_hu == "`ls'", bin(60) color(red%30) ///
			legend(label(2 "Observed"))) , ///
		title("`ls' hours")  name(ind_gross_inc_`year'_`ls', replace) ///
			xlabel(,labsize(vsmall) angle(forty_five)) ///
			ylabel(0(`steps')`max_y', labsize(vsmall)) ///
			graphregion(color(white)) 
		
		drop d_sim v1 max_d_sim max_value

	}
}

* Combine plots by year 
qui sum year
local min_year = r(min)  
local max_year = r(max) 

forvalues year = `min_year'/`max_year' {
	
	grc1leg ind_gross_inc_`year'_all ind_gross_inc_`year'_ZERO  ///
		ind_gross_inc_`year'_TWENTY ind_gross_inc_`year'_THIRTY ///
		ind_gross_inc_`year'_THIRTY_SIX ind_gross_inc_`year'_FORTY, ///
		title("Individual gross income by weekly hours of work") ///
		subtitle("`year', Females") ///
		legendfrom(ind_gross_inc_`year'_all) rows(2) ///
		graphregion(color(white)) ///
		note("Notes: Series represents average individual gross income without benefits through time. Statistics computed by averaging individual" "level gross income for all females aged 18-65. Values in € per year, 2015 prices. Sample trimmed. Weekly hours worked categories:" "ZERO = 0, TWENTY = [1,29], THIRTY = [30,35], THIRTY_SIX = [36, 39]. FORTY = 40+.", size(vsmall)) 
			
	graph export "$dir_output_files/income/validation_${country}_ind_gross_income_dist_`year'_female.png", ///
		replace width(2400) height(1350) 
		
}
	
graph drop _all

/*

* Investigation into who the people are with high working hours and low gross 
* income 
/*
Note plot ben unit observations using individual level data. 

Components of gross income. 

Gross personal income components 
• PY010G - Gross employee cash or near cash employee income 
• PY050G - Gross cash benefits or losses from self-employment 
			(including royalties) 
• PY080G - Pensions received from individual private plans (other than those 
			covered under ESSPROS)
 
Plus gross income components at household level 
• HY040G - Income from rental of a property or land 
• HY080G - Regular inter-household cash transfers received 
• HY090G - Interests, dividends, profit from capital investments in 
			unincorporated business 
• HY110G - Income received by people aged under 16 
*/

* Explore 2018 FIFTY hours 
use "$dir_data/${country}-eusilc_validation_sample.dta", clear

keep if year == 2018 & laboursupplyweekly_hu == "FIFTY" 

order idperson idbenefit lhw valid_y_gross_nsbc_person_yr ///
	y_gross_labour_person valid_wage_hour ///
	py010g* py050g py080g ///
	hy080g_pc hy110g_pc hy040g_pc hy090g_pc	missing*
	
fre missing_py010g missing_py050g missing_py080g missing_hy080g ///
	missing_hy110g missing_hy040g missing_hy090g missing_lhw if ///
	valid_y_gross_nsbc_person_yr == 0 	// none missing seems to be in the data 
	
	

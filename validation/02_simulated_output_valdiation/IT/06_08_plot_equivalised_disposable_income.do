/*
This do file plots simulated and observed equivalised disposable income, per 
benefit unit

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
*/

collapse (mean) valid_y_eq_disp_yr_bu [aw = dwt], by(year)

gen l_valid_y_eq_disp_yr_bu = valid_y_eq_disp_yr_bu[_n+1]

save "$dir_data/temp_valid_stats.dta", replace

* Prepare simulated data
use run year equivalisedincome using "$dir_data/simulated_data.dta", clear


* Trim outliers
if "$trim_outliers" == "true" {
	sum equivalisedincome, d
	replace equivalisedincome = . if ///
		equivalisedincome < r(p1) | equivalisedincome > r(p99)
}
*/

collapse (mean) equivalisedincome, by(run year)
collapse (mean) equivalisedincome ///
		 (sd) equivalisedincome_sd = equivalisedincome, by(year)
		 
foreach varname in equivalisedincome {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
twoway (rarea equivalisedincome_high equivalisedincome_low year, ///
	sort color(green%20) legend(label(1 "Simulated"))) ///
(line valid_y_eq_disp_yr_bu year, sort color(green) ///
	legend(label(2 "Observed"))), ///
	title("Equivalised disposable income") xtitle("Year") ///
	ytitle("€ per year.") ///
	ylabel(,labsize(small)) xlabel(,labsize(small)) ///
	graphregion(color(white)) ///
	note("Notes: Equivalised disposable income assigned to each person computed by adjusting benefit unit's disposable income by the" "modified OECD scale. Samples includes all individuals ages 18-65. Trimmed sample. Amounts in 2015 prices.", size(vsmall))

graph export ///
"$dir_output_files/income/validation_${country}_equivalised_disposable_income_ts_${min_age}_${max_age}_both.jpg", ///
	replace width(2400) height(1350) 
	
	
* Males 

* Prepare validation data
use year dwt valid_y_eq_disp_yr_bu dgn using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

keep if dgn == 1

* Trim outliers
if "$trim_outliers" == "true" {
	sum valid_y_eq_disp_yr_bu, d
	replace valid_y_eq_disp_yr_bu = . if ///
		valid_y_eq_disp_yr_bu < r(p1) | valid_y_eq_disp_yr_bu > r(p99)
}

collapse (mean) valid_y_eq_disp_yr_bu [aw = dwt], by(year)


save "$dir_data/temp_valid_stats.dta", replace

* Prepare simulated data
use run year equivalisedincome dgn using "$dir_data/simulated_data.dta", clear

keep if dgn == "Male"

* Trim outliers
if "$trim_outliers" == "true" {
	sum equivalisedincome, d
	replace equivalisedincome = . if ///
		equivalisedincome < r(p1) | equivalisedincome > r(p99)
}

collapse (mean) equivalisedincome, by(run year)
collapse (mean) equivalisedincome ///
		 (sd) equivalisedincome_sd = equivalisedincome, by(year)
		 
foreach varname in equivalisedincome {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
twoway (rarea equivalisedincome_high equivalisedincome_low year, ///
	sort color(green%20) legend(label(1 "Simulated"))) ///
(line valid_y_eq_disp_yr_bu year, sort color(green) ///
	legend(label(2 "Observed"))), ///
	title("Equivalised disposable income") subtitle("Males") ///
	xtitle("Year") ///
	ytitle("€ per year.") ///
	ylabel(,labsize(small)) xlabel(,labsize(small)) ///
	graphregion(color(white)) ///
	note("Notes: Equivalised disposable income assigned to each person computed by adjusting benefit unit's disposable income by the" "modified OECD scale. Samples includes males ages 18-65. Trimmed sample. Amounts in 2015 prices.", size(vsmall))

graph export ///
"$dir_output_files/income/validation_${country}_equivalised_disposable_income_ts_${min_age}_${max_age}_male.jpg", ///
	replace width(2400) height(1350) 	
	
	
* Females 

* Prepare validation data
use year dwt valid_y_eq_disp_yr_bu dgn using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

keep if dgn == 0

* Trim outliers
if "$trim_outliers" == "true" {
	sum valid_y_eq_disp_yr_bu, d
	replace valid_y_eq_disp_yr_bu = . if ///
		valid_y_eq_disp_yr_bu < r(p1) | valid_y_eq_disp_yr_bu > r(p99)
}

collapse (mean) valid_y_eq_disp_yr_bu [aw = dwt], by(year)


save "$dir_data/temp_valid_stats.dta", replace

* Prepare simulated data
use run year equivalisedincome dgn using "$dir_data/simulated_data.dta", clear

keep if dgn == "Female"

* Trim outliers
if "$trim_outliers" == "true" {
	sum equivalisedincome, d
	replace equivalisedincome = . if ///
		equivalisedincome < r(p1) | equivalisedincome > r(p99)
}

collapse (mean) equivalisedincome, by(run year)
collapse (mean) equivalisedincome ///
		 (sd) equivalisedincome_sd = equivalisedincome, by(year)
		 
foreach varname in equivalisedincome {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
twoway (rarea equivalisedincome_high equivalisedincome_low year, ///
	sort color(green%20) legend(label(1 "Simulated"))) ///
(line valid_y_eq_disp_yr_bu year, sort color(green) ///
	legend(label(2 "Observed"))), ///
	title("Equivalised disposable income") subtitle("Females") ///
	xtitle("Year") ///
	ytitle("€ per year.") ///
	ylabel(,labsize(small)) xlabel(,labsize(small)) ///
	graphregion(color(white)) ///
	note("Notes: Equivalised disposable income assigned to each person computed by adjusting benefit unit's disposable income by the" "modified OECD scale. Samples includes females ages 18-65. Trimmed sample. Amounts in 2015 prices.", size(vsmall))

graph export ///
"$dir_output_files/income/validation_${country}_equivalised_disposable_income_ts_${min_age}_${max_age}_female.jpg", ///
	replace width(2400) height(1350) 		


/*==============================================================================
2 : Histograms by year, and by category of weekly labour supply 
==============================================================================*/

* Males 

* Prepare validation data
use year dwt valid_y_eq_disp_yr_bu laboursupplyweekly_hu dgn using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

keep if dgn == 1 
drop dgn 			
		
	
* Trim outliers
if "$trim_outliers" == "true" {
	sum valid_y_eq_disp_yr_bu, d
	replace valid_y_eq_disp_yr_bu = . if ///
		valid_y_eq_disp_yr_bu < r(p1) | valid_y_eq_disp_yr_bu > r(p99)
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

	twoway__histogram_gen valid_y_eq_disp_yr_bu if year == `year' , ///
		bin(60) den gen(d_valid v2)

	qui sum d_valid
	gen max_d_valid_`year' = r(max) 
	
	drop d_valid v2

	foreach ls in ZERO THIRTY THIRTY_SIX FORTY FIFTY {
	
		twoway__histogram_gen valid_y_eq_disp_yr_bu if ///
		year == `year' & labour == "`ls'", bin(60) den gen(d_valid v2)

		qui sum d_valid
		gen max_d_valid_`year'_`ls' = r(max) 
		
		drop d_valid v2	
	
	}
}

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year equivalisedincome laboursupplyweekly dgn using ///
	"$dir_data/simulated_data.dta", clear

keep if dgn == "Male"
drop dgn	
	
	
* Trim outliers
if "$trim_outliers" == "true" {
	sum equivalisedincome, d
	replace equivalisedincome = . if ///
		equivalisedincome < r(p1) | equivalisedincome > r(p99)
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

qui sum year
local min_year = r(min)  
local max_year = r(max)  

forval year = `min_year'/`max_year' {
	
    * Prepare info needed for dynamic y axis labels 
	twoway__histogram_gen equivalisedincome if year == `year', bin(60) ///
		den gen(d_sim v1)

	qui sum d_sim 
	gen max_d_sim = r(max)

	gen max_value = max_d_valid_`year' if max_d_valid_`year' > max_d_sim 
	replace max_value = max_d_sim if max_value == . 

	sum max_value 
	local max_y = 1.25*r(max)
	local steps = `max_y'/2
	
	* Plot all hours
	twoway (hist equivalisedincome if year == `year' , ///
		color(green%30) legend(label(1 "Simulated"))) ///
	(hist valid_y_eq_disp_yr_bu if year == `year' , color(red%30) ///
		legend(label(2 "Observed"))) , ///
	subtitle("ALL hours") name(eqdisp_inc_`year'_all, replace) ///
		xlabel(,labsize(vsmall) angle(forty_five)) ///
		ylabel(0(`steps')`max_y', labsize(vsmall)) ///
		graphregion(color(white))		
		
	drop d_sim v1 max_d_sim max_value	
	
	foreach ls in ZERO THIRTY THIRTY_SIX FORTY FIFTY {
	
		* Prepare info needed for dynamic y axis labels 
		twoway__histogram_gen equivalisedincome if year == `year' & ///
			laboursupplyweekly == "`ls'", bin(60) den gen(d_sim v1)

		qui sum d_sim 
		gen max_d_sim = r(max)

		gen max_value = max_d_valid_`year'_`ls' if ///
			max_d_valid_`year'_`ls' > max_d_sim 
		replace max_value = max_d_sim if max_value == . 

		sum max_value 
		local max_y = 1.25*r(max)
		local steps = `max_y'/2		
	
		twoway (hist equivalisedincome if year == `year' &  ///
			laboursupplyweekly == "`ls'", color(green%30) ///
			legend(label(1 "Simulated"))) ///
		(hist valid_y_eq_disp_yr_bu if year == `year' & ///
			laboursupplyweekly_hu == "`ls'", color(red%30) ///
			legend(label(2 "Observed"))) , ///
		subtitle("`ls' hours")  name(eqdisp_inc_`year'_`ls', replace) ///
			xlabel(,labsize(vsmall) angle(forty_five)) ///
			ylabel(0(`steps')`max_y', labsize(vsmall)) ///
			graphregion(color(white)) 
			
		drop d_sim v1 max_d_sim max_value
		
	}
}

qui sum year
local min_year = r(min)  
local max_year = r(max)  

forvalues year = `min_year'/`max_year' {
	
	grc1leg eqdisp_inc_`year'_all eqdisp_inc_`year'_ZERO ///
		eqdisp_inc_`year'_THIRTY eqdisp_inc_`year'_THIRTY_SIX ///
		eqdisp_inc_`year'_FORTY eqdisp_inc_`year'_FIFTY, ///
		title("Equivalised disposable income") ///
		subtitle("`year'") ///
		legendfrom(eqdisp_inc_`year'_all) rows(2) ///
		graphregion(color(white)) ///		
		note("Notes: Series represents average benefit unit equivalised disposable income for all persons ages 18-65. Individual observations plotted." "Values in € per year, 2015 prices. Sample trimmed. Weekly hours worked categories:" "ZERO = 0, THIRTY = [1,35], THIRTY_SIX = [36, 39], FORTY = [40,49], FIFTY = 50+", size(vsmall)) 
		
	graph export ///
 "$dir_output_files/income/validation_${country}_equivalised_disposable_inc_dist_`year'_male.png", ///
		replace width(2560) height(1440) 

}

graph drop _all 


* Females 

* Prepare validation data
use year dwt valid_y_eq_disp_yr_bu laboursupplyweekly_hu dgn using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

keep if dgn == 0 
drop dgn 			
		
	
* Trim outliers
if "$trim_outliers" == "true" {
	sum valid_y_eq_disp_yr_bu, d
	replace valid_y_eq_disp_yr_bu = . if ///
		valid_y_eq_disp_yr_bu < r(p1) | valid_y_eq_disp_yr_bu > r(p99)
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

	twoway__histogram_gen valid_y_eq_disp_yr_bu if year == `year' , ///
		bin(60) den gen(d_valid v2)

	qui sum d_valid
	gen max_d_valid_`year' = r(max) 
	
	drop d_valid v2

	foreach ls in ZERO TWENTY THIRTY THIRTY_SIX FORTY {
	
		twoway__histogram_gen valid_y_eq_disp_yr_bu if ///
		year == `year' & labour == "`ls'", bin(60) den gen(d_valid v2)

		qui sum d_valid
		gen max_d_valid_`year'_`ls' = r(max) 
		
		drop d_valid v2	
	
	}
}

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year equivalisedincome laboursupplyweekly dgn using ///
	"$dir_data/simulated_data.dta", clear

keep if dgn == "Female"
drop dgn	
	
	
* Trim outliers
if "$trim_outliers" == "true" {
	sum equivalisedincome, d
	replace equivalisedincome = . if ///
		equivalisedincome < r(p1) | equivalisedincome > r(p99)
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
replace laboursupplyweekly = "THIRTY" if ///
	laboursupplyweekly == "CATEGORY_2"
replace laboursupplyweekly = "THIRTY_SIX" if laboursupplyweekly == "CATEGORY_3"
replace laboursupplyweekly = "FORTY" if laboursupplyweekly == "CATEGORY_4"

append using "$dir_data/temp_valid_stats.dta"

qui sum year
local min_year = r(min)  
local max_year = r(max)  

forval year = `min_year'/`max_year' {
	
    * Prepare info needed for dynamic y axis labels 
	twoway__histogram_gen equivalisedincome if year == `year', bin(60) ///
		den gen(d_sim v1)

	qui sum d_sim 
	gen max_d_sim = r(max)

	gen max_value = max_d_valid_`year' if max_d_valid_`year' > max_d_sim 
	replace max_value = max_d_sim if max_value == . 

	sum max_value 
	local max_y = 1.25*r(max)
	local steps = `max_y'/2
	
	* Plot all hours
	twoway (hist equivalisedincome if year == `year' , ///
		color(green%30) legend(label(1 "Simulated"))) ///
	(hist valid_y_eq_disp_yr_bu if year == `year' , color(red%30) ///
		legend(label(2 "Observed"))) , ///
	subtitle("ALL hours") name(eqdisp_inc_`year'_all, replace) ///
		xlabel(,labsize(vsmall) angle(forty_five)) ///
		ylabel(0(`steps')`max_y', labsize(vsmall)) ///
		graphregion(color(white))		
		
	drop d_sim v1 max_d_sim max_value	
	
	foreach ls in ZERO TWENTY THIRTY THIRTY_SIX FORTY {
	
		* Prepare info needed for dynamic y axis labels 
		twoway__histogram_gen equivalisedincome if year == `year' & ///
			laboursupplyweekly == "`ls'", bin(60) den gen(d_sim v1)

		qui sum d_sim 
		gen max_d_sim = r(max)

		gen max_value = max_d_valid_`year'_`ls' if ///
			max_d_valid_`year'_`ls' > max_d_sim 
		replace max_value = max_d_sim if max_value == . 

		sum max_value 
		local max_y = 1.25*r(max)
		local steps = `max_y'/2		
	
		twoway (hist equivalisedincome if year == `year' &  ///
			laboursupplyweekly == "`ls'", color(green%30) ///
			legend(label(1 "Simulated"))) ///
		(hist valid_y_eq_disp_yr_bu if year == `year' & ///
			laboursupplyweekly_hu == "`ls'", color(red%30) ///
			legend(label(2 "Observed"))) , ///
		subtitle("`ls' hours")  name(eqdisp_inc_`year'_`ls', replace) ///
			xlabel(,labsize(vsmall) angle(forty_five)) ///
			ylabel(0(`steps')`max_y', labsize(vsmall)) ///
			graphregion(color(white)) 
			
		drop d_sim v1 max_d_sim max_value
		
	}
}

qui sum year
local min_year = r(min)  
local max_year = r(max)  

forvalues year = `min_year'/`max_year' {
	
	grc1leg eqdisp_inc_`year'_all eqdisp_inc_`year'_ZERO ///
		eqdisp_inc_`year'_TWENTY eqdisp_inc_`year'_THIRTY ///
		eqdisp_inc_`year'_THIRTY_SIX eqdisp_inc_`year'_FORTY, ///
		title("Equivalised disposable income") ///
		subtitle("`year'") ///
		legendfrom(eqdisp_inc_`year'_all) rows(2) ///
		graphregion(color(white)) ///		
		note("Notes: Series represents average benefit unit equivalised disposable income for all persons ages 18-65. Individual observations plotted" "Values in € per year, 2015 prices. Sample trimmed. Weekly hours worked categories:" "ZERO = 0, TWENTY = [1,29], THIRTY = [30,35], THIRTY_SIX = [36, 39]. FORTY = 40+.", size(vsmall)) 
		
	graph export ///
 "$dir_output_files/income/validation_${country}_equivalised_disposable_inc_dist_`year'_female.png", ///
		replace width(2560) height(1440) 

}

graph drop _all 

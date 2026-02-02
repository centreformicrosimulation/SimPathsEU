/*******************************************************************************
* PROJECT:  		SimPaths EU 
* SECTION:			Validation
* OBJECT: 			Gross income
* AUTHORS:			Patryk Bronka, Ashley Burdett 
* LAST UPDATE:		11/2025 (AB)
* COUNTRY: 			Poland 
********************************************************************************
* NOTES: 			Data details: The underlying variable is composed of 
* 					- wages
*					- self-employment eanrings/losses
* 					- private pension income 
* 					- regular inter-hh transfers
* 					- child earnings (<16)*
* 					- Income from rental property of land*
* 					- Interest, dividends, profit from capital investment*
	
* 					Underlying variable measured at the hh level and assumed to 
* 					be spread evenly among adult hh members. 
*******************************************************************************/

********************************************************************************
* 1 : Mean values over time
********************************************************************************
********************************************************************************
* 1.1 : Mean values over time - By benefit unit 
********************************************************************************

* Prepare validation data 
use year dwt valid_y_gross_bu_yr using ///
	"$dir_data/${country}-eusilc_validation_sample_long.dta", clear

* Trim outliers
if "$trim_outliers" == "true" {
	
	sum valid_y_gross_bu_yr, d
	
	replace valid_y_gross_bu_yr = . if ///
		valid_y_gross_bu_yr < r(p1) | valid_y_gross_bu_yr > r(p99)

}

collapse (mean) valid_y_gross_bu_yr [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year sim_y_gross_yr_bu laboursupplyweekly using ///
	"$dir_data/simulated_data.dta", clear

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
	(line valid_y_gross_bu_yr year, sort color(green) ///
		legend(label(2 "SILC"))), ///
	title("Gross Income") ///
	subtitle("Ages ${min_age}-${max_age}") ///
	xtitle("Year", size(small)) ///
	ytitle("€ per year", size(small)) ///
	ylabel(,labsize(small)) ///
	xlabel(,labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white)) ///
	note("Notes: Series represents average benefit unit gross income without benefits through time. Statistics computed by averaging benefit" "unit-level gross income over all persons ages ${min_age}-${max_age}. Amounts in 2015 prices. Top and bottom percentiles trimmed.", ///
	size(vsmall))

graph export ///
"$dir_output_files/income/gross_income/validation_${country}_gross_income_ts_${min_age}_${max_age}_both.jpg", ///
	replace width(2400) height(1350) quality(100)

	
********************************************************************************
* 1.2 : Mean values over time - By individual 
********************************************************************************	
********************************************************************************
* 1.2.1 : Mean values over time - By individual, All 
********************************************************************************	
	
* Prepare validation data 
use year dwt valid_y_gross_ind_yr using ///
	"$dir_data/${country}-eusilc_validation_sample_long.dta", clear

* Trim outliers
if "$trim_outliers" == "true" {
	
	sum valid_y_gross_ind_yr, d
	
	replace valid_y_gross_ind_yr = . if ///
		valid_y_gross_ind_yr < r(p1) | ///
		valid_y_gross_ind_yr > r(p99)
		
}

collapse (mean) valid_y_gross_ind_yr [aw = dwt], by(year)

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
(line valid_y_gross_ind_yr year, sort color(green) ///
	legend(label(2 "SILC"))), ///
	title("Individual Gross Income") ///
	xtitle("Year", size(small)) ///
	ytitle("€ per year", size(small)) ///
	ylabel(,labsize(small)) ///
	xlabel(,labsize(vsmall)) ///
	legend(size(small)) ///
	graphregion(color(white)) ///
	note("Notes: Series represents average individual gross income without benefits through time. Statistics computed by averaging" "person-level gross income over all persons ages ${min_age}-${max_age}. Values in 2015 prices. Top and bottom percentiles trimmed.", ///
	size(vsmall))
		
graph export ///
"$dir_output_files/income/gross_income/validation_${country}_ind_gross_income_ts_${min_age}_${max_age}_both.jpg", ///
	replace width(2400) height(1350) quality(100)

	
********************************************************************************
* 1.2.2 : Mean values over time - By individual, By gender 
********************************************************************************	
* Prepare validation data 
use year dwt valid_y_gross_ind_yr dgn using ///
	"$dir_data/${country}-eusilc_validation_sample_long.dta", clear

keep if dgn == 1	

* Trim outliers
if "$trim_outliers" == "true" {
	
	sum valid_y_gross_ind_yr, d
	
	replace valid_y_gross_ind_yr = . if ///
		valid_y_gross_ind_yr < r(p1) | ///
		valid_y_gross_ind_yr > r(p99)
		
}

collapse (mean) valid_y_gross_ind_yr [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace

* Prepare simulated data
use run year sim_y_gross_yr dgn using "$dir_data/simulated_data.dta", clear

keep if dgn == "Male"

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
(line valid_y_gross_ind_yr year, sort color(green) ///
	legend(label(2 "SILC"))), ///
	title("Individual Gross Income") ///
	subtitle("Males") ///
	xtitle("Year", size(small)) ///
	ytitle("€ per year", size(small)) ///
	ylabel(,labsize(small)) ///
	xlabel(,labsize(vsmall)) ///
	legend(size(small)) ///
	graphregion(color(white)) ///
	note("Notes: Series represents average individual gross income without benefits through time. Statistics computed by averaging" "person-level gross income over all persons ages ${min_age}-${max_age}. Values in 2015 prices. Top and bottom percentiles trimmed.", ///
	size(vsmall))
		
graph export ///
"$dir_output_files/income/gross_income/validation_${country}_ind_gross_income_ts_${min_age}_${max_age}_male.jpg", ///
	replace width(2400) height(1350) quality(100)

	
* Female 
* Prepare validation data 
use year dwt valid_y_gross_ind_yr dgn using ///
	"$dir_data/${country}-eusilc_validation_sample_long.dta", clear

keep if dgn == 0	

* Trim outliers
if "$trim_outliers" == "true" {
	
	sum valid_y_gross_ind_yr, d
	
	replace valid_y_gross_ind_yr = . if ///
		valid_y_gross_ind_yr < r(p1) | ///
		valid_y_gross_ind_yr > r(p99)
		
}

collapse (mean) valid_y_gross_ind_yr [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace

* Prepare simulated data
use run year sim_y_gross_yr dgn using "$dir_data/simulated_data.dta", clear

keep if dgn == "Female"

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
(line valid_y_gross_ind_yr year, sort color(green) ///
	legend(label(2 "SILC"))), ////
	title("Individual Gross Income") ///
	subtitle("Females") ///
	xtitle("Year", size(small)) ///
	ytitle("€ per year", size(small)) ///
	ylabel(,labsize(small)) ///
	xlabel(,labsize(vsmall)) ///
	legend(size(small)) ///
	graphregion(color(white)) ///
	note("Notes: Series represents average individual gross income without benefits through time. Statistics computed by averaging" "person-level gross income over all persons ages ${min_age}-${max_age}. Values in 2015 prices. Top and bottom percentiles trimmed.", ///
	size(vsmall))
		
graph export ///
"$dir_output_files/income/gross_income/validation_${country}_ind_gross_income_ts_${min_age}_${max_age}_female.jpg", ///
	replace width(2400) height(1350) quality(100)	
	
	
/*******************************************************************************
* 2 : Histograms 
*******************************************************************************/
	
/*******************************************************************************
* 2.1 : Histograms - Benefit unit gross income by year, and by category of  
weekly labour supply 
*******************************************************************************/

* Prepare validation data 
use year dwt valid_y_gross_bu_yr laboursupplyweekly_hu using ///
	"$dir_data/${country}-eusilc_validation_sample_long.dta", clear

* Trim outliers
if "$trim_outliers" == "true" {	
	
	sum valid_y_gross_bu_yr, d
	
	replace valid_y_gross_bu_yr = . if ///
		valid_y_gross_bu_yr < r(p1) | valid_y_gross_bu_yr > r(p99)		

}

* Prepare info needed for dynamic y axis labels 
qui sum year
local min_year = 2011
local max_year = r(max)   

forval year = `min_year'/`max_year' {

	twoway__histogram_gen valid_y_gross_bu_yr if year == `year', ///
		width(750) den gen(d_valid v2)

	qui sum d_valid
	gen max_d_valid_`year' = r(max) 
	
	drop d_valid v2

	foreach ls in $ls_cat {
	
		twoway__histogram_gen valid_y_gross_bu_yr if ///
		year == `year' & labour == "`ls'", width(750) den gen(d_valid v2)

		qui sum d_valid
		gen max_d_valid_`year'_`ls' = r(max) 
		
		drop d_valid v2	
	
	}
	
}

save "$dir_data/temp_valid_stats.dta", replace

* Prepare simulated data
use run year sim_y_gross_yr_bu laboursupplyweekly using ///
	"$dir_data/simulated_data.dta", clear

* Trim outliers
if "$trim_outliers" == "true" {
	
	sum sim_y_gross_yr_bu, d
	
	replace sim_y_gross_yr_bu = . if ///
		sim_y_gross_yr_bu < r(p1) | sim_y_gross_yr_bu > r(p99)

}

keep if run == 1

append using "$dir_data/temp_valid_stats.dta"

* Plot sub-figures 
qui sum year
local min_year = 2011 
local max_year = r(max) 

//local year = 2011

forval year = `min_year'/`max_year' {
	
	* Prepare info needed for dynamic y axis labels
	twoway__histogram_gen sim_y_gross_yr if year == `year', width(750) ///
		den gen(d_sim v1)

	qui sum d_sim 
	gen max_d_sim = r(max)

	gen max_value = max_d_valid_`year' if max_d_valid_`year' > max_d_sim 
	replace max_value = max_d_sim if max_value == . 

	sum max_value 
	local max_y = 1.25*r(max)
	local steps = `max_y'/3	
	
	
	twoway (hist sim_y_gross_yr_bu if year == `year', width(750) ///
		color(green%30) legend(label(1 "Simulated"))) ///
	(hist valid_y_gross_bu_yr if year == `year', width(750) ///
		color(red%30) legend(label(2 "SILC"))) , ///
	title("ALL hours") ///
	name(gross_inc_`year'_all, replace) ///
	xtitle("€ per year", size(small)) ///
	ytitle("", size(small)) ///	
	xlabel(,labsize(vsmall) angle(forty_five)) ///
	ylabel(0(`steps')`max_y',labsize(vsmall)) ///
	legend(size(small)) ///
	graphregion(color(white))		

	drop d_sim v1 max_d_sim max_value
	
	
	foreach ls in $ls_cat {
	
		* Prepare info needed for dynamic y axis labels 	
		twoway__histogram_gen sim_y_gross_yr if year == `year' & ///
			laboursupplyweekly == "`ls'", width(750) den gen(d_sim v1)
		
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
			laboursupplyweekly == "`ls'", width(750) color(green%30) ///
			legend(label(1 "Simulated"))) ///
		(hist valid_y_gross_bu_yr if year == `year' & ///
			laboursupplyweekly_hu == "`ls'", width(750) color(red%30) ///
			legend(label(2 "SILC"))) , ///
			title("`ls' hours")  ///
			name(gross_inc_`year'_`ls', replace) ///
			xtitle("€ per year", size(small)) ///
			ytitle("", size(small)) ///
			xlabel(,labsize(vsmall) angle(forty_five)) ///
			ylabel(0(`steps')`max_y',labsize(vsmall)) ///
			legend(size(small)) ///
			graphregion(color(white)) 
		
		drop d_sim v1 max_d_sim max_value
		
	}
}

* Combine plots by year 
qui sum year
local min_year = 2011
local max_year = r(max) 

forvalues year = `min_year'/`max_year' {
	
	grc1leg gross_inc_`year'_all gross_inc_`year'_ZERO ///
		gross_inc_`year'_TWENTY ///
		gross_inc_`year'_FORTY gross_inc_`year'_FIFTY, ///
		title("Gross Income By Weekly Hours of Work") ///
		subtitle("`year'") ///
		legendfrom(gross_inc_`year'_all) rows(2) ///
		graphregion(color(white)) ///
		note("Notes: Series represents average benefit unit gross income without benefits through time. Statistics computed by averaging benefit" "unit-level gross income for all males aged ${min_age}-${max_age}. Values in € per year, 2015 prices. Weekly hours worked categories:" "ZERO = 0, TWENTY = [1,39], FORTY = 40, FIFTY = 41+. . Top and bottom percentiles trimmed.", ///
		size(vsmall)) 

	graph export "$dir_output_files/income/gross_income/validation_${country}_gross_income_dist_`year'.png", ///
		replace width(2400) height(1350) 
		
}

graph drop _all


/*******************************************************************************
* 2.2 : Histograms - Individual gross income by year, and by category of weekly 
labour supply
*******************************************************************************/
/*******************************************************************************
* 2.2.1 : Histograms - Individual gross income by year, and by category of weekly 
labour supply, By gender
*******************************************************************************/

* Males 

* Prepare validation data 
use year dwt valid_y_gross_ind_yr laboursupplyweekly_hu dgn using ///
		"$dir_data/${country}-eusilc_validation_sample_long.dta", clear

keep if dgn == 1 
drop dgn 			
	
* Trim outliers
if "$trim_outliers" == "true" {
	
	sum valid_y_gross_ind_yr, d
	
	replace valid_y_gross_ind_yr = . if ///
		valid_y_gross_ind_yr < r(p1) | ///
		valid_y_gross_ind_yr > r(p99)
		
}


* Prepare info needed for dynamic y axis labels 
qui sum year
local min_year = 2011 
local max_year = r(max) 

forval year = `min_year'/`max_year' { 

	twoway__histogram_gen valid_y_gross_ind_yr if year == `year' , ///
		width(750) den gen(d_valid v2)

	qui sum d_valid
	gen max_d_valid_`year' = r(max) 
	
	drop d_valid v2

	foreach ls in $ls_cat {
	
		twoway__histogram_gen valid_y_gross_ind_yr if ///
		year == `year' & labour == "`ls'", width(750) den gen(d_valid v2)

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

append using "$dir_data/temp_valid_stats.dta"

* Plot sub-figures 
qui sum year
local min_year = 2011  
local max_year = r(max) 

forval year =  `min_year'/`max_year' { 

	* Prepare info needed for dynamic y axis labels 
	twoway__histogram_gen sim_y_gross_yr if year == `year', width(750) ///
		den gen(d_sim v1)

	qui sum d_sim 
	gen max_d_sim = r(max)

	gen max_value = max_d_valid_`year' if max_d_valid_`year' > max_d_sim 
	replace max_value = max_d_sim if max_value == . 

	sum max_value 
	local max_y = 1.25*r(max)
	local steps = `max_y'/3	
	
	* Plot all hours
	twoway (hist sim_y_gross_yr if year == `year', width(750) ///
		color(green%30) legend(label(1 "Simulated"))) ///
	(hist valid_y_gross_ind_yr if year == `year', width(750) ///
		color(red%30) legend(label(2 "SILC"))) , ///
		title("ALL hours") ///
		name(ind_gross_inc_`year'_all, replace) ///
		xtitle("€ per year", size(small)) ///
		ytitle("", size(small)) ///	
		xlabel(,labsize(vsmall) angle(forty_five)) ///
		ylabel(0(`steps')`max_y', labsize(vsmall)) ///
		legend(size(small)) ///
		graphregion(color(white)) 
	
	drop d_sim v1 max_d_sim max_value
		
	foreach ls in $ls_cat {
	
		* Prepare info needed for dynamic y axis labels 
		twoway__histogram_gen sim_y_gross_yr if year == `year' & ///
			laboursupplyweekly == "`ls'", width(750) den gen(d_sim v1)

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
			laboursupplyweekly == "`ls'", width(750) color(green%30) ///
			legend(label(1 "Simulated"))) ///
		(hist valid_y_gross_ind_yr if year == `year' & ///
			laboursupplyweekly_hu == "`ls'", width(750) color(red%30) ///
			legend(label(2 "SILC"))) , ///
			title("`ls' hours")  ///
			name(ind_gross_inc_`year'_`ls', replace) ///
			xtitle("€ per year", size(small)) ///
			ytitle("", size(small)) ///
			xlabel(,labsize(vsmall) angle(forty_five)) ///
			ylabel(0(`steps')`max_y', labsize(vsmall)) ///
			legend(size(small)) ///
			graphregion(color(white)) 
		
		drop d_sim v1 max_d_sim max_value

	}
}

* Combine plots by year 
qui sum year
local min_year = 2011  
local max_year = r(max) 

forvalues year = `min_year'/`max_year' {
	
	grc1leg ind_gross_inc_`year'_all ind_gross_inc_`year'_ZERO  ///
		ind_gross_inc_`year'_TWENTY ///
		ind_gross_inc_`year'_FORTY ind_gross_inc_`year'_FIFTY, ///
		title("Individual Gross Income By Weekly Hours of Work") ///
		subtitle("`year', Males") ///
		legendfrom(ind_gross_inc_`year'_all) rows(2) ///
		graphregion(color(white)) ///
		note("Notes: Series represents average individual gross income without benefits through time. Statistics computed by averaging individual" "level gross income for all males aged ${min_age}-${max_age}. Values in € per year, 2015 prices. Sample trimmed. Weekly hours worked categories:" "ZERO = 0, TWENTY = [1,39], FORTY = 40, FIFTY = 41+. Top and bottom percentiles trimmed.", ///
		size(vsmall)) 
			
	graph export "$dir_output_files/income/gross_income/validation_${country}_ind_gross_income_dist_`year'_male.png", ///
		replace width(2400) height(1350) 
		
}
	
graph drop _all


* Females 

* Prepare validation data 
use year dwt valid_y_gross_ind_yr laboursupplyweekly_hu dgn using ///
		"$dir_data/${country}-eusilc_validation_sample_long.dta", clear

keep if dgn == 0
drop dgn 			
	
* Trim outliers
if "$trim_outliers" == "true" {
	
	sum valid_y_gross_ind_yr, d
	
	replace valid_y_gross_ind_yr = . if ///
		valid_y_gross_ind_yr < r(p1) | ///
		valid_y_gross_ind_yr > r(p99)

}


* Prepare info needed for dynamic y axis labels 
qui sum year
local min_year = 2011  
local max_year = r(max) 

forval year = `min_year'/`max_year' { 

	twoway__histogram_gen valid_y_gross_ind_yr if year == `year' , ///
		width(750) den gen(d_valid v2)

	qui sum d_valid
	gen max_d_valid_`year' = r(max) 
	
	drop d_valid v2

	foreach ls in $ls_cat {
	
		twoway__histogram_gen valid_y_gross_ind_yr if ///
		year == `year' & labour == "`ls'", width(750) den gen(d_valid v2)

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


append using "$dir_data/temp_valid_stats.dta"

* Plot sub-figures 
qui sum year
local min_year = 2011  
local max_year = r(max) 

forval year = `min_year'/`max_year' { 

	* Prepare info needed for dynamic y axis labels 
	twoway__histogram_gen sim_y_gross_yr if year == `year', width(750) ///
		den gen(d_sim v1)

	qui sum d_sim 
	gen max_d_sim = r(max)

	gen max_value = max_d_valid_`year' if max_d_valid_`year' > max_d_sim 
	replace max_value = max_d_sim if max_value == . 

	sum max_value 
	local max_y = 1.25*r(max)
	local steps = `max_y'/3	
	
	* Plot all hours
	twoway (hist sim_y_gross_yr if year == `year', width(750) ///
		color(green%30) legend(label(1 "Simulated"))) ///
	(hist valid_y_gross_ind_yr if year == `year', width(750) ///
		color(red%30) legend(label(2 "SILC"))) , ///
		title("ALL hours") ///
		name(ind_gross_inc_`year'_all, replace) ///
		xtitle("€ per year", size(small)) ///
		ytitle("", size(small)) ///			
		xlabel(,labsize(vsmall) angle(forty_five)) ///
		ylabel(0(`steps')`max_y', labsize(vsmall)) ///
		legend(size(small)) ///	
		graphregion(color(white)) 
	
	drop d_sim v1 max_d_sim max_value
	
	foreach ls in $ls_cat {
	
		* Prepare info needed for dynamic y axis labels 
		twoway__histogram_gen sim_y_gross_yr if year == `year' & ///
			laboursupplyweekly == "`ls'", width(750) den gen(d_sim v1)

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
			laboursupplyweekly == "`ls'", width(750) color(green%30) ///
			legend(label(1 "Simulated"))) ///
		(hist valid_y_gross_ind_yr if year == `year' & ///
			laboursupplyweekly_hu == "`ls'", width(750) color(red%30) ///
			legend(label(2 "SILC"))) , ///
			title("`ls' hours")  ///
			name(ind_gross_inc_`year'_`ls', replace) ///
			xtitle("€ per year", size(small)) ///
			ytitle("", size(small)) ///			
			xlabel(,labsize(vsmall) angle(forty_five)) ///
			ylabel(0(`steps')`max_y', labsize(vsmall)) ///
			legend(size(small)) ///	
			graphregion(color(white)) 
		
		drop d_sim v1 max_d_sim max_value

	}
}

* Combine plots by year 
qui sum year
local min_year = 2011  
local max_year = r(max) 

forvalues year = `min_year'/`max_year' {
	
	grc1leg ind_gross_inc_`year'_all ind_gross_inc_`year'_ZERO  ///
		ind_gross_inc_`year'_TWENTY ind_gross_inc_`year'_FORTY ///
		ind_gross_inc_`year'_FIFTY, ///
		title("Individual Gross Income by Weekly Hours of Work") ///
		subtitle("`year', Females") ///
		legendfrom(ind_gross_inc_`year'_all) rows(2) ///
		graphregion(color(white)) ///
		note("Notes: Series represents average individual gross income without benefits through time. Statistics computed by averaging individual" "level gross income for all females aged ${min_age}-${max_age}. Values in € per year, 2015 prices. Sample trimmed. Weekly hours worked categories:" "ZERO = 0, TWENTY = [1,39], FORTY = 40, FIFTY = 41+. Top and bottom percentiles trimmed.", ///
		size(vsmall)) 
			
	graph export "$dir_output_files/income/gross_income/validation_${country}_ind_gross_income_dist_`year'_female.png", ///
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
use "$dir_data/${country}-eusilc_validation_sample_long.dta", clear

keep if year == 2018 & laboursupplyweekly_hu == "FIFTY" 

order idperson idbenefit lhw valid_y_gross_nsbc_person_yr ///
	y_gross_labour_person valid_wage_hour ///
	py010g* py050g py080g ///
	hy080g_pc hy110g_pc hy040g_pc hy090g_pc	missing*
	
fre missing_py010g missing_py050g missing_py080g missing_hy080g ///
	missing_hy110g missing_hy040g missing_hy090g missing_lhw if ///
	valid_y_gross_nsbc_person_yr == 0 	// none missing seems to be in the data 
	
	

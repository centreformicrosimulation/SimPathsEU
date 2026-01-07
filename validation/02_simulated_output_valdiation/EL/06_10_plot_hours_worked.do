********************************************************************************
* PROJECT:  		ESPON 
* SECTION:			Validation
* OBJECT: 			Hours worked 
* AUTHORS:			Patryk Bronka, Ashley Burdett 
* LAST UPDATE:		06/2025 (AB)
* COUNTRY: 			Greece 

* NOTES: 			Histrograms by gender restrict hours. 
********************************************************************************

********************************************************************************
* 1 : Mean values over time
********************************************************************************

* Prepare validation data
use year dwt les_c4 lhw using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

* Keep only employed individuals
keep if les_c4 == 1

collapse (mean) lhw [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year les_c4 hoursworkedweekly using ///
	"$dir_data/simulated_data.dta", clear

rename hoursworkedweekly lhw_sim

* Keep only employed individuals
keep if les_c4 == "EmployedOrSelfEmployed"

collapse (mean) lhw_sim, by(run year)
collapse (mean) lhw_sim ///
		 (sd) lhw_sim_sd = lhw_sim ///
		 , by(year)
		 
foreach varname in lhw_sim {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
twoway (rarea lhw_sim_high lhw_sim_low year, sort color(green%20) ///
	legend(label(1 "Simulated"))) ///
(line lhw year, sort color(green) legend(label(2 "Observed"))), ///
	title("Average weekly hours worked") xtitle("Year") ///
	ytitle("Hours per week") ///
	ylabel(34 [2] 44) ///
	graphregion(color(white)) ///
	note("Note: Statistics calculated on sample of employed and self-employed individuals", ///
	size(vsmall))		

* Save figure
graph export ///
"$dir_output_files/hours_worked/validation_${country}_hours_worked_ts_${min_age}_${max_age}_both.jpg", ///
	replace width(2560) height(1440) quality(100)
	
	
* Males 

* Prepare validation data
use year dwt les_c4 hours dgn using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

keep if dgn == 1	
	
* Keep only employed individuals
keep if les_c4 == 1

collapse (mean) hours [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year les_c4 hoursworkedweekly dgn  using ///
	"$dir_data/simulated_data.dta", clear

rename hoursworkedweekly lhw

keep if dgn == "Male"

* Keep only employed individuals
keep if les_c4 == "EmployedOrSelfEmployed"

collapse (mean) lhw, by(run year)
collapse (mean) lhw ///
		 (sd) lhw_sd = lhw ///
		 , by(year)
		 
foreach varname in lhw {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
twoway (rarea lhw_high lhw_low year, sort color(green%20) ///
	legend(label(1 "Simulated"))) ///
(line hours year, sort color(green) legend(label(2 "Observed"))), ///
	title("Average weekly hours worked") subtitle("Males") ///
	xtitle("Year") ytitle("Hours per week") ///
	ylabel(30 [2] 42) ///
	graphregion(color(white)) ///
	note("Note: Statistics calculated on sample of employed and self-employed individuals", ///
	size(vsmall))		

* Save figure
graph export ///
"$dir_output_files/hours_worked/validation_${country}_hours_worked_ts_${min_age}_${max_age}_male.jpg", ///
	replace width(2560) height(1440) quality(100)
		

* Females 

* Prepare validation data
use year dwt les_c4 hours dgn using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

keep if dgn == 0	
	
* Keep only employed individuals
keep if les_c4 == 1

collapse (mean) hours [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year les_c4 hoursworkedweekly dgn  using ///
	"$dir_data/simulated_data.dta", clear

rename hoursworkedweekly lhw

keep if dgn == "Female"

* Keep only employed individuals
keep if les_c4 == "EmployedOrSelfEmployed"

collapse (mean) lhw, by(run year)
collapse (mean) lhw ///
		 (sd) lhw_sd = lhw ///
		 , by(year)
		 
foreach varname in lhw {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
twoway (rarea lhw_high lhw_low year, sort color(green%20) ///
	legend(label(1 "Simulated"))) ///
(line hours year, sort color(green) legend(label(2 "Observed"))), ///
	title("Average weekly hours worked") subtitle("Females") ///
	xtitle("Year") ytitle("Hours per week") ///
	ylabel(30 [2] 46) ///
	graphregion(color(white)) ///
	note("Note: Statistics calculated on sample of employed and self-employed individuals", ///
	size(vsmall))		

* Save figure
graph export ///
"$dir_output_files/hours_worked/validation_${country}_hours_worked_ts_${min_age}_${max_age}_female.jpg", ///
	replace width(2560) height(1440) quality(100)
		

********************************************************************************
* 2 : Histograms by year
********************************************************************************

* Prepare validation data
use year dwt les_c4 hours using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

* Keep only employed individuals
keep if les_c4 == 1

* Prepare info needed for dynamic y axis labels 
qui sum year
local min_year = r(min)  
local max_year = r(max)  

forval year = `min_year'/`max_year' { 

	twoway__histogram_gen hours if year == `year' , ///
		bin(60) den gen(d_valid v2)

	qui sum d_valid
	gen max_d_valid_`year' = r(max) 
	
	drop d_valid v2

}

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run idperson year les_c4 hoursworkedweekly using ///
	"$dir_data/simulated_data.dta", clear

rename hoursworkedweekly lhw

* Keep only employed individuals
keep if les_c4 == "EmployedOrSelfEmployed"

collapse (mean) lhw, by(idperson year)

append using "$dir_data/temp_valid_stats.dta"

qui sum year
local min_year = r(min)  
local max_year = r(max)  

forval year = `min_year'/`max_year' {
	
	* Prepare info needed for dynamic y axis labels 
	twoway__histogram_gen lhw if year == `year', bin(60) ///
		den gen(d_sim v1)

	qui sum d_sim 
	gen max_d_sim = r(max)

	gen max_value = max_d_valid_`year' if max_d_valid_`year' > max_d_sim 
	replace max_value = max_d_sim if max_value == . 

	sum max_value 
	local max_y = 1.25*r(max)
	local steps = `max_y'/2
	
	twoway (hist lhw if year == `year' /*& lhw <= 65*/, width(1) color(green%20) ///
		legend(label(1 "Simulated"))) ///
	(hist hours if year == `year' /*& hours <= 65*/, width(1)  color(red%20) ///
		legend(label(2 "Observed"))), ///
	title("Weekly hours worked") ///
		subtitle("`year'") ///
		xtitle("Hours") ///
		xlabel(,labsize(small)) ///
		ylabel(0(`steps')`max_y', labsize(small)) ///
		graphregion(color(white)) ///
	note("Note: Statistics calculated on sample of employed and self-employed individuals. Observed hours unrestricted.", ///
	size(vsmall))		
		
	graph export ///
		"$dir_output_files/hours_worked/validation_${country}_hours_worked_hist_`year'_unrestricted.png", ///
		replace width(2400) height(1350) 
	
	drop d_sim v1 max_d_sim max_value
}


forval year = `min_year'/`max_year' {
	
	* Prepare info needed for dynamic y axis labels 
	twoway__histogram_gen lhw if year == `year', bin(60) ///
		den gen(d_sim v1)

	qui sum d_sim 
	gen max_d_sim = r(max)

	gen max_value = max_d_valid_`year' if max_d_valid_`year' > max_d_sim 
	replace max_value = max_d_sim if max_value == . 

	sum max_value 
	local max_y = 1.25*r(max)
	local steps = `max_y'/2
	
	twoway (hist lhw if year == `year' & lhw <= 65, width(1) color(green%20) ///
		legend(label(1 "Simulated"))) ///
	(hist hours if year == `year' & hours <= 65, width(1)  color(red%20) ///
		legend(label(2 "Observed"))), ///
	title("Weekly hours worked") ///
		subtitle("`year'") ///
		xtitle("Hours") ///
		xlabel(,labsize(small)) ///
		ylabel(0(`steps')`max_y', labsize(small)) ///
		graphregion(color(white)) ///
	note("Note: Statistics calculated on sample of employed and self-employed individuals. Hours restricted to <= 65 per week.", ///
	size(vsmall))		
		
	graph export ///
		"$dir_output_files/hours_worked/validation_${country}_hours_worked_hist_`year'.png", ///
		replace width(2400) height(1350) 
	
	drop d_sim v1 max_d_sim max_value
}


** By gender 

* Female 
* Prepare validation data
use year dwt les_c4 hours dgn using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

* Keep only employed individuals
keep if les_c4 == 1
keep if dgn == 0 

* Prepare info needed for dynamic y axis labels 
qui sum year
local min_year = r(min)  
local max_year = r(max)  

forval year = `min_year'/`max_year' { 

	twoway__histogram_gen hours if year == `year' , ///
		bin(60) den gen(d_valid v2)

	qui sum d_valid
	gen max_d_valid_`year' = r(max) 
	
	drop d_valid v2

}

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run idperson year les_c4 dgn hoursworkedweekly using ///
	"$dir_data/simulated_data.dta", clear

rename hoursworkedweekly lhw

* Keep only employed individuals
keep if les_c4 == "EmployedOrSelfEmployed"
keep if dgn == "Female"

collapse (mean) lhw, by(idperson year)

append using "$dir_data/temp_valid_stats.dta"

qui sum year
local min_year = r(min)  
local max_year = r(max)  

forval year = `min_year'/`max_year' {
	
	* Prepare info needed for dynamic y axis labels 
	twoway__histogram_gen lhw if year == `year', bin(60) ///
		den gen(d_sim v1)

	qui sum d_sim 
	gen max_d_sim = r(max)

	gen max_value = max_d_valid_`year' if max_d_valid_`year' > max_d_sim 
	replace max_value = max_d_sim if max_value == . 

	sum max_value 
	local max_y = 1.25*r(max)
	local steps = `max_y'/2
	
	twoway (hist lhw if year == `year' /*& lhw <= 65*/, width(1) ///
		color(green%20) legend(label(1 "Simulated"))) ///
	(hist hours if year == `year' /*& hours <= 65*/, width(1) color(red%20) ///
		legend(label(2 "Observed"))), ///
	title("Weekly hours worked") ///
		subtitle("`year', females") ///
		xtitle("Hours") ///
		xlabel(,labsize(small)) ///
		ylabel(0(`steps')`max_y', labsize(small)) ///
		graphregion(color(white)) ///
	note("Note: Statistics calculated on sample of employed and self-employed individuals", ///
	size(vsmall))		
		
	graph export ///
		"$dir_output_files/hours_worked/validation_${country}_hours_worked_hist_`year'_female.png", ///
		replace width(2400) height(1350) 
	
	drop d_sim v1 max_d_sim max_value
}


* Male 
* Prepare validation data
use year dwt les_c4 hours dgn using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

* Keep only employed individuals
keep if les_c4 == 1
keep if dgn == 1 

* Prepare info needed for dynamic y axis labels 
qui sum year
local min_year = r(min)  
local max_year = r(max)  

forval year = `min_year'/`max_year' { 

	twoway__histogram_gen hours if year == `year' , ///
		bin(60) den gen(d_valid v2)

	qui sum d_valid
	gen max_d_valid_`year' = r(max) 
	
	drop d_valid v2

}

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run idperson year les_c4 dgn hoursworkedweekly using ///
	"$dir_data/simulated_data.dta", clear

rename hoursworkedweekly lhw

* Keep only employed individuals
keep if les_c4 == "EmployedOrSelfEmployed"
keep if dgn == "Male"

collapse (mean) lhw, by(idperson year)

append using "$dir_data/temp_valid_stats.dta"

qui sum year
local min_year = r(min)  
local max_year = r(max)  

forval year = `min_year'/`max_year' {
	
	* Prepare info needed for dynamic y axis labels 
	twoway__histogram_gen lhw if year == `year', bin(60) ///
		den gen(d_sim v1)

	qui sum d_sim 
	gen max_d_sim = r(max)

	gen max_value = max_d_valid_`year' if max_d_valid_`year' > max_d_sim 
	replace max_value = max_d_sim if max_value == . 

	sum max_value 
	local max_y = 1.25*r(max)
	local steps = `max_y'/2
	
	twoway (hist lhw if year == `year' /*& lhw <= 65*/, width(1) ///
		color(green%20) legend(label(1 "Simulated"))) ///
	(hist hours if year == `year' /*& lhw <= 65*/, width(1) color(red%20) ///
		legend(label(2 "Observed"))), ///
	title("Weekly hours worked") ///
		subtitle("`year', males") ///
		xtitle("Hours") ///
		xlabel(,labsize(small)) ///
		ylabel(0(`steps')`max_y', labsize(small)) ///
		graphregion(color(white)) ///
	note("Note: Statistics calculated on sample of employed and self-employed individuals", ///
	size(vsmall))		
		
	graph export ///
		"$dir_output_files/hours_worked/validation_${country}_hours_worked_hist_`year'_male.png", ///
		replace width(2400) height(1350) 
	
	drop d_sim v1 max_d_sim max_value
}	
	
	
graph drop _all 	

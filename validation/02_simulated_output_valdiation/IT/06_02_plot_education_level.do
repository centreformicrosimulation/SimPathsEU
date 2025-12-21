/*
This do file plots simulated and observed education level from 2011 - 2023 in 
Polnad. 

Author: Patryk Bronka, Ashley Burdett
Last modified: March 2025 

*/


** Full population 

* Prepare  validation data
use year dwt valid_edu_high valid_edu_med valid_edu_low using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear
	
drop if valid_edu_high == 0 & valid_edu_med == 0 & valid_edu_low == 0 
	// accounts for missing values 	
	
collapse (mean) valid_edu_high valid_edu_med valid_edu_low [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace

* Prepare simulated data
use run year sim_edu_high sim_edu_med sim_edu_low using ///
	"$dir_data/simulated_data.dta", clear

collapse (mean) sim_edu_high sim_edu_med sim_edu_low, by(run year)
collapse (mean) sim_edu_high sim_edu_med sim_edu_low ///
		 (sd) sim_edu_high_sd = sim_edu_high ///
		 sim_edu_med_sd = sim_edu_med ///
		 sim_edu_low_sd = sim_edu_low ///
		 , by(year)
		 
foreach varname in sim_edu_high sim_edu_med sim_edu_low {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
twoway ///
(rarea sim_edu_high_high sim_edu_high_low year, sort color(green%20) ///
	legend(label(1 "High education, simulated"))) ///
(line valid_edu_high year, sort color(green) ///
	legend(label(2 "High education, observed"))) ///
(rarea sim_edu_med_high sim_edu_med_low year, sort color(blue%20) ///
	legend(label(3 "Medium education, simulated"))) ///
(line valid_edu_med year, sort color(blue) ///
	legend(label(4 "Medium education, observed"))) ///
(rarea sim_edu_low_high sim_edu_low_low year, sort color(red%20) ///
	legend(label(5 "Low education, simulated"))) ///
(line valid_edu_low year, sort color(red) ///
	legend(label(6 "Low education, observed"))), ///
	title("Educational attainment") subtitle("Ages ${min_age}-${max_age}") /// 
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note(Notes:, size(vsmall))
	
graph export ///
"$dir_output_files/education/validation_${country}_education_ts_${min_age}_${max_age}_both.jpg", ///
	replace width(2400) height(1350) quality(100)

	
** Among young people 

* Prepare  validation data
use year dwt valid_edu_high valid_edu_med valid_edu_low dag using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear
	
drop if dag > 30 	
	
drop if valid_edu_high == 0 & valid_edu_med == 0 & valid_edu_low == 0 
	// accounts for missing values 	
	
collapse (mean) valid_edu_high valid_edu_med valid_edu_low [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace

* Prepare simulated data
use run year sim_edu_high sim_edu_med sim_edu_low dag using ///
	"$dir_data/simulated_data.dta", clear

drop if dag > 30 	
	
collapse (mean) sim_edu_high sim_edu_med sim_edu_low, by(run year)
collapse (mean) sim_edu_high sim_edu_med sim_edu_low ///
		 (sd) sim_edu_high_sd = sim_edu_high ///
		 sim_edu_med_sd = sim_edu_med ///
		 sim_edu_low_sd = sim_edu_low ///
		 , by(year)
		 
foreach varname in sim_edu_high sim_edu_med sim_edu_low {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
twoway ///
(rarea sim_edu_high_high sim_edu_high_low year, sort color(green%20) ///
	legend(label(1 "High education, simulated"))) ///
(line valid_edu_high year, sort color(green) ///
	legend(label(2 "High education, observed"))) ///
(rarea sim_edu_med_high sim_edu_med_low year, sort color(blue%20) ///
	legend(label(3 "Medium education, simulated"))) ///
(line valid_edu_med year, sort color(blue) ///
	legend(label(4 "Medium education, observed"))) ///
(rarea sim_edu_low_high sim_edu_low_low year, sort color(red%20) ///
	legend(label(5 "Low education, simulated"))) ///
(line valid_edu_low year, sort color(red) ///
	legend(label(6 "Low education, observed"))), ///
	title("Educational attainment") subtitle("Ages ${min_age}-30") /// 
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note(Notes:, size(vsmall))
	
graph export ///
"$dir_output_files/education/validation_${country}_education_ts_${min_age}_30_both.jpg", ///
	replace width(2400) height(1350) quality(100)

	
** Among those just above retirement age 

* Prepare  validation data
use year dwt valid_edu_high valid_edu_med valid_edu_low dag using ///
	"$dir_data/${country}-eusilc_validation_full_sample.dta", clear
	
drop if dag < 66  
drop if dag > 70 	
	
drop if valid_edu_high == 0 & valid_edu_med == 0 & valid_edu_low == 0 
	// accounts for missing values 	
	
collapse (mean) valid_edu_high valid_edu_med valid_edu_low [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace

* Prepare simulated data
use run year sim_edu_high sim_edu_med sim_edu_low dag using ///
	"$dir_data/simulated_data_full.dta", clear

drop if dag < 66  
drop if dag > 70 
	
collapse (mean) sim_edu_high sim_edu_med sim_edu_low, by(run year)
collapse (mean) sim_edu_high sim_edu_med sim_edu_low ///
		 (sd) sim_edu_high_sd = sim_edu_high ///
		 sim_edu_med_sd = sim_edu_med ///
		 sim_edu_low_sd = sim_edu_low ///
		 , by(year)
		 
foreach varname in sim_edu_high sim_edu_med sim_edu_low {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
twoway ///
(rarea sim_edu_high_high sim_edu_high_low year, sort color(green%20) ///
	legend(label(1 "High education, simulated"))) ///
(line valid_edu_high year, sort color(green) ///
	legend(label(2 "High education, observed"))) ///
(rarea sim_edu_med_high sim_edu_med_low year, sort color(blue%20) ///
	legend(label(3 "Medium education, simulated"))) ///
(line valid_edu_med year, sort color(blue) ///
	legend(label(4 "Medium education, observed"))) ///
(rarea sim_edu_low_high sim_edu_low_low year, sort color(red%20) ///
	legend(label(5 "Low education, simulated"))) ///
(line valid_edu_low year, sort color(red) ///
	legend(label(6 "Low education, observed"))), ///
	title("Educational attainment") subtitle("Ages 66-70") /// 
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note(Notes:, size(vsmall))
	
graph export ///
"$dir_output_files/education/validation_${country}_education_ts_66_70_both.jpg", ///
	replace width(2400) height(1350) quality(100)	
	
	
** 60-70 

* Prepare  validation data
use year dwt valid_edu_high valid_edu_med valid_edu_low dag using ///
	"$dir_data/${country}-eusilc_validation_full_sample.dta", clear
	
drop if dag < 60  
drop if dag > 70 	
	
drop if valid_edu_high == 0 & valid_edu_med == 0 & valid_edu_low == 0 
	// accounts for missing values 	
	
collapse (mean) valid_edu_high valid_edu_med valid_edu_low [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace

* Prepare simulated data
use run year sim_edu_high sim_edu_med sim_edu_low dag using ///
	"$dir_data/simulated_data_full.dta", clear

drop if dag < 60  
drop if dag > 70 
	
collapse (mean) sim_edu_high sim_edu_med sim_edu_low, by(run year)
collapse (mean) sim_edu_high sim_edu_med sim_edu_low ///
		 (sd) sim_edu_high_sd = sim_edu_high ///
		 sim_edu_med_sd = sim_edu_med ///
		 sim_edu_low_sd = sim_edu_low ///
		 , by(year)
		 
foreach varname in sim_edu_high sim_edu_med sim_edu_low {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
twoway ///
(rarea sim_edu_high_high sim_edu_high_low year, sort color(green%20) ///
	legend(label(1 "High education, simulated"))) ///
(line valid_edu_high year, sort color(green) ///
	legend(label(2 "High education, observed"))) ///
(rarea sim_edu_med_high sim_edu_med_low year, sort color(blue%20) ///
	legend(label(3 "Medium education, simulated"))) ///
(line valid_edu_med year, sort color(blue) ///
	legend(label(4 "Medium education, observed"))) ///
(rarea sim_edu_low_high sim_edu_low_low year, sort color(red%20) ///
	legend(label(5 "Low education, simulated"))) ///
(line valid_edu_low year, sort color(red) ///
	legend(label(6 "Low education, observed"))), ///
	title("Educational attainment") subtitle("Ages 60-70") /// 
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note(Notes:, size(vsmall))
		
	
	

	
	
/*
* Among those that have left their intiial education spell 
* Prepare  validation data
use year dwt valid_edu_high valid_edu_med valid_edu_low ded using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear
	
drop if valid_edu_high == 0 & valid_edu_med == 0 & valid_edu_low == 0 
	// accounts for missing values 	
	
drop if ded == 1 	
	
collapse (mean) valid_edu_high valid_edu_med valid_edu_low [aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace

* Prepare simulated data
use run year sim_edu_high sim_edu_med sim_edu_low ded using ///
	"$dir_data/simulated_data.dta", clear
	
drop if ded == 1 	

collapse (mean) sim_edu_high sim_edu_med sim_edu_low, by(run year)
collapse (mean) sim_edu_high sim_edu_med sim_edu_low ///
		 (sd) sim_edu_high_sd = sim_edu_high ///
		 sim_edu_med_sd = sim_edu_med ///
		 sim_edu_low_sd = sim_edu_low ///
		 , by(year)
		 
foreach varname in sim_edu_high sim_edu_med sim_edu_low {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
twoway ///
(rarea sim_edu_high_high sim_edu_high_low year, sort color(green%20) ///
	legend(label(1 "High education, simulated"))) ///
(line valid_edu_high year, sort color(green) ///
	legend(label(2 "High education, observed"))) ///
(rarea sim_edu_med_high sim_edu_med_low year, sort color(blue%20) ///
	legend(label(3 "Medium education, simulated"))) ///
(line valid_edu_med year, sort color(blue) ///
	legend(label(4 "Medium education, observed"))) ///
(rarea sim_edu_low_high sim_edu_low_low year, sort color(red%20) ///
	legend(label(5 "Low education, simulated"))) ///
(line valid_edu_low year, sort color(red) ///
	legend(label(6 "Low education, observed"))) ///
, title("Educational levels,") xtitle("Year") ytitle("Share") ///
	note(Notes: Age 18-65. Sample only includes individuals that have left their initial education spell.)

graph export ///
"$dir_output_files/validation_education_level_EUSILC_age_${min_age}_${max_age}_left_int_edu.jpg", ///
	replace width(2560) height(1440) quality(100)
*/

graph drop _all 


/*
Additional plots 

- Education level of those leaving education 
- Education level of those leaving initial education spell 
- Education level of those leaving returning to education 
- Education level of those leaving the working age population 

Are these possible given we are using the x-sectional SILC? 
*/



*** Education level of those leaving education 
/*
Simulation sample only
*/

use "$dir_data/simulated_data.dta", clear

order idperson year les_c4	

sort idperson year 

gen left_edu = 1 if les_c4[_n-1] == "Student" & idperson == idperson[_n-1] & ///
	les_c4 != "Student"
  
tab left_edu 


tab deh_c3 year if left_edu == 1, col
  
	
	
	


	

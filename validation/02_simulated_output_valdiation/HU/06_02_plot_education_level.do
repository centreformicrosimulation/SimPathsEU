********************************************************************************
* PROJECT:  		ESPON 
* SECTION:			Validation
* OBJECT: 			Education
* AUTHORS:			Patryk Bronka, Ashley Burdett 
* LAST UPDATE:		06/2025 (AB)
* COUNTRY: 			Poland 

* NOTES: 			This do file plots simulated and observed education. 
* 					Unable to look at transitions because use X-sectional 
* 					SILC data. 
********************************************************************************

********************************************************************************
* 1 : Mean values over time
********************************************************************************
* Prepare  validation data
use year dwt valid_edu_high valid_edu_med valid_edu_low using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

* Get rid of observations with missing values 	
drop if valid_edu_high == 0 & valid_edu_med == 0 & valid_edu_low == 0 
	
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
	note("Notes: Not required to have left initial education spell.", ///
	size(vsmall))
	
graph export ///
"$dir_output_files/education/validation_${country}_education_ts_${min_age}_${max_age}_both.jpg", ///
	replace width(2400) height(1350) quality(100)

	
* By gender 	
* Prepare  validation data
use year dwt valid_edu_high valid_edu_med valid_edu_low dgn using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

	
* Get rid of observations with missing values 	
drop if valid_edu_high == 0 & valid_edu_med == 0 & valid_edu_low == 0 
	
collapse (mean) valid_edu_high valid_edu_med valid_edu_low [aw = dwt], ///
	by(year dgn)

save "$dir_data/temp_valid_stats.dta", replace

* Prepare simulated data
use run year sim_edu_high sim_edu_med sim_edu_low dgn using ///
	"$dir_data/simulated_data.dta", clear
	
gen dgn2 = 0 if dgn == "Female"
replace dgn2 = 1 if dgn == "Male"

drop dgn
rename dgn2 dgn 		

collapse (mean) sim_edu_high sim_edu_med sim_edu_low, by(run year dgn)
collapse (mean) sim_edu_high sim_edu_med sim_edu_low ///
		 (sd) sim_edu_high_sd = sim_edu_high ///
		 (sd) sim_edu_med_sd = sim_edu_med ///
		 (sd) sim_edu_low_sd = sim_edu_low ///	 
		 , by(year dgn )
		 
foreach varname in sim_edu_high sim_edu_med sim_edu_low {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year dgn using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure - female
twoway ///
(rarea sim_edu_high_high sim_edu_high_low year if dgn == 0, ///
	sort color(green%20) legend(label(1 "High education, simulated"))) ///
(line valid_edu_high year if dgn == 0, sort color(green) ///
	legend(label(2 "High education, observed"))) ///
(rarea sim_edu_med_high sim_edu_med_low year if dgn == 0, ///
	sort color(blue%20) legend(label(3 "Medium education, simulated"))) ///
(line valid_edu_med year if dgn == 0, sort color(blue) ///
	legend(label(4 "Medium education, observed"))) ///
(rarea sim_edu_low_high sim_edu_low_low year if dgn == 0, sort color(red%20) ///
	legend(label(5 "Low education, simulated"))) ///
(line valid_edu_low year if dgn == 0, sort color(red) ///
	legend(label(6 "Low education, observed"))), ///
	title("Educational attainment") ///
	subtitle("Ages ${min_age}-${max_age}, females") /// 
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Not required to have left initial education spell.", ///
	size(vsmall))
	
graph export ///
"$dir_output_files/education/validation_${country}_education_ts_${min_age}_${max_age}_female.jpg", ///
	replace width(2400) height(1350) quality(100)
	
* Plot figure - male	
twoway ///
(rarea sim_edu_high_high sim_edu_high_low year if dgn == 1, ///
	sort color(green%20) legend(label(1 "High education, simulated"))) ///
(line valid_edu_high year if dgn == 1, sort color(green) ///
	legend(label(2 "High education, observed"))) ///
(rarea sim_edu_med_high sim_edu_med_low year if dgn == 1, ///
	sort color(blue%20) legend(label(3 "Medium education, simulated"))) ///
(line valid_edu_med year if dgn == 1, sort color(blue) ///
	legend(label(4 "Medium education, observed"))) ///
(rarea sim_edu_low_high sim_edu_low_low year if dgn == 1, sort color(red%20) ///
	legend(label(5 "Low education, simulated"))) ///
(line valid_edu_low year if dgn == 1, sort color(red) ///
	legend(label(6 "Low education, observed"))), ///
	title("Educational attainment") ///
	subtitle("Ages ${min_age}-${max_age}, males") /// 
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Not required to have left initial education spell.", ///
	size(vsmall))
	
graph export ///
"$dir_output_files/education/validation_${country}_education_ts_${min_age}_${max_age}_male.jpg", ///
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
	note("Notes: Not required to have left initial education spell.", ///
	size(vsmall))
	
graph export ///
"$dir_output_files/education/validation_${country}_education_ts_${min_age}_30_both.jpg", ///
	replace width(2400) height(1350) quality(100)

	
* By gender 	
	
* Prepare  validation data
use year dwt valid_edu_high valid_edu_med valid_edu_low dag dgn using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear
	
drop if dag > 30 	
	
drop if valid_edu_high == 0 & valid_edu_med == 0 & valid_edu_low == 0 
	// accounts for missing values 	
	
collapse (mean) valid_edu_high valid_edu_med valid_edu_low [aw = dwt], ///
	by(year dgn)

save "$dir_data/temp_valid_stats.dta", replace

* Prepare simulated data
use run year sim_edu_high sim_edu_med sim_edu_low dag dgn using ///
	"$dir_data/simulated_data.dta", clear

drop if dag > 30 

gen dgn2 = 0 if dgn == "Female"
replace dgn2 = 1 if dgn == "Male"

drop dgn
rename dgn2 dgn 	
	
collapse (mean) sim_edu_high sim_edu_med sim_edu_low, by(run year dgn)
collapse (mean) sim_edu_high sim_edu_med sim_edu_low ///
		 (sd) sim_edu_high_sd = sim_edu_high ///
		 (sd) sim_edu_med_sd = sim_edu_med ///
		 (sd) sim_edu_low_sd = sim_edu_low ///
		 , by(year dgn)
		 
foreach varname in sim_edu_high sim_edu_med sim_edu_low {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year dgn using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure - female
twoway ///
(rarea sim_edu_high_high sim_edu_high_low year if dgn == 0, ///
	sort color(green%20) legend(label(1 "High education, simulated"))) ///
(line valid_edu_high year  if dgn == 0, sort color(green) ///
	legend(label(2 "High education, observed"))) ///
(rarea sim_edu_med_high sim_edu_med_low year if dgn == 0, ///
	sort color(blue%20) legend(label(3 "Medium education, simulated"))) ///
(line valid_edu_med year if dgn == 0, sort color(blue) ///
	legend(label(4 "Medium education, observed"))) ///
(rarea sim_edu_low_high sim_edu_low_low year if dgn == 0, sort color(red%20) ///
	legend(label(5 "Low education, simulated"))) ///
(line valid_edu_low year if dgn == 0, sort color(red) ///
	legend(label(6 "Low education, observed"))), ///
	title("Educational attainment") subtitle("Ages ${min_age}-30, females") /// 
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Not required to have left initial education spell.", ///
	size(vsmall))
	
graph export ///
"$dir_output_files/education/validation_${country}_education_ts_${min_age}_30_female.jpg", ///
	replace width(2400) height(1350) quality(100)	
	
* Plot figure - male 
twoway ///
(rarea sim_edu_high_high sim_edu_high_low year if dgn == 1, ///
	sort color(green%20) legend(label(1 "High education, simulated"))) ///
(line valid_edu_high year  if dgn == 1, sort color(green) ///
	legend(label(2 "High education, observed"))) ///
(rarea sim_edu_med_high sim_edu_med_low year if dgn == 1, ///
	sort color(blue%20) legend(label(3 "Medium education, simulated"))) ///
(line valid_edu_med year if dgn == 1, sort color(blue) ///
	legend(label(4 "Medium education, observed"))) ///
(rarea sim_edu_low_high sim_edu_low_low year if dgn == 1, sort color(red%20) ///
	legend(label(5 "Low education, simulated"))) ///
(line valid_edu_low year if dgn == 1, sort color(red) ///
	legend(label(6 "Low education, observed"))), ///
	title("Educational attainment") subtitle("Ages ${min_age}-30, females") /// 
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Not required to have left initial education spell.", ///
	size(vsmall))
	
graph export ///
"$dir_output_files/education/validation_${country}_education_ts_${min_age}_30_male.jpg", ///
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
					
	

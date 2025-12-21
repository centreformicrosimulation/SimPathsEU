/*
This do file plots Simulated and Observed health score, by age and sex

Author: Patryk Bronka
Last modified: October 2023

Simlated data doesn't contain 80-100 year olds which make up group 8. 
Adjusted the code so that runs without this group. 

*/


* Prepare validation data
use year dwt dgn ageGroup dhe using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

gen health_m = dhe if dgn == 1
gen health_f = dhe if dgn == 0

drop if ageGroup == 0 | ageGroup == 8 

collapse (mean) health* [aw = dwt], by(ageGroup year)

drop if missing(ageGroup)
reshape wide health*, i(year) j(ageGroup)

forvalues i = 1(1)7 {
	rename health_f`i' health_f_`i'_valid
	rename health_m`i' health_m_`i'_valid
}

save "$dir_data/temp_valid_stats.dta", replace


* Prepare Simulated data
use run year sim_sex ageGroup dhe using "$dir_data/simulated_data.dta", clear

gen health_m = dhe if sim_sex == 1
gen health_f = dhe if sim_sex == 2

collapse (mean) health*, by(ageGroup run year)
drop if missing(ageGroup)
reshape wide health*, i(year run) j(ageGroup)

collapse (mean) health* ///
		 (sd) health_m_1_sd = health_m1 ///
		 (sd) health_f_1_sd = health_f1 ///
		 (sd) health_m_2_sd = health_m2 ///
		 (sd) health_f_2_sd = health_f2 ///
		 (sd) health_m_3_sd = health_m3 ///
		 (sd) health_f_3_sd = health_f3 ///
		 (sd) health_m_4_sd = health_m4 ///
		 (sd) health_f_4_sd = health_f4 ///
		 (sd) health_m_5_sd = health_m5 ///
		 (sd) health_f_5_sd = health_f5 ///
		 (sd) health_m_6_sd = health_m6 ///
		 (sd) health_f_6_sd = health_f6 ///
		 (sd) health_m_7_sd = health_m7 ///
		 (sd) health_f_7_sd = health_f7 ///
		 , by(year)
		 /*(sd) health_m_8_sd = health_m8 ///
		 *(sd) health_f_8_sd = health_f8 /// */
		 
	 

forvalues i=1(1)7 {
	gen health_f_`i'_sim_high = health_f`i' + 1.96*health_f_`i'_sd
	gen health_f_`i'_sim_low = health_f`i' - 1.96*health_f_`i'_sd
	gen health_m_`i'_sim_high = health_m`i' + 1.96*health_m_`i'_sd
	gen health_m_`i'_sim_low = health_m`i' - 1.96*health_m_`i'_sd	
}
		 

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figure
foreach vble in "health_f" "health_m" {
	twoway (rarea `vble'_1_sim_high `vble'_1_sim_low year, sort ///
		color(red%20) legend(label(1 "Simulated") position(6) rows(1))) ///
		(line `vble'_1_valid year, sort legend(label(2 "Observed"))), ///
		title("age 15-19") name(`vble'_1, replace) ylabel(3 [1] 5) ///
	graphregion(color(white))
		
	twoway (rarea `vble'_2_sim_high `vble'_2_sim_low year, sort ///
		color(red%20) legend(label(1 "Simulated") position(6) rows(1))) ///
		(line `vble'_2_valid year, sort legend(label(2 "Observed"))), ///
		title("age 20-24") name(`vble'_2, replace) ylabel(3 [1] 5) ///
	graphregion(color(white))
		
	twoway (rarea `vble'_3_sim_high `vble'_3_sim_low year, sort ///
		color(red%20) legend(label(1 "Simulated") position(6) rows(1))) ///
		(line `vble'_3_valid year, sort legend(label(2 "Observed"))), ///
		title("age 25-29") name(`vble'_3, replace) ylabel(3 [1] 5) ///
	graphregion(color(white))
		
	twoway (rarea `vble'_4_sim_high `vble'_4_sim_low year, sort ///
		color(red%20) legend(label(1 "Simulated") position(6) rows(1))) ///
		(line `vble'_4_valid year, sort legend(label(2 "Observed"))), ///
		title("age 30-34") name(`vble'_4, replace) ylabel(3 [1] 5) ///
	graphregion(color(white))
		
	twoway (rarea `vble'_5_sim_high `vble'_5_sim_low year, sort ///
		color(red%20) legend(label(1 "Simulated") position(6) rows(1))) ///
		(line `vble'_5_valid year, sort legend(label(2 "Observed"))), ///
		title("age 35-39") name(`vble'_5, replace) ylabel(3 [1] 5) ///
	graphregion(color(white))
		
	twoway (rarea `vble'_6_sim_high `vble'_6_sim_low year, sort ///
		color(red%20) legend(label(1 "Simulated") position(6) rows(1))) ///
		(line `vble'_6_valid year, sort legend(label(2 "Observed"))), ///
		title("age 40-59") name(`vble'_6, replace) ylabel(3 [1] 5) ///
	graphregion(color(white))
	
	twoway (rarea `vble'_7_sim_high `vble'_7_sim_low year, sort ///
		color(red%20) legend(label(1 "Simulated") position(6) rows(1))) ///
		(line `vble'_7_valid year, sort legend(label(2 "Observed"))), ///
		title("age 60-79") name(`vble'_7, replace) ylabel(3 [1] 5) ///
	graphregion(color(white))
		
	/*twoway (rarea `vble'_8_sim_high `vble'_8_sim_low year, sort ///
		color(red%20) legend(label(1 "Simulated") position(6) rows(1))) ///
		(line `vble'_8_valid year, sort legend(label(2 "Observed"))), ///
		title("age 80-100") name(`vble'_8, replace) ylabel(1 [1] 5)*/
}

* Save figures
grc1leg health_f_1 health_f_2 health_f_3 health_f_4 health_f_5 ///
	health_f_6 health_f_7 /*health_f_8*/, ///
	title("Average health score by age") ///
	subtitle("Females") ///
	legendfrom(health_f_1) ///
	graphregion(color(white)) ///
	note("Notes: ", size(vsmall))
	
graph export ///
	"$dir_output_files/health/validation_${country}_health_ts_all_female.jpg", ///
	replace width(2400) height(1350) quality(100)
		

grc1leg health_m_1 health_m_2 health_m_3 health_m_4 health_m_5 ///
	health_m_6 health_m_7 /*health_m_8*/, ///
	title("Average health score by age") ///
	subtitle("Males") ///
	legendfrom(health_m_1) ///
	graphregion(color(white)) ///
	note("Notes: ", size(vsmall))
	
graph export ///
	"$dir_output_files/health/validation_${country}_health_ts_all_male.jpg", ///
	replace width(2400) height(1350) quality(100)
	
graph drop _all 	


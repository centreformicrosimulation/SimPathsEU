/*
This do file plots simulated and observed activity status, by age

Author: Patryk Bronka
Last modified: October 2023


No ageGroup == 8 in the simulated data (80-100). 
Code adjusted to account for this. 
*/

* Prepare validation data
use year dwt dgn ageGroup valid_student valid_employed using ///
	"$dir_data/${country}-eusilc_validation_sample.dta", clear

gen student = valid_student
gen employed_f = (valid_employed) if dgn == 0
gen employed_m = (valid_employed) if dgn == 1

drop if ageGroup == 0 | ageGroup == 8  

collapse (mean) student employed_f employed_m [aweight=dwt], ///
	by(ageGroup year)
drop if missing(ageGroup)
reshape wide student employed_f employed_m, i(year) j(ageGroup)

forvalues i = 1(1)7 {
	rename student`i' student_`i'_valid
	rename employed_f`i' employed_f_`i'_valid
	rename employed_m`i' employed_m_`i'_valid
}

save "$dir_data/temp_valid_stats.dta", replace


* Prepare simulated data
use run year sim_sex ageGroup sim_student sim_employed using ///
	"$dir_data/simulated_data.dta", clear

gen student = sim_student
gen employed_f = (sim_employed) if sim_sex == 2
gen employed_m = (sim_employed) if sim_sex == 1

collapse (mean) student employed_f employed_m, by(ageGroup run year)
drop if missing(ageGroup)
reshape wide student employed_f employed_m, i(year run) j(ageGroup)

forvalues i=1(1)7{
	rename student`i' student_`i'_sim
	rename employed_f`i' employed_f_`i'_sim
	rename employed_m`i' employed_m_`i'_sim
}

collapse (mean) student* employed* ///
	(sd) sd_student_1_sim=student_1_sim ///
		 sd_student_2_sim=student_2_sim ///
		 sd_student_3_sim=student_3_sim ///
	     sd_student_4_sim=student_4_sim ///
		 sd_student_5_sim=student_5_sim ///
		 sd_student_6_sim=student_6_sim ///
		 sd_student_7_sim=student_7_sim ///
		 sd_employed_f_1_sim=employed_f_1_sim ///
		 sd_employed_f_2_sim=employed_f_2_sim ///
		 sd_employed_f_3_sim=employed_f_3_sim ///
		 sd_employed_f_4_sim=employed_f_4_sim ///
		 sd_employed_f_5_sim=employed_f_5_sim ///
		 sd_employed_f_6_sim=employed_f_6_sim ///
		 sd_employed_f_7_sim=employed_f_7_sim ///
		 sd_employed_m_1_sim=employed_m_1_sim ///
		 sd_employed_m_2_sim=employed_m_2_sim ///
		 sd_employed_m_3_sim=employed_m_3_sim ///
		 sd_employed_m_4_sim=employed_m_4_sim ///
		 sd_employed_m_5_sim=employed_m_5_sim ///
		 sd_employed_m_6_sim=employed_m_6_sim ///
		 sd_employed_m_7_sim=employed_m_7_sim ///
		 , by(year)
		 
		 /* sd_student_8_sim=student_8_sim ///
		 sd_employed_f_8_sim=employed_f_8_sim ///
		 sd_employed_m_8_sim=employed_m_8_sim /// */

forvalues i=1(1)7 {
	gen student_`i'_sim_high = student_`i'_sim + 1.96*sd_student_`i'_sim
	gen student_`i'_sim_low = student_`i'_sim - 1.96*sd_student_`i'_sim
	gen employed_f_`i'_sim_high = employed_f_`i'_sim + 1.96*sd_employed_f_`i'_sim
	gen employed_f_`i'_sim_low = employed_f_`i'_sim - 1.96*sd_employed_f_`i'_sim
	gen employed_m_`i'_sim_high = employed_m_`i'_sim + 1.96*sd_employed_m_`i'_sim
	gen employed_m_`i'_sim_low = employed_m_`i'_sim - 1.96*sd_employed_m_`i'_sim	
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figures
foreach vble in "student" "employed_f" "employed_m" {
	
	twoway (rarea `vble'_1_sim_high `vble'_1_sim_low year, ///
		sort color(red%20) legend(label(1 "Simulated") position(6) rows(1))) ///
		(line `vble'_1_valid year, sort legend(label(2 "Observed"))), ///
		title("age 15-19") name(`vble'_1, replace) ylabel(0 [0.5] 1) ///
	graphregion(color(white)) xtitle("")
	
	twoway (rarea `vble'_2_sim_high `vble'_2_sim_low year, ///
		sort color(red%20) legend(label(1 "Simulated") position(6) rows(1))) ///
		(line `vble'_2_valid year, sort legend(label(2 "Observed"))), ///
		title("age 20-24") name(`vble'_2, replace) ylabel(0 [0.5] 1) ///
	graphregion(color(white)) xtitle("")
	
	twoway (rarea `vble'_3_sim_high `vble'_3_sim_low year, ///
		sort color(red%20) legend(label(1 "Simulated") position(6) rows(1))) ///
		(line `vble'_3_valid year, sort legend(label(2 "Observed"))), ///
		title("age 25-29") name(`vble'_3, replace) ylabel(0 [0.5] 1) ///
	graphregion(color(white)) xtitle("") 
	
	twoway (rarea `vble'_4_sim_high `vble'_4_sim_low year, ///
		sort color(red%20) legend(label(1 "Simulated") position(6) rows(1))) ///
		(line `vble'_4_valid year, sort legend(label(2 "Observed"))), ///
		title("age 30-34") name(`vble'_4, replace) ylabel(0 [0.5] 1) ///
	graphregion(color(white)) xtitle("")
	
	twoway (rarea `vble'_5_sim_high `vble'_5_sim_low year, ///
		sort color(red%20) legend(label(1 "Simulated") position(6) rows(1))) ///
		(line `vble'_5_valid year, sort legend(label(2 "Observed"))), ///
		title("age 35-39") name(`vble'_5, replace) ylabel(0 [0.5] 1) ///
	graphregion(color(white)) xtitle("")
	
	twoway (rarea `vble'_6_sim_high `vble'_6_sim_low year, ///
		sort color(red%20) legend(label(1 "Simulated") position(6) ///
		rows(1)))(line `vble'_6_valid year, sort ///
		legend(label(2 "observed"))), ///
		title("age 40-59") name(`vble'_6, replace) ylabel(0 [0.5] 1) ///
	graphregion(color(white)) xtitle("")
	
	twoway (rarea `vble'_7_sim_high `vble'_7_sim_low year, ///
		sort color(red%20) legend(label(1 "Simulated") position(6) rows(1))) ///
		(line `vble'_7_valid year, sort legend(label(2 "Observed"))), ///
		title("age 60-79") name(`vble'_7, replace) ylabel(0 [0.5] 1) ///
	graphregion(color(white)) xtitle("")
	
	/*twoway (rarea `vble'_8_sim_high `vble'_8_sim_low year, sort color(red%20) legend(label(1 "simulated") position(6) rows(1)))(line `vble'_8_valid year, sort legend(label(2 "observed"))), title("age 80-100") name(`vble'_8, replace) ylabel(0 [0.5] 1)*/
}


* Save figures

* Share students
grc1leg student_1 student_2 student_3 student_4 student_5 student_6 ///
	student_7 , title("Share of students by age") legendfrom(student_1) ///
	graphregion(color(white)) ///
	note("Notes: ", size(vsmall))
	
graph export ///
"$dir_output_files/economic_activity/validation_${country}_students_ts_all_both.jpg", ///
	replace width(2400) height(1350) quality(100)
	
	
* Share employed women
grc1leg employed_f_1 employed_f_2 employed_f_3 employed_f_4 employed_f_5 ///
	employed_f_6 employed_f_7 , title("Employment rate by age") ///
	subtitle("Females") ///
	legendfrom(employed_f_1) ///
	graphregion(color(white)) ///
	note("Notes: ", size(vsmall))

graph export ///
"$dir_output_files/economic_activity/validation_${country}_employed_ts_all_female.jpg", ///
	replace width(2400) height(1350) quality(100)

	
* Share employed men 	
grc1leg employed_m_1 employed_m_2 employed_m_3 employed_m_4 employed_m_5 ///
	employed_m_6 employed_m_7 , title("Employment rate by age") ///
	subtitle("Males") ///
	legendfrom(employed_m_1) ///
	graphregion(color(white)) ///
	note("Notes: ", size(vsmall))

	
graph export ///
"$dir_output_files/economic_activity/validation_${country}_employed_ts_all_male.jpg", ///
	replace width(2400) height(1350) quality(100)

	
graph drop _all 	

/*
This do file plots validation graphs for economics activity status (4 cat). 

Author: Patryk Bronka, Ashley Burdett
Last modified: March 2025

*/


*** Status time series 

** Young people 

* Prepare validation data
use year dwt valid_employed valid_student valid_inactive dag  ///
	valid_retired using "$dir_data/${country}-eusilc_validation_sample.dta", ///
	clear
	
drop if dag > 30 	
	
collapse (mean) valid_employed valid_student valid_inactive valid_retired ///
	[aw = dwt], by(year)

save "$dir_data/temp_valid_stats.dta", replace

* Prepare simulated data
use run year sim_employed sim_student sim_inactive sim_retired dag using ///
	"$dir_data/simulated_data.dta", clear

drop if dag > 30 
	
collapse (mean) sim_employed sim_student sim_inactive sim_retired, ///
	by(run year)
collapse (mean) sim_employed sim_student sim_inactive sim_retired ///
		 (sd) sim_employed_sd = sim_employed ///
		 sim_student_sd = sim_student ///
		 sim_inactive_sd = sim_inactive ///
		 sim_retired_sd = sim_retired ///
		 , by(year)
		 
foreach varname in sim_employed sim_student sim_inactive sim_retired {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen


collapse (mean) sim* valid*, by(year)

* Plot figure 
twoway ///
(rarea sim_employed_high sim_employed_low year, sort color(green%20) ///
	legend(label(1 "Employed, simulated"))) ///
(line valid_employed year, sort color(green) ///
	legend(label(2 "Employed, observed"))) ///
(rarea sim_student_high sim_student_low year, sort color(blue%20) ///
	legend(label(3 "Students, simulated"))) ///
(line valid_student year, sort color(blue) ///
	legend(label(4 "Students, observed"))) ///
(rarea sim_inactive_high sim_inactive_low year, sort color(red%20) ///
	legend(label(5 "Non-employed, simulated"))) ///
(line valid_inactive year, sort color(red) ///
	legend(label(6 "Non-employed, observed"))) ///
(rarea sim_retired_high sim_retired_low year, sort color(grey%20) ///
	legend(label(7 "Retired, simulated"))) ///
(line valid_retired year, sort color(grey) ///
	legend(label(8 "Retired, observed"))), ///
	title("Activity status") subtitle("Ages ${min_age}-30") ///
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", size(vsmall))

* Save figure
graph export ///
	"$dir_output_files/economic_activity/validation_${country}_activity_status_ts_${min_age}_30_both.jpg", ///
	replace width(2400) height(1350) quality(100)


** Working age 

* Prepare validation data
use year dwt valid_employed valid_student valid_inactive dgn ///
	valid_retired using "$dir_data/${country}-eusilc_validation_sample.dta", ///
	clear
	
collapse (mean) valid_employed valid_student valid_inactive valid_retired ///
	[aw = dwt], by(year dgn)

save "$dir_data/temp_valid_stats.dta", replace

* Prepare simulated data
use run year sim_employed sim_student sim_inactive sim_retired dgn using ///
	"$dir_data/simulated_data.dta", clear

gen dgn_coded = .
replace dgn_coded = 1 if dgn == "Male"
replace dgn_coded = 0 if dgn == "Female"

drop dgn
rename dgn_coded dgn	
	
collapse (mean) sim_employed sim_student sim_inactive sim_retired, ///
	by(run year dgn)
collapse (mean) sim_employed sim_student sim_inactive sim_retired ///
		 (sd) sim_employed_sd = sim_employed ///
		 sim_student_sd = sim_student ///
		 sim_inactive_sd = sim_inactive ///
		 sim_retired_sd = sim_retired ///
		 , by(year dgn)
		 
foreach varname in sim_employed sim_student sim_inactive sim_retired {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year dgn using "$dir_data/temp_valid_stats.dta", keep(3) nogen


** All 

preserve

collapse (mean) sim* valid*, by(year)

* Plot figure 
twoway ///
(rarea sim_employed_high sim_employed_low year, sort color(green%20) ///
	legend(label(1 "Employed, simulated"))) ///
(line valid_employed year, sort color(green) ///
	legend(label(2 "Employed, observed"))) ///
(rarea sim_student_high sim_student_low year, sort color(blue%20) ///
	legend(label(3 "Students, simulated"))) ///
(line valid_student year, sort color(blue) ///
	legend(label(4 "Students, observed"))) ///
(rarea sim_inactive_high sim_inactive_low year, sort color(red%20) ///
	legend(label(5 "Non-employed, simulated"))) ///
(line valid_inactive year, sort color(red) ///
	legend(label(6 "Non-employed, observed"))) ///
(rarea sim_retired_high sim_retired_low year, sort color(grey%20) ///
	legend(label(7 "Retired, simulated"))) ///
(line valid_retired year, sort color(grey) ///
	legend(label(8 "Retired, observed"))), ///
	title("Activity status") subtitle("Ages ${min_age}-${max_age}") ///
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", size(vsmall))

* Save figure
graph export ///
	"$dir_output_files/economic_activity/validation_${country}_activity_status_ts_${min_age}_${max_age}_both.jpg", ///
	replace width(2400) height(1350) quality(100)

restore, preserve


	
** Males 

keep if dgn == 1 

* Plot figure 
twoway ///
(rarea sim_employed_high sim_employed_low year, sort color(green%20) ///
	legend(label(1 "Employed, simulated"))) ///
(line valid_employed year, sort color(green) ///
	legend(label(2 "Employed, observed"))) ///
(rarea sim_student_high sim_student_low year, sort color(blue%20) ///
	legend(label(3 "Students, simulated"))) ///
(line valid_student year, sort color(blue) ///
	legend(label(4 "Students, observed"))) ///
(rarea sim_inactive_high sim_inactive_low year, sort color(red%20) ///
	legend(label(5 "Non-employed, simulated"))) ///
(line valid_inactive year, sort color(red) ///
	legend(label(6 "Non-employed, observed"))) ///
(rarea sim_retired_high sim_retired_low year, sort color(grey%20) ///
	legend(label(7 "Retired, simulated"))) ///
(line valid_retired year, sort color(grey) ///
	legend(label(8 "Retired, observed"))), ///
	title("Activity status") subtitle("Ages ${min_age}-${max_age}, males") ///
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", size(vsmall))
	
* Save figure
graph export ///
	"$dir_output_files/economic_activity/validation_${country}_activity_status_ts_${min_age}_${max_age}_male.jpg", ///
	replace width(2400) height(1350) quality(100)


restore, preserve

	
** Females 

keep if dgn == 0 

* Plot figure 
twoway ///
(rarea sim_employed_high sim_employed_low year, sort color(green%20) ///
	legend(label(1 "Employed, simulated"))) ///
(line valid_employed year, sort color(green) ///
	legend(label(2 "Employed, observed"))) ///
(rarea sim_student_high sim_student_low year, sort color(blue%20) ///
	legend(label(3 "Students, simulated"))) ///
(line valid_student year, sort color(blue) ///
	legend(label(4 "Students, observed"))) ///
(rarea sim_inactive_high sim_inactive_low year, sort color(red%20) ///
	legend(label(5 "Non-employed, simulated"))) ///
(line valid_inactive year, sort color(red) ///
	legend(label(6 "Non-employed, observed"))) ///
(rarea sim_retired_high sim_retired_low year, sort color(grey%20) ///
	legend(label(7 "Retired, simulated"))) ///
(line valid_retired year, sort color(grey) ///
	legend(label(8 "Retired, observed"))), ///
	title("Activity status") subtitle("Ages ${min_age}-${max_age}, females") /// 
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", size(vsmall))
	
* Save figure
graph export ///
"$dir_output_files/economic_activity/validation_${country}_activity_status_ts_${min_age}_${max_age}_female.jpg", ///
	replace width(2400) height(1350) quality(100)
	
restore 	
	
	
** Females ages 18-60 (before state pension age)

* Prepare validation data
use year dwt valid_employed valid_student valid_inactive dgn dag ///
	valid_retired using "$dir_data/${country}-eusilc_validation_sample.dta", ///
	clear
	
drop if dag > 60	
	
collapse (mean) valid_employed valid_student valid_inactive valid_retired ///
	[aw = dwt], by(year dgn)

save "$dir_data/temp_valid_stats.dta", replace

* Prepare simulated data
use run year sim_employed sim_student sim_inactive sim_retired dgn dag using ///
	"$dir_data/simulated_data.dta", clear
	
drop if dag > 60

gen dgn_coded = .
replace dgn_coded = 1 if dgn == "Male"
replace dgn_coded = 0 if dgn == "Female"

drop dgn
rename dgn_coded dgn	
	
collapse (mean) sim_employed sim_student sim_inactive sim_retired, ///
	by(run year dgn)
collapse (mean) sim_employed sim_student sim_inactive sim_retired ///
		 (sd) sim_employed_sd = sim_employed ///
		 sim_student_sd = sim_student ///
		 sim_inactive_sd = sim_inactive ///
		 sim_retired_sd = sim_retired ///
		 , by(year dgn)
		 
foreach varname in sim_employed sim_student sim_inactive sim_retired {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year dgn using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Females 
keep if dgn == 0

* Plot figure 
twoway ///
(rarea sim_employed_high sim_employed_low year, sort color(green%20) ///
	legend(label(1 "Employed, simulated"))) ///
(line valid_employed year, sort color(green) ///
	legend(label(2 "Employed, observed"))) ///
(rarea sim_student_high sim_student_low year, sort color(blue%20) ///
	legend(label(3 "Students, simulated"))) ///
(line valid_student year, sort color(blue) ///
	legend(label(4 "Students, observed"))) ///
(rarea sim_inactive_high sim_inactive_low year, sort color(red%20) ///
	legend(label(5 "Non-employed, simulated"))) ///
(line valid_inactive year, sort color(red) ///
	legend(label(6 "Non-employed, observed"))) ///
(rarea sim_retired_high sim_retired_low year, sort color(grey%20) ///
	legend(label(7 "Retired, simulated"))) ///
(line valid_retired year, sort color(grey) ///
	legend(label(8 "Retired, observed"))), ///
	title("Activity status") subtitle("Ages ${min_age}-60") ///
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", size(vsmall))

* Save figure
graph export ///
"$dir_output_files/economic_activity/validation_${country}_activity_status_ts_${min_age}_60_female.jpg", ///
	replace width(2400) height(1350) quality(100)

	
** All ages

* Prepare validation data
use year dwt valid_employed valid_student valid_inactive dgn ///
	valid_retired using ///
	"$dir_data/${country}-eusilc_validation_full_sample.dta", ///
	clear
		
collapse (mean) valid_employed valid_student valid_inactive valid_retired ///
	[aw = dwt], by(year dgn)

save "$dir_data/temp_valid_stats.dta", replace

* Prepare simulated data
use run year sim_employed sim_student sim_inactive sim_retired dgn using ///
	"$dir_data/simulated_data_full.dta", clear

gen dgn_coded = .
replace dgn_coded = 1 if dgn == "Male"
replace dgn_coded = 0 if dgn == "Female"

drop dgn
rename dgn_coded dgn	
	
collapse (mean) sim_employed sim_student sim_inactive sim_retired, ///
	by(run year dgn)
	
collapse (mean) sim_employed sim_student sim_inactive sim_retired ///
		 (sd) sim_employed_sd = sim_employed ///
		 sim_student_sd = sim_student ///
		 sim_inactive_sd = sim_inactive ///
		 sim_retired_sd = sim_retired ///
		 , by(year dgn)
		 
foreach varname in sim_employed sim_student sim_inactive sim_retired {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year dgn using "$dir_data/temp_valid_stats.dta", keep(3) nogen
 
** All  
 
preserve

collapse (mean) sim* valid*, by(year)

* Plot figure 
twoway ///
(rarea sim_employed_high sim_employed_low year, sort color(green%20) ///
	legend(label(1 "Employed, simulated"))) ///
(line valid_employed year, sort color(green) ///
	legend(label(2 "Employed, observed"))) ///
(rarea sim_student_high sim_student_low year, sort color(blue%20) ///
	legend(label(3 "Students, simulated"))) ///
(line valid_student year, sort color(blue) ///
	legend(label(4 "Students, observed"))) ///
(rarea sim_inactive_high sim_inactive_low year, sort color(red%20) ///
	legend(label(5 "Non-employed, simulated"))) ///
(line valid_inactive year, sort color(red) ///
	legend(label(6 "Non-employed, observed"))) ///
(rarea sim_retired_high sim_retired_low year, sort color(grey%20) ///
	legend(label(7 "Retired, simulated"))) ///
(line valid_retired year, sort color(grey) ///
	legend(label(8 "Retired, observed"))), ///
	title("Activity status") subtitle("All ages") ///
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", size(vsmall))

* Save figure
graph export ///
"$dir_output_files/economic_activity/validation_${country}_activity_status_ts_all_both.jpg", ///
	replace width(2400) height(1350) quality(100) 	
	
restore, preserve

	
** Males 

keep if dgn == 1 

* Plot figure 
twoway ///
(rarea sim_employed_high sim_employed_low year, sort color(green%20) ///
	legend(label(1 "Employed, simulated"))) ///
(line valid_employed year, sort color(green) ///
	legend(label(2 "Employed, observed"))) ///
(rarea sim_student_high sim_student_low year, sort color(blue%20) ///
	legend(label(3 "Students, simulated"))) ///
(line valid_student year, sort color(blue) ///
	legend(label(4 "Students, observed"))) ///
(rarea sim_inactive_high sim_inactive_low year, sort color(red%20) ///
	legend(label(5 "Non-employed, simulated"))) ///
(line valid_inactive year, sort color(red) ///
	legend(label(6 "Non-employed, observed"))) ///
(rarea sim_retired_high sim_retired_low year, sort color(grey%20) ///
	legend(label(7 "Retired, simulated"))) ///
(line valid_retired year, sort color(grey) ///
	legend(label(8 "Retired, observed"))), ///
	title("Activity status") subtitle("All ages, males") /// 
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", size(vsmall))

* Save figure
graph export ///
"$dir_output_files/economic_activity/validation_${country}_activity_status_ts_all_male.jpg", ///
	replace width(2400) height(1350) quality(100)


restore, preserve

	
** Females 

keep if dgn == 0 

* Plot figure 
twoway ///
(rarea sim_employed_high sim_employed_low year, sort color(green%20) ///
	legend(label(1 "Employed, simulated"))) ///
(line valid_employed year, sort color(green) ///
	legend(label(2 "Employed, observed"))) ///
(rarea sim_student_high sim_student_low year, sort color(blue%20) ///
	legend(label(3 "Students, simulated"))) ///
(line valid_student year, sort color(blue) ///
	legend(label(4 "Students, observed"))) ///
(rarea sim_inactive_high sim_inactive_low year, sort color(red%20) ///
	legend(label(5 "Non-employed, simulated"))) ///
(line valid_inactive year, sort color(red) ///
	legend(label(6 "Non-employed, observed"))) ///
(rarea sim_retired_high sim_retired_low year, sort color(grey%20) ///
	legend(label(7 "Retired, simulated"))) ///
(line valid_retired year, sort color(grey) ///
	legend(label(8 "Retired, observed"))), ///
	title("Activity status") subtitle("All ages, females") ///
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", size(vsmall))

* Save figure
graph export ///
"$dir_output_files/economic_activity/validation_${country}_activity_status_ts_all_female.jpg", ///
	replace width(2400) height(1350) quality(100)
	
restore 

graph drop _all 	



*** Partnership status 

* Prepare validation data
use year dwt valid_employed valid_student valid_inactive valid_retired dcpst ///
	dgn using "$dir_data/${country}-eusilc_validation_sample.dta", clear
	
collapse (mean) valid_employed valid_student valid_inactive valid_retired ///
	[aw = dwt], by(year dcpst dgn)

save "$dir_data/temp_valid_stats.dta", replace

* Prepare simulated data
use run year sim_employed sim_student sim_inactive sim_retired dcpst dgn ///
	using "$dir_data/simulated_data.dta", clear

gen dcpst_coded = .
replace dcpst_coded = 1 if dcpst == "Partnered"
replace dcpst_coded = 3 if dcpst == "PreviouslyPartnered"
replace dcpst_coded = 2 if dcpst == "SingleNeverMarried"

drop dcpst
rename dcpst_coded dcpst

gen dgn_coded = .
replace dgn_coded = 1 if dgn == "Male"
replace dgn_coded = 0 if dgn == "Female"

drop dgn
rename dgn_coded dgn

collapse (mean) sim_employed sim_student sim_inactive sim_retired, ///
	by(run year dcpst dgn)
collapse (mean) sim_employed sim_student sim_inactive sim_retired ///
		 (sd) sim_employed_sd = sim_employed ///
		 sim_student_sd = sim_student ///
		 sim_inactive_sd = sim_inactive ///
		 sim_retired_sd = sim_retired ///
		 , by(year dcpst dgn)
		 
foreach varname in sim_employed sim_student sim_inactive sim_retired {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year dcpst dgn using "$dir_data/temp_valid_stats.dta", keep(3) nogen


** All 

preserve

collapse (mean) sim* valid*, by(year dcpst)

* Plot figure: dcpst == 1, partnered
keep if dcpst == 1

twoway ///
(rarea sim_employed_high sim_employed_low year, sort color(green%20) ///
	legend(label(1 "Employed, simulated"))) ///
(line valid_employed year, sort color(green) ///
	legend(label(2 "Employed, observed"))) ///
(rarea sim_student_high sim_student_low year, sort color(blue%20) ///
	legend(label(3 "Students, simulated"))) ///
(line valid_student year, sort color(blue) ///
	legend(label(4 "Students, observed"))) ///
(rarea sim_inactive_high sim_inactive_low year, sort color(red%20) ///
	legend(label(5 "Non-employed, simulated"))) ///
(line valid_inactive year, sort color(red) ///
	legend(label(6 "Non-employed, observed"))) ///
(rarea sim_retired_high sim_retired_low year, sort color(grey%20) ///
	legend(label(7 "Retired, simulated"))) ///
(line valid_retired year, sort color(grey) ///
	legend(label(8 "Retired, observed"))), ///
title("Activity status") subtitle("Ages ${min_age}-${max_age}, partnered") ///
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", size(vsmall))

graph export ///
"$dir_output_files/economic_activity/validation_${country}_activity_status_ts_${min_age}_${max_age}_both_partnered.jpg", ///
	replace width(2400) height(1350) quality(100) 

restore, preserve

collapse (mean) sim* valid*, by(year dcpst)

* Plot figure: dcpst == 2, single
keep if dcpst == 2

twoway ///
(rarea sim_employed_high sim_employed_low year, sort color(green%20) ///
	legend(label(1 "Employed, simulated"))) ///
(line valid_employed year, sort color(green) ///
	legend(label(2 "Employed, observed"))) ///
(rarea sim_student_high sim_student_low year, sort color(blue%20) ///
	legend(label(3 "Students, simulated"))) ///
(line valid_student year, sort color(blue) ///
	legend(label(4 "Students, observed"))) ///
(rarea sim_inactive_high sim_inactive_low year, sort color(red%20) ///
	legend(label(5 "Non-employed, simulated"))) ///
(line valid_inactive year, sort color(red) ///
	legend(label(6 "Non-employed, observed"))) ///
(rarea sim_retired_high sim_retired_low year, sort color(grey%20) ///
	legend(label(7 "Retired, simulated"))) ///
(line valid_retired year, sort color(grey) ///
	legend(label(8 "Retired, observed"))), ///
	title("Activity status") ///
	subtitle("Ages ${min_age}-${max_age}, single") xtitle("Year") ///
	ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", size(vsmall))

graph export ///
"$dir_output_files/economic_activity/validation_${country}_activity_status_ts_${min_age}_${max_age}_both_single.jpg", ///
	replace width(2400) height(1350) quality(100)

restore, preserve

collapse (mean) sim* valid*, by(year dcpst)

* Plot figure: dcpst == 3, previously partnered
keep if dcpst == 3

twoway ///
(rarea sim_employed_high sim_employed_low year, sort color(green%20) ///
	legend(label(1 "Employed, simulated"))) ///
(line valid_employed year, sort color(green) ///
	legend(label(2 "Employed, observed"))) ///
(rarea sim_student_high sim_student_low year, sort color(blue%20) ///
	legend(label(3 "Students, simulated"))) ///
(line valid_student year, sort color(blue) ///
	legend(label(4 "Students, observed"))) ///
(rarea sim_inactive_high sim_inactive_low year, sort color(red%20) ///
	legend(label(5 "Non-employed, simulated"))) ///
(line valid_inactive year, sort color(red) ///
	legend(label(6 "Non-employed, observed"))) ///
(rarea sim_retired_high sim_retired_low year, sort color(grey%20) ///
	legend(label(7 "Retired, simulated"))) ///
(line valid_retired year, sort color(grey) ///
	legend(label(8 "Retired, observed"))), ///
	title("Activity status") ///
	subtitle("Ages ${min_age}-${max_age}, previously partnered") ///
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", size(vsmall))

graph export ///
"$dir_output_files/economic_activity/validation_${country}_activity_status_ts_${min_age}_${max_age}_both_prev_partnered.jpg", ///
	replace width(2400) height(1350) quality(100)

restore


** Males

* Plot figure: dcpst == 1, partnered
preserve

keep if dcpst == 1 & dgn == 1

twoway ///
(rarea sim_employed_high sim_employed_low year, sort color(green%20) ///
	legend(label(1 "Employed, simulated"))) ///
(line valid_employed year, sort color(green) ///
	legend(label(2 "Employed, observed"))) ///
(rarea sim_student_high sim_student_low year, sort color(blue%20) ///
	legend(label(3 "Students, simulated"))) ///
(line valid_student year, sort color(blue) ///
	legend(label(4 "Students, observed"))) ///
(rarea sim_inactive_high sim_inactive_low year, sort color(red%20) ///
	legend(label(5 "Non-employed, simulated"))) ///
(line valid_inactive year, sort color(red) ///
	legend(label(6 "Non-employed, observed"))) ///
(rarea sim_retired_high sim_retired_low year, sort color(grey%20) ///
	legend(label(7 "Retired, simulated"))) ///
(line valid_retired year, sort color(grey) ///
	legend(label(8 "Retired, observed"))), ///
	title("Activity status") ///
	subtitle("Ages ${min_age}-${max_age}, partnered males") ///
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", size(vsmall))

graph export ///
"$dir_output_files/economic_activity/validation_${country}_activity_status_ts_${min_age}_${max_age}_male_partnered.jpg", ///
	replace width(2400) height(1350) quality(100)

restore, preserve

* Plot figure: dcpst == 2, single
keep if dcpst == 2 & dgn == 1

twoway ///
(rarea sim_employed_high sim_employed_low year, sort color(green%20) ///
	legend(label(1 "Employed, simulated"))) ///
(line valid_employed year, sort color(green) ///
	legend(label(2 "Employed, observed"))) ///
(rarea sim_student_high sim_student_low year, sort color(blue%20) ///
	legend(label(3 "Students, simulated"))) ///
(line valid_student year, sort color(blue) ///
	legend(label(4 "Students, observed"))) ///
(rarea sim_inactive_high sim_inactive_low year, sort color(red%20) ///
	legend(label(5 "Non-employed, simulated"))) ///
(line valid_inactive year, sort color(red) ///
	legend(label(6 "Non-employed, observed"))) ///
(rarea sim_retired_high sim_retired_low year, sort color(grey%20) ///
	legend(label(7 "Retired, simulated"))) ///
(line valid_retired year, sort color(grey) ///
	legend(label(8 "Retired, observed"))), ///
	title("Activity status") ///
	subtitle("Ages ${min_age}-${max_age}, single males") ///
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", size(vsmall))

graph export ///
"$dir_output_files/economic_activity/validation_${country}_activity_status_ts_${min_age}_${max_age}_male_single.jpg", ///
	replace width(2400) height(1350) quality(100)

restore, preserve

* Plot figure: dcpst == 3, previously partnered
keep if dcpst == 3 & dgn == 1

twoway ///
(rarea sim_employed_high sim_employed_low year, sort color(green%20) ///
	legend(label(1 "Employed, simulated"))) ///
(line valid_employed year, sort color(green) ///
	legend(label(2 "Employed, observed"))) ///
(rarea sim_student_high sim_student_low year, sort color(blue%20) ///
	legend(label(3 "Students, simulated"))) ///
(line valid_student year, sort color(blue) ///
	legend(label(4 "Students, observed"))) ///
(rarea sim_inactive_high sim_inactive_low year, sort color(red%20) ///
	legend(label(5 "Non-employed, simulated"))) ///
(line valid_inactive year, sort color(red) ///
	legend(label(6 "Non-employed, observed"))) ///
(rarea sim_retired_high sim_retired_low year, sort color(grey%20) ///
	legend(label(7 "Retired, simulated"))) ///
(line valid_retired year, sort color(grey) ///
	legend(label(8 "Retired, observed"))), ///
	title("Activity status") ///
	subtitle("Ages ${min_age}-${max_age}, prevously partnered males") ///
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", size(vsmall))

graph export ///
"$dir_output_files/economic_activity/validation_${country}_activity_status_ts_${min_age}_${max_age}_male_prev_partnered.jpg", ///
	replace width(2400) height(1350) quality(100)

restore


** Females

* Plot figure: dcpst == 1, partnered
preserve

keep if dcpst == 1 & dgn == 0

twoway ///
(rarea sim_employed_high sim_employed_low year, sort color(green%20) ///
	legend(label(1 "Employed, simulated"))) ///
(line valid_employed year, sort color(green) ///
	legend(label(2 "Employed, observed"))) ///
(rarea sim_student_high sim_student_low year, sort color(blue%20) ///
	legend(label(3 "Students, simulated"))) ///
(line valid_student year, sort color(blue) ///
	legend(label(4 "Students, observed"))) ///
(rarea sim_inactive_high sim_inactive_low year, sort color(red%20) ///
	legend(label(5 "Non-employed, simulated"))) ///
(line valid_inactive year, sort color(red) ///
	legend(label(6 "Non-employed, observed"))) ///
(rarea sim_retired_high sim_retired_low year, sort color(grey%20) ///
	legend(label(7 "Retired, simulated"))) ///
(line valid_retired year, sort color(grey) ///
	legend(label(8 "Retired, observed"))), ///
	title("Activity status") ///
	subtitle("Ages ${min_age}-${max_age}, partnered females") ///
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", size(vsmall))

graph export ///
"$dir_output_files/economic_activity/validation_${country}_activity_status_ts_${min_age}_${max_age}_female_partnered.jpg", ///
	replace width(2400) height(1350) quality(100)

restore, preserve

* Plot figure: dcpst == 2, single
keep if dcpst == 2 & dgn == 0

twoway ///
(rarea sim_employed_high sim_employed_low year, sort color(green%20) ///
	legend(label(1 "Employed, simulated"))) ///
(line valid_employed year, sort color(green) ///
	legend(label(2 "Employed, observed"))) ///
(rarea sim_student_high sim_student_low year, sort color(blue%20) ///
	legend(label(3 "Students, simulated"))) ///
(line valid_student year, sort color(blue) ///
	legend(label(4 "Students, observed"))) ///
(rarea sim_inactive_high sim_inactive_low year, sort color(red%20) ///
	legend(label(5 "Non-employed, simulated"))) ///
(line valid_inactive year, sort color(red) ///
	legend(label(6 "Non-employed, observed"))) ///
(rarea sim_retired_high sim_retired_low year, sort color(grey%20) ///
	legend(label(7 "Retired, simulated"))) ///
(line valid_retired year, sort color(grey) ///
	legend(label(8 "Retired, observed"))), ///
	title("Activity status") ///
	subtitle("Ages ${min_age}-${max_age}, single females") ///
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", size(vsmall))

graph export ///
"$dir_output_files/economic_activity/validation_${country}_activity_status_ts_${min_age}_${max_age}_female_single.jpg", ///
	replace width(2400) height(1350) quality(100)

restore, preserve

* Plot figure: dcpst == 3, previously partnered
keep if dcpst == 3 & dgn == 0

twoway ///
(rarea sim_employed_high sim_employed_low year, sort color(green%20) ///
	legend(label(1 "Employed, simulated"))) ///
(line valid_employed year, sort color(green) ///
	legend(label(2 "Employed, observed"))) ///
(rarea sim_student_high sim_student_low year, sort color(blue%20) ///
	legend(label(3 "Students, simulated"))) ///
(line valid_student year, sort color(blue) ///
	legend(label(4 "Students, observed"))) ///
(rarea sim_inactive_high sim_inactive_low year, sort color(red%20) ///
	legend(label(5 "Non-employed, simulated"))) ///
(line valid_inactive year, sort color(red) ///
	legend(label(6 "Non-employed, observed"))) ///
(rarea sim_retired_high sim_retired_low year, sort color(grey%20) ///
	legend(label(7 "Retired, simulated"))) ///
(line valid_retired year, sort color(grey) ///
	legend(label(8 "Retired, observed"))), ///
	title("Activity status") ///
	subtitle("Ages ${min_age}-${max_age}, previously partnered females") ///
	xtitle("Year") ///
	ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", size(vsmall))

graph export ///
"$dir_output_files/economic_activity/validation_${country}_activity_status_ts_${min_age}_${max_age}_female_prev_partnered.jpg", ///
	replace width(2400) height(1350) quality(100)

graph drop _all	

restore 


*** Employed time series 

* Prepare validation data
use year dwt valid_employed valid_student valid_inactive dgn ///
	valid_retired using "$dir_data/${country}-eusilc_validation_sample.dta", ///
	clear
	
collapse (mean) valid_employed valid_student valid_inactive valid_retired ///
	[aw = dwt], by(year dgn)

save "$dir_data/temp_valid_stats.dta", replace

* Prepare simulated data
use run year sim_employed sim_student sim_inactive sim_retired dgn using ///
	"$dir_data/simulated_data.dta", clear

gen dgn_coded = .
replace dgn_coded = 1 if dgn == "Male"
replace dgn_coded = 0 if dgn == "Female"

drop dgn
rename dgn_coded dgn	
	
collapse (mean) sim_employed sim_student sim_inactive sim_retired, ///
	by(run year dgn)
collapse (mean) sim_employed sim_student sim_inactive sim_retired ///
		 (sd) sim_employed_sd = sim_employed ///
		 sim_student_sd = sim_student ///
		 sim_inactive_sd = sim_inactive ///
		 sim_retired_sd = sim_retired ///
		 , by(year dgn)
		 
foreach varname in sim_employed sim_student sim_inactive sim_retired {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year dgn using "$dir_data/temp_valid_stats.dta", keep(3) nogen


** All 

preserve

collapse (mean) sim* valid*, by(year)

* Plot figure 
twoway ///
(rarea sim_employed_high sim_employed_low year, sort color(green%20) ///
	legend(label(1 "Employed, simulated"))) ///
(line valid_employed year, sort color(green) ///
	legend(label(2 "Employed, observed"))), ///
	title("Employed") subtitle("Ages ${min_age}-${max_age}") ///
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note(Notes:, size(vsmall))

* Save figure
graph export ///
"$dir_output_files/economic_activity/validation_${country}_employed_ts_${min_age}_${max_age}_both.jpg", ///
	replace width(2400) height(1350) quality(100)

restore, preserve

	
** Males 

keep if dgn == 1 

* Plot figure 
twoway ///
(rarea sim_employed_high sim_employed_low year, sort color(green%20) ///
	legend(label(1 "Employed, simulated"))) ///
(line valid_employed year, sort color(green) ///
	legend(label(2 "Employed, observed"))), ///
	title("Employed") subtitle("Ages ${min_age}-${max_age}, males") ///
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note(Notes:, size(vsmall))
	
* Save figure
graph export ///
	"$dir_output_files/economic_activity/validation_${country}_employed_ts_${min_age}_${max_age}_male.jpg", ///
	replace width(2400) height(1350) quality(100)


restore, preserve

	
** Females 

keep if dgn == 0 

* Plot figure 
twoway ///
(rarea sim_employed_high sim_employed_low year, sort color(green%20) ///
	legend(label(1 "Employed, simulated"))) ///
(line valid_employed year, sort color(green) ///
	legend(label(2 "Employed, observed"))), ///
	title("Employed") subtitle("Ages ${min_age}-${max_age}, females") /// 
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note(Notes:, size(vsmall))
	
* Save figure
graph export ///
"$dir_output_files/economic_activity/validation_${country}_employed_ts_${min_age}_${max_age}_female.jpg", ///
	replace width(2400) height(1350) quality(100)
	
restore 	
	
	
** Females ages 18-60 (before state pension age)

* Prepare validation data
use year dwt valid_employed valid_student valid_inactive dgn dag ///
	valid_retired using "$dir_data/${country}-eusilc_validation_sample.dta", ///
	clear
	
drop if dag > 60	
	
collapse (mean) valid_employed valid_student valid_inactive valid_retired ///
	[aw = dwt], by(year dgn)

save "$dir_data/temp_valid_stats.dta", replace

* Prepare simulated data
use run year sim_employed sim_student sim_inactive sim_retired dgn dag using ///
	"$dir_data/simulated_data.dta", clear
	
drop if dag > 60

gen dgn_coded = .
replace dgn_coded = 1 if dgn == "Male"
replace dgn_coded = 0 if dgn == "Female"

drop dgn
rename dgn_coded dgn	
	
collapse (mean) sim_employed sim_student sim_inactive sim_retired, ///
	by(run year dgn)
collapse (mean) sim_employed sim_student sim_inactive sim_retired ///
		 (sd) sim_employed_sd = sim_employed ///
		 sim_student_sd = sim_student ///
		 sim_inactive_sd = sim_inactive ///
		 sim_retired_sd = sim_retired ///
		 , by(year dgn)
		 
foreach varname in sim_employed sim_student sim_inactive sim_retired {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year dgn using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Females 
keep if dgn == 0

* Plot figure 
twoway ///
(rarea sim_employed_high sim_employed_low year, sort color(green%20) ///
	legend(label(1 "Employed, simulated"))) ///
(line valid_employed year, sort color(green) ///
	legend(label(2 "Employed, observed"))), ///
	title("Employed") subtitle("Ages ${min_age}-60") ///
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note(Notes:, size(vsmall))

* Save figure
graph export ///
"$dir_output_files/economic_activity/validation_${country}_employed_ts_${min_age}_60_female.jpg", ///
	replace width(2400) height(1350) quality(100)

	
** All ages

* Prepare validation data
use year dwt valid_employed valid_student valid_inactive dgn ///
	valid_retired using ///
	"$dir_data/${country}-eusilc_validation_full_sample.dta", ///
	clear
		
collapse (mean) valid_employed valid_student valid_inactive valid_retired ///
	[aw = dwt], by(year dgn)

save "$dir_data/temp_valid_stats.dta", replace

* Prepare simulated data
use run year sim_employed sim_student sim_inactive sim_retired dgn using ///
	"$dir_data/simulated_data_full.dta", clear

gen dgn_coded = .
replace dgn_coded = 1 if dgn == "Male"
replace dgn_coded = 0 if dgn == "Female"

drop dgn
rename dgn_coded dgn	
	
collapse (mean) sim_employed sim_student sim_inactive sim_retired, ///
	by(run year dgn)
	
collapse (mean) sim_employed sim_student sim_inactive sim_retired ///
		 (sd) sim_employed_sd = sim_employed ///
		 sim_student_sd = sim_student ///
		 sim_inactive_sd = sim_inactive ///
		 sim_retired_sd = sim_retired ///
		 , by(year dgn)
		 
foreach varname in sim_employed sim_student sim_inactive sim_retired {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year dgn using "$dir_data/temp_valid_stats.dta", keep(3) nogen
 
** All  
 
preserve

collapse (mean) sim* valid*, by(year)

* Plot figure 
twoway ///
(rarea sim_employed_high sim_employed_low year, sort color(green%20) ///
	legend(label(1 "Employed, simulated"))) ///
(line valid_employed year, sort color(green) ///
	legend(label(2 "Employed, observed"))), ///
	title("Employed") subtitle("All ages") ///
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note(Notes:, size(vsmall))

* Save figure
graph export ///
"$dir_output_files/economic_activity/validation_${country}_employed_ts_all_both.jpg", ///
	replace width(2400) height(1350) quality(100) 	
	
restore, preserve

	
** Males 

keep if dgn == 1 

* Plot figure 
twoway ///
(rarea sim_employed_high sim_employed_low year, sort color(green%20) ///
	legend(label(1 "Employed, simulated"))) ///
(line valid_employed year, sort color(green) ///
	legend(label(2 "Employed, observed"))), ///
	title("Employed") subtitle("All ages, males") /// 
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note(Notes:, size(vsmall))

* Save figure
graph export ///
"$dir_output_files/economic_activity/validation_${country}_employed_ts_all_male.jpg", ///
	replace width(2400) height(1350) quality(100)


restore, preserve

	
** Females 

keep if dgn == 0 

* Plot figure 
twoway ///
(rarea sim_employed_high sim_employed_low year, sort color(green%20) ///
	legend(label(1 "Employed, simulated"))) ///
(line valid_employed year, sort color(green) ///
	legend(label(2 "Employed, observed"))), ///
	title("Employed") subtitle("All ages, females") ///
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note(Notes:, size(vsmall))

* Save figure
graph export ///
"$dir_output_files/economic_activity/validation_${country}_employed_ts_all_female.jpg", ///
	replace width(2400) height(1350) quality(100)
	
restore 

graph drop _all 	



*** Others (student, non-employed, retired) time series 
 
* Prepare validation data
use year dwt valid_employed valid_student valid_inactive dgn ///
	valid_retired using "$dir_data/${country}-eusilc_validation_sample.dta", ///
	clear
	
collapse (mean) valid_employed valid_student valid_inactive valid_retired ///
	[aw = dwt], by(year dgn)

save "$dir_data/temp_valid_stats.dta", replace

* Prepare simulated data
use run year sim_employed sim_student sim_inactive sim_retired dgn using ///
	"$dir_data/simulated_data.dta", clear

gen dgn_coded = .
replace dgn_coded = 1 if dgn == "Male"
replace dgn_coded = 0 if dgn == "Female"

drop dgn
rename dgn_coded dgn	
	
collapse (mean) sim_employed sim_student sim_inactive sim_retired, ///
	by(run year dgn)
collapse (mean) sim_employed sim_student sim_inactive sim_retired ///
		 (sd) sim_employed_sd = sim_employed ///
		 sim_student_sd = sim_student ///
		 sim_inactive_sd = sim_inactive ///
		 sim_retired_sd = sim_retired ///
		 , by(year dgn)
		 
foreach varname in sim_employed sim_student sim_inactive sim_retired {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year dgn using "$dir_data/temp_valid_stats.dta", keep(3) nogen


** All 

preserve

collapse (mean) sim* valid*, by(year)

* Plot figure 
twoway ///
(rarea sim_student_high sim_student_low year, sort color(blue%20) ///
	legend(label(1 "Students, simulated"))) ///
(line valid_student year, sort color(blue) ///
	legend(label(2 "Students, observed"))) ///
(rarea sim_inactive_high sim_inactive_low year, sort color(red%20) ///
	legend(label(3 "Non-employed, simulated"))) ///
(line valid_inactive year, sort color(red) ///
	legend(label(4 "Non-employed, observed"))) ///
(rarea sim_retired_high sim_retired_low year, sort color(grey%20) ///
	legend(label(5 "Retired, simulated"))) ///
(line valid_retired year, sort color(grey) ///
	legend(label(6 "Retired, observed"))), ///
	title("Activity status of those not employed") subtitle("Ages ${min_age}-${max_age}") ///
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.) minus students and retired. ", size(vsmall))

* Save figure
graph export ///
	"$dir_output_files/economic_activity/validation_${country}_activity_status_not_employed_ts_${min_age}_${max_age}_both.jpg", ///
	replace width(2400) height(1350) quality(100)

restore, preserve

	
** Males 

keep if dgn == 1 

* Plot figure 
twoway ///
(rarea sim_student_high sim_student_low year, sort color(blue%20) ///
	legend(label(1 "Students, simulated"))) ///
(line valid_student year, sort color(blue) ///
	legend(label(2 "Students, observed"))) ///
(rarea sim_inactive_high sim_inactive_low year, sort color(red%20) ///
	legend(label(3 "Non-employed, simulated"))) ///
(line valid_inactive year, sort color(red) ///
	legend(label(4 "Non-employed, observed"))) ///
(rarea sim_retired_high sim_retired_low year, sort color(grey%20) ///
	legend(label(5 "Retired, simulated"))) ///
(line valid_retired year, sort color(grey) ///
	legend(label(6 "Retired, observed"))), ///
	title("Activity status of those not employed") subtitle("Ages ${min_age}-${max_age}, males") ///
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", size(vsmall))
	
* Save figure
graph export ///
	"$dir_output_files/economic_activity/validation_${country}_activity_status_not_employed_ts_${min_age}_${max_age}_male.jpg", ///
	replace width(2400) height(1350) quality(100)


restore, preserve

	
** Females 

keep if dgn == 0 

* Plot figure 
twoway ///
(rarea sim_student_high sim_student_low year, sort color(blue%20) ///
	legend(label(1 "Students, simulated"))) ///
(line valid_student year, sort color(blue) ///
	legend(label(2 "Students, observed"))) ///
(rarea sim_inactive_high sim_inactive_low year, sort color(red%20) ///
	legend(label(3 "Non-employed, simulated"))) ///
(line valid_inactive year, sort color(red) ///
	legend(label(4 "Non-employed, observed"))) ///
(rarea sim_retired_high sim_retired_low year, sort color(grey%20) ///
	legend(label(5 "Retired, simulated"))) ///
(line valid_retired year, sort color(grey) ///
	legend(label(6 "Retired, observed"))), ///
	title("Activity status of those not employed") subtitle("Ages ${min_age}-${max_age}, females") /// 
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", size(vsmall))
	
* Save figure
graph export ///
"$dir_output_files/economic_activity/validation_${country}_activity_status_not_employed_ts_${min_age}_${max_age}_female.jpg", ///
	replace width(2400) height(1350) quality(100)
	
restore 	
	
	
** Females ages 18-60 (before state pension age)

* Prepare validation data
use year dwt valid_employed valid_student valid_inactive dgn dag ///
	valid_retired using "$dir_data/${country}-eusilc_validation_sample.dta", ///
	clear
	
drop if dag > 60	
	
collapse (mean) valid_employed valid_student valid_inactive valid_retired ///
	[aw = dwt], by(year dgn)

save "$dir_data/temp_valid_stats.dta", replace

* Prepare simulated data
use run year sim_employed sim_student sim_inactive sim_retired dgn dag using ///
	"$dir_data/simulated_data.dta", clear
	
drop if dag > 60

gen dgn_coded = .
replace dgn_coded = 1 if dgn == "Male"
replace dgn_coded = 0 if dgn == "Female"

drop dgn
rename dgn_coded dgn	
	
collapse (mean) sim_employed sim_student sim_inactive sim_retired, ///
	by(run year dgn)
collapse (mean) sim_employed sim_student sim_inactive sim_retired ///
		 (sd) sim_employed_sd = sim_employed ///
		 sim_student_sd = sim_student ///
		 sim_inactive_sd = sim_inactive ///
		 sim_retired_sd = sim_retired ///
		 , by(year dgn)
		 
foreach varname in sim_employed sim_student sim_inactive sim_retired {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year dgn using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Females 
keep if dgn == 0

* Plot figure 
twoway ///
(rarea sim_student_high sim_student_low year, sort color(blue%20) ///
	legend(label(1 "Students, simulated"))) ///
(line valid_student year, sort color(blue) ///
	legend(label(2 "Students, observed"))) ///
(rarea sim_inactive_high sim_inactive_low year, sort color(red%20) ///
	legend(label(3 "Non-employed, simulated"))) ///
(line valid_inactive year, sort color(red) ///
	legend(label(4 "Non-employed, observed"))) ///
(rarea sim_retired_high sim_retired_low year, sort color(grey%20) ///
	legend(label(5 "Retired, simulated"))) ///
(line valid_retired year, sort color(grey) ///
	legend(label(6 "Retired, observed"))), ///
	title("Activity status of those not employed") subtitle("Ages ${min_age}-60") ///
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", size(vsmall))

* Save figure
graph export ///
"$dir_output_files/economic_activity/validation_${country}_activity_status_not_employed_ts_${min_age}_60_female.jpg", ///
	replace width(2400) height(1350) quality(100)

	
** All ages

* Prepare validation data
use year dwt valid_employed valid_student valid_inactive dgn ///
	valid_retired using ///
	"$dir_data/${country}-eusilc_validation_full_sample.dta", ///
	clear
		
collapse (mean) valid_employed valid_student valid_inactive valid_retired ///
	[aw = dwt], by(year dgn)

save "$dir_data/temp_valid_stats.dta", replace

* Prepare simulated data
use run year sim_employed sim_student sim_inactive sim_retired dgn using ///
	"$dir_data/simulated_data_full.dta", clear

gen dgn_coded = .
replace dgn_coded = 1 if dgn == "Male"
replace dgn_coded = 0 if dgn == "Female"

drop dgn
rename dgn_coded dgn	
	
collapse (mean) sim_employed sim_student sim_inactive sim_retired, ///
	by(run year dgn)
	
collapse (mean) sim_employed sim_student sim_inactive sim_retired ///
		 (sd) sim_employed_sd = sim_employed ///
		 sim_student_sd = sim_student ///
		 sim_inactive_sd = sim_inactive ///
		 sim_retired_sd = sim_retired ///
		 , by(year dgn)
		 
foreach varname in sim_employed sim_student sim_inactive sim_retired {
	gen `varname'_high = `varname' + 1.96*`varname'_sd
	gen `varname'_low = `varname' - 1.96*`varname'_sd
}

merge 1:1 year dgn using "$dir_data/temp_valid_stats.dta", keep(3) nogen
 
** All  
 
preserve

collapse (mean) sim* valid*, by(year)

* Plot figure 
twoway ///
(rarea sim_student_high sim_student_low year, sort color(blue%20) ///
	legend(label(1 "Students, simulated"))) ///
(line valid_student year, sort color(blue) ///
	legend(label(2 "Students, observed"))) ///
(rarea sim_inactive_high sim_inactive_low year, sort color(red%20) ///
	legend(label(3 "Non-employed, simulated"))) ///
(line valid_inactive year, sort color(red) ///
	legend(label(4 "Non-employed, observed"))) ///
(rarea sim_retired_high sim_retired_low year, sort color(grey%20) ///
	legend(label(5 "Retired, simulated"))) ///
(line valid_retired year, sort color(grey) ///
	legend(label(6 "Retired, observed"))), ///
	title("Activity status") subtitle("All ages") ///
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", size(vsmall))

* Save figure
graph export ///
"$dir_output_files/economic_activity/validation_${country}_activity_status_not_employed_ts_all_both.jpg", ///
	replace width(2400) height(1350) quality(100) 	
	
restore, preserve

	
** Males 

keep if dgn == 1 

* Plot figure 
twoway ///
(rarea sim_student_high sim_student_low year, sort color(blue%20) ///
	legend(label(1 "Students, simulated"))) ///
(line valid_student year, sort color(blue) ///
	legend(label(2 "Students, observed"))) ///
(rarea sim_inactive_high sim_inactive_low year, sort color(red%20) ///
	legend(label(3 "Non-employed, simulated"))) ///
(line valid_inactive year, sort color(red) ///
	legend(label(4 "Non-employed, observed"))) ///
(rarea sim_retired_high sim_retired_low year, sort color(grey%20) ///
	legend(label(5 "Retired, simulated"))) ///
(line valid_retired year, sort color(grey) ///
	legend(label(6 "Retired, observed"))), ///
	title("Activity status") subtitle("All ages, males") /// 
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", size(vsmall))

* Save figure
graph export ///
"$dir_output_files/economic_activity/validation_${country}_activity_status_not_employed_ts_all_male.jpg", ///
	replace width(2400) height(1350) quality(100)


restore, preserve

	
** Females 

keep if dgn == 0 

* Plot figure 
twoway ///
(rarea sim_student_high sim_student_low year, sort color(blue%20) ///
	legend(label(1 "Students, simulated"))) ///
(line valid_student year, sort color(blue) ///
	legend(label(2 "Students, observed"))) ///
(rarea sim_inactive_high sim_inactive_low year, sort color(red%20) ///
	legend(label(3 "Non-employed, simulated"))) ///
(line valid_inactive year, sort color(red) ///
	legend(label(4 "Non-employed, observed"))) ///
(rarea sim_retired_high sim_retired_low year, sort color(grey%20) ///
	legend(label(5 "Retired, simulated"))) ///
(line valid_retired year, sort color(grey) ///
	legend(label(6 "Retired, observed"))), ///
	title("Activity status") subtitle("All ages, females") ///
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", size(vsmall))

* Save figure
graph export ///
"$dir_output_files/economic_activity/validation_${country}_activity_status_not_employed_ts_all_female.jpg", ///
	replace width(2400) height(1350) quality(100)
	
restore 

graph drop _all 

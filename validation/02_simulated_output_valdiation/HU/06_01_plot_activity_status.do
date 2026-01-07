********************************************************************************
* PROJECT:  		ESPON 
* SECTION:			Validation
* OBJECT: 			Activity status plots
* AUTHORS:			Patryk Bronka, Ashley Burdett 
* LAST UPDATE:		06/2025 (AB)
* COUNTRY: 			Poland 

* NOTES: 			This do file plots validation graphs for economics activity 
* 					status (4 cat). 
********************************************************************************

********************************************************************************
* 1 : Mean values over time
********************************************************************************

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
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", ///
	size(vsmall))

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
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", ///
	size(vsmall))

* Save figure
graph export ///
	"$dir_output_files/economic_activity/validation_${country}_activity_status_ts_${min_age}_${max_age}_both.jpg", ///
	replace width(2400) height(1350) quality(100)

restore, preserve
	
** By gender 
* Male
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
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", ///
	size(vsmall))
	
* Save figure
graph export ///
	"$dir_output_files/economic_activity/validation_${country}_activity_status_ts_${min_age}_${max_age}_male.jpg", ///
	replace width(2400) height(1350) quality(100)


restore, preserve

	
* Female
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
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", ///
	size(vsmall))
	
* Save figure
graph export ///
"$dir_output_files/economic_activity/validation_${country}_activity_status_ts_${min_age}_${max_age}_female.jpg", ///
	replace width(2400) height(1350) quality(100)
	
restore 	
	
	
* Females ages 18-60 (before state pension age)

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
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", ///
	size(vsmall))

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
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", ///
	size(vsmall))

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
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", ///
	size(vsmall))

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
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", ///
	size(vsmall))

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
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", ///
	size(vsmall))

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
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", ///
	size(vsmall))

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
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", ///
	size(vsmall))

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
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", ///
	size(vsmall))

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
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", ///
	size(vsmall))

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
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", ///
	size(vsmall))

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
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", ///
	size(vsmall))

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
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", ///
	size(vsmall))

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
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", ///
	size(vsmall))

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
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.) minus students and retired. ", ///
	size(vsmall))

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
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", ///
	size(vsmall))
	
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
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", ///
	size(vsmall))
	
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
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", ///
	size(vsmall))

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
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", ///
	size(vsmall))

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
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", ///
	size(vsmall))

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
	note("Notes: Non-employed includes the unemployed and inactive (homemakers, incapacity, carers, discouraged workers etc.)" "minus students and retired. ", ///
	size(vsmall))

* Save figure
graph export ///
"$dir_output_files/economic_activity/validation_${country}_activity_status_not_employed_ts_all_female.jpg", ///
	replace width(2400) height(1350) quality(100)
	
restore 


* Employed by age group 

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
	gen employed_f_`i'_sim_high = ///
		employed_f_`i'_sim + 1.96*sd_employed_f_`i'_sim
	gen employed_f_`i'_sim_low = ///
		employed_f_`i'_sim - 1.96*sd_employed_f_`i'_sim
	gen employed_m_`i'_sim_high = ///
		employed_m_`i'_sim + 1.96*sd_employed_m_`i'_sim
	gen employed_m_`i'_sim_low = ///
		employed_m_`i'_sim - 1.96*sd_employed_m_`i'_sim	
}

merge 1:1 year using "$dir_data/temp_valid_stats.dta", keep(3) nogen

* Plot figures
foreach vble in "student" "employed_f" "employed_m" {
	
	twoway (rarea `vble'_1_sim_high `vble'_1_sim_low year, ///
		sort color(green%20) ///
		legend(label(1 "Simulated") position(6) rows(1))) ///
		(line `vble'_1_valid year, sort color(green) ///
		legend(label(2 "Observed"))), ///
		title("Age 15-19") name(`vble'_1, replace) ylabel(0 [0.5] 1) ///
	graphregion(color(white)) xtitle("")
	
	twoway (rarea `vble'_2_sim_high `vble'_2_sim_low year, ///
		sort color(green%20) ///
		legend(label(1 "Simulated") position(6) rows(1))) ///
		(line `vble'_2_valid year, sort color(green) ///
		legend(label(2 "Observed"))), ///
		title("Age 20-24") name(`vble'_2, replace) ylabel(0 [0.5] 1) ///
	graphregion(color(white)) xtitle("")
	
	twoway (rarea `vble'_3_sim_high `vble'_3_sim_low year, ///
		sort color(green%20) ///
		legend(label(1 "Simulated") position(6) rows(1))) ///
		(line `vble'_3_valid year, sort color(green) ///
		legend(label(2 "Observed"))), ///
		title("Age 25-29") name(`vble'_3, replace) ylabel(0 [0.5] 1) ///
	graphregion(color(white)) xtitle("") 
	
	twoway (rarea `vble'_4_sim_high `vble'_4_sim_low year, ///
		sort color(green%20) ///
		legend(label(1 "Simulated") position(6) rows(1))) ///
		(line `vble'_4_valid year, sort color(green) ///
		legend(label(2 "Observed"))), ///
		title("Age 30-34") name(`vble'_4, replace) ylabel(0 [0.5] 1) ///
	graphregion(color(white)) xtitle("")
	
	twoway (rarea `vble'_5_sim_high `vble'_5_sim_low year, ///
		sort color(green%20) ///
		legend(label(1 "Simulated") position(6) rows(1))) ///
		(line `vble'_5_valid year, sort color(green) ///
		legend(label(2 "Observed"))), ///
		title("Age 35-39") name(`vble'_5, replace) ylabel(0 [0.5] 1) ///
	graphregion(color(white)) xtitle("")
	
	twoway (rarea `vble'_6_sim_high `vble'_6_sim_low year, ///
		sort color(green%20) ///
		legend(label(1 "Simulated") position(6) ///
		rows(1)))(line `vble'_6_valid year, sort color(green) ///
		legend(label(2 "observed"))), ///
		title("Age 40-59") name(`vble'_6, replace) ylabel(0 [0.5] 1) ///
	graphregion(color(white)) xtitle("")
	
	twoway (rarea `vble'_7_sim_high `vble'_7_sim_low year, ///
		sort color(green%20) ///
		legend(label(1 "Simulated") position(6) rows(1))) ///
		(line `vble'_7_valid year, sort color(green) ///
		legend(label(2 "Observed"))), ///
		title("Age 60-79") name(`vble'_7, replace) ylabel(0 [0.5] 1) ///
	graphregion(color(white)) xtitle("")
	
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
	
grc1leg student_1 student_2 student_3 , ///
	title("Share of students by age") legendfrom(student_1) ///
	graphregion(color(white)) ///
	note("Notes: ", size(vsmall))
	
graph export ///
	"$dir_output_files/economic_activity/validation_${country}_students_ts_15_29_both.jpg", ///
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






graph drop _all 

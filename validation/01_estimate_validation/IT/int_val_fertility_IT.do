********************************************************************************
* PROJECT:  		ESPON 
* SECTION:			Fertility
* OBJECT: 			Internal validation
* AUTHORS:			Ashley Burdett 
* LAST UPDATE:		April 2025
* COUNTRY: 			Italy 

* NOTES: 			Compares predicted values to the observed values of the 
* 					2 fertility processes estimated. 
* 					Individual heterogeneity addchpd to the standard predicted 
* 					values form the using a random draw like in stochasitic 
* 					imputation. The pooled mean is obtained as in multiple 
* 					imputation by repeating the random draw 20 times for each 
* 					process. 
* 
* 					Run after "reg_fertility_IT.do"
********************************************************************************

**********************************************
* F1a - Having a child, in initial edu spell * 
**********************************************

* Overall 
use "$dir_data/F1a_sample", clear 

set seed 12345
gen rnd = runiform() 	
gen pred_dchpd = 0 
replace pred_dchpd = 1 if inrange(p,rnd,1)

keep if in_sample == 1 

twoway ///
(histogram pred_dchpd, color(red%30)) ///
(histogram dchpd, color(green%30)), ///
xtitle (Had child) ///
legend(lab(1 "Predicted") lab( 2 "Observed")) name(levels, replace) ///
title("Fertility, in initial education spell")
graph export ///
	"$dir_internal_validation/fertility/F1a_fertility_in_edu.jpg", ///
	replace width(2560) height(1440) quality(100)
	

* Year 
use "$dir_data/F1a_sample", clear

// construct multiple versions of the predicted outcome allowing for different 
// random draws 
forvalues i = 0/19 {
	local my_seed = 12345 + `i'  
    set seed `my_seed' 	
	gen rnd = runiform() 	
	gen pred_dchpd`i' = 0 
	replace pred_dchpd`i' = 1 if inrange(p,rnd,1)
	drop rnd
}

keep if in_sample == 1 

preserve

// for each iteration calculate the share that leave edu 
collapse (mean) dchpd pred_dchpd* [aw = dwt], by(stm)

order pred_dchpd*

// take the average across datasets 
egen pred_dchpd = rowmean(pred_dchpd0-pred_dchpd19)
replace stm = 2000 + stm 

twoway ///
(line pred_dchpd stm, sort color(green) legend(label(1 "Predicted"))) ///
(line dchpd stm, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "Observed"))), ///
title("Fertility in initial education spell") xtitle("Year") ytitle("Share")

graph export ///
	"$dir_internal_validation/fertility/F1a_fertility_in_edu_year.jpg", ///
	replace width(2560) height(1440) quality(100)
 
restore  
 
 
* Age
preserve

collapse (mean) dchpd pred_dchpd* [aw = dwt], by(dag)

order pred_dchpd*

egen pred_dchpd = rowmean(pred_dchpd0-pred_dchpd19)

twoway ///
(line pred_dchpd dag, sort color(green) legend(label(1 "Predicted"))) ///
(line dchpd dag, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "Observed"))), ///
title("Fertility in initial edu spell by age") xtitle("Age") ///
	ytitle("Share")

graph export ///
	"$dir_internal_validation/fertility/F1a_fertility_in_edu_age.jpg", ///
	replace width(2560) height(1440) quality(100)

restore


* Income 
preserve

collapse (mean) dchpd pred_dchpd* [aw = dwt], by(ydses_c5 stm)

order pred_dchpd*

egen pred_dchpd = rowmean(pred_dchpd0-pred_dchpd19)
replace stm = 2000 + stm 

twoway ///
(line pred_dchpd stm if ydses_c5 == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dchpd stm if ydses_c5 == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("First quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_dchpd stm if ydses_c5 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dchpd stm if ydses_c5 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Second quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_dchpd stm if ydses_c5 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dchpd stm if ydses_c5 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Third quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_dchpd stm if ydses_c5 == 4, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dchpd stm if ydses_c5 == 4, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph4) title("Forth quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_dchpd stm if ydses_c5 == 5, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dchpd stm if ydses_c5 == 5, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph5) title("Fifth quintile") xtitle("Year") ytitle("")

graph combine graph1 graph2 graph3 graph4 graph5, col(3) ///
	title("Fertility in initial edu by hh income")

graph export ///
	"$dir_internal_validation/fertility/F1a_fertility_in_edu_hh_income.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore


************************************************
* F1b - Having a child, left initial edu spell *
************************************************

* Overall 
use "$dir_data/F1b_sample", clear 

set seed 12345
gen rnd = runiform() 	
gen pred_dchpd = 0 
replace pred_dchpd = 1 if inrange(p,rnd,1)

keep if in_sample == 1 

twoway ///
(histogram pred_dchpd, color(red%30)) ///
(histogram dchpd, color(green%30)), ///
xtitle (Had child) ///
legend(lab(1 "Predicted") lab( 2 "Observed")) name(levels, replace) ///
title("Fertility left initial education spell")
graph export ///
	"$dir_internal_validation/fertility/F1b_fertility_left_edu.jpg", ///
	replace width(2560) height(1440) quality(100)
	

* Year 
use "$dir_data/F1b_sample", clear

// construct multiple versions of the predicted outcome allowing for different 
// random draws 
forvalues i = 0/19 {
	local my_seed = 12345 + `i'  
    set seed `my_seed' 	
	gen rnd = runiform() 	
	gen pred_dchpd`i' = 0 
	replace pred_dchpd`i' = 1 if inrange(p,rnd,1)
	drop rnd
}

keep if in_sample == 1 

preserve

collapse (mean) dchpd pred_dchpd* [aw = dwt], by(stm)

order pred_dchpd*

egen pred_dchpd = rowmean(pred_dchpd0-pred_dchpd19)

replace stm = 2000 + stm 

twoway ///
(line pred_dchpd stm, sort color(green) legend(label(1 "Predicted"))) ///
(line dchpd stm, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "Observed"))), ///
title("Fertility left initial edu by year") xtitle("Year") ytitle("Share")

graph export ///
"$dir_internal_validation/fertility/F1b_fertility_left_edu_year.jpg", ///
	replace width(2560) height(1440) quality(100)
 
restore  
 
 
* Age
preserve

collapse (mean) dchpd pred_dchpd* [aw = dwt], by(dag)

order pred_dchpd*

egen pred_dchpd = rowmean(pred_dchpd0-pred_dchpd19)

twoway ///
(line pred_dchpd dag, sort color(green) legend(label(1 "Predicted"))) ///
(line dchpd dag, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "Observed"))), ///
title("Fertility left initial edu spell by age") xtitle("Age") ///
	ytitle("Share")

graph export ///
	"$dir_internal_validation/fertility/F1b_fertility_left_edu_age.jpg", ///
	replace width(2560) height(1440) quality(100)

restore


* Income 
preserve

collapse (mean) dchpd pred_dchpd* [aw = dwt], by(ydses_c5 stm)

order pred_dchpd*

egen pred_dchpd = rowmean(pred_dchpd0-pred_dchpd19)

replace stm = 2000 + stm 

twoway ///
(line pred_dchpd stm if ydses_c5 == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dchpd stm if ydses_c5 == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("First quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_dchpd stm if ydses_c5 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dchpd stm if ydses_c5 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Second quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_dchpd stm if ydses_c5 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dchpd stm if ydses_c5 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Third quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_dchpd stm if ydses_c5 == 4, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dchpd stm if ydses_c5 == 4, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph4) title("Forth quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_dchpd stm if ydses_c5 == 5, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dchpd stm if ydses_c5 == 5, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph5) title("Fifth quintile") xtitle("Year") ytitle("")

graph combine graph1 graph2 graph3 graph4 graph5, col(3) ///
	title("Fertility left initial edu by hh income")

graph export ///
"$dir_internal_validation/fertility/F1b_fertility_left_edu_hh_income.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore


* Education
preserve

collapse (mean) dchpd pred_dchpd* [aw = dwt], by(deh_c3 stm)

order pred_dchpd*

egen pred_dchpd = rowmean(pred_dchpd0-pred_dchpd19)

replace stm = 2000 + stm 

twoway ///
(line pred_dchpd stm if deh_c3 == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dchpd stm if deh_c3 == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("High education") xtitle("Year") ytitle("")

twoway ///
(line pred_dchpd stm if deh_c3 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dchpd stm if deh_c3 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Medium education") xtitle("Year") ytitle("")

twoway ///
(line pred_dchpd stm if deh_c3 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dchpd stm if deh_c3 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Low education") xtitle("Year") ytitle("")

graph combine graph1 graph2 graph3, col(2) ///
	title("Fertility left initial edu by education")

graph export ///
	"$dir_internal_validation/fertility/F1b_fertility_left_edu_edu.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore


* Marital status 
preserve

collapse (mean) dchpd pred_dchpd* [aw = dwt], by(dcpst stm)

order pred_dchpd*

egen pred_dchpd = rowmean(pred_dchpd0-pred_dchpd19)

replace stm = 2000 + stm 

twoway ///
(line pred_dchpd stm if dcpst == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dchpd stm if dcpst == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("Partnered") xtitle("Year") ytitle("")

twoway ///
(line pred_dchpd stm if dcpst == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dchpd stm if dcpst == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Single") xtitle("Year") ytitle("")

twoway ///
(line pred_dchpd stm if dcpst == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dchpd stm if dcpst == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Previously partnered") xtitle("Year") ytitle("")

graph combine graph1 graph2 graph3, col(2) ///
	title("Fertility left initial edu by partnerhip status")

graph export ///
"$dir_internal_validation/fertility/F1b_fertility_left_edu_partnership.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore

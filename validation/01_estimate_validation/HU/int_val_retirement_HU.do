********************************************************************************
* PROJECT:  		ESPON 
* SECTION:			Retirement
* OBJECT: 			Internal validation
* AUTHORS:			Ashley Burdett 
* LAST UPDATE:		12/12/2024 
* COUNTRY: 			Hungary 

* NOTES: 			Compares predicted values to the observed values of the 
* 					2 retirement processes estimated. 
* 					Individual heterogeneity added to the standard predicted 
* 					values form the using a random draw like in stochasitic 
* 					imputation. The pooled mean is obtained as in multiple 
* 					imputation by repeating the random draw 20 times for each 
* 					process. 
* 
* 					Run after "reg_retirement_HU.do"
********************************************************************************

****************************
* R1a: Retirement - Single *
****************************

* Overall

use "$dir_data/R1a_sample", clear

set seed 12345
gen rnd = runiform() 	
gen pred_drtren = 0 
replace pred_drtren = 1 if inrange(p,rnd,1)

keep if in_sample == 1 

twoway ///
(histogram pred_drtren, color(red%30)) ///
(histogram drtren, color(green%30)), ///
xtitle (Retired) ///
legend(lab(1 "Predicted") lab( 2 "Observed")) name(levels, replace) ///
title("Retirement single")
graph export ///
	"$dir_internal_validation/retirement/R1a_retirement_single.jpg", ///
	replace width(2560) height(1440) quality(100)
	

* Year 
use "$dir_data/R1a_sample", clear

// construct multiple versions of the predicted outcome allowing for different 
// random draws 
forvalues i = 0/19 {
	local my_seed = 12345 + `i'  
    set seed `my_seed' 	
	gen rnd = runiform() 	
	gen pred_drtren`i' = 0 
	replace pred_drtren`i' = 1 if inrange(p,rnd,1)
	drop rnd
}

keep if in_sample == 1 

preserve

// for each iteration calculate the share that leave edu 
collapse (mean) drtren pred_drtren* [aw = dwt], by(stm)

order pred_drtren*

// take the average across datasets 
egen pred_drtren = rowmean(pred_drtren0-pred_drtren19)
replace stm = 2000 + stm 

twoway ///
(line pred_drtren stm, sort color(green) legend(label(1 "Predicted"))) ///
(line drtren stm, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "Observed"))), ///
title("Retirement single by year") xtitle("Year") ytitle("Share")

graph export ///
	"$dir_internal_validation/retirement/R1a_retirement_single_year.jpg", ///
	replace width(2560) height(1440) quality(100)
 
restore  
 
 
* Age
preserve

collapse (mean) drtren pred_drtren* [aw = dwt], by(dag)

order pred_drtren*

egen pred_drtren = rowmean(pred_drtren0-pred_drtren19)

twoway ///
(line pred_drtren dag, sort color(green) legend(label(1 "Predicted"))) ///
(line drtren dag, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "Observed"))), ///
title("Retirement single by age") xtitle("Age") ///
	ytitle("Share")

graph export ///
	"$dir_internal_validation/retirement/R1a_retirement_single_age.jpg", ///
	replace width(2560) height(1440) quality(100)

restore


* Income 
preserve

collapse (mean) drtren pred_drtren* [aw = dwt], by(ydses_c5 stm)

order pred_drtren*

egen pred_drtren = rowmean(pred_drtren0-pred_drtren19)

replace stm = 2000 + stm 

twoway ///
(line pred_drtren stm if ydses_c5 == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if ydses_c5 == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("First quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_drtren stm if ydses_c5 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if ydses_c5 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Second quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_drtren stm if ydses_c5 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if ydses_c5 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Third quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_drtren stm if ydses_c5 == 4, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if ydses_c5 == 4, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph4) title("Forth quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_drtren stm if ydses_c5 == 5, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if ydses_c5 == 5, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph5) title("Fifth quintile") xtitle("Year") ytitle("")

graph combine graph1 graph2 graph3 graph4 graph5, col(3) ///
	title("Retirement single by hh income")

graph export ///
"$dir_internal_validation/retirement/R1a_retirement_single_hh_income.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore


* Education 
preserve

collapse (mean) drtren pred_drtren* [aw = dwt], by(deh_c3 stm)

order pred_drtren*

egen pred_drtren = rowmean(pred_drtren0-pred_drtren19)

replace stm = 2000 + stm 

twoway ///
(line pred_drtren stm if deh_c3 == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if deh_c3 == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("High education") xtitle("Year") ytitle("")

twoway ///
(line pred_drtren stm if deh_c3 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if deh_c3 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Medium education") xtitle("Year") ytitle("")

twoway ///
(line pred_drtren stm if deh_c3 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if deh_c3 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Low education") xtitle("Year") ytitle("")

graph combine graph1 graph2 graph3, col(2) ///
	title("Retirement single by education")

graph export "$dir_internal_validation/retirement/R1a_retirement_single_edu.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore


*******************************
* R1b: Retirement - Partnered *
*******************************

* Overall
use "$dir_data/R1b_sample", clear

set seed 12345
gen rnd = runiform() 	
gen pred_drtren = 0 
replace pred_drtren = 1 if inrange(p,rnd,1)

keep if in_sample == 1 

twoway ///
(histogram pred_drtren, color(red%30)) ///
(histogram drtren, color(green%30)), ///
xtitle (Retired) ///
legend(lab(1 "Predicted") lab( 2 "Observed")) name(levels, replace) ///
title("Retirement partnered")
graph export ///
	"$dir_internal_validation/retirement/R1b_retirement_partnered.jpg", ///
	replace width(2560) height(1440) quality(100)
	

* Year 
use "$dir_data/R1b_sample", clear

forvalues i = 0/19 {
	local my_seed = 12345 + `i'  
    set seed `my_seed' 	
	gen rnd = runiform() 	
	gen pred_drtren`i' = 0 
	replace pred_drtren`i' = 1 if inrange(p,rnd,1)
	drop rnd
}

keep if in_sample == 1 

preserve

collapse (mean) drtren pred_drtren* [aw = dwt], by(stm)

order pred_drtren*

egen pred_drtren = rowmean(pred_drtren0-pred_drtren19)

replace stm = 2000 + stm 

twoway ///
(line pred_drtren stm, sort color(green) legend(label(1 "Predicted"))) ///
(line drtren stm, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "Observed"))), ///
title("Retirement partnered by year") xtitle("Year") ytitle("Share")

graph export ///
	"$dir_internal_validation/retirement/R1b_retirement_partnered_year.jpg", ///
	replace width(2560) height(1440) quality(100)
 
restore  
 
 
* Age
preserve

collapse (mean) drtren pred_drtren* [aw = dwt], by(dag)

order pred_drtren*

egen pred_drtren = rowmean(pred_drtren0-pred_drtren19)

twoway ///
(line pred_drtren dag, sort color(green) legend(label(1 "Predicted"))) ///
(line drtren dag, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "Observed"))), ///
title("Retirement partnered by age") xtitle("Age") ///
	ytitle("Share")

graph export ///
	"$dir_internal_validation/retirement/R1b_retirement_partnered_age.jpg", ///
	replace width(2560) height(1440) quality(100)

restore


* Income 
preserve

collapse (mean) drtren pred_drtren* [aw = dwt], by(ydses_c5 stm)

order pred_drtren*

egen pred_drtren = rowmean(pred_drtren0-pred_drtren19)

replace stm = 2000 + stm 

twoway ///
(line pred_drtren stm if ydses_c5 == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if ydses_c5 == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("First quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_drtren stm if ydses_c5 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if ydses_c5 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Second quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_drtren stm if ydses_c5 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if ydses_c5 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Third quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_drtren stm if ydses_c5 == 4, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if ydses_c5 == 4, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph4) title("Forth quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_drtren stm if ydses_c5 == 5, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if ydses_c5 == 5, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph5) title("Fifth quintile") xtitle("Year") ytitle("")

graph combine graph1 graph2 graph3 graph4 graph5, col(3) ///
	title("Retirement partnered by hh income")

graph export ///
"$dir_internal_validation/retirement/R1b_retirement_partnered_hh_income.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore


* Education 
preserve

collapse (mean) drtren pred_drtren* [aw = dwt], by(deh_c3 stm)

order pred_drtren*

egen pred_drtren = rowmean(pred_drtren0-pred_drtren19)

replace stm = 2000 + stm 

twoway ///
(line pred_drtren stm if deh_c3 == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if deh_c3 == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("High education") xtitle("Year") ytitle("")

twoway ///
(line pred_drtren stm if deh_c3 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if deh_c3 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Medium education") xtitle("Year") ytitle("")

twoway ///
(line pred_drtren stm if deh_c3 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if deh_c3 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Low education") xtitle("Year") ytitle("")

graph combine graph1 graph2 graph3, col(2) ///
	title("Retirement partnered by education")

graph export ///
	"$dir_internal_validation/retirement/R1b_retirement_partnered_edu.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore




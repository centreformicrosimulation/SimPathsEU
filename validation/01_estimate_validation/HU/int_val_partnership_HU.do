********************************************************************************
* PROJECT:  		ESPON 
* SECTION:			Partnership
* OBJECT: 			Internal validation
* AUTHORS:			Ashley Burdett 
* LAST UPDATE:		12/12/2024 
* COUNTRY: 			Hungary 

* NOTES: 			Compares predicted values to the observed values of the 
* 					partnership processes. 
* 					Individual heterogeneity added to the standard predicted 
* 					values form the using a random draw like in stochasitic 
* 					imputation. The pooled mean is obtained as in multiple 
* 					imputation by repeating the random draw 20 times for each 
* 					process. 
* 
* 					Run after "reg_partnership_HU.do"
********************************************************************************

****************************************************
* U1a: Partnership formation, in initial edu spell *
****************************************************

* Overall 
use "$dir_data/U1a_sample", clear 

set seed 12345
gen rnd = runiform() 	
gen pred_dcpen = 0 
replace pred_dcpen = 1 if inrange(p,rnd,1)

keep if in_sample == 1 

twoway ///
(histogram pred_dcpen, color(red%30)) ///
(histogram dcpen, color(green%30)), ///
xtitle (Formation) ///
legend(lab(1 "Predicted") lab( 2 "Observed")) name(levels, replace) ///
title("Partnership formation in initial education spell")
graph export ///
"$dir_internal_validation/partnership/U1a_partnership_formation_in_edu.jpg", ///
	replace width(2560) height(1440) quality(100)

	
* Year 
use "$dir_data/U1a_sample", clear 

forvalues i = 0/19 {
	local my_seed = 12345 + `i'  
    set seed `my_seed' 	
	gen rnd = runiform() 	
	gen pred_dcpen`i' = 0 
	replace pred_dcpen`i' = 1 if inrange(p,rnd,1)
	drop rnd
}

keep if in_sample == 1 

preserve

collapse (mean) dcpen pred_dcpen* [aw = dwt], by(stm)

order pred_dcpen*

egen pred_dcpen = rowmean(pred_dcpen0-pred_dcpen19)

replace stm = 2000 + stm 

twoway ///
(line pred_dcpen stm, sort color(green) legend(label(1 "Predicted"))) ///
(line dcpen stm, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "Observed"))), ///
title("Partnership formation in initial edu spell by year") ///
	xtitle("Year") ytitle("Share")

graph export ///
"$dir_internal_validation/partnership/U1a_partnership_formation_in_edu_year.jpg", ///
	replace width(2560) height(1440) quality(100)
 
restore  


* Gender 
preserve

collapse (mean) dcpen pred_dcpen* [aw = dwt], by(dgn stm)

order pred_dcpen*

egen pred_dcpen = rowmean(pred_dcpen0-pred_dcpen19)

replace stm = 2000 + stm 

twoway ///
(line pred_dcpen stm if dgn == 0, sort color(green) ///
	legend(label(1 "Predicted"))) ///
(line dcpen stm if dgn == 0, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Observed"))), ///
name(graph1) title("Females") xtitle("Year") ytitle("Share")

twoway ///
(line pred_dcpen stm if dgn == 1, sort color(green) ///
	legend(label(1 "Predicted"))) ///
(line dcpen stm if dgn == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Observed"))), ///
name(graph2) title("Males") xtitle("Year") ytitle("Share")

graph combine graph1 graph2, col(2) ///
	title("Partnership formation in initial edu by gender")

graph export ///
"$dir_internal_validation/partnership/U1a_partnership_formation_in_edu_gender.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all  

restore 
 
 
* Age
preserve

collapse (mean) dcpen pred_dcpen* [aw = dwt], by(dag)

order pred_dcpen*

egen pred_dcpen = rowmean(pred_dcpen0-pred_dcpen19)

twoway ///
(line pred_dcpen dag, sort color(green) legend(label(1 "Predicted"))) ///
(line dcpen dag, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "Observed"))), ///
title("Partnership formation in initial edu by age") xtitle("Age") ///
	ytitle("Share")

graph export ///
"$dir_internal_validation/partnership/U1a_partnership_formation_in_edu_age.jpg", ///
	replace width(2560) height(1440) quality(100)

restore


* Income 
preserve

collapse (mean) dcpen pred_dcpen* [aw = dwt], by(ydses_c5 stm)

order pred_dcpen*

egen pred_dcpen = rowmean(pred_dcpen0-pred_dcpen19)

replace stm = 2000 + stm 

twoway ///
(line pred_dcpen stm if ydses_c5 == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpen stm if ydses_c5 == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("First quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_dcpen stm if ydses_c5 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpen stm if ydses_c5 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Second quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_dcpen stm if ydses_c5 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpen stm if ydses_c5 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Third quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_dcpen stm if ydses_c5 == 4, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpen stm if ydses_c5 == 4, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph4) title("Forth quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_dcpen stm if ydses_c5 == 5, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpen stm if ydses_c5 == 5, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph5) title("Fifth quintile") xtitle("Year") ytitle("")

graph combine graph1 graph2 graph3 graph4 graph5, col(3) ///
	title("Partnership formation in initial edu  by hh income")

graph export ///
"$dir_internal_validation/partnership/U1a_partnership_formation_in_edu_hh_income.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore


******************************************************
* U1b: Partnership formation, left initial edu spell *
******************************************************

* Overall 
use "$dir_data/U1b_sample", clear 

set seed 12345
gen rnd = runiform() 	
gen pred_dcpen = 0 
replace pred_dcpen = 1 if inrange(p,rnd,1)

keep if in_sample == 1 

twoway ///
(histogram pred_dcpen, color(red%30)) ///
(histogram dcpen, color(green%30)), ///
xtitle (Formation) ///
legend(lab(1 "Predicted") lab( 2 "Observed")) name(levels, replace) ///
title("Partnership formation, left initial education spell")
graph export ///
	"$dir_internal_validation/partnership/U1b_partnership_formation_left_edu.jpg", ///
	replace width(2560) height(1440) quality(100)

	
* Year 
use "$dir_data/U1b_sample", clear 

forvalues i = 0/19 {
	local my_seed = 12345 + `i'  
    set seed `my_seed' 	
	gen rnd = runiform() 	
	gen pred_dcpen`i' = 0 
	replace pred_dcpen`i' = 1 if inrange(p,rnd,1)
	drop rnd
}

keep if in_sample == 1 

preserve

collapse (mean) dcpen pred_dcpen* [aw = dwt], by(stm)

order pred_dcpen*

egen pred_dcpen = rowmean(pred_dcpen0-pred_dcpen19)

replace stm = 2000 + stm 

twoway ///
(line pred_dcpen stm, sort color(green) legend(label(1 "Predicted"))) ///
(line dcpen stm, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "Observed"))), ///
title("Partnership formation left initial edu spell by year") ///
	xtitle("Year") ytitle("Share")

graph export ///
	"$dir_internal_validation/partnership/U1b_partnership_formation_left_edu_year.jpg", ///
	replace width(2560) height(1440) quality(100)
 
restore  


* Gender 
preserve

collapse (mean) dcpen pred_dcpen* [aw = dwt], by(dgn stm)

order pred_dcpen*

egen pred_dcpen = rowmean(pred_dcpen0-pred_dcpen19)

replace stm = 2000 + stm 

twoway ///
(line pred_dcpen stm if dgn == 0, sort color(green) ///
	legend(label(1 "Predicted"))) ///
(line dcpen stm if dgn == 0, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Observed"))), ///
name(graph1) title("Females") xtitle("Year") ytitle("Share")

twoway ///
(line pred_dcpen stm if dgn == 1, sort color(green) ///
	legend(label(1 "Predicted"))) ///
(line dcpen stm if dgn == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Observed"))), ///
name(graph2) title("Males") xtitle("Year") ytitle("Share")

graph combine graph1 graph2, col(2) ///
	title("Partnership formation left initial edu by gender")

graph export ///
"$dir_internal_validation/partnership/U1b_partnership_formation_left_edu_gender.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all  

restore 
 
 
* Age
preserve

collapse (mean) dcpen pred_dcpen* [aw = dwt], by(dag)

order pred_dcpen*

egen pred_dcpen = rowmean(pred_dcpen0-pred_dcpen19)

twoway ///
(line pred_dcpen dag, sort color(green) legend(label(1 "Predicted"))) ///
(line dcpen dag, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "Observed"))), ///
title("Partnership formation left initial edu by age") xtitle("Age") ///
	ytitle("Share")

graph export ///
"$dir_internal_validation/partnership/U1b_partnership_formation_left_edu_age.jpg", ///
	replace width(2560) height(1440) quality(100)

restore


* Income 
preserve

collapse (mean) dcpen pred_dcpen* [aw = dwt], by(ydses_c5 stm)

order pred_dcpen*

egen pred_dcpen = rowmean(pred_dcpen0-pred_dcpen19)

replace stm = 2000 + stm 

twoway ///
(line pred_dcpen stm if ydses_c5 == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpen stm if ydses_c5 == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("First quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_dcpen stm if ydses_c5 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpen stm if ydses_c5 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Second quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_dcpen stm if ydses_c5 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpen stm if ydses_c5 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Third quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_dcpen stm if ydses_c5 == 4, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpen stm if ydses_c5 == 4, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph4) title("Forth quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_dcpen stm if ydses_c5 == 5, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpen stm if ydses_c5 == 5, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph5) title("Fifth quintile") xtitle("Year") ytitle("")

graph combine graph1 graph2 graph3 graph4 graph5, col(3) ///
	title("Partnership formation left initial edu by hh income")

graph export ///
"$dir_internal_validation/partnership/U1b_partnership_formation_left_edu_hh_income.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore


**********************************************************
* U2b: Partnership termination, not in initial edu spell *
**********************************************************

* Overall 
use "$dir_data/U2b_sample", clear 

set seed 12345
gen rnd = runiform() 	
gen pred_dcpex = 0 
replace pred_dcpex = 1 if inrange(p,rnd,1)

keep if in_sample == 1 

twoway ///
(histogram pred_dcpex, color(red%30)) ///
(histogram dcpex, color(green%30)), ///
xtitle (Formation) ///
legend(lab(1 "Predicted") lab( 2 "Observed")) name(levels, replace) ///
title("Partnership termination, left initial education spell")
graph export ///
"$dir_internal_validation/partnership/U2b_partnership_termination_left_edu.jpg", ///
	replace width(2560) height(1440) quality(100)

	
* Year 
use "$dir_data/U2b_sample", clear 

forvalues i = 0/19 {
	local my_seed = 12345 + `i'  
    set seed `my_seed' 	
	gen rnd = runiform() 	
	gen pred_dcpex`i' = 0 
	replace pred_dcpex`i' = 1 if inrange(p,rnd,1)
	drop rnd
}

keep if in_sample == 1 

preserve

collapse (mean) dcpex pred_dcpex* [aw = dwt], by(stm)

order pred_dcpex*

egen pred_dcpex = rowmean(pred_dcpex0-pred_dcpex19)

replace stm = 2000 + stm 

twoway ///
(line pred_dcpex stm, sort color(green) legend(label(1 "Predicted"))) ///
(line dcpex stm, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "Observed"))), ///
title("Partnership termination, left initial edu spell by year") ///
	xtitle("Year") ytitle("Share")

graph export ///
"$dir_internal_validation/partnership/U2b_partnership_termination_left_edu_year.jpg", ///
	replace width(2560) height(1440) quality(100)
 
restore  
 
 
* Age
preserve

collapse (mean) dcpex pred_dcpex* [aw = dwt], by(dag)

order pred_dcpex*

egen pred_dcpex = rowmean(pred_dcpex0-pred_dcpex19)

twoway ///
(line pred_dcpex dag, sort color(green) legend(label(1 "Predicted"))) ///
(line dcpex dag, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "Observed"))), ///
title("Partnership termination left initial edu by age") xtitle("Age") ///
	ytitle("Share")

graph export ///
"$dir_internal_validation/partnership/U2b_partnership_termination_left_edu_age.jpg", ///
	replace width(2560) height(1440) quality(100)

restore


* Income 
preserve

collapse (mean) dcpex pred_dcpex* [aw = dwt], by(ydses_c5 stm)

order pred_dcpex*

egen pred_dcpex = rowmean(pred_dcpex0-pred_dcpex19)

replace stm = 2000 + stm 

twoway ///
(line pred_dcpex stm if ydses_c5 == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpex stm if ydses_c5 == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("First quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_dcpex stm if ydses_c5 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpex stm if ydses_c5 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Second quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_dcpex stm if ydses_c5 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpex stm if ydses_c5 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Third quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_dcpex stm if ydses_c5 == 4, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpex stm if ydses_c5 == 4, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph4) title("Forth quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_dcpex stm if ydses_c5 == 5, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpex stm if ydses_c5 == 5, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph5) title("Fifth quintile") xtitle("Year") ytitle("")

graph combine graph1 graph2 graph3 graph4 graph5, col(3) ///
	title("Partnership termination left initial edu by hh income")

graph export ///
"$dir_internal_validation/partnership/U2b_partnership_termination_left_edu_hh_income.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore


* Education
preserve

collapse (mean) dcpex pred_dcpex* [aw = dwt], by(deh_c3 stm)

order pred_dcpex*

egen pred_dcpex = rowmean(pred_dcpex0-pred_dcpex19)

replace stm = 2000 + stm 

twoway ///
(line pred_dcpex stm if deh_c3 == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpex stm if deh_c3 == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("High education") xtitle("Year") ytitle("")

twoway ///
(line pred_dcpex stm if deh_c3 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpex stm if deh_c3 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Medium education") xtitle("Year") ytitle("")

twoway ///
(line pred_dcpex stm if deh_c3 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpex stm if deh_c3 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Low education") xtitle("Year") ytitle("")

graph combine graph1 graph2 graph3, col(2) ///
	title("Termination partnership by education")

graph export ///
"$dir_internal_validation/partnership/U2b_partnership_termination_left_edu_edu.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore

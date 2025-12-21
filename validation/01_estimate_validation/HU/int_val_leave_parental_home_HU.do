********************************************************************************
* PROJECT:  		ESPON 
* SECTION:			Leave parental home
* OBJECT: 			Internal validation
* AUTHORS:			Ashley Burdett 
* LAST UPDATE:		12/12/2024 
* COUNTRY: 			Hungary 

* NOTES: 			Compares predicted values to the observed values of the 
* 					leaving the parental home process. 
* 					Individual heterogeneity added to the standard predicted 
* 					values form the using a random draw like in stochasitic 
* 					imputation. The pooled mean is obtained as in multiple 
* 					imputation by repeating the random draw 20 times for each 
* 					process. 
* 
* 					Run after "reg_leave_parental_home_HU.do"
********************************************************************************

************************************
* Process P1a: Leave Parental Home *
************************************

* Overall 
use "$dir_data/P1a_sample", clear 

set seed 12345
gen rnd = runiform() 	
gen pred_dlftphm = 0 
replace pred_dlftphm = 1 if inrange(p,rnd,1)

keep if in_sample == 1 

twoway ///
(histogram pred_dlftphm, color(red%30)) ///
(histogram dlftphm, color(green%30)), ///
xtitle (Leave) ///
legend(lab(1 "Predicted") lab( 2 "Observed")) name(levels, replace) ///
title("Leave the parental home")
graph export ///
"$dir_internal_validation/leave_parental_home/P1a_leave_parental_home.jpg", ///
	replace width(2560) height(1440) quality(100)
	

* Year 
use "$dir_data/P1a_sample", clear 

forvalues i = 0/19 {
	local my_seed = 12345 + `i'  
    set seed `my_seed' 	
	gen rnd = runiform() 	
	gen pred_dlftphm`i' = 0 
	replace pred_dlftphm`i' = 1 if inrange(p,rnd,1)
	drop rnd
}

keep if in_sample == 1 

preserve

collapse (mean) dlftphm pred_dlftphm* [aw = dwt], by(stm)

order pred_dlftphm*

egen pred_dlftphm = rowmean(pred_dlftphm0-pred_dlftphm19)

replace stm = 2000 + stm 

twoway ///
(line pred_dlftphm stm, sort color(green) legend(label(1 "Predicted"))) ///
(line dlftphm stm, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "Observed"))), ///
title("Leaving the parental home") xtitle("Year") ytitle("Share")

graph export ///
"$dir_internal_validation/leave_parental_home/P1a_leave_parental_home_year.jpg", ///
	replace width(2560) height(1440) quality(100)
 
restore  


* Gender 
preserve

collapse (mean) dlftphm pred_dlftphm* [aw = dwt], by(dgn stm)

order pred_dlftphm*

egen pred_dlftphm = rowmean(pred_dlftphm0-pred_dlftphm19)

replace stm = 2000 + stm 

twoway ///
(line pred_dlftphm stm if dgn == 0, sort color(green) ///
	legend(label(1 "Predicted"))) ///
(line dlftphm stm if dgn == 0, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Observed"))), ///
name(graph1) title("Females") xtitle("Year") ytitle("Share")

twoway ///
(line pred_dlftphm stm if dgn == 1, sort color(green) ///
	legend(label(1 "Predicted"))) ///
(line dlftphm stm if dgn == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Observed"))), ///
name(graph2) title("Males") xtitle("Year") ytitle("Share")

graph combine graph1 graph2, col(2) title("Leaving the parental home by gender")

graph export ///
"$dir_internal_validation/leave_parental_home/P1a_leave_parental_home_gender.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all  

restore 
 
 
* Age
preserve

collapse (mean) dlftphm pred_dlftphm* [aw = dwt], by(dag)

order pred_dlftphm*

egen pred_dlftphm = rowmean(pred_dlftphm0-pred_dlftphm19)

twoway ///
(line pred_dlftphm dag, sort color(green) legend(label(1 "Predicted"))) ///
(line dlftphm dag, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "Observed"))), ///
title("Leaving the parental home by age") xtitle("Age") ///
	ytitle("Share")

graph export ///
"$dir_internal_validation/leave_parental_home/P1a_leave_parental_home_age.jpg", ///
	replace width(2560) height(1440) quality(100)

restore


* Income 
preserve

collapse (mean) dlftphm pred_dlftphm* [aw = dwt], by(ydses_c5 stm)

order pred_dlftphm*

egen pred_dlftphm = rowmean(pred_dlftphm0-pred_dlftphm19)

replace stm = 2000 + stm 

twoway ///
(line pred_dlftphm stm if ydses_c5 == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dlftphm stm if ydses_c5 == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("First quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_dlftphm stm if ydses_c5 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dlftphm stm if ydses_c5 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Second quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_dlftphm stm if ydses_c5 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dlftphm stm if ydses_c5 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Third quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_dlftphm stm if ydses_c5 == 4, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dlftphm stm if ydses_c5 == 4, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph4) title("Forth quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_dlftphm stm if ydses_c5 == 5, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dlftphm stm if ydses_c5 == 5, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph5) title("Fifth quintile") xtitle("Year") ytitle("")

graph combine graph1 graph2 graph3 graph4 graph5, col(3) ///
	title("Leaving the parental home by hh income")

graph export ///
"$dir_internal_validation/leave_parental_home/P1a_leave_parental_home_hh_income.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore


* Education 
preserve

collapse (mean) dlftphm pred_dlftphm* [aw = dwt], by(deh_c3 stm)

order pred_dlftphm*

egen pred_dlftphm = rowmean(pred_dlftphm0-pred_dlftphm19)

replace stm = 2000 + stm 

twoway ///
(line pred_dlftphm stm if deh_c3 == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dlftphm stm if deh_c3 == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("High education") xtitle("Year") ytitle("")

twoway ///
(line pred_dlftphm stm if deh_c3 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dlftphm stm if deh_c3 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Medium education") xtitle("Year") ytitle("")

twoway ///
(line pred_dlftphm stm if deh_c3 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dlftphm stm if deh_c3 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Low education") xtitle("Year") ytitle("")

graph combine graph1 graph2 graph3, col(2) ///
	title("Leaving the parental home by education")

graph export ///
"$dir_internal_validation/leave_parental_home/P1a_leave_parental_home_education.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore



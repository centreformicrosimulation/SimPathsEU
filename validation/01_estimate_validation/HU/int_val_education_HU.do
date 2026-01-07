********************************************************************************
* PROJECT:  		ESPON 
* SECTION:			Education
* OBJECT: 			Internal validation
* AUTHORS:			Ashley Burdett 
* LAST UPDATE:		12/12/2024 
* COUNTRY: 			Hungary 

* NOTES: 			Compares predicted values to the observed values of the 
* 					3 education processes estimated. 
* 					Individual heterogeneity added to the standard predicted 
* 					values form the using a random draw like in stochasitic 
* 					imputation. The pooled mean is obtained as in multiple 
* 					imputation by repeating the random draw 20 times for each 
* 					process. 
* 
* 					Run after "reg_education_HU.do"
********************************************************************************

*******************************************************
* E1a: Probability of Leaving Initial Education Spell *
*******************************************************

* Year 
use "$dir_data/E1a_sample", clear

// construct multiple versions of the predicted outcome allowing for different 
// random draws 
forvalues i = 0/19 {
	local my_seed = 12345 + `i'  
    set seed `my_seed' 	
	gen rnd = runiform() 	
	gen pred_ded`i' = 0 
	replace pred_ded`i' = 1 if inrange(p,rnd,1)
	drop rnd
}

keep if in_sample == 1 

preserve

// for each iteration calculate the share that leave edu 
collapse (mean) ded pred_ded* [aw = dwt], by(stm)

order pred_ded*

// take the average across datasets 
egen pred_ded = rowmean(pred_ded0-pred_ded19)
replace stm = 2000 + stm 

twoway ///
(line pred_ded stm, sort color(green) legend(label(1 "Predicted"))) ///
(line ded stm, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "Observed"))), ///
title("Continues in initial education spell") xtitle("Year") ytitle("Share")

graph export "$dir_internal_validation/education/E1a_continues_edu_year.jpg", ///
	replace width(2560) height(1440) quality(100)
 
restore  


* Gender 
preserve
collapse (mean) ded pred_ded* [aw = dwt], by(dgn stm)

order pred_ded*

egen pred_ded = rowmean(pred_ded0-pred_ded19)

replace stm = 2000 + stm 

twoway ///
(line pred_ded stm if dgn == 0, sort color(green) ///
	legend(label(1 "Predicted"))) ///
(line ded stm if dgn == 0, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Observed"))), ///
name(graph1) title("Females") xtitle("Year") ytitle("Share")

twoway ///
(line pred_ded stm if dgn == 1, sort color(green) ///
	legend(label(1 "Predicted"))) ///
(line ded stm if dgn == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Observed"))), ///
name(graph2) title("Males") xtitle("Year") ytitle("Share")

graph combine graph1 graph2, col(2) title("Continues in initial education")

graph export "$dir_internal_validation/education/E1a_continues_edu_gender.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all  

restore
 
 
* Age
preserve

collapse (mean) ded pred_ded* [aw = dwt], by(dag)

order pred_ded*

egen pred_ded = rowmean(pred_ded0-pred_ded19)

twoway ///
(line pred_ded dag, sort color(green) legend(label(1 "Predicted"))) ///
(line ded dag, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "Observed"))), ///
title("Continues in initial education spell by age") xtitle("Age") ///
	ytitle("Share")

graph export "$dir_internal_validation/education/E1a_continues_edu_age.jpg", ///
	replace width(2560) height(1440) quality(100)

restore


* Income 
preserve

collapse (mean) ded pred_ded* [aw = dwt], by(ydses_c5 stm)

order pred_ded*

egen pred_ded = rowmean(pred_ded0-pred_ded19)

replace stm = 2000 + stm 

twoway ///
(line pred_ded stm if ydses_c5 == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line ded stm if ydses_c5 == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("First quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_ded stm if ydses_c5 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line ded stm if ydses_c5 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Second quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_ded stm if ydses_c5 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line ded stm if ydses_c5 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Third quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_ded stm if ydses_c5 == 4, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line ded stm if ydses_c5 == 4, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph4) title("Forth quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_ded stm if ydses_c5 == 5, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line ded stm if ydses_c5 == 5, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph5) title("Fifth quintile") xtitle("Year") ytitle("")

graph combine graph1 graph2 graph3 graph4 graph5, col(3) ///
	title("Continues in initial education by hh income")

graph export ///
	"$dir_internal_validation/education/E1a_continues_edu_hh_income.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore


* Martial status 
preserve

collapse (mean) ded pred_ded* [aw = dwt], by(dcpst stm)

order pred_ded*

egen pred_ded = rowmean(pred_ded0-pred_ded19)

replace stm = 2000 + stm 

twoway ///
(line pred_ded stm if dcpst == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line ded stm if dcpst == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("Partnered") xtitle("Year") ytitle("")

twoway ///
(line pred_ded stm if dcpst == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line ded stm if dcpst == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Single") xtitle("Year") ytitle("")

twoway ///
(line pred_ded stm if dcpst == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line ded stm if dcpst == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Previously partnered") xtitle("Year") ytitle("")

graph combine graph1 graph2 graph3, col(2) ///
	title("Continues in initial education by partnership status")

graph export ///
	"$dir_internal_validation/education/E1a_continues_edu_partnership.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore


**********************************************
* E1b: Probability of Returning to Education *
**********************************************

* Year
use "$dir_data/E1b_sample", clear

forvalues i = 0/19 {
	local my_seed = 12345 + `i'  
    set seed `my_seed' 	
	gen rnd = runiform() 	
	gen pred_der`i' = 0 
	replace pred_der`i' = 1 if inrange(p,rnd,1)
	drop rnd
}

keep if in_sample == 1 

preserve

collapse (mean) der pred_der* [aw = dwt], by(stm)

order pred_der*

egen pred_der = rowmean(pred_der0-pred_der19)
replace stm = 2000 + stm 

twoway ///
(line pred_der stm, sort color(green) legend(label(1 "Predicted"))) ///
(line der stm, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "Observed"))), ///
title("Returns to education") xtitle("Year") ytitle("Share")

graph export "$dir_internal_validation/education/E1b_returns_edu.jpg", ///
	replace width(2560) height(1440) quality(100)
 
restore  


* Gender 
preserve

collapse (mean) der pred_der* [aw = dwt], by(dgn stm)

order pred_der*

egen pred_der = rowmean(pred_der0-pred_der19)

replace stm = 2000 + stm 

twoway ///
(line pred_der stm if dgn == 0, sort color(green) ///
	legend(label(1 "Predicted"))) ///
(line der stm if dgn == 0, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Observed"))), ///
name(graph1) title("Females") xtitle("Year") ytitle("Share")

twoway ///
(line pred_der stm if dgn == 1, sort color(green) ///
	legend(label(1 "Predicted"))) ///
(line der stm if dgn == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Observed"))), ///
name(graph2) title("Males") xtitle("Year") ytitle("Share")

graph combine graph1 graph2, col(2) title("Returns to education")

graph export ///
	"$dir_internal_validation/education/E1b_returns_edu_gender.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all  

restore
 
 
* Age
preserve

collapse (mean) der pred_der* [aw = dwt], by(dag)

order pred_der*

egen pred_der = rowmean(pred_der0-pred_der19)

twoway ///
(line pred_der dag, sort color(green) legend(label(1 "Predicted"))) ///
(line der dag, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Observed"))), ///
title("Returns to education spell by age") xtitle("Age") ytitle("Share")

graph export "$dir_internal_validation/education/E1b_returns_edu_age.jpg", ///
	replace width(2560) height(1440) quality(100)

restore


* Income 
preserve

collapse (mean) der pred_der* [aw = dwt], by(ydses_c5 stm)

order pred_der*

egen pred_der = rowmean(pred_der0-pred_der19)
replace stm = 2000 + stm 

twoway ///
(line pred_der stm if ydses_c5 == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line der stm if ydses_c5 == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("First quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_der stm if ydses_c5 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line der stm if ydses_c5 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Second quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_der stm if ydses_c5 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line der stm if ydses_c5 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Third quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_der stm if ydses_c5 == 4, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line der stm if ydses_c5 == 4, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph4) title("Forth quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_der stm if ydses_c5 == 5, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line der stm if ydses_c5 == 5, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph5) title("Fifth quintile") xtitle("Year") ytitle("")

graph combine graph1 graph2 graph3 graph4 graph5, col(3) ///
	title("Returns to education by hh income")

graph export ///
"$dir_internal_validation/education/E1b_returns_edu_hh_income.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore


* Martial status 
preserve

collapse (mean) der pred_der* [aw = dwt], by(dcpst stm)

order pred_der*

egen pred_der = rowmean(pred_der0-pred_der19)

replace stm = 2000 + stm 

twoway ///
(line pred_der stm if dcpst == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line der stm if dcpst == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("Partnered") xtitle("Year") ytitle("")

twoway ///
(line pred_der stm if dcpst == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line der stm if dcpst == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Single") xtitle("Year") ytitle("")

twoway ///
(line pred_der stm if dcpst == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line der stm if dcpst == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Previously partnered") xtitle("Year") ytitle("")

graph combine graph1 graph2 graph3, col(2) ///
	title("Returns to education by partnership status")

graph export ///
	"$dir_internal_validation/education/E1b_returns_edu_parntership.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore


*************************************************
* E2a Educational Level After Leaving Education *
*************************************************

* Overall 
use "$dir_data/E2a_sample", clear

sum p1-p3 // inspect negative values  

gen p1p2 = p1 + p2 // create cdf

gen rnd = runiform()
gen edu_pred = cond((rnd < p1), 1, cond(rnd < p1p2, 2, 3)) 

twoway (histogram edu_pred if in_sample == 1, color(red%30)) ///
	(histogram deh_c3_recoded if in_sample == 1, color(green%30)), ///
	xtitle (Education level) ///
	legend(lab(1 "Predicted") lab( 2 "Observed")) name(levels, replace) ///
	title("Level of education when leave initial education spell")
graph export "$dir_internal_validation/education/E2a_edu_attainment.jpg", ///
	replace width(2560) height(1440) quality(100)
	
	
* Year 
use "$dir_data/E2a_sample", clear

sum p1-p3 

gen p1p2 = p1 + p2 

forvalues i = 0/19 {
	local my_seed = 12345 + `i'  
    set seed `my_seed' 	
	gen rnd = runiform() 	
	gen edu_pred`i' = cond((rnd < p1), 1, cond(rnd < p1p2, 2, 3)) 
	gen pred_edu_low`i' = (edu_pred`i' == 1)
	gen pred_edu_med`i' = (edu_pred`i' == 2)
	gen pred_edu_high`i' = (edu_pred`i' == 3)
	drop rnd
}

keep if in_sample == 1 

gen edu_low = (deh_c3_recoded == 1)
gen edu_med = (deh_c3_recoded == 2)
gen edu_high = (deh_c3_recoded == 3)

preserve 

collapse (mean) edu_low edu_med edu_high pred_edu_low* pred_edu_med* ///
	pred_edu_high* [aw = dwt], by(stm)

order pred_edu_low* pred_edu_med* pred_edu_high*	
	
egen pred_edu_low = rowmean(pred_edu_low0-pred_edu_low19)
egen pred_edu_med = rowmean(pred_edu_med0-pred_edu_med19)
egen pred_edu_high = rowmean(pred_edu_high0-pred_edu_high19)

replace stm = 2000 + stm 

twoway ///
(line pred_edu_low stm, sort color(green) legend(label(1 "Pred"))) ///
(line edu_low stm, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("Low education") xtitle("Year") ytitle("")

twoway ///
(line pred_edu_med stm, sort color(green) legend(label(1 "Pred"))) ///
(line edu_med stm, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Medium education") xtitle("Year") ytitle("")

twoway ///
(line pred_edu_high stm, sort color(green) legend(label(1 "Pred"))) ///
(line edu_high stm, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("High education") xtitle("Year") ytitle("")

graph combine graph1 graph2 graph3, col(2) ///
	title("Education attainment of those leaving education")
graph export ///
"$dir_internal_validation/education/E2a_edu_attainment_year.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore


* Gender 
preserve 

collapse (mean) edu_low edu_med edu_high pred_edu_low* pred_edu_med* ///
	pred_edu_high* [aw = dwt], by(stm dgn)

order pred_edu_low* pred_edu_med* pred_edu_high*		
	
egen pred_edu_low = rowmean(pred_edu_low0-pred_edu_low19)
egen pred_edu_med = rowmean(pred_edu_med0-pred_edu_med19)
egen pred_edu_high = rowmean(pred_edu_high0-pred_edu_high19)

replace stm = 2000 + stm 

twoway ///
(line pred_edu_low stm if dgn == 0, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line edu_low stm if dgn == 0, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("Low education, females") xtitle("Year") ytitle("")

twoway ///
(line pred_edu_med stm if dgn == 0, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line edu_med stm if dgn == 0, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Medium education, females") xtitle("Year") ytitle("")

twoway ///
(line pred_edu_high stm if dgn == 0, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line edu_high stm if dgn == 0, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("High education, females") xtitle("Year") ytitle("")

twoway ///
(line pred_edu_low stm if dgn == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line edu_low stm if dgn == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph4) title("Low education, males") xtitle("Year") ytitle("")

twoway ///
(line pred_edu_med stm if dgn == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line edu_med stm if dgn == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph5) title("Medium education, males") xtitle("Year") ytitle("")

twoway ///
(line pred_edu_high stm if dgn == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line edu_high stm if dgn == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph6) title("High education, males") xtitle("Year") ytitle("")

graph combine graph1 graph2 graph3 graph4 graph5 graph6, col(3) ///
	title("Education attainment of those leaving education by gender")
graph export ///
"$dir_internal_validation/education/E2a_edu_attainment_gender.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore
	
	
* Age
preserve 

collapse (mean) edu_low edu_med edu_high pred_edu_low* pred_edu_med* ///
	pred_edu_high* [aw = dwt], by(dag)

order pred_edu_low* pred_edu_med* pred_edu_high*		
	
egen pred_edu_low = rowmean(pred_edu_low0-pred_edu_low19)
egen pred_edu_med = rowmean(pred_edu_med0-pred_edu_med19)
egen pred_edu_high = rowmean(pred_edu_high0-pred_edu_high19)

twoway ///
(line pred_edu_low dag, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line edu_low dag, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("Low education") xtitle("Age") ytitle("")

twoway ///
(line pred_edu_med dag, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line edu_med dag, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Medium education") xtitle("Age") ytitle("")

twoway ///
(line pred_edu_high dag, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line edu_high dag, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("High education") xtitle("Age") ytitle("")

graph combine graph1 graph2 graph3, col(2) ///
	title("Education attainment of those leaving education by age")
graph export ///
"$dir_internal_validation/education/E2a_edu_attainment_age.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore


* Income  
preserve 

collapse (mean) edu_low edu_med edu_high pred_edu_low* pred_edu_med* ///
	pred_edu_high* [aw = dwt], by(stm ydses_c5)

order pred_edu_low* pred_edu_med* pred_edu_high*	
	
egen pred_edu_low = rowmean(pred_edu_low0-pred_edu_low19)
egen pred_edu_med = rowmean(pred_edu_med0-pred_edu_med19)
egen pred_edu_high = rowmean(pred_edu_high0-pred_edu_high19)

replace stm = 2000 + stm 

twoway ///
(line pred_edu_low stm if ydses_c5 == 1, sort color(green) ///
	legend(label(1 "L Pred"))) ///
(line edu_low stm if ydses_c5 == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "L Obs"))) ///
(line pred_edu_med stm if ydses_c5 == 1, sort color(red) ///
	legend(label(3 "M Pred"))) ///
(line edu_med stm if ydses_c5 == 1, sort color(red) color(red%20) ///
	lpattern(dash) legend(label(4 "M Obs")))	///
(line pred_edu_high stm if ydses_c5 == 1, sort color(blue) ///
	legend(label(5 "H Pred"))) ///
(line edu_high stm if ydses_c5 == 1, sort color(blue) color(blue%20) ///
	lpattern(dash) legend(label(6 "H Obs"))), ///
name(graph1) title("First quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_edu_low stm if ydses_c5 == 2, sort color(green) ///
	legend(label(1 "L Pred"))) ///
(line edu_low stm if ydses_c5 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "L Obs"))) ///
(line pred_edu_med stm if ydses_c5 == 2, sort color(red) ///
	legend(label(3 "M Pred"))) ///
(line edu_med stm if ydses_c5 == 2, sort color(red) color(red%20) ///
	lpattern(dash) legend(label(4 "M Obs")))	///
(line pred_edu_high stm if ydses_c5 == 2, sort color(blue) ///
	legend(label(5 "H Pred"))) ///
(line edu_high stm if ydses_c5 == 2, sort color(blue) color(blue%20) ///
	lpattern(dash) legend(label(6 "H Obs"))), ///
name(graph2) title("Second quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_edu_low stm if ydses_c5 == 3, sort color(green) ///
	legend(label(1 "L Pred"))) ///
(line edu_low stm if ydses_c5 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "L Obs"))) ///
(line pred_edu_med stm if ydses_c5 == 3, sort color(red) ///
	legend(label(3 "M Pred"))) ///
(line edu_med stm if ydses_c5 == 3, sort color(red) color(red%20) ///
	lpattern(dash) legend(label(4 "M Obs")))	///
(line pred_edu_high stm if ydses_c5 == 3, sort color(blue) ///
	legend(label(5 "H Pred"))) ///
(line edu_high stm if ydses_c5 == 3, sort color(blue) color(blue%20) ///
	lpattern(dash) legend(label(6 "H Obs"))), ///
name(graph3) title("Third quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_edu_low stm if ydses_c5 == 4, sort color(green) ///
	legend(label(1 "L Pred"))) ///
(line edu_low stm if ydses_c5 == 4, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "L Obs"))) ///
(line pred_edu_med stm if ydses_c5 == 4, sort color(red) ///
	legend(label(3 "M Pred"))) ///
(line edu_med stm if ydses_c5 == 4, sort color(red) color(red%20) ///
	lpattern(dash) legend(label(4 "M Obs")))	///
(line pred_edu_high stm if ydses_c5 == 4, sort color(blue) ///
	legend(label(5 "H Pred"))) ///
(line edu_high stm if ydses_c5 == 4, sort color(blue) color(blue%20) ///
	lpattern(dash) legend(label(6 "H Obs"))), ///
name(graph4) title("Fourth quintile") xtitle("Year") ytitle("")

twoway ///
(line pred_edu_low stm if ydses_c5 == 5, sort color(green) ///
	legend(label(1 "L Pred"))) ///
(line edu_low stm if ydses_c5 == 5, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "L Obs"))) ///
(line pred_edu_med stm if ydses_c5 == 5, sort color(red) ///
	legend(label(3 "M Pred"))) ///
(line edu_med stm if ydses_c5 == 5, sort color(red) color(red%20) ///
	lpattern(dash) legend(label(4 "M Obs")))	///
(line pred_edu_high stm if ydses_c5 == 5, sort color(blue) ///
	legend(label(5 "H Pred"))) ///
(line edu_high stm if ydses_c5 == 5, sort color(blue) color(blue%20) ///
	lpattern(dash) legend(label(6 "H Obs"))), ///
name(graph5) title("Fifth quintile") xtitle("Year") ytitle("")

graph combine graph1 graph2 graph3 graph4 graph5, col(3) ///
	title("Education attainment of those leaving education by hh income")
graph export ///
"$dir_internal_validation/education/E2a_edu_attainment_hh_income.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore 

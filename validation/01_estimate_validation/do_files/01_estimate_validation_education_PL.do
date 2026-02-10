********************************************************************************
* PROJECT:  		SimPath EU  
* SECTION:			Education
* OBJECT: 			Estimate validation 
* AUTHORS:			Ashley Burdett, Aleksandra Kolndrekaj  
* LAST UPDATE:		Jan 2026
* COUNTRY: 			Poland  
********************************************************************************
* NOTES: 			Compares predicted values to the observed values of the 
* 					3 education processes estimated. 
* 					Individual heterogeneity added to the standard predicted 
* 					values form the using a random draw like in stochasitic 
* 					imputation. The pooled mean is obtained as in multiple 
* 					imputation by repeating the random draw 20 times for each 
* 					process. 
* 
* 					Run after "reg_education_PL.do"
********************************************************************************


*****************************************
* E1a: Probability of Leaving Education *
*****************************************


* Share by year 
use "$dir_data/E1a_sample", clear

sort idperson swv 

forvalues i = 0/19 {
	local my_seed = 12345 + `i'  
	set seed `my_seed' 		
	gen rnd = runiform() 		
	gen pred_Dst`i' = 0 	
	replace pred_Dst`i' = 1 if inrange(p,rnd,1)	
	drop rnd
}

keep if in_sample == 1 

preserve

collapse (mean) Dst pred_Dst* [aw = dwt], by(stm)

order pred_Dst*

egen pred_Dst = rowmean(pred_Dst0-pred_Dst19)
replace stm = 2000 + stm 

twoway ///
(line pred_Dst stm, sort color(green) legend(label(1 "Predictions"))) ///
(line Dst stm, sort color(green) color(green%50) lpattern(dash) ///
	legend(label(2 "SILC"))), ///
	title("Continues in Education") ///
	xtitle("Year", size(small)) ///
	ytitle("Share", size(small)) ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${e1a_if_condition}).", size(vsmall))

graph export ///
"$dir_internal_validation/education/int_validation_${country}_E1a_continues_edu_ts_16_29_both.jpg", ///
	replace width(2560) height(1440) quality(100)
 
restore  


* Share by year by gender 
preserve
collapse (mean) Dst pred_Dst* [aw = dwt], by(dgn stm)

order pred_Dst*

egen pred_Dst = rowmean(pred_Dst0-pred_Dst19)

replace stm = 2000 + stm 

twoway ///
(line pred_Dst stm if dgn == 0, sort color(green) ///
	legend(label(1 "Predictions"))) ///
(line Dst stm if dgn == 0, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
	name(graph1) ///
	title("Females") ///
	xtitle("Year", size(small)) ///
	ytitle("Share", size(small)) ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) 

twoway ///
(line pred_Dst stm if dgn == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line Dst stm if dgn == 1, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph2) ///
	title("Males") ///
	xtitle("Year", size(small)) ///
	ytitle("Share", size(small)) ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) 
		
	
grc1leg graph1 graph2 ,  ///
	title("Continues in Education") ///
	legendfrom(graph1) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${e1a_if_condition}).", size(vsmall))
	
graph export ///
	"$dir_internal_validation/education/int_validation_${country}_E1a_continues_edu_ts_16_29_gender.jpg", ///
	replace width(2560) height(1440) quality(100)
	
graph drop _all  

restore
 
 
* Age 
preserve

collapse (mean) Dst pred_Dst* [aw = dwt], by(dag)

order pred_Dst*

egen pred_Dst = rowmean(pred_Dst0-pred_Dst19)

twoway ///
(line pred_Dst dag, sort color(green) legend(label(1 "Predictions"))) ///
(line Dst dag, sort color(green) color(green%40) lpattern(dash) ///
	legend(label(2 "SILC"))), ///
title("Continues in Education") ///
	subtitle("Share by age") ///
	xtitle("Age", size(small)) ///
	ytitle("Share", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${e1a_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/education/int_validation_${country}_E1a_continues_edu_share_age.jpg", ///
	replace width(2560) height(1440) quality(100)
	
restore


* Income 
preserve

collapse (mean) Dst pred_Dst* [aw = dwt], by(ydses_c5 stm)

order pred_Dst*

egen pred_Dst = rowmean(pred_Dst0-pred_Dst19)

replace stm = 2000 + stm 

twoway ///
(line pred_Dst stm if ydses_c5 == 1, sort color(green) ///
	legend(label(1 "Predictions"))) ///
(line Dst stm if ydses_c5 == 1, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
	name(graph1) ///
	title("First quintile") ///
	xtitle("Year", size(small)) /// 
	ytitle("", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_Dst stm if ydses_c5 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line Dst stm if ydses_c5 == 2, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph2) ///
	title("Second quintile") ///
	xtitle("Year", size(small)) /// 
	ytitle("", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_Dst stm if ydses_c5 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line Dst stm if ydses_c5 == 3, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph3) ///
	title("Third quintile") ///
	xtitle("Year", size(small)) /// 
	ytitle("", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_Dst stm if ydses_c5 == 4, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line Dst stm if ydses_c5 == 4, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph4) ///
	title("Fourth quintile") ///
	xtitle("Year", size(small)) /// 
	ytitle("", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_Dst stm if ydses_c5 == 5, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line Dst stm if ydses_c5 == 5, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph5) ///
	title("Fifth quintile") ///
	xtitle("Year", size(small)) ///
	ytitle("", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

grc1leg graph1 graph2 graph3 graph4 graph5,  ///
	title("Continues in Education") ///
	subtitle("By hh income quintile") ///
	legendfrom(graph1) rows(2) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${e1a_if_condition}).", size(vsmall))

graph export ///
"$dir_internal_validation/education/int_validation_${country}_E1a_continues_edu_ts_16_29_both_income.jpg", ///	
	replace width(2560) height(1440) quality(100)
	
graph drop _all 	
	
restore


* Partnership status 
preserve

collapse (mean) Dst pred_Dst* [aw = dwt], by(dcpst stm)

order pred_Dst*

egen pred_Dst = rowmean(pred_Dst0-pred_Dst19)

replace stm = 2000 + stm 

twoway ///
(line pred_Dst stm if dcpst == 1, sort color(green) ///
	legend(label(1 "Predictions"))) ///
(line Dst stm if dcpst == 1, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
	name(graph1) ///
	title("Partnered") ///
	xtitle("Year", size(small)) ///
	ytitle("", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_Dst stm if dcpst == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line Dst stm if dcpst == 2, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph2) ///
	title("Single") ///
	xtitle("Year", size(small)) /// 
	ytitle("", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

grc1leg graph1 graph2 ,  ///
	title("Continues in Education") ///
	subtitle("By partnership status") ///
	legendfrom(graph1) rows(1) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${e1a_if_condition}).", size(vsmall))
	
graph export ///
"$dir_internal_validation/education/int_validation_${country}_E1a_continues_edu_ts_16_29_both_partnership.jpg", ///	
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
(line pred_der stm, sort color(green) legend(label(1 "Predictions"))) ///
(line der stm, sort color(green) color(green%50) lpattern(dash) ///
	legend(label(2 "SILC"))), ///
	title("Returns to Education") ///
	xtitle("Year", size(small)) ///
	ytitle("Share", size(small)) ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${e1b_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/education/int_validation_${country}_E1b_returns_edu_ts_both.jpg", ///
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
	legend(label(1 "Predictions"))) ///
(line der stm if dgn == 0, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
	name(graph1) ///
	title("Females") ///
	xtitle("Year", size(small)) ///
	ytitle("Share", size(small)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_der stm if dgn == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line der stm if dgn == 1, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph2) ///
	title("Males") ///
	xtitle("Year", size(small)) ///
	ytitle("Share", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

grc1leg graph1 graph2, ///
	title("Returns to education") ///
	legendfrom(graph1) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${e1b_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/education/int_validation_${country}_E1b_returns_edu_ts_gender.jpg", ///	
replace width(2560) height(1440) quality(100)
	
graph drop _all  

restore
 
 
* Age
preserve

collapse (mean) der pred_der* [aw = dwt], by(dag)

order pred_der*

egen pred_der = rowmean(pred_der0-pred_der19)

twoway ///
(line pred_der dag, sort color(green) legend(label(1 "Predictions"))) ///
(line der dag, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
	title("Returns to Education") ///
	subtitle("Share by age") ///
	xtitle("Age", size(small)) ///
	ytitle("Share", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${e1b_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/education/int_validation_${country}_E1b_returns_edu_share_age.jpg", ///	
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
	legend(label(1 "Predictions"))) ///
(line der stm if ydses_c5 == 1, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
	name(graph1) ///
	title("First quintile") ///
	xtitle("Year", size(small)) ///
	ytitle("", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_der stm if ydses_c5 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line der stm if ydses_c5 == 2, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph2) ///
	title("Second quintile") ///
	xtitle("Year", size(small)) ///
	ytitle("", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_der stm if ydses_c5 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line der stm if ydses_c5 == 3, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph3) title("Third quintile") ///
	xtitle("Year", size(small)) ///
	ytitle("", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_der stm if ydses_c5 == 4, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line der stm if ydses_c5 == 4, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph4) ///
	title("Fourth quintile") ///
	xtitle("Year", size(small)) ///
	ytitle("", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_der stm if ydses_c5 == 5, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line der stm if ydses_c5 == 5, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph5) ///
	title("Fifth quintile") ///
	xtitle("Year", size(small)) ///
	ytitle("", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

grc1leg graph1 graph2 graph3 graph4 graph5, ///
	title("Returns to Education") ///
	subtitle("By hh income quintile") ///
	legendfrom(graph1) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${e1b_if_condition}).", size(vsmall))

graph export ///
"$dir_internal_validation/education/int_validation_${country}_E1b_returns_edu_ts_both_income.jpg", ///	
	replace width(2560) height(1440) quality(100)	
	
graph drop _all 	
	
restore


* Partnership status 
preserve

collapse (mean) der pred_der* [aw = dwt], by(dcpst stm)

order pred_der*

egen pred_der = rowmean(pred_der0-pred_der19)

replace stm = 2000 + stm 

twoway ///
(line pred_der stm if dcpst == 1, sort color(green) ///
	legend(label(1 "Predictions"))) ///
(line der stm if dcpst == 1, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
	name(graph1) ///
	title("Partnered") ///
	xtitle("Year", size(small)) ///
	ytitle("", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_der stm if dcpst == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line der stm if dcpst == 2, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph2) ///
	title("Single") ///
	xtitle("Year", size(small)) ///
	ytitle("", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))


grc1leg graph1 graph2, ///
	title("Returns to Education") ///
	subtitle("By partnership status") ///
	legendfrom(graph1) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${e1b_if_condition}).", size(vsmall))
	
graph export "$dir_internal_validation/education/int_validation_${country}_E1b_returns_edu_ts_both_partnership.jpg", ///	
	replace width(2560) height(1440) quality(100)
	
graph drop _all 	
	
restore


**********************************************
* E2a Educational Level When Leave Education *
**********************************************

* Overall 
use "$dir_data/E2a_sample", clear

sum p1-p3 // inspect negative values  

gen p1p2 = p1 + p2 // create cdf

gen rnd = runiform()
gen edu_pred = cond((rnd < p1), 1, cond(rnd < p1p2, 2, 3)) 

keep if in_sample == 1 

/*
order idperson stm deh_c3_recoded edu_pred p1 p2 p3

save "/Users/ashleyburdett/Library/CloudStorage/Box-Box/CeMPA shared area/ESPON - OVERLAP/_countries/IT/regression_estimates/data/edu_attainment_obs_vs_pred.dta", replace
*/

twoway (histogram edu_pred if in_sample == 1, color(red%30)) ///
       (histogram deh_c3_recoded if in_sample == 1, color(green%30)), ///
       xtitle("Education level", size(small)) ///
       ytitle("", size(small)) ///
       xlabel(, labsize(small)) ///
       ylabel(, labsize(small)) ///
       legend(lab(1 "Predictions") lab(2 "SILC")) ///
       name(levels, replace) ///
       title("Educational Attainment when Leave Education") ///
       graphregion(color(white)) ///
	   	note("Notes: Estimation sample plotted. Regression if condition (${e2_if_condition})." "1 = Low education, 2 = Medium education, 3 = High education.", size(vsmall))

graph export "$dir_internal_validation/education/int_validation_${country}_E2a_edu_attainment_hist_both.jpg", ///
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
(line pred_edu_low stm, sort color(red) ///
	legend(label(1 "Low education, predicted"))) ///
(line edu_low stm, sort color(red) color(red%50) ///
	lpattern(dash) legend(label(2 "Low education, SILC"))) ///
(line pred_edu_med stm, sort color(blue) ///
	legend(label(3 "Medium education, predicted"))) ///
(line edu_med stm, sort color(blue) color(blue%50) ///
	lpattern(dash) legend(label(4 "Medium education, SILC"))) ///
(line pred_edu_high stm, sort color(green) ///
	legend(label(5 "High education, predicted"))) ///
(line edu_high stm, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(6 "High education, SILC"))) , ///
	title("Educational Attainment when Leave Education") ///
	subtitle("" ) ///
	xtitle("Year", size(small)) /// 
	ytitle("", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${e2_if_condition}).", size(vsmall))
	
graph export "$dir_internal_validation/education/int_validation_${country}_E2a_edu_attainment_ts_both.jpg", ///
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
(line pred_edu_low stm if dgn == 0, sort color(red) ///
	legend(label(1 "Low education, predicted"))) ///
(line edu_low stm if dgn == 0, sort color(red) color(red%50) ///
	lpattern(dash) legend(label(2 "Low education, SILC"))) ///
(line pred_edu_med stm if dgn == 0, sort color(blue) ///
	legend(label(3 "Medium education, predicted"))) ///
(line edu_med stm if dgn == 0, sort color(blue) color(blue%50) ///
	lpattern(dash) legend(label(4 "Medium education, SILC"))) ///
(line pred_edu_high stm if dgn == 0, sort color(green) ///
	legend(label(5 "High education, predicted"))) ///
(line edu_high stm if dgn == 0, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(6 "High education, SILC"))) , ///
	name(edu_attainment_female, replace) ///
	title("Females") ///
	xtitle("Year", size(small)) ///
	ytitle("", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white)) 
	
twoway ///
(line pred_edu_low stm if dgn == 1, sort color(red) ///
	legend(label(1 "Low education, predicted"))) ///
(line edu_low stm if dgn == 1, sort color(red) color(red%50) ///
	lpattern(dash) legend(label(2 "Low education, SILC"))) ///
(line pred_edu_med stm if dgn == 1, sort color(blue) ///
	legend(label(3 "Medium education, predicted"))) ///
(line edu_med stm if dgn == 1, sort color(blue) color(blue%50) ///
	lpattern(dash) legend(label(4 "Medium education, SILC"))) ///
(line pred_edu_high stm if dgn == 1, sort color(green) ///
	legend(label(5 "High education, predicted"))) ///
(line edu_high stm if dgn == 1, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(6 "High education, SILC"))) , ///
	name(edu_attainment_male, replace) ///
	title("Males") ///
	xtitle("Year", size(small)) ///
	ytitle("", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white)) 	
	
grc1leg edu_attainment_female edu_attainment_male, ///
	title("Educational Attainment when Leave Education") ///
	legendfrom(edu_attainment_male) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${e2_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/education/int_validation_${country}_E2a_edu_attainment_ts_gender.jpg", ///
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
(line pred_edu_low dag, sort color(red) ///
	legend(label(1 "Low education, predicted"))) ///
(line edu_low dag, sort color(red) color(red%50) ///
	lpattern(dash) legend(label(2 "Low education, SILC"))) ///
(line pred_edu_med dag, sort color(blue) ///
	legend(label(3 "Medium education, predicted"))) ///
(line edu_med dag, sort color(blue) color(blue%50) ///
	lpattern(dash) legend(label(4 "Medium education, SILC"))) ///
(line pred_edu_high dag, sort color(green) ///
	legend(label(5 "High education, predicted"))) ///
(line edu_high dag, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(6 "High education, SILC"))), ///
	title("Educational Attainment when Leave Education") ///
	subtitle("By age") ///
	xtitle("Age", size(small)) ///
	ytitle("", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${e2_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/education/int_validation_${country}_E2a_edu_attainment_share_age.jpg", ///
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
(line pred_edu_low stm if ydses_c5 == 1, sort color(red) ///
	legend(label(1 "Low education, predicted"))) ///
(line edu_low stm if ydses_c5 == 1, sort color(red) color(red%50) ///
	lpattern(dash) legend(label(2 "Low education, SILC"))) ///
(line pred_edu_med stm if ydses_c5 == 1, sort color(blue) ///
	legend(label(3 "Medium education, predicted"))) ///
(line edu_med stm if ydses_c5 == 1, sort color(blue) color(blue%50) ///
	lpattern(dash) legend(label(4 "Medium education, SILC")))	///
(line pred_edu_high stm if ydses_c5 == 1, sort color(green) ///
	legend(label(5 "High education, predicted"))) ///
(line edu_high stm if ydses_c5 == 1, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(6 "High education, SILC"))), ///
	name(graph1) ///
	title("First quintile") ///
	xtitle("Year", size(small)) /// 
	ytitle("", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white)) 	

twoway ///
(line pred_edu_low stm if ydses_c5 == 2, sort color(red) ///
	legend(label(1 "L Pred"))) ///
(line edu_low stm if ydses_c5 == 2, sort color(red) color(red%50) ///
	lpattern(dash) legend(label(2 "L Obs"))) ///
(line pred_edu_med stm if ydses_c5 == 2, sort color(blue) ///
	legend(label(3 "M Pred"))) ///
(line edu_med stm if ydses_c5 == 2, sort color(blue) color(blue%50) ///
	lpattern(dash) legend(label(4 "M Obs")))	///
(line pred_edu_high stm if ydses_c5 == 2, sort color(green) ///
	legend(label(5 "H Pred"))) ///
(line edu_high stm if ydses_c5 == 2, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(6 "H Obs"))), ///
	name(graph2) ///
	title("Second quintile") ///
	xtitle("Year", size(small)) /// ytitle("", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white)) 

twoway ///
(line pred_edu_low stm if ydses_c5 == 3, sort color(red) ///
	legend(label(1 "L Pred"))) ///
(line edu_low stm if ydses_c5 == 3, sort color(red) color(red%50) ///
	lpattern(dash) legend(label(2 "L Obs"))) ///
(line pred_edu_med stm if ydses_c5 == 3, sort color(blue) ///
	legend(label(3 "M Pred"))) ///
(line edu_med stm if ydses_c5 == 3, sort color(blue) color(blue%50) ///
	lpattern(dash) legend(label(4 "M Obs")))	///
(line pred_edu_high stm if ydses_c5 == 3, sort color(green) ///
	legend(label(5 "H Pred"))) ///
(line edu_high stm if ydses_c5 == 3, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(6 "H Obs"))), ///
	name(graph3) ///
	title("Third quintile") ///
	xtitle("Year", size(small)) ///
	ytitle("", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white)) 

twoway ///
(line pred_edu_low stm if ydses_c5 == 4, sort color(red) ///
	legend(label(1 "L Pred"))) ///
(line edu_low stm if ydses_c5 == 4, sort color(red) color(red%50) ///
	lpattern(dash) legend(label(2 "L Obs"))) ///
(line pred_edu_med stm if ydses_c5 == 4, sort color(blue) ///
	legend(label(3 "M Pred"))) ///
(line edu_med stm if ydses_c5 == 4, sort color(blue) color(blue%50) ///
	lpattern(dash) legend(label(4 "M Obs")))	///
(line pred_edu_high stm if ydses_c5 == 4, sort color(green) ///
	legend(label(5 "H Pred"))) ///
(line edu_high stm if ydses_c5 == 4, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(6 "H Obs"))), ///
	name(graph4) ///
	title("Fourth quintile") ///
	xtitle("Year", size(small)) /// 
	ytitle("", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white)) 
	
twoway ///
(line pred_edu_low stm if ydses_c5 == 5, sort color(red) ///
	legend(label(1 "L Pred"))) ///
(line edu_low stm if ydses_c5 == 5, sort color(red) color(red%50) ///
	lpattern(dash) legend(label(2 "L Obs"))) ///
(line pred_edu_med stm if ydses_c5 == 5, sort color(blue) ///
	legend(label(3 "M Pred"))) ///
(line edu_med stm if ydses_c5 == 5, sort color(blue) color(blue%50) ///
	lpattern(dash) legend(label(4 "M Obs")))	///
(line pred_edu_high stm if ydses_c5 == 5, sort color(green) ///
	legend(label(5 "H Pred"))) ///
(line edu_high stm if ydses_c5 == 5, sort color(green) color(green%50) ///
	lpattern(dash) legend(label(6 "H Obs"))), ///
	name(graph5) ///
	title("Fifth quintile") ///
	xtitle("Year", size(small)) /// ///
	ytitle("", size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white)) 

grc1leg graph1 graph2 graph3 graph4 graph5 , ///
	title("Educational Attainment when Education") ///
	subtitle("By hh income quintile") ///
	legendfrom(graph1) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${e2_if_condition}).", size(vsmall))
	
graph export ///
"$dir_internal_validation/education/int_validation_${country}_E2a_edu_attainment_ts_both_income.jpg", ///
	replace width(2560) height(1440) quality(100)	
	
graph drop _all 	
	
restore 

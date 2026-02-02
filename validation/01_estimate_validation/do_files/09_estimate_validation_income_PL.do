********************************************************************************
* PROJECT:  		SimPaths EU  
* SECTION:			Income
* OBJECT: 			Internal validation
* AUTHORS:			Ashley Burdett, Aleksandra Kolndrekaj 
* LAST UPDATE:		Jan 2026
* COUNTRY: 			Poland  
********************************************************************************
* NOTES: 			Compares predicted values to the observed values of the 
* 					hurdle models used for the income processes. 
* 					Individual heterogeneity added to the standard predicted 
* 					values form the using a random draw like in stochasitic 
* 					imputation. The pooled mean is obtained as in multiple 
* 					imputation by repeating the random draw 20 times for each 
* 					process. 
* 
* 					Run after "reg_income_PL.do"
********************************************************************************

* I1a selection - capital income
		
use "$dir_data/I1_selection_sample", clear 

forvalues i = 0/19 {
	local my_seed = 12345 + `i'  
    set seed `my_seed' 	
	gen rnd = runiform() 	
	gen pred_receives_ypncp`i' = 0 
	replace pred_receives_ypncp`i' = 1 if inrange(p,rnd,1)
	drop rnd
}

keep if in_sample == 1 

//replace stm = 2000 + stm 
egen pred_receives_ypncp = rowmean(pred_receives_ypncp0-pred_receives_ypncp19)

* Raw prediction vs observed
twoway ///
	(histogram pred_receives_ypncp0, color(red%30)) ///
	(histogram receives_ypncp, color(green%30)), ///
	xtitle (Receives capital income) ///
	legend(lab(1 "Predictions") lab( 2 "SILC")) name(levels, replace) ///
	title("Receives Capital Income") ///
	subtitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	graphregion(color(white)) ///
	legend(size(small)) ///
	note("Notes: Predicted vs observed of dummy indicating capital income is received. Estimation sample plotted. Regression if condition (${i1a_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/income/int_validation_${country}_I1a_selection_capital_hist_all.jpg", ///
	replace width(2560) height(1440) quality(100)

	
* Year 
preserve

collapse (mean) receives_ypncp pred_receives_ypncp  [aw = dwt], by(stm)

twoway ///
(line pred_receives_ypncp stm, sort color(green) ///
	legend(label(1 "Predictions"))) ///
(line receives_ypncp stm, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "SILC"))), ///
title("Receives Captial Income") ///
	subtitle("") ///
	xtitle("Year") ///
	ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${i1a_if_condition}).", size(vsmall))

	
graph export "$dir_internal_validation/income/int_validation_${country}_I1a_selection_capital_ts_all_both.jpg", ///
	replace width(2560) height(1440) quality(100)
	
	
restore	
	
graph drop _all	
	

* By gender 	
preserve
	
collapse (mean) receives_ypncp pred_receives_ypncp  [aw = dwt], by(stm dgn)
	
twoway ///
(line pred_receives_ypncp stm if dgn == 0, sort color(green) ///
	legend(label(1 "Predictions"))) ///
(line receives_ypncp stm if dgn == 0, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
name(graph1) title("Females") xtitle("Year") ytitle("Share") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white)) 

twoway ///
(line pred_receives_ypncp stm if dgn == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line receives_ypncp stm if dgn == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
name(graph2) title("Males") xtitle("Year") ytitle("Share")  ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white)) 

grc1leg graph1 graph2 ,  ///
	title("Receives Captial Income ") ///
	subtitle("") ///
	legendfrom(graph1) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${i1a_if_condition}).", size(vsmall))
	
graph export "$dir_internal_validation/income/int_validation_${country}_I1a_selection_capital_ts_all_gender.jpg", ///
	replace width(2560) height(1440) quality(100)
	
restore 

graph drop _all 
	
	
* Share by age 
preserve
	
collapse (mean) receives_ypncp pred_receives_ypncp  [aw = dwt], by(dag)

twoway ///
(line pred_receives_ypncp dag, sort color(green) ///
	legend(label(1 "Predicitions"))) ///
(line receives_ypncp dag, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "SILC"))), ///
	title("Receives Capital Income") ///
	subtitle("") ///
	xtitle("Age") ///
	ytitle("Share") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${i1a_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/income/int_validation_${country}_I1a_selection_capital_left_edu_share_age.jpg", ///
	replace width(2560) height(1440) quality(100)
	
restore
	
graph drop _all	
	
	
* Hh income 	
preserve	
	
xtset idperson swv

gen L_ydses = l.ydses_c5
	
collapse (mean) receives_ypncp pred_receives_ypncp  [aw = dwt], by(L_ydses stm)

twoway ///
(line pred_receives_ypncp stm if L_ydses == 1, sort color(green) ///
	legend(label(1 "Predicitions"))) ///
(line receives_ypncp stm if L_ydses == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
	name(graph1) ///
	title("First quintile") ///
	xtitle("Year") ///
	ytitle("") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_receives_ypncp stm if L_ydses == 2, sort color(green) ///
	legend(label(1 "Predicitions"))) ///
(line receives_ypncp stm if L_ydses == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
	name(graph2) ///
	title("Second quintile") ///
	xtitle("Year") ///
	ytitle("") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_receives_ypncp stm if L_ydses == 3, sort color(green) ///
	legend(label(1 "Predicitions"))) ///
(line receives_ypncp stm if L_ydses == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
	name(graph3) ///
	title("Third quintile") ///
	xtitle("Year") ///
	ytitle("") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_receives_ypncp stm if L_ydses == 4, sort color(green) ///
	legend(label(1 "Predicitions"))) ///
(line receives_ypncp stm if L_ydses == 4, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
	name(graph4) ///
	title("Fourth quintile") ///
	xtitle("Year") ///
	ytitle("") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_receives_ypncp stm if L_ydses == 5, sort color(green) ///
	legend(label(1 "Predictions"))) ///
(line receives_ypncp stm if L_ydses == 5, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
	name(graph5) ///
	title("Fifth quintile") ///
	xtitle("Year") ///
	ytitle("") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

grc1leg graph1 graph2 graph3 graph4 graph5,  ///
	title("Receives Capital Income ") ///
	subtitle("By hh income quintile") ///
	legendfrom(graph1) rows(2) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${i1a_if_condition}).", size(vsmall))
	
graph export "$dir_internal_validation/income/int_validation_${country}_I1a_selection_capital_ts_all_both_income.jpg", ///
	replace width(2560) height(1440) quality(100)

restore
	
graph drop _all		
	
	
* Marital status 
preserve
	
collapse (mean) receives_ypncp pred_receives_ypncp  [aw = dwt], by(dcpst stm)
	
twoway ///
(line pred_receives_ypncp stm if dcpst == 1, sort color(green) ///
	legend(label(1 "Predictions"))) ///
(line receives_ypncp stm if dcpst == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
	name(graph1) ///
	title("Partnered") ///
	xtitle("Year") ///
	ytitle("") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_receives_ypncp stm if dcpst == 2, sort color(green) ///
	legend(label(1 "Predicitions"))) ///
(line receives_ypncp stm if dcpst == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
	name(graph2) ///
	title("Single") ///
	xtitle("Year") ///
	ytitle("") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

grc1leg graph1 graph2,  ///
	title("Receives Capital Income") ///
	subtitle("") ///
	legendfrom(graph1) rows(1) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${i1a_if_condition}).", size(vsmall))
	
graph export ///
"$dir_internal_validation/income/int_validation_${country}_I1a_selection_capital_ts_all_both_partnership.jpg", ///
	replace width(2560) height(1440) quality(100)

restore 

graph drop _all 			
	

	
	
* I1b amount - left initial education spell 

use "$dir_data/I1_level_sample", clear

keep if in_sample == 1 

* Obtain predicted log amount 
gen pred_ln_ypncp = p 

* Obtain random component 
gen epsilon = rnormal()*sigma

* Convert into level with random component 
gen pred_ypncp = exp(pred_ln_ypncp + epsilon) 

* Trim predictions
sum pred_ypncp, d
replace pred_ypncp = . if pred_ypncp < r(p1) | pred_ypncp > r(p99)

* Generate level in SILC data 
replace ln_ypncp = exp(ln_ypncp)

twoway (hist pred_ypncp, width(5) color(green%30)) ///
	(hist ln_ypncp, width(5) color(red%30)), ///
	xtitle (€) ///
	legend(lab(1 "Predictions") lab( 2 "SILC")) ///
	name(levels, replace) ///
	title("Capital Income Amount") ///
	subtitle("") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	graphregion(color(white)) ///
	legend(size(small)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${i1b_if_condition})." "€ per year, in 2015 prices.", size(vsmall))

graph export "$dir_internal_validation/income/int_validation_${country}_I1b_amount_capital_hist_all.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all
	
	
* By gender 

* Males 
twoway (hist pred_ypncp if dgn == 1, width(5) color(green%30) ///
	legend(lab(1 "Predictions"))) ///
(histogram ln_ypncp if dgn == 1, width(5) color(red%30) ///
	legend(lab( 2 "SILC"))), ///
	subtitle("Males") ///
	name(graph1, replace) ///
	xtitle (€) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	graphregion(color(white)) 
	
* Females 
twoway (hist pred_ypncp if dgn == 0, width(5) color(green%30) ///
	legend(lab(1 "Predictions"))) ///
(histogram ln_ypncp if dgn == 0, width(5) color(red%30) ///
	legend(lab( 2 "SILC"))), ///
	subtitle("Females") ///
	name(graph2, replace) ///
	xtitle (€) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	graphregion(color(white)) 
	
	
grc1leg graph1 graph2 ,  ///
	title("Capital Income Amount") ///
	subtitle("") ///
	legendfrom(graph1) rows(1) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${i1b_if_condition})." "€ per year, in 2015 prices.", size(vsmall))

graph export "$dir_internal_validation/income/int_validation_${country}_I1b_amount_capital_left_edu_hist_all_gender.jpg", ///
	replace width(2560) height(1440) quality(100)


* By education 	
	twoway (hist pred_ypncp if deh_c4 == 0, width(5) color(green%30) ///
	legend(lab(1 "Predictions"))) ///
(histogram ln_ypncp if deh_c4 == 0, width(5) color(red%30) ///
	legend(lab( 2 "SILC"))), ///
	subtitle("In initial education spell") ///
	name(graph0, replace) ///
	xtitle (€) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	graphregion(color(white)) 
* Low 
twoway (hist pred_ypncp if deh_c4 == 3, width(5) color(green%30) ///
	legend(lab(1 "Predictions"))) ///
(histogram ln_ypncp if deh_c4 == 3, width(5) color(red%30) ///
	legend(lab( 2 "SILC"))), ///
	subtitle("Low education") ///
	name(graph1, replace) ///
	xtitle (€) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	graphregion(color(white)) 
	
* Medium
twoway (hist pred_ypncp if deh_c4 == 2, width(5) color(green%30) ///
	legend(lab(1 "Predicitions"))) ///
(histogram ln_ypncp if deh_c4 == 2, width(5) color(red%30) ///
	legend(lab( 2 "SILC"))), ///
	subtitle("Medium education") ///
	name(graph2, replace) ///
	xtitle (€) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	graphregion(color(white)) 
	
* High	
twoway (hist pred_ypncp if deh_c4 == 1, width(5) color(green%30) ///
	legend(lab(1 "Predictions"))) ///
(histogram ln_ypncp if deh_c4 == 1, width(5) color(red%30) ///
	legend(lab( 2 "SILC"))), ///
	subtitle("High education") ///
	name(graph3, replace) ///
	xtitle (€) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	graphregion(color(white)) 	
	
	
grc1leg graph0 graph1 graph2 graph3 ,  ///
	title("Capital Income Amount") ///
	subtitle("") ///
	legendfrom(graph1) rows(2) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${i1b_if_condition})." "€ per year, in 2015 prices.", size(vsmall))

graph export "$dir_internal_validation/income/int_validation_${country}_I1b_amount_capital_left_edu_hist_all_edu.jpg", ///
	replace width(2560) height(1440) quality(100)
	
	
graph drop _all 	
	
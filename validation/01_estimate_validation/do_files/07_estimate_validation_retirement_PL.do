********************************************************************************
* PROJECT:  		SimPaths EU 
* SECTION:			Retirement
* OBJECT: 			Internal validation
* AUTHORS:			Ashley Burdett, Aleksandra Kolndrekaj   
* LAST UPDATE:		jan 2026
* COUNTRY: 			Poland 
********************************************************************************
* NOTES: 			Compares predicted values to the observed values of the 
* 					2 retirement processes estimated. 
* 					Individual heterogeneity added to the standard predicted 
* 					values form the using a random draw like in stochasitic 
* 					imputation. The pooled mean is obtained as in multiple 
* 					imputation by repeating the random draw 20 times for each 
* 					process. 
* 
* 					Run after "reg_retirement_PL.do"
* 
* 					Not in the unnique dataset individuals are forced into 
* 					retirement at the age of 75. 
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
	legend(lab(1 "Predictions") lab( 2 "SILC")) ///
	name(levels, replace) ///
	title("Retire") ///
	subtitle("Singles") ///
	xtitle("Retire") ///	
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	graphregion(color(white)) ///
	legend(size(small)) ///
	note("Notes: Predicted vs observed of dummy indicating retire. Estimation sample plotted. Regression if condition" "(${r1a_if_condition}).", size(vsmall))
	
graph export "$dir_internal_validation/retirement/int_validation_${country}_R1a_retirement_single_hist_50.jpg", ///
	replace width(2560) height(1440) quality(100)
	

* Year 
use "$dir_data/R1a_sample", clear

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
(line pred_drtren stm, sort color(green) legend(label(1 "Predictions"))) ///
(line drtren stm, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "SILC"))), ///
	title("Retire") ///
	subtitle("Singles") ///
	xtitle("Year") ///
	ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Estimation sample plotted. Regrssion if condition (${r1a_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/retirement/int_validation_${country}_R1a_retirement_single_ts_50.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 
 
restore  
 
 
* Age
preserve

collapse (mean) drtren pred_drtren* [aw = dwt], by(dag)

order pred_drtren*

egen pred_drtren = rowmean(pred_drtren0-pred_drtren19)

twoway ///
(line pred_drtren dag, sort color(green) legend(label(1 "Predictions"))) ///
(line drtren dag, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "SILC"))), ///
	title("Retire") ///
	subtitle("Singles") ///
	xtitle("Age") ///
	ytitle("Share") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regrssion if condition (${r1a_if_condition}).", size(vsmall))


graph export "$dir_internal_validation/retirement/int_validation_${country}_R1a_retirement_single_share_age.jpg", ///
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
	legend(label(1 "Predictions"))) ///
(line drtren stm if ydses_c5 == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
	name(graph1) title("First quintile") ///
	xtitle("Year") ///
	ytitle("")  ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_drtren stm if ydses_c5 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if ydses_c5 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph2) ///
	title("Second quintile") ///
	xtitle("Year") ///
	ytitle("")  ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_drtren stm if ydses_c5 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if ydses_c5 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph3) ///
	title("Third quintile") ///
	xtitle("Year") ///
	ytitle("")  ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_drtren stm if ydses_c5 == 4, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if ydses_c5 == 4, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph4) ///
	title("Forth quintile") ///
	xtitle("Year") ///
	ytitle("")  ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_drtren stm if ydses_c5 == 5, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if ydses_c5 == 5, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph5) ///
	title("Fifth quintile") ///
	xtitle("Year") ytitle("")  ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

grc1leg graph1 graph2 graph3 graph4 graph5,  ///
	title("Retirement single") ///
	subtitle("Singles, by hh income quintile") ///
	legendfrom(graph1) rows(2) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regrssion if condition (${r1a_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/retirement/int_validation_${country}_R1a_retirement_single_ts_50_both_income.jpg", ///
	replace width(2560) height(1440) quality(100)
	
	
graph drop _all 	
	
restore


* Education 
preserve

collapse (mean) drtren pred_drtren* [aw = dwt], by(deh_c4 stm)

order pred_drtren*

egen pred_drtren = rowmean(pred_drtren0-pred_drtren19)

replace stm = 2000 + stm 
twoway ///
(line pred_drtren stm if deh_c4 == 0, sort color(green) ///
	legend(label(1 "Predictions"))) ///
(line drtren stm if deh_c4 == 0, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
	name(graph0) ///
	title("In initial education spell") ///
	xtitle("Year") ///
	ytitle("")  ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_drtren stm if deh_c4 == 1, sort color(green) ///
	legend(label(1 "Predictions"))) ///
(line drtren stm if deh_c4 == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
	name(graph1) ///
	title("High education") ///
	xtitle("Year") ///
	ytitle("")  ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_drtren stm if deh_c4 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if deh_c4 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph2) ///
	title("Medium education") ///
	xtitle("Year") ytitle("")  ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_drtren stm if deh_c4 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if deh_c4 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph3) ///
	title("Low education") ///
	xtitle("Year") ///
	ytitle("")  ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))


grc1leg graph0 graph1 graph2 graph3 ,  ///
	title("Retire") ///
	subtitle("Singles") ///
	legendfrom(graph1) rows(2) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regrssion if condition (${r1a_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/retirement/int_validation_${country}_R1a_retirement_single_ts_50_both_edu.jpg", ///
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
	legend(lab(1 "Predictions") lab( 2 "SILC")) ///
	name(levels, replace) ///
	title("Retire") ///
	subtitle("Partnered") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	graphregion(color(white)) ///
	legend(size(small)) ///
	note("Notes: Predicted vs observed of dummy indicating retire. Estimation sample plotted. Regression if condition" "(${r1b_if_condition}).", size(vsmall))
	
graph export "$dir_internal_validation/retirement/int_validation_${country}_R1b_retirement_partnered_hist_50.jpg", ///
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
(line pred_drtren stm, sort color(green) legend(label(1 "Predictions"))) ///
(line drtren stm, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "SILC"))), ///
	title("Retire") ///
	subtitle("Partnered") ///
	xtitle("Year") ///
	ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${r1b_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/retirement/int_validation_${country}_R1b_retirement_partnered_ts_50.jpg", ///
	replace width(2560) height(1440) quality(100)
 
restore  
 
 
* Age
preserve

collapse (mean) drtren pred_drtren* [aw = dwt], by(dag)

order pred_drtren*

egen pred_drtren = rowmean(pred_drtren0-pred_drtren19)

twoway ///
(line pred_drtren dag, sort color(green) legend(label(1 "Predictions"))) ///
(line drtren dag, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "SILC"))), ///
	title("Retire") ///
	subtitle("Partnered") ///
	xtitle("Age") ///
	ytitle("Share") xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${r1b_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/retirement/int_validation_${country}_R1b_retirement_partnered_share_age.jpg", ///
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
	legend(label(1 "Predictions"))) ///
(line drtren stm if ydses_c5 == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
	name(graph1) ///
	title("First quintile") ///
	xtitle("Year") ///
	ytitle("")  ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_drtren stm if ydses_c5 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if ydses_c5 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph2) ///
	title("Second quintile") ///
	xtitle("Year") ///
	ytitle("")  ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_drtren stm if ydses_c5 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if ydses_c5 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph3) ///
	title("Third quintile") ///
	xtitle("Year") ///
	ytitle("")  ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_drtren stm if ydses_c5 == 4, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if ydses_c5 == 4, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph4) ///
	title("Forth quintile") ///
	xtitle("Year") ///
	ytitle("")  ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_drtren stm if ydses_c5 == 5, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if ydses_c5 == 5, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph5) ///
	title("Fifth quintile") ///
	xtitle("Year") ///
	ytitle("")  ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

grc1leg graph1 graph2 graph3 graph4 graph5,  ///
	title("Retire") ///
	subtitle("Partnered, by hh income quintile") ///
	legendfrom(graph1) rows(2) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${r1b_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/retirement/int_validation_${country}_R1b_retirement_partnered_ts_50_both_income.jpg", ///
	replace width(2560) height(1440) quality(100)
	
graph drop _all 	
	
restore


* Education 
preserve

collapse (mean) drtren pred_drtren* [aw = dwt], by(deh_c4 stm)

order pred_drtren*

egen pred_drtren = rowmean(pred_drtren0-pred_drtren19)

replace stm = 2000 + stm 

twoway ///
(line pred_drtren stm if deh_c4 == 0, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if deh_c4 == 0, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph0) ///
	title("In initial education spell") ///
	xtitle("Year") ///
	ytitle("")  ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_drtren stm if deh_c4 == 1, sort color(green) ///
	legend(label(1 "Predictions"))) ///
(line drtren stm if deh_c4 == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
	name(graph1) ///
	title("High education") ///
	xtitle("Year") ///
	ytitle("")  ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_drtren stm if deh_c4 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if deh_c4 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph2) ///
	title("Medium education") ///
	xtitle("Year") ytitle("")  ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_drtren stm if deh_c4 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line drtren stm if deh_c4 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph3) ///
	title("Low education") ///
	xtitle("Year") ytitle("")  ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))


grc1leg graph0 graph1 graph2 graph3 ,  ///
	title("Retire") ///
	subtitle("Partnered") ///
	legendfrom(graph1) rows(2) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${r1b_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/retirement/int_validation_${country}_R1b_retirement_partnered_ts_50_both_edu.jpg", ///
	replace width(2560) height(1440) quality(100)


graph drop _all 	
	
restore


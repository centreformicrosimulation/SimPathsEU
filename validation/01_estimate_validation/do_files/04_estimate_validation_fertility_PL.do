********************************************************************************
* PROJECT:  		SimPaths EU 
* SECTION:			Fertility
* OBJECT: 			Internal validation
* AUTHORS:			Ashley Burdett 
* LAST UPDATE:		April 2025
* COUNTRY: 			Poland 
********************************************************************************
* NOTES: 			Compares predicted values to the observed values of the 
* 					2 fertility processes estimated. 
* 					Individual heterogeneity addchpd to the standard predicted 
* 					values form the using a random draw like in stochasitic 
* 					imputation. The pooled mean is obtained as in multiple 
* 					imputation by repeating the random draw 20 times for each 
* 					process. 
* 
* 					Run after "reg_fertility_PL.do"
********************************************************************************


************************************************
* F1 - Having a child, *
************************************************

* Overall 
use "$dir_data/F1_sample", clear 

set seed 12345
gen rnd = runiform() 	
gen pred_dchpd = 0 
replace pred_dchpd = 1 if inrange(p,rnd,1)

keep if in_sample == 1 


twoway ///
	(histogram pred_dchpd, color(red%30)) ///
	(histogram dchpd, color(green%30)), ///
	xtitle (Had child) ///
	legend(lab(1 "Predictions") lab( 2 "SILC")) name(levels, replace) ///
	title("Fertility") ///
	subtitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	graphregion(color(white)) ///
	legend(size(small)) ///
	note("Notes: Predicted vs observed of dummy indicating a female has a new born child. Estimation sample plotted." "Regression if condition (${f1_if_condition})", size(vsmall))

graph export "$dir_internal_validation/fertility/int_validation_${country}_F1_fertility_hist_18_45.jpg", ///
	replace width(2560) height(1440) quality(100)	

	
* Year 
use "$dir_data/F1_sample", clear

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

replace stm = stm + 2000


preserve

collapse (mean) dchpd pred_dchpd* [aw = dwt], by(stm)

order pred_dchpd*

egen pred_dchpd = rowmean(pred_dchpd0-pred_dchpd19)

// replace stm= 2000 + stm 

twoway ///
(line pred_dchpd stm, sort color(green) legend(label(1 "Predictions"))) ///
(line dchpd stm, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "SILC"))), ///
title("Fertility") ///
	subtitle("") ///
	xtitle("Year") ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Share of females that have a new born child. Estimation sample plotted.""Regression if condition (${f1_if_condition})", size(vsmall))

graph export "$dir_internal_validation/fertility/int_validation_${country}_F1_fertility_ts_18_45.jpg", ///
	replace width(2560) height(1440) quality(100)
 
restore  
 
 
* Age
preserve

collapse (mean) dchpd pred_dchpd* [aw = dwt], by(dag)

order pred_dchpd*

egen pred_dchpd = rowmean(pred_dchpd0-pred_dchpd19)

twoway ///
(line pred_dchpd dag, sort color(green) legend(label(1 "Predictions"))) ///
(line dchpd dag, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "SILC"))), ///
title("Fertility ") ///
	subtitle("") ///
	xtitle("Age") ///
	ytitle("Share") xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white)) ///
	note("Notes: Share of females that have a new born child. Estimation sample plotted.""Regression if condition (${f1_if_condition})", size(vsmall))

graph export "$dir_internal_validation/fertility/int_validation_${country}_F1_fertility_share_age.jpg", ///
	replace width(2560) height(1440) quality(100)
	
restore


* Income 
preserve
xtset idperson swv
gen Lag_ydses_c5=l.ydses_c5

collapse (mean) dchpd pred_dchpd* [aw = dwt], by(Lag_ydses_c5 stm)

order pred_dchpd*

egen pred_dchpd = rowmean(pred_dchpd0-pred_dchpd19)

// replace stm= 2000 + stm 

twoway ///
(line pred_dchpd stm if Lag_ydses_c5 == 1, sort color(green) ///
	legend(label(1 "Predictions"))) ///
(line dchpd stm if Lag_ydses_c5 == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
name(graph1) title("First quintile") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_dchpd stm if Lag_ydses_c5 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dchpd stm if Lag_ydses_c5 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Second quintile") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_dchpd stm if Lag_ydses_c5 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dchpd stm if Lag_ydses_c5 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Third quintile") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_dchpd stm if Lag_ydses_c5 == 4, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dchpd stm if Lag_ydses_c5 == 4, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph4) title("Fourth quintile") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_dchpd stm if Lag_ydses_c5 == 5, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dchpd stm if Lag_ydses_c5 == 5, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph5) title("Fifth quintile") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

grc1leg graph1 graph2 graph3 graph4 graph5,  ///
	title("Fertility") ///
	subtitle("By hh income quintile") ///
	legendfrom(graph1) rows(2) ///
	graphregion(color(white)) ///
	note("Notes: Share of females that have a new born child. Estimation sample plotted.""Regression if condition (${f1_if_condition})", size(vsmall))

graph export "$dir_internal_validation/fertility/int_validation_${country}_F1_fertility_ts_18_45_income.jpg", ///
	replace width(2560) height(1440) quality(100)
	
graph drop _all 	
	
restore


* Education
preserve

collapse (mean) dchpd pred_dchpd* [aw = dwt], by(deh_c4 stm)

order pred_dchpd*

egen pred_dchpd = rowmean(pred_dchpd0-pred_dchpd19)

// replace stm= 2000 + stm 
twoway ///
(line pred_dchpd stm if deh_c4 == 0, sort color(green) ///
	legend(label(1 "Predictions"))) ///
(line dchpd stm if deh_c4 == 0, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
name(graph0) title("Initial education spell") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))


twoway ///
(line pred_dchpd stm if deh_c4 == 1, sort color(green) ///
	legend(label(1 "Predictions"))) ///
(line dchpd stm if deh_c4 == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
name(graph1) title("High education") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_dchpd stm if deh_c4 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dchpd stm if deh_c4 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Medium education") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_dchpd stm if deh_c4 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dchpd stm if deh_c4 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Low education") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

grc1leg graph0 graph1 graph2 graph3,  ///
	title("Fertility") ///
	subtitle("") ///
	legendfrom(graph1) rows(2) ///
	graphregion(color(white)) ///
	note("Notes: Share of females that have a new born child. Estimation sample plotted.""Regression if condition (${f1_if_condition})", size(vsmall))

graph export "$dir_internal_validation/fertility/int_validation_${country}_F1_fertility_ts_18_45_edu.jpg", ///
	replace width(2560) height(1440) quality(100)
	
graph drop _all 	
	
restore


* Marital status 
preserve

collapse (mean) dchpd pred_dchpd* [aw = dwt], by(dcpst stm)

order pred_dchpd*

egen pred_dchpd = rowmean(pred_dchpd0-pred_dchpd19)

// replace stm= 2000 + stm 

twoway ///
(line pred_dchpd stm if dcpst == 1, sort color(green) ///
	legend(label(1 "Predictions"))) ///
(line dchpd stm if dcpst == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
name(graph1) title("Partnered") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_dchpd stm if dcpst == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dchpd stm if dcpst == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Single") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))


grc1leg graph1 graph2,  ///
	title("Fertility ") ///
	subtitle("") ///
	legendfrom(graph1) rows(1) ///
	graphregion(color(white)) ///
	note("Notes: Share of females that have a new born child. Estimation sample plotted.""Regression if condition (${f1_if_condition})", size(vsmall))

graph export "$dir_internal_validation/fertility/int_validation_${country}_F1_fertility_ts_18_45_partnership.jpg", ///
	replace width(2560) height(1440) quality(100)
	
	
graph drop _all 	
	
restore

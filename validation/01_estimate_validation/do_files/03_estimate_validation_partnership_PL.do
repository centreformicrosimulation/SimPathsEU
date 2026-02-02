********************************************************************************
* PROJECT:  		SimPaths EU 
* SECTION:			Partnership
* OBJECT: 			Internal validation
* AUTHORS:			Ashley Burdett, Aleksandra Kolndrekaj  
* LAST UPDATE:		Jan 2026 
* COUNTRY: 			Poland 
********************************************************************************
* NOTES: 			Compares predicted values to the observed values of the 
* 					partnership processes. 
* 					Individual heterogeneity added to the standard predicted 
* 					values form the using a random draw like in stochasitic 
* 					imputation. The pooled mean is obtained as in multiple 
* 					imputation by repeating the random draw 20 times for each 
* 					process. 
* 
* 					Run after "reg_partnership_PL.do"
********************************************************************************


******************************************************
* U1a: Partnership formation, left initial edu spell *
******************************************************

* Overall 
use "$dir_data/U1_sample", clear 
xtset idperson swv	
gen Lag_ydses_c5=l.ydses_c5
set seed 12345
gen rnd = runiform() 	
gen pred_dcpen = 0 
replace pred_dcpen = 1 if inrange(p,rnd,1)

keep if in_sample == 1 

twoway ///
	(histogram pred_dcpen, color(red%30)) ///
	(histogram dcpen, color(green%30)), ///
	xtitle (Formation) ///
	legend(lab(1 "Predictions") lab( 2 "SILC")) name(levels, replace) ///
	title("Partnership Formation") ///
	subtitle("") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	graphregion(color(white)) ///
	legend(size(small)) ///
	note("Notes: Predicted vs observed of dummy indicating forming a partnership. Estimation sample plotted. Regression if condition" "(${u1_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/partnership/int_validation_${country}_U1_partnership_all.jpg", ///
	replace width(2560) height(1440) quality(100)
	
* Year 
use "$dir_data/U1_sample", clear 
gen Lag_ydses_c5 = l.ydses_c5

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
(line pred_dcpen stm, sort color(green) legend(label(1 "Predictions"))) ///
(line dcpen stm, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "SILC"))), ///
	title("Partnership Formation") ///
	subtitle("") ///
	xtitle("Year") ///
	ytitle("Share") ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${u1_if_condition}).", size(vsmall))


graph export "$dir_internal_validation/partnership/int_validation_${country}_U1_partnership_both.jpg", ///
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
	legend(label(1 "Predictions"))) ///
(line dcpen stm if dgn == 0, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
	name(graph1) ///
	title("Females") ///
	xtitle("Year") ///
	ytitle("Share")  ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_dcpen stm if dgn == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpen stm if dgn == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph2) ///
	title("Males") ///
	xtitle("Year") ///
	ytitle("Share")  ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

grc1leg graph1 graph2,  ///
	title("Partnership Formation") ///
	subtitle("") ///
	legendfrom(graph1) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${u1_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/partnership/int_validation_${country}_U1_partnership_ts_all_gender.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all  

restore 
 
 
* Age
preserve

collapse (mean) dcpen pred_dcpen* [aw = dwt], by(dag)

order pred_dcpen*

egen pred_dcpen = rowmean(pred_dcpen0-pred_dcpen19)

twoway ///
(line pred_dcpen dag, sort color(green) legend(label(1 "Predictions"))) ///
(line dcpen dag, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "SILC"))), ///
	title("Partnership Formation") ///
	subtitle("") ///
	xtitle("Age") ///
	ytitle("Share") xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${u1_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/partnership/int_validation_${country}_U1_partnership_share_age.jpg", ///
	replace width(2560) height(1440) quality(100)

restore


* Income 
preserve
xtset idperson swv
collapse (mean) dcpen pred_dcpen* [aw = dwt], by(Lag_ydses_c5 stm)

order pred_dcpen*

egen pred_dcpen = rowmean(pred_dcpen0-pred_dcpen19)

replace stm = 2000 + stm 

twoway ///
(line pred_dcpen stm if Lag_ydses_c5 == 1, sort color(green) ///
	legend(label(1 "Predictions"))) ///
(line dcpen stm if Lag_ydses_c5 == 1, sort color(green) color(green%20) ///
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
(line pred_dcpen stm if Lag_ydses_c5 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpen stm if Lag_ydses_c5 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph2) ///
	title("Second quintile") ///
	xtitle("Year") ///
	ytitle("") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_dcpen stm if Lag_ydses_c5 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpen stm if Lag_ydses_c5 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph3) ///
	title("Third quintile") ///
	xtitle("Year") ///
	ytitle("") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_dcpen stm if Lag_ydses_c5 == 4, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpen stm if Lag_ydses_c5 == 4, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph4) ///
	title("Forth quintile") ///
	xtitle("Year") ///
	ytitle("") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_dcpen stm if Lag_ydses_c5 == 5, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpen stm if Lag_ydses_c5 == 5, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph5) ///
	title("Fifth quintile") ///
	xtitle("Year") ///
	ytitle("") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

grc1leg graph1 graph2 graph3 graph4 graph5,  ///
	title("Partnership Formation") ///
	subtitle("") ///
	legendfrom(graph1) ///
	rows(2) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${u1_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/partnership/int_validation_${country}_U1_partnership_ts_all_both_income.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore

*******************************
* U2: Partnership termination *
*******************************

* Overall 
use "$dir_data/U2_sample", clear 
xtset idperson swv
gen Lag_ydses_c5 = l.ydses_c5

set seed 12345
gen rnd = runiform() 	
gen pred_dcpex = 0 
replace pred_dcpex = 1 if inrange(p,rnd,1)

keep if in_sample == 1 

twoway ///
	(histogram pred_dcpex, color(red%30)) ///
	(histogram dcpex, color(green%30)), ///
	xtitle (Formation) ///
	legend(lab(1 "Predictions") lab( 2 "SILC")) name(levels, replace) ///
	title("Partnership Termination") ///
	subtitle("")  ///
	xtitle("Dissolution") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	graphregion(color(white)) ///
	legend(size(small)) ///
	note("Notes: Predicted vs observed of dummy indiciating ending a partnership. Estimation sample plotted. Regression if condition" "(${u2_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/partnership/int_validation_${country}_U2_separation_hist_all.jpg", ///
	replace width(2560) height(1440) quality(100)

	
* Year 
use "$dir_data/U2_sample", clear 

xtset idperson swv

gen Lag_ydses_c5 = l.ydses_c5

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
(line pred_dcpex stm, sort color(green) legend(label(1 "Predictions"))) ///
(line dcpex stm, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "Obs"))), ///
	title("Partnership Termination") ///
	subtitle("")  ///
	xtitle("Year") ///
	ytitle("Share")  ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Estimation sample plotted. Regression if condition" "(${u2_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/partnership/int_validation_${country}_U2_separation_ts_all_both.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all
	
restore  

 
* Age
preserve

collapse (mean) dcpex pred_dcpex* [aw = dwt], by(dag)

order pred_dcpex*

egen pred_dcpex = rowmean(pred_dcpex0-pred_dcpex19)

twoway ///
(line pred_dcpex dag, sort color(green) legend(label(1 "Predictions"))) ///
(line dcpex dag, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "SILC"))), ///
title("Partnership Termination") ///
	subtitle("")  ///
	xtitle("Age") ///
	ytitle("Share") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition" "(${u2_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/partnership/int_validation_${country}_U2_separation_share_age.jpg", ///
	replace width(2560) height(1440) quality(100)

restore

* Income 
preserve

xtset idperson swv

collapse (mean) dcpex pred_dcpex* [aw = dwt], by(Lag_ydses_c5 stm)

order pred_dcpex*

egen pred_dcpex = rowmean(pred_dcpex0-pred_dcpex19)

replace stm = 2000 + stm 

twoway ///
(line pred_dcpex stm if Lag_ydses_c5 == 1, sort color(green) ///
	legend(label(1 "Predictions"))) ///
(line dcpex stm if Lag_ydses_c5 == 1, sort color(green) color(green%20) ///
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
(line pred_dcpex stm if Lag_ydses_c5 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpex stm if Lag_ydses_c5 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph2) ///
	 title("Second quintile") ///
	 xtitle("Year") ///
	 ytitle("") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))


twoway ///
(line pred_dcpex stm if Lag_ydses_c5 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpex stm if Lag_ydses_c5 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph3) ///
	title("Third quintile") ///
	xtitle("Year") ///
	ytitle("") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))


twoway ///
(line pred_dcpex stm if Lag_ydses_c5 == 4, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpex stm if Lag_ydses_c5 == 4, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph4) ///
	title("Forth quintile") ///
	xtitle("Year") ///
	ytitle("") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))


twoway ///
(line pred_dcpex stm if Lag_ydses_c5 == 5, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpex stm if Lag_ydses_c5 == 5, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph5) ///
	title("Fifth quintile") ///
	xtitle("Year") ///
	ytitle("") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

grc1leg graph1 graph2 graph3 graph4 graph5,  ///
title("Partnership Termination") ///
	subtitle("By hh income quintile") ///
	legendfrom(graph1) rows(2) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition" "(${u2_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/partnership/int_validation_${country}_U2_separation_ts_all_both_income.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore


* Education
preserve

collapse (mean) dcpex pred_dcpex* [aw = dwt], by(deh_c4 stm)

order pred_dcpex*

egen pred_dcpex = rowmean(pred_dcpex0-pred_dcpex19)

replace stm = 2000 + stm 
twoway ///
(line pred_dcpex stm if deh_c4 == 0, sort color(green) ///
	legend(label(1 "Predictions"))) ///
(line dcpex stm if deh_c4 == 0, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
	name(graph0) ///
	title("In initial education spell") ///
	xtitle("Year") ///
	ytitle("") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))
	

twoway ///
(line pred_dcpex stm if deh_c4 == 1, sort color(green) ///
	legend(label(1 "Predictions"))) ///
(line dcpex stm if deh_c4 == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "SILC"))), ///
	name(graph1) ///
	title("High education") ///
	xtitle("Year") ///
	ytitle("") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_dcpex stm if deh_c4 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpex stm if deh_c4 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph2) ///
	title("Medium education") ///
	xtitle("Year") ///
	ytitle("") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_dcpex stm if deh_c4 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dcpex stm if deh_c4 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
	name(graph3) ///
	title("Low education") ///
	xtitle("Year") ///
	ytitle("") ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

grc1leg graph0 graph1 graph2 graph3,  ///
title("Partnership Termination") ///
	subtitle("")  ///
	legendfrom(graph1) rows(2) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition" "(${u2_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/partnership/int_validation_${country}_U2_separation_all_both_edu.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore

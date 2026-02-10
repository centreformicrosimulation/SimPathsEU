********************************************************************************
* PROJECT:  		ESPON 
* SECTION:			Health 
* OBJECT: 			Internal validation
* AUTHORS:			Ashley Burdett, Aleksandra Kolndrekaj  
* LAST UPDATE:		Jan 2026
* COUNTRY: 			Poland  
********************************************************************************
* NOTES: 			Compares predicted values to the observed values of the 
* 					3 health processes estimated. 
* 					Individual heterogeneity added to the standard predicted 
* 					values form the using a random draw like in stochasitic 
* 					imputation. The pooled mean is obtained as in multiple 
* 					imputation by repeating the random draw 20 times for each 
* 					process. 
* 
* 					Run after "reg_health_PL.do"
********************************************************************************



**********************************************
* H1: Health status, left initial edu spell *
**********************************************

* Overall 
use "$dir_data/H1_sample", clear

sum p1-p5 // inspect negative values 
		
gen p1p2 = p1 + p2 
gen p1p2p3 = p1p2 + p3
gen p1p2p3p4 = p1p2p3 + p4 // generate cumulative probabilities for all options

gen rnd = runiform()
gen pred_health = cond((rnd < p1), 1, cond(rnd < p1p2, 2, ///
	cond(rnd < p1p2p3, 3, cond(rnd < p1p2p3p4, 4, 5))))

keep if in_sample == 1 	
	
twoway (histogram pred_health if in_sample == 1, color(red%30)) ///
	(histogram dhe if in_sample == 1, color(green%30)), ///
	xtitle (Self-rated health) ///
	legend(lab(1 "Pred") lab( 2 "Obs")) name(levels, replace) ///
	title("Health Status") ///
	subtitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	graphregion(color(white)) ///
	legend(size(small)) ///
	note("Notes: Predicted vs observed of self-reported health status. Estimation sample plotted. Regression if condition ($h1_if_condition)." "1 = Poor, ..., 5 = Excellent." , ///
		size(vsmall))
	
graph export "$dir_internal_validation/health/int_validation_${country}_H1_health_hist_all.jpg", ///
	replace	width(2560) height(1440) quality(100)	
	
	
* Year 
use "$dir_data/H1_sample", clear

sum p1-p5 // inspect negative values 
		
gen p1p2 = p1 + p2 
gen p1p2p3 = p1p2 + p3
gen p1p2p3p4 = p1p2p3 + p4 // generate cumulative probabilities for all options

forvalues i = 0/19 {
	local my_seed = 12345 + `i'  
    set seed `my_seed' 	
	gen rnd = runiform() 	
	gen pred_health`i' = cond((rnd < p1), 1, cond(rnd < p1p2, 2, ///
		cond(rnd < p1p2p3, 3, cond(rnd < p1p2p3p4, 4, 5))))
	gen pred_health_poor`i' = (pred_health`i' == 1)
	gen pred_health_fair`i' = (pred_health`i' == 2)
	gen pred_health_good`i' = (pred_health`i' == 3)
	gen pred_health_vgood`i' = (pred_health`i' == 4)
	gen pred_health_excel`i' = (pred_health`i' == 5)
	drop rnd
}

keep if in_sample == 1 

gen health_poor = (dhe == 1)
gen health_fair = (dhe == 2)
gen health_good = (dhe == 3)
gen health_vgood = (dhe == 4)
gen health_excel = (dhe == 5)

preserve 

collapse (mean) health_* pred_health_*  [aw = dwt], by(stm)

order pred_health_poor* pred_health_fair* pred_health_good* ///
	pred_health_vgood* pred_health_excel*

egen pred_health_poor = rowmean(pred_health_poor0-pred_health_poor19)
egen pred_health_fair = rowmean(pred_health_fair0-pred_health_fair19)
egen pred_health_good = rowmean(pred_health_good0-pred_health_good19)
egen pred_health_vgood = rowmean(pred_health_vgood0-pred_health_vgood19)
egen pred_health_excel = rowmean(pred_health_excel0-pred_health_excel19)

replace stm = 2000 + stm 

twoway ///
(line pred_health_poor stm, sort color(green) legend(label(1 "Pred"))) ///
(line health_poor stm, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("Poor ") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_health_fair stm, sort color(green) legend(label(1 "Pred"))) ///
(line health_fair stm, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Fair ") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_health_good stm, sort color(green) legend(label(1 "Pred"))) ///
(line health_good stm, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Good ") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_health_vgood stm, sort color(green) legend(label(1 "Pred"))) ///
(line health_vgood stm, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph4) title("Very good ") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_health_excel stm, sort color(green) legend(label(1 "Pred"))) ///
(line health_excel stm, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph5) title("Excellent ") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))


grc1leg graph1 graph2 graph3 graph4 graph5,  ///
	title("Health Status") ///
	subtitle(" ") ///
	legendfrom(graph1) rows(2) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${h1_if_condition}).", size(vsmall))
		
graph export "$dir_internal_validation/health/int_validation_${country}_H1_health_ts_all_both.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore	


* Gender
preserve 
	
collapse (mean) health_* pred_health_*  [aw = dwt], by(stm dgn)
	
order pred_health_poor* pred_health_fair* pred_health_good* ///
	pred_health_vgood* pred_health_excel*

egen pred_health_poor = rowmean(pred_health_poor0-pred_health_poor19)
egen pred_health_fair = rowmean(pred_health_fair0-pred_health_fair19)
egen pred_health_good = rowmean(pred_health_good0-pred_health_good19)
egen pred_health_vgood = rowmean(pred_health_vgood0-pred_health_vgood19)
egen pred_health_excel = rowmean(pred_health_excel0-pred_health_excel19)

replace stm = 2000 + stm 

* Female
twoway ///
(line pred_health_poor stm if dgn == 0, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line health_poor stm if dgn == 0, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("Poor ") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_health_fair stm if dgn == 0, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line health_fair stm if dgn == 0, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Fair ") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_health_good stm if dgn == 0, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line health_good stm if dgn == 0, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Good ") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_health_vgood stm if dgn == 0, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line health_vgood stm if dgn == 0, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph4) title("Very good ") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_health_excel stm if dgn == 0, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line health_excel stm if dgn == 0, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph5) title("Excellent ") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

grc1leg graph1 graph2 graph3 graph4 graph5,  ///
	title("Health Status") ///
	subtitle("Females ") ///
	legendfrom(graph1) rows(2) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${h1_if_condition}).", size(vsmall))
	
graph export "$dir_internal_validation/health/int_validation_${country}_H1_health_ts_all_female.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	

twoway ///
(line pred_health_poor stm if dgn == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line health_poor stm if dgn == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("Poor ") xtitle("Year") ytitle("")  ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_health_fair stm if dgn == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line health_fair stm if dgn == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Fair ") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_health_good stm if dgn == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line health_good stm if dgn == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Good ") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_health_vgood stm if dgn == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line health_vgood stm if dgn == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph4) title("Very good ") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_health_excel stm if dgn == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line health_excel stm if dgn == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph5) title("Excellent ") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

grc1leg graph1 graph2 graph3 graph4 graph5,  ///
	title("Health Status") ///
	subtitle("Males ") ///
	legendfrom(graph1) rows(2) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${h1_if_condition}).", size(vsmall))
	
graph export "$dir_internal_validation/health/int_validation_${country}_H1_health_ts_all_male.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore

*education

* Gender
preserve 
	
collapse (mean) health_* pred_health_*  [aw = dwt], by(stm deh_c4)
	
order pred_health_poor* pred_health_fair* pred_health_good* ///
	pred_health_vgood* pred_health_excel*

egen pred_health_poor = rowmean(pred_health_poor0-pred_health_poor19)
egen pred_health_fair = rowmean(pred_health_fair0-pred_health_fair19)
egen pred_health_good = rowmean(pred_health_good0-pred_health_good19)
egen pred_health_vgood = rowmean(pred_health_vgood0-pred_health_vgood19)
egen pred_health_excel = rowmean(pred_health_excel0-pred_health_excel19)

replace stm = 2000 + stm 

* education
forvalues i=0(1)3{
	

twoway ///
(line pred_health_poor stm if deh_c4 == `i', sort color(green) ///
	legend(label(1 "Pred"))) ///
(line health_poor stm if deh_c4 == `i', sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("Poor ") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_health_fair stm if deh_c4 == `i', sort color(green) ///
	legend(label(1 "Pred"))) ///
(line health_fair stm if deh_c4 == `i', sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Fair ") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_health_good stm if deh_c4 == `i', sort color(green) ///
	legend(label(1 "Pred"))) ///
(line health_good stm if deh_c4== `i', sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Good ") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_health_vgood stm if deh_c4== `i', sort color(green) ///
	legend(label(1 "Pred"))) ///
(line health_vgood stm if deh_c4== `i', sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph4) title("Very good ") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_health_excel stm if deh_c4 == `i', sort color(green) ///
	legend(label(1 "Pred"))) ///
(line health_excel stm if deh_c4== `i', sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph5) title("Excellent ") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

grc1leg graph1 graph2 graph3 graph4 graph5,  ///
	title("Health Status") ///
	subtitle(" Education level `i' ") ///
	legendfrom(graph1) rows(2) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${h1_if_condition})." "Education level: 0 = in initial education spell, 1 = High, 2 = Medium, 3 = Low.", size(vsmall))
	
graph export "$dir_internal_validation/health/int_validation_${country}_H1_health_ts_all_initial_educ`i'.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
}

restore

***********************************************************
* H2: Long-term sick or disabled, left initial edu spell *
***********************************************************

* Overall 
use "$dir_data/H2_sample", clear 

set seed 12345
gen rnd = runiform() 	
gen pred_dlltsd = 0 
replace pred_dlltsd = 1 if inrange(p,rnd,1)

keep if in_sample == 1 

twoway ///
	(histogram pred_dlltsd, color(red%30)) ///
	(histogram dlltsd, color(green%30)), ///
	xtitle (Disabled/long-term sick ) ///
	legend(lab(1 "Pred") lab( 2 "Obs")) name(levels, replace) ///
	title("Disability/long-term sick") ///
	subtitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	graphregion(color(white)) ///
	legend(size(small)) ///
	note("Notes: Predicted vs observed of disability/long-term sick dummy. Estimation sample plotted. Regression if condition (${h2_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/health/int_validation_${country}_H2_disablilty_hist_all.jpg", ///
	replace width(2560) height(1440) quality(100)


* Year 
use "$dir_data/H2_sample", clear

// construct multiple versions of the predicted outcome allowing for different 
// random draws 
forvalues i = 0/19 {
	local my_seed = 12345 + `i'  
    set seed `my_seed' 	
	gen rnd = runiform() 	
	gen pred_dlltsd`i' = 0 
	replace pred_dlltsd`i' = 1 if inrange(p,rnd,1)
	drop rnd
}

keep if in_sample == 1 
preserve 
// for each iteration calculate the share that leave edu 
collapse (mean) dlltsd pred_dlltsd* [aw = dwt], by(stm)

order pred_dlltsd*

// take the average across datasets 
egen pred_dlltsd = rowmean(pred_dlltsd0-pred_dlltsd19)
replace stm = 2000 + stm 

twoway ///
(line pred_dlltsd stm, sort color(green) legend(label(1 "Pred"))) ///
(line dlltsd stm, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "Obs"))), ///
	title("Disability/long-term sick") ///
	subtitle("") ///
	xtitle("Year") ///
	ytitle("Share")  ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${h2_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/health/int_validation_${country}_H2_disablilty_ts_all_both.jpg", ///
	replace width(2560) height(1440) quality(100)
 
graph drop _all 
 
restore  
 
 
* Age
preserve

collapse (mean) dlltsd pred_dlltsd* [aw = dwt], by(dag)

order pred_dlltsd*

egen pred_dlltsd = rowmean(pred_dlltsd0-pred_dlltsd19)

twoway ///
(line pred_dlltsd dag, sort color(green) legend(label(1 "Pred"))) ///
(line dlltsd dag, sort color(green) color(green%20) lpattern(dash) ///
	legend(label(2 "Obs"))), ///
	title("Disability/long-term sick") ///
	subtitle("Share by age") ///
	xtitle("Age") ///
	ytitle("Share")  ///
	graphregion(color(white)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(size(small)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${h2_if_condition}).", size(vsmall))

graph export "$dir_internal_validation/health/int_validation_${country}_H2_disablilty_share_age.jpg", ///
	replace width(2560) height(1440) quality(100)

graph drop _all 	
	
restore


* Income 
preserve

collapse (mean) dlltsd pred_dlltsd* [aw = dwt], by(ydses_c5 stm)

order pred_dlltsd*

egen pred_dlltsd = rowmean(pred_dlltsd0-pred_dlltsd19)

replace stm = 2000 + stm 

twoway ///
(line pred_dlltsd stm if ydses_c5 == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dlltsd stm if ydses_c5 == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("First quintile") xtitle("Year") ytitle("")  ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_dlltsd stm if ydses_c5 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dlltsd stm if ydses_c5 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Second quintile") xtitle("Year") ytitle("")  ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_dlltsd stm if ydses_c5 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dlltsd stm if ydses_c5 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Third quintile") xtitle("Year") ytitle("")  ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_dlltsd stm if ydses_c5 == 4, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dlltsd stm if ydses_c5 == 4, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph4) title("Forth quintile") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_dlltsd stm if ydses_c5 == 5, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dlltsd stm if ydses_c5 == 5, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph5) title("Fifth quintile") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

grc1leg graph1 graph2 graph3 graph4 graph5,  ///
	title("Disability/long-term sick") ///
	subtitle("By hh income quintile") ///
	legendfrom(graph1) rows(2) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${h2_if_condition}).", size(vsmall))
	
graph export "$dir_internal_validation/health/int_validation_${country}_H2_disablilty_ts_all_both_income.jpg", ///
	replace width(2560) height(1440) quality(100)	
	

graph drop _all 	
	
restore


* Education
preserve

collapse (mean) dlltsd pred_dlltsd* [aw = dwt], by(deh_c4 stm)

order pred_dlltsd*

egen pred_dlltsd = rowmean(pred_dlltsd0-pred_dlltsd19)

replace stm = 2000 + stm 

twoway ///
(line pred_dlltsd stm if deh_c4 == 0, sort color(green) ///
	legend(label(1 "Pre"))) ///
(line dlltsd stm if deh_c4 == 0, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), /// 
name(graph0) title("Initial education spell") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))


twoway ///
(line pred_dlltsd stm if deh_c4 == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dlltsd stm if deh_c4 == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), /// 
name(graph1) title("High education") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_dlltsd stm if deh_c4 == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dlltsd stm if deh_c4 == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Medium education") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_dlltsd stm if deh_c4 == 3, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dlltsd stm if deh_c4 == 3, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph3) title("Low education") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

grc1leg graph0 graph1 graph2 graph3 ,  ///
	title("Disability/long-term sick") ///
	subtitle("") ///
	legendfrom(graph1) rows(2) ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${h2_if_condition}).", size(vsmall))
	
graph export "$dir_internal_validation/health/int_validation_${country}_H2_disablilty_ts_all_both_edu.jpg", ///
	replace width(2560) height(1440) quality(100)	
	
graph drop _all 	
	
restore


* Marital status 
preserve

collapse (mean) dlltsd pred_dlltsd* [aw = dwt], by(dcpst stm)

order pred_dlltsd*

egen pred_dlltsd = rowmean(pred_dlltsd0-pred_dlltsd19)

replace stm = 2000 + stm 

twoway ///
(line pred_dlltsd stm if dcpst == 1, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dlltsd stm if dcpst == 1, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph1) title("Partnered") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

twoway ///
(line pred_dlltsd stm if dcpst == 2, sort color(green) ///
	legend(label(1 "Pred"))) ///
(line dlltsd stm if dcpst == 2, sort color(green) color(green%20) ///
	lpattern(dash) legend(label(2 "Obs"))), ///
name(graph2) title("Single") xtitle("Year") ytitle("") ///
	xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	legend(size(small)) ///
	graphregion(color(white))

grc1leg graph1 graph2 ,  ///
	title("Disability/long-term sick") ///
	subtitle("") ///
	graphregion(color(white)) ///
	note("Notes: Estimation sample plotted. Regression if condition (${h2_if_condition}).", size(vsmall))
	
graph export "$dir_internal_validation/health/int_validation_${country}_H2_disablilty_left_edu_ts_all_both_partnership.jpg", ///
	replace width(2560) height(1440) quality(100)	

graph drop _all 	
	
restore

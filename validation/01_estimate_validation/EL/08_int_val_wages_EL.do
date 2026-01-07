********************************************************************************
* PROJECT:  		ESPON 
* SECTION:			Wages
* OBJECT: 			Internal validation
* AUTHORS:			Ashley Burdett 
* LAST UPDATE:		May 2025
* COUNTRY: 			Greece  

* NOTES: 			Compares predicted values to the observed values of the 
* 					3 education processes estimated. 
* 					Individual heterogeneity added to the standard predicted 
* 					values form the using a random draw like in stochasitic 
* 					imputation. The pooled mean is obtained as in multiple 
* 					imputation by repeating the random draw 20 times for each 
* 					process. 
* 
* 					Run after "reg_income_EL.do"
********************************************************************************

* Female - No previous wage 

use "$dir_data/Female_NPW_sample", clear

* Correct bias when transforming from log to levels 
cap drop epsilon
gen epsilon = rnormal()*e(sigma) 

replace pred_hourly_wage = exp(lwage_hour_hat + epsilon) if in_sample_fnpw 
 
twoway (hist pred_hourly_wage if in_sample_fnpw == 1, ///
		width(1) color(red%30)) ///
	(hist wage_hour if in_sample_fnpw == 1, width(1) ///
	color(green%30)), ///
	title("Hourly Wages") ///
	subtitle("Females, no previous wage observed") ///
	xtitle (Gross hourly wages (Euro)) legend(lab(1 "Observed") ///
	lab( 2 "Predicted")) name(log, replace) ///
	graphregion(color(white)) ///
	legend(size(small)) ///
	note("Notes: Sample includes working age (18-64) females. Predictions obtained from the estimates of  a Heckman model.", size(vsmall))
	
graph export ///
	"$dir_internal_validation/wages/int_validation_${country}_wages_hist_f_npw.pdf", replace
	
	
* Male - No previous wage 

use "$dir_data/Male_NPW_sample", clear

* Correct bias when transforming from log to levels 
cap drop epsilon
gen epsilon = rnormal()*e(sigma) 

replace pred_hourly_wage = exp(lwage_hour_hat + epsilon) if in_sample_fnpw 
 
twoway (hist pred_hourly_wage if in_sample_mnpw == 1, ///
		width(1) color(red%30)) ///
	(hist wage_hour if in_sample_mnpw == 1, width(1) ///
	color(green%30)), ///
	title("Hourly Wages") ///
	subtitle("Males, no previous wage observed") ///
	xtitle (Gross hourly wages (Euro)) legend(lab(1 "Observed") ///
	lab( 2 "Predicted")) name(log, replace) ///
	graphregion(color(white)) ///
	legend(size(small)) ///
	note("Notes: Sample includes working age (18-64) males. Predictions obtained from the estimates of  a Heckman model.", size(vsmall))
	
graph export ///
	"$dir_internal_validation/wages/int_validation_${country}_wages_hist_m_npw.pdf", replace	
	
	
* Female - Previous wage 

use "$dir_data/Female_PW_sample", clear

* Correct bias when transforming from log to levels 
cap drop epsilon
gen epsilon = rnormal()*e(sigma) 

replace pred_hourly_wage = exp(lwage_hour_hat + epsilon) if in_sample_fnpw 
 
twoway (hist pred_hourly_wage if in_sample_fpw == 1, ///
		width(1) color(red%30)) ///
	(hist wage_hour if in_sample_fpw == 1, width(1) ///
	color(green%30)), ///
	title("Hourly Wages") ///
	subtitle("Females, previous wage observed") ///
	xtitle (Gross hourly wages (Euro)) legend(lab(1 "Observed") ///
	lab( 2 "Predicted")) name(log, replace) ///
	graphregion(color(white)) ///
	legend(size(small)) ///
	note("Notes: Sample includes working age (18-64) females. Predictions obtained from the estimates of  a Heckman model.", size(vsmall))
	
graph export ///
	"$dir_internal_validation/wages/int_validation_${country}_wages_hist_f_pw.pdf", replace	
	
	
* Male - Previous wage 

use "$dir_data/Male_PW_sample", clear

* Correct bias when transforming from log to levels 
cap drop epsilon
gen epsilon = rnormal()*e(sigma) 

replace pred_hourly_wage = exp(lwage_hour_hat + epsilon) if in_sample_fnpw 
 
twoway (hist pred_hourly_wage if in_sample_fpw == 1, ///
		width(1) color(red%30)) ///
	(hist wage_hour if in_sample_fpw == 1, width(1) ///
	color(green%30)), ///
	title("Hourly Wages") ///
	subtitle("Males, previous wage observed") ///
	xtitle (Gross hourly wages (Euro)) legend(lab(1 "Observed") ///
	lab( 2 "Predicted")) name(log, replace) ///
	graphregion(color(white)) ///
	legend(size(small)) ///
	note("Notes: Sample includes working age (18-64) males. Predictions obtained from the estimates of  a Heckman model.", size(vsmall))
	
graph export ///
	"$dir_internal_validation/wages/int_validation_${country}_wages_hist_m_pw.pdf", replace		
	

graph drop _all



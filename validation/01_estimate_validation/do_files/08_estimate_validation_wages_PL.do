********************************************************************************
* PROJECT:  		SimPaths EU 
* SECTION:			Wages
* OBJECT: 			Internal validation
* AUTHORS:			Ashley Burdett, Aleksandra Kolndrekaj 
* LAST UPDATE:		Feb 2026
* COUNTRY: 			Poland  
********************************************************************************
* NOTES: 			
* 
* 				
********************************************************************************

/******************** WAGES: FEMALE, NO PREV WAGE OBSERVED *********************/

local filter = "${W1fa_if_condition} & previouslyWorking == 0"


use "$dir_data/Female_NPW_sample", clear

twoway (hist wage_hour if `filter' & (!missing(wage_hour)) & ///
	in_sample_fnpw == 1 , width(0.5) lcolor(green%30) fcolor(green%30)) ///
	(hist pred_hourly_wage if `filter' & (!missing(wage_hour)) & ///
	in_sample_fnpw == 1, width(0.5) fcolor(none) lcolor(red)), ///
	title("Gross Hourly Wage (Level)") ///
	subtitle("Females, No previously observed wage") ///
	ytitle(,size(small)) ///
	xtitle(€, size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(lab(1 "SILC") lab(2 "Prediction")) ///
	graphregion(color(white)) ///
	note("Notes: Second stage estimation sample plotted. Sample condition" "(${W1fa_if_condition} & previouslyWorking == 0).", size(vsmall))	

graph export ///
	"$dir_internal_validation/wages/int_validation_${country}_wages_hist_f_npw.jpg", replace


sum wage_hour if `filter' & (!missing(wage_hour)) & in_sample_fnpw == 1 [aw=dwt]
sum pred_hourly_wage if `filter' & (!missing(wage_hour)) & ///
	in_sample_fnpw == 1 [aw=dwt]
	
	
* Mean by age 

use "$dir_data/Female_NPW_sample", clear

preserve
    collapse (mean) wage_hour pred_hourly_wage if ${W1fa_if_condition} & ///
	lwage_hour != . , by(dag)
    
    twoway (scatter wage_hour dag, mcolor(grey%40)) ///
           (line pred_hourly_wage dag, lcolor(blue) lwidth(medthick)), ///
           title("Observed vs. Predicted Wages ") ///
           xtitle("Age") ytitle("Hourly Wage") ///
           legend(label(1 "Observed Mean") label(2 "Predicted ")) ///
		   graphregion(color(white)) 
restore


preserve
    collapse (mean) lwage_hour lwage_hour_hat if ${W1fa_if_condition} & ///
	lwage_hour != . , by(dag)
    
    twoway (scatter lwage_hour dag, mcolor(grey%40)) ///
           (line lwage_hour_hat dag, lcolor(blue) lwidth(medthick)), ///
           title("Observed vs. Predicted Wages ") ///
           xtitle("Age") ytitle("Log Hourly Wage") ///
           legend(label(1 "Observed Mean") label(2 "Predicted ")) ///
		   graphregion(color(white)) 
restore 	
	
	


/********************* WAGES: MALE, NO PREV WAGE OBSERVED *********************/

local filter = "${W1ma_if_condition} & previouslyWorking == 0"


use "$dir_data/Male_NPW_sample", clear

twoway (hist wage_hour if `filter' & (!missing(wage_hour)) & ///
	in_sample_mnpw == 1 , width(0.5) lcolor(green%30) fcolor(green%30)) ///
	(hist pred_hourly_wage if `filter' & (!missing(wage_hour)) & ///
	in_sample_mnpw == 1, width(0.5) fcolor(none) lcolor(red)), ///
	title("Gross Hourly Wage (Level)") ///
	subtitle("Females, No previously observed wage") ///
	ytitle(,size(small)) ///
	xtitle(€, size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(lab(1 "SILC") lab(2 "Prediction")) ///
	graphregion(color(white)) ///
	note("Notes: Second stage estimation sample plotted. Sample condition" "(${W1ma_if_condition} & previouslyWorking == 0).", size(vsmall))	

graph export ///
	"$dir_internal_validation/wages/int_validation_${country}_wages_hist_m_npw.jpg", replace


sum wage_hour if `filter' & (!missing(wage_hour)) & in_sample_mnpw == 1 [aw=dwt]
sum pred_hourly_wage if `filter' & (!missing(wage_hour)) & ///
	in_sample_mnpw == 1 [aw=dwt]
	
	
* Mean by age 

use "$dir_data/Male_NPW_sample", clear

preserve
    collapse (mean) wage_hour pred_hourly_wage if ${W1ma_if_condition} & ///
	lwage_hour != . , by(dag)
    
    twoway (scatter wage_hour dag, mcolor(grey%40)) ///
           (line pred_hourly_wage dag, lcolor(blue) lwidth(medthick)), ///
           title("Observed vs. Predicted Wages ") ///
           xtitle("Age") ytitle("Hourly Wage") ///
           legend(label(1 "Observed Mean") label(2 "Predicted "))  ///
		   graphregion(color(white)) 
restore


preserve
    collapse (mean) lwage_hour lwage_hour_hat if ${W1ma_if_condition} & ///
	lwage_hour != . , by(dag)
    
    twoway (scatter lwage_hour dag, mcolor(grey%40)) ///
           (line lwage_hour_hat dag, lcolor(blue) lwidth(medthick)), ///
           title("Observed vs. Predicted Wages ") ///
           xtitle("Age") ytitle("Log Hourly Wage") ///
           legend(label(1 "Observed Mean") label(2 "Predicted ")) ///
		   graphregion(color(white)) 
restore 	


/********************** WAGES: FEMALE, PREV WAGE OBSERVED *********************/

use "$dir_data/Female_PW_sample", clear

twoway (hist wage_hour if ${W1fb_if_condition} & (!missing(wage_hour)) & ///
	in_sample_fpw == 1 , width(0.5) lcolor(green%30) fcolor(green%30)) ///
	(hist pred_hourly_wage if ${W1fb_if_condition} & (!missing(wage_hour)) & ///
	in_sample_fpw == 1, width(0.5) fcolor(none) lcolor(red)), ///
	title("Gross Hourly Wage (Level)") ///
	subtitle("Females, Previously observed wage") ///
	ytitle(,size(small)) ///
	xtitle(€, size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(lab(1 "SILC") lab(2 "Prediction")) ///
	graphregion(color(white)) ///
	note("Notes: Second stage estimation sample plotted. Sample condition" "(${W1fb_if_condition}).", size(vsmall))	

graph export ///
	"$dir_internal_validation/wages/int_validation_${country}_wages_hist_f_pw.jpg", replace

	
sum wage_hour if ${W1fb_if_condition} [aw=dwt]
sum pred_hourly_wage if ${W1fb_if_condition} & (!missing(wage_hour)) [aw=dwt]

	
* Mean by age 

use "$dir_data/Female_PW_sample", clear

preserve
    collapse (mean) wage_hour pred_hourly_wage if ${W1fb_if_condition} & ///
	lwage_hour != . , by(dag)
    
    twoway (scatter wage_hour dag, mcolor(grey%40)) ///
           (line pred_hourly_wage dag, lcolor(blue) lwidth(medthick)), ///
           title("Observed vs. Predicted Wages") ///
           xtitle("Age") ytitle("Hourly Wage") ///
           legend(label(1 "Observed Mean") label(2 "Predicted ")) ///
		   graphregion(color(white)) 
restore


preserve
    collapse (mean) lwage_hour lwage_hour_hat if ${W1fb_if_condition} & ///
	lwage_hour != . , by(dag)
    
    twoway (scatter lwage_hour dag, mcolor(grey%40)) ///
           (line lwage_hour_hat dag, lcolor(blue) lwidth(medthick)), ///
           title("Observed vs. Predicted Wages") ///
           xtitle("Age") ytitle("Log Hourly Wage") ///
           legend(label(1 "Observed Mean") label(2 "Predicted ")) ///
		   graphregion(color(white)) 
restore 	
	
	
/*********************** WAGES:MALE, PREV WAGE OBSERVED ***********************/
		
use "$dir_data/Male_PW_sample", clear

twoway (hist wage_hour if ${W1mb_if_condition} & (!missing(wage_hour)) & ///
	in_sample_mpw == 1 , width(0.5) lcolor(green%30) fcolor(green%30)) ///
	(hist pred_hourly_wage if ${W1mb_if_condition} & (!missing(wage_hour)) & ///
	in_sample_mpw == 1, width(0.5) fcolor(none) lcolor(red)), ///
	title("Gross Hourly Wage (Level)") ///
	subtitle("Males, Previously observed wage") ///
	ytitle(,size(small)) ///
	xtitle(€, size(small)) ///
	xlabel(, labsize(small)) ///
	ylabel(, labsize(small)) ///
	legend(lab(1 "SILC") lab(2 "Prediction")) ///
	graphregion(color(white)) ///
	note("Notes: Second stage estimation sample plotted. Sample condition" "(${W1mb_if_condition}).", size(vsmall))	

graph export ///
	"$dir_internal_validation/wages/int_validation_${country}_wages_hist_m_pw.jpg", replace

	
sum wage_hour if ${W1fb_if_condition} [aw=dwt]
sum pred_hourly_wage if ${W1fb_if_condition} & (!missing(wage_hour)) [aw=dwt]


* Mean by age 

use "$dir_data/Male_PW_sample", clear

preserve
    collapse (mean) wage_hour pred_hourly_wage if ${W1mb_if_condition} & ///
	lwage_hour != . , by(dag)
    
    twoway (scatter wage_hour dag, mcolor(grey%40)) ///
           (line pred_hourly_wage dag, lcolor(blue) lwidth(medthick)), ///
           title("Observed vs. Predicted Wages ") ///
           xtitle("Age") ytitle("Hourly Wage") ///
           legend(label(1 "Observed Mean") label(2 "Predicted ")) ///
		   graphregion(color(white)) 
restore


preserve
    collapse (mean) lwage_hour lwage_hour_hat if ${W1mb_if_condition} & ///
	lwage_hour != . , by(dag)
    
    twoway (scatter lwage_hour dag, mcolor(grey%40)) ///
           (line lwage_hour_hat dag, lcolor(blue) lwidth(medthick)), ///
           title("Observed vs. Predicted Wages ") ///
           xtitle("Age") ytitle("Log Hourly Wage") ///
           legend(label(1 "Observed Mean") label(2 "Predicted ")) ///
		   graphregion(color(white)) 
restore 


graph drop _all 


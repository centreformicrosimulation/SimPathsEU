/*******************************************************************************
* PROJECT:  		SimPaths EU 
* SECTION:			Wage regression 
* OBJECT: 			Heckman selection regressions 
* AUTHORS:			Daria Popova, Justin van de Ven, Ashley Burdett
* LAST UPDATE:		Feb 2025
* COUNTRY: 			Poland
******************************************************************************** 
* NOTES: 			Strategy: Pooled cross-sectional regressions. 
* 					1) Heckman estimated on the sub-sample of individuals 
* 						who are not observed working in previous period. 
*   					=> Wage equation does not controls for lagged wage
* 					2) Heckman estimated on the sub-sample of individuals who 
* 						are observed working in previous period. 
*    					=> Wage equation controls for lagged wage
* 					Specification of selection equation is the same in the 
* 						two samples
* 					
* 					Import labour cost index to create a measure of wage growth. 
* 					Make sure loaded into the external_data subfolder. 
* 
* 					Update the winsorization process if alter data 
* 					Update CPI if apply to a different country 
*******************************************************************************/

clear all
set more off
set mem 200m
set type double
set maxvar 30000

* Set off log 
cap log close 
log using "$dir_log/reg_wages.log", replace


/********************************* SET EXCEL FILE *****************************/

* Info sheet - first stage 
putexcel set "$dir_work/reg_employmentSelection_${country}", sheet("Info") ///
	replace
putexcel A1 = "Description:", bold
putexcel B1 = "This file contains regression estimates from the first stage of the Heckman selection model used to estimates wages."

putexcel A2 = "Authors:", bold
putexcel B2 = "Ashley Burdett, Aleksandra Kolndrekaj" 	
putexcel A3 = "Last edit:", bold
putexcel B3 = "12 Jan 2016 AB"

putexcel A5 = "Process:", bold
putexcel B5 = "Description:", bold
putexcel A6 = "W1fa-sel"
putexcel B6 = "First stage Heckman selection estimates for women that do not have an observed wage in the previous year"
putexcel A7 = "W1ma-sel"
putexcel B7 = "First stage Heckman selection estimates for women that do not have an observed wage in the previous year"
putexcel A8 = "W1fb-sel"
putexcel B8 = "First stage Heckman selection estimates for women that have an observed wage in the previous year"
putexcel A9 = "W1mb-sel"
putexcel B9 = "First stage Heckman selection estimates for men that have an observed wage in the previous year"

putexcel A12 = "Notes:", bold
putexcel B12 = "Estimated on panel data unlike the labour supply estimates"
putexcel B13 = "Predicted wages used as input into union parameters and income process estimates"
putexcel B14 = "Two-step Heckman command is used which does not permit weights"
putexcel B15 = "Regions: PL4 = Polnocno-Zachodni, PL5 = Poludniowo-Zachodni, PL6 = Polnocy, PL10 = Central + East. Poludniowy is the omitted category."
putexcel B16 = "Estimate the models without the lagged wage observation on the full working age sample. Choice made because otherwise the reduction in the sample size makes the sigma used when correcting the bias when transforming the log wages to wage levels too large."

* Info sheet - second stage 
putexcel set "$dir_work/reg_wages_${country}", sheet("Info") replace
putexcel A1 = "Description:", bold
putexcel B1 = "This file contains regression estimates used to calculate potential wages for males and females in the simulation."

putexcel A2 = "Authors:", bold
putexcel B2 = "Ashley Burdett, Aleksandra Kolndrekaj" 	
putexcel A3 = "Last edit:", bold
putexcel B3 = "12 Jan 2016 AB"

putexcel A5 = "Process:", bold
putexcel B5 = "Description:", bold
putexcel A6 = "W1fa"
putexcel B6 = "Heckman selection estimates using women that do not have an observed wage in the previous year"
putexcel A7 = "W1ma"
putexcel B7 = "Heckman selection estimates using men that do not have an observed wage in the previous year"
putexcel A8 = "W1fb"
putexcel B8 = "Heckman selection estimates using women that have an observed wage in the previous year"
putexcel A9 = "W1mb"
putexcel B9 = "Heckman selection estimates using men that have an observed wage in the previous year"

putexcel A12 = "Notes:", bold
putexcel B12 = "Estimated on panel data unlike the labour supply estimates"
putexcel B13 = "Predicted wages used as input into union parameters and income process estimates"
putexcel B14 = "Two-step Heckman command is used which does not permit weights"
putexcel B15 = "Regions: PL4 = Polnocno-Zachodni, PL5 = Poludniowo-Zachodni, PL6 = Polnocy, PL10 = Central + East. Poludniowy is the omitted category."
putexcel B16 = "Estimate the models without the lagged wage observation on the full working age sample. Choice made because otherwise the reduction in the sample size makes the sigma used when correcting the bias when transforming the log wages to wage levels too large."


/********************************* PREPARE DATA *******************************/

* Convert real wage growth into .dta file

import excel "$dir_data/time_series_factor.xlsx", sheet("wage_growth") ///
	firstrow clear

rename Year swv 

gen stm = swv - 2000
drop swv 

rename Value real_wage_growth 

save "$dir_data/growth_rates", replace

* Load main dataset
use "$dir_input_data/${country}_pooled_ipop.dta", clear

* Set data
xtset idperson swv 
sort idperson swv

* Ensure missing is missing
recode deh_c3 deh_c4 obs_earning lhw drgn1 dhe les_c3 les_c4 (-9=.)

* Drop children 
drop if dag < ${age_seek_employment}

* Adjust variables 

* Time variables 
* Centre time variables 
replace stm = stm - 2000
replace swv = swv - 2010

* Year dummies
gen y2011 = (stm == 11)
gen y2012 = (stm == 12)
gen y2013 = (stm == 13)
gen y2014 = (stm == 14)
gen y2015 = (stm == 15)
gen y2016 = (stm == 16)
gen y2017 = (stm == 17)
gen y2018 = (stm == 18)
gen y2019 = (stm == 19)
gen y2020 = (stm == 20)
gen y2021 = (stm == 21)
gen y2022 = (stm == 22)
gen y2023 = (stm == 23)

sort idperson swv 

gen L1les_c3 = L.les_c3

replace deh_c3 = . if deh_c4 == 0 

* Merge in wage growth index
merge m:1 stm using "$dir_data/growth_rates", keep(3) nogen ///
	keepusing(real_wage_growth)

* Check idperson and stm ensures uniqueness
duplicates tag idperson stm, gen(dup)

sort idperson stm
xtset idperson stm

* Total hours work per week (average)
gen hours = 0
replace hours = lhw if ((lhw > 0) & (lhw < .))
label var hours "Hours worked per week"

* Hour groups
gen hrs1 = (hours >   0) * (hours < 10)
gen hrs2 = (hours >= 10) * (hours < 15)
gen hrs3 = (hours >= 15) * (hours < 20)
gen hrs4 = (hours >= 20) * (hours < 25)
gen hrs5 = (hours >= 25) * (hours < 30)
gen hrs6 = (hours >= 30) * (hours < 35)
gen hrs7 = (hours >= 35) * (hours < 40)


lab var yplgrs_dv "Gross personal employment income, IHS"

* Hourly wage	
gen wage_hour = obs_earnings_hourly
	
* Winsorize
sum wage_hour, det
replace wage_hour = . if wage_hour <= 0
replace wage_hour = . if wage_hour >= r(p99)

gen lwage_hour = ln(wage_hour)
label var lwage_hour "Log gross hourly wage"

gen lwage_hour_2 = lwage_hour^2
label var lwage_hour_2 "Squared log gross hourly wage"

* Part-time dummy
gen pt = (hours >  0) * (hours <= 25)
label var pt "Works part-time"

* Create exclusion restrictions 
* Relationship status 
gen mar = (dcpst == 1)
label var mar "In a partnership"

* Children
gen any02 = dnc02 > 0 & dnc02 != . 
label var any02 "Has children between 0-2 years old"

cap gen child = (dnc > 0 & dnc != .)
label var child "Has children"

* Set data 
sort idperson stm
xtset idperson stm

* Flag to identify observations to be included in the estimation sample 
* Need to have been observed at least once in the past and activity information 
* is not missing in the previous observation 
bys idperson (swv): gen obs_count_ttl = _N
bys idperson(swv): gen obs_count = _n

gen in_sample = (obs_count_ttl > 1 & obs_count > 1) 
replace in_sample = 0 if swv != swv[_n-1] +1 & idperson == idperson[_n-1]
replace in_sample = 0 if les_c3 == . | obs_earning == . 

* Flag to distinguish the two samples (prev work and not)
xtset idperson swv 
sort idperson swv 

capture drop previouslyWorking

gen previouslyWorking = (L1.lwage_hour != .) 
replace previouslyWorking = . if in_sample == 0 

* Prep storage 
capture drop lwage_hour_hat wage_hour_hat esample

gen lwage_hour_hat = .
gen wage_hour_hat = .
gen esample = .
gen pred_hourly_wage = .


/********************************** ESTIMATION ********************************/

/******************** WAGES: FEMALE, NO PREV WAGE OBSERVED ********************/

global wage_eqn "lwage_hour dag dagsq i.deh_c3 i.deh_c3#c.dag i.dhe i.drgn1 i.pt real_wage_growth y2020 y2021"
global seln_eqn "i.L1les_c3 dag dagsq i.deh_c3 i.deh_c3#c.dag i.mar i.child i.dhe i.drgn1 y2020 y2021" 
local filter = "${W1fa_if_condition} & previouslyWorking == 0"

heckman $wage_eqn if ${W1fa_if_condition}, select($seln_eqn) twostep mills(lambda)


* Save raw restults
outreg2 stats(coef se pval) using "$dir_raw_results/wages/W1fa.doc", replace ///
	title("Heckman-corrected wage equation estimated on the sample of women who were not in employment last year") ///
	ctitle(Not working women) label side dec(2) noparen 	
	
* Obtain predicted values (log wage) with selection correction
predict pred if `filter', ycond  
replace lwage_hour_hat = pred if `filter'

gen in_sample_fnpw = e(sample)	

* Correct bias when transforming from log to levels 
cap drop epsilon
gen epsilon = rnormal()*e(sigma) 

replace pred_hourly_wage = exp(lwage_hour_hat + epsilon) if `filter' 
 
* Save sample validation 
save "$dir_data/Female_NPW_sample", replace 
	
cap drop pred epsilon	
	
* Formatted results
* Clean up matrix of estimates 
* Note: Zeros values are eliminated 
matrix b = e(b)	
matrix V = e(V)

* Store variance-covariance matrix 
preserve

putexcel set "$dir_data/var_cov", sheet("var_cov") replace
putexcel A1 = matrix(V)

import excel "$dir_data/var_cov", sheet("var_cov") clear

describe
local no_vars = `r(k)'	
	
forvalues i = 1/2 {
	
	egen row_sum = rowtotal(*)
	drop if row_sum == 0 
	drop row_sum
	xpose, clear	

}	
	
mkmat v*, matrix(var)	

* Second stage
putexcel set "$dir_data/reg_wages_${country}", sheet("W1fa") replace
putexcel C2 = matrix(var)
		
restore	

* Store estimated coefficients 
* Initialize a counter for non-zero coefficients
local non_zero_count = 0
//local names : colnames b

* Loop through each element in `b` to count non-zero coefficients
forvalues i = 1/`no_vars' {
    if (b[1, `i'] != 0) {
	
        local non_zero_count = `non_zero_count' + 1
    
	}
}

* Create a new row vector to hold only non-zero coefficients
matrix nonzero_b = J(1, `non_zero_count', .)

* Populate nonzero_b with non-zero coefficients from b
local index = 1

forvalues i = 1/`no_vars' {
    if (b[1, `i'] != 0) {
	
        matrix nonzero_b[1, `index'] = b[1, `i']
        local index = `index' + 1
    
	}
}

putexcel set "$dir_data/reg_wages_${country}", sheet("W1fa") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 

preserve

import excel "$dir_data/reg_wages_${country}", sheet("W1fa") ///
	firstrow clear

drop if C == 0 // UPDATE 
drop A 
drop V-AP

mkmat *, matrix(Females_NLW)
putexcel set "$dir_work/reg_wages_${country}", sheet("W1fa") modify 
putexcel B2 = matrix(Females_NLW)

restore 

* Labelling 
putexcel set "$dir_work/reg_wages_${country}", sheet("W1fa") modify 

local var_list Dag Dag_sq Deh_c3_Medium Deh_c3_Low Deh_c3_Medium_Dag ///
	Deh_c3_Low_Dag Dhe_Fair Dhe_Good Dhe_VeryGood Dhe_Excellent ///
	PL4 PL5 PL6 PL10 Pt RealWageGrowth Y2020 Y2021 Constant InverseMillsRatio

putexcel A1 = "REGRESSOR"
putexcel B1 = "COEFFICIENT"

local i = 1 	
foreach var in `var_list' {
	local ++i
	
	putexcel A`i' = "`var'"
	
} 	

local i = 2 	
foreach var in `var_list' {
    local ++i

    if `i' <= 26 {
        local letter = char(64 + `i')  // Convert 1=A, 2=B, ..., 26=Z
        putexcel `letter'1 = "`var'"
    }
    else {
        local first = char(64 + int((`i' - 1) / 26))  // First letter: A-Z
        local second = char(65 + mod((`i' - 1), 26)) // Second letter: A-Z
        putexcel `first'`second'1 = "`var'"  // Correctly places AA-ZZ
    }
}
	
* Calculate RMSE 
capture drop residuals squared_residuals  

gen residuals = lwage_hour - lwage_hour_hat
gen squared_residuals = residuals^2

preserve 
keep if `filter'
sum squared_residuals 
di "RMSE for Not employed women:  " sqrt(r(mean))

putexcel set "$dir_work/reg_RMSE_${country}.xlsx", sheet("${country}") replace
putexcel A1 = ("REGRESSOR") B1 = ("COEFFICIENT") ///
	A2 = ("W1fa") B2 = (sqrt(r(mean))) 
restore 

* First stage
preserve

import excel "$dir_data/reg_wages_${country}", sheet("W1fa") firstrow clear

drop if V == 0 // UPDATE
drop A 
drop C-U
drop AQ

mkmat *, matrix(Females_NLW)
putexcel set "$dir_work/reg_employmentSelection_${country}", ///
	sheet("W1fa-sel") modify 
putexcel B2 = matrix(Females_NLW)

restore 

* Labelling 
putexcel set "$dir_work/reg_employmentSelection_${country}", ///
	sheet("W1fa-sel") modify 
	
local var_list Les_c3_Student_L1 Les_c3_NotEmployed_L1 Dag Dag_sq ///
	Deh_c3_Medium Deh_c3_Low Deh_c3_Medium_Dag  Deh_c3_Low_Dag ///
	Dcpst_Partnered D_Children Dhe_Fair Dhe_Good ///
	Dhe_VeryGood Dhe_Excellent PL4 PL5 PL6 PL10 Y2020 Y2021 ///
	Constant	

putexcel A1 = "REGRESSOR"
putexcel B1 = "COEFFICIENT"

local i = 1 	
foreach var in `var_list' {
	local ++i
	
	putexcel A`i' = "`var'"
	
} 	

local i = 2 	
foreach var in `var_list' {
    local ++i

    if `i' <= 26 {
        local letter = char(64 + `i')  // Convert 1=A, 2=B, ..., 26=Z
        putexcel `letter'1 = "`var'"
    }
    else {
        local first = char(64 + int((`i' - 1) / 26))  // First letter: A-Z
        local second = char(65 + mod((`i' - 1), 26)) // Second letter: A-Z
        putexcel `first'`second'1 = "`var'"  // Correctly places AA-ZZ
    }
}

cap drop lambda


/********************* WAGES: MALE, NO PREV WAGE OBSERVED *********************/

global wage_eqn "lwage_hour dag dagsq i.deh_c3 i.deh_c3#c.dag i.dhe i.drgn1 i.pt real_wage_growth y2020 y2021" 
global seln_eqn "i.L1les_c3 dag dagsq i.deh_c3 i.deh_c3#c.dag i.mar i.child i.dhe i.drgn1 y2020 y2021" 
local filter = "${W1ma_if_condition} & previouslyWorking == 0"

heckman $wage_eqn if ${W1ma_if_condition}, select($seln_eqn) ///
	twostep mills(lambda)

* Obtain predicted values (log wage) with selection correction
predict pred if `filter', ycond 	// ycond -> include IMR in prediction 
replace lwage_hour_hat = pred if `filter'

gen in_sample_mnpw = e(sample)	

* Correct bias transforming from log to levels 
gen epsilon = rnormal()*e(sigma) 

replace pred_hourly_wage = exp(lwage_hour_hat + epsilon) if `filter'  
 
* Save sample for validation
save "$dir_data/Male_NPW_sample", replace 
cap drop pred epsilon
	
* Formatted results 
* Clean up matrix of estimates 
* Note: Zeros values are eliminated 
matrix b = e(b)	
matrix V = e(V)

* Store variance-covariance matrix 
preserve

putexcel set "$dir_data/var_cov", sheet("var_cov") replace
putexcel A1 = matrix(V)

import excel "$dir_data/var_cov", sheet("var_cov") clear

describe
local no_vars = `r(k)'	
	
forvalues i = 1/2 {
	
	egen row_sum = rowtotal(*)
	drop if row_sum == 0 
	drop row_sum
	xpose, clear	

}	
	
mkmat v*, matrix(var)	

* Second stage
putexcel set "$dir_data/reg_wages_${country}", sheet("W1ma") modify
putexcel C2 = matrix(var)
		
restore	

* Store estimated coefficients 
* Initialize a counter for non-zero coefficients
local non_zero_count = 0
//local names : colnames b

* Loop through each element in `b` to count non-zero coefficients
forvalues i = 1/`no_vars' {
    if (b[1, `i'] != 0) {
	
        local non_zero_count = `non_zero_count' + 1
    
	}
}

* Create a new row vector to hold only non-zero coefficients
matrix nonzero_b = J(1, `non_zero_count', .)

* Populate nonzero_b with non-zero coefficients from b
local index = 1

forvalues i = 1/`no_vars' {
    if (b[1, `i'] != 0) {
	
        matrix nonzero_b[1, `index'] = b[1, `i']
        local index = `index' + 1
    
	}
}

putexcel set "$dir_data/reg_wages_${country}", sheet("W1ma") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 

preserve

import excel "$dir_data/reg_wages_${country}", sheet("W1ma") firstrow clear

drop if C == 0 // UPDATE 
drop A 
drop V-AP

mkmat *, matrix(Males_NLW)
putexcel set "$dir_work/reg_wages_${country}", sheet("W1ma") modify 
putexcel B2 = matrix(Males_NLW)

restore 

* Labelling 
putexcel set "$dir_work/reg_wages_${country}", sheet("W1ma") modify 

local var_list Dag Dag_sq Deh_c3_Medium Deh_c3_Low Deh_c3_Medium_Dag ///
	Deh_c3_Low_Dag Dhe_Fair Dhe_Good Dhe_VeryGood Dhe_Excellent ///
	PL4 PL5 PL6 PL10 Pt RealWageGrowth Y2020 Y2021 Constant InverseMillsRatio

putexcel A1 = "REGRESSOR"
putexcel B1 = "COEFFICIENT"

local i = 1 	
foreach var in `var_list' {
	local ++i
	
	putexcel A`i' = "`var'"
	
} 	

local i = 2 	
foreach var in `var_list' {
    local ++i

    if `i' <= 26 {
        local letter = char(64 + `i')  // Convert 1=A, 2=B, ..., 26=Z
        putexcel `letter'1 = "`var'"
    }
    else {
        local first = char(64 + int((`i' - 1) / 26))  // First letter: A-Z
        local second = char(65 + mod((`i' - 1), 26)) // Second letter: A-Z
        putexcel `first'`second'1 = "`var'"  // Correctly places AA-ZZ
    }
}

* Calculate RMSE 
cap drop residuals squared_residuals  

gen residuals = lwage_hour - lwage_hour_hat
gen squared_residuals = residuals^2

preserve 

keep if `filter'
sum squared_residuals 
di "RMSE for Not employed men: " sqrt(r(mean))

putexcel set "$dir_work/reg_RMSE_${country}.xlsx", sheet("${country}") modify
putexcel A3 = ("W1ma") B3 = (sqrt(r(mean))) 

restore 

* First stage
preserve

import excel "$dir_data/reg_wages_${country}", sheet("W1ma") firstrow clear

drop if V == 0  // UPDATE
drop A 
drop C-U
drop AQ

mkmat *, matrix(Males_NLW)
putexcel set "$dir_work/reg_employmentSelection_${country}", ///
	sheet("W1ma-sel") modify
putexcel B2 = matrix(Males_NLW)

restore 

* Labelling 
putexcel set "$dir_work/reg_employmentSelection_${country}", ///
	sheet("W1ma-sel") modify 

local var_list Les_c3_Student_L1 Les_c3_NotEmployed_L1 Dag Dag_sq ///
	Deh_c3_Medium Deh_c3_Low Deh_c3_Medium_Dag  Deh_c3_Low_Dag ///
	Dcpst_Partnered D_Children Dhe_Fair Dhe_Good ///
	Dhe_VeryGood Dhe_Excellent PL4 PL5 PL6 PL10 Y2020 Y2021 ///
	Constant	

putexcel A1 = "REGRESSOR"
putexcel B1 = "COEFFICIENT"

local i = 1 	
foreach var in `var_list' {
	local ++i
	
	putexcel A`i' = "`var'"
	
} 	

local i = 2 	
foreach var in `var_list' {
    local ++i

    if `i' <= 26 {
        local letter = char(64 + `i')  // Convert 1=A, 2=B, ..., 26=Z
        putexcel `letter'1 = "`var'"
    }
    else {
        local first = char(64 + int((`i' - 1) / 26))  // First letter: A-Z
        local second = char(65 + mod((`i' - 1), 26)) // Second letter: A-Z
        putexcel `first'`second'1 = "`var'"  // Correctly places AA-ZZ
    }
}

cap drop lambda


/********************** WAGES: FEMALE, PREV WAGE OBSERVED *********************/

global wage_eqn "lwage_hour L1.lwage_hour dag dagsq i.deh_c3 i.deh_c3#c.dag i.dhe i.drgn1 i.pt real_wage_growth y2020 y2021" 
global seln_eqn "dag dagsq i.deh_c3 i.deh_c3#c.dag i.mar i.child i.dhe i.drgn1 y2020 y2021" 

heckman $wage_eqn if ${W1fb_if_condition}, select($seln_eqn) twostep
	
* Internal validation  
* Obtain predicted values (log wage) with selection correction
predict pred if ${W1fb_if_condition}, ycond 
	// ycond -> include IMR in prediction 
replace lwage_hour_hat = pred if ${W1fb_if_condition}

gen in_sample_fpw = 1 if e(sample) == 1

* Correct bias transforming from log to levels 
gen epsilon = rnormal()* e(sigma) 

replace pred_hourly_wage = exp(lwage_hour_hat + epsilon) if ${W1fb_if_condition} 	


* Save sample for validation
save "$dir_data/Female_PW_sample", replace 	

cap drop pred epsilon
	
* Formatted results 
* Clean up matrix of estimates 
* Note: Zeros values are eliminated 
matrix b = e(b)	
matrix V = e(V)

* Store variance-covariance matrix 
preserve

putexcel set "$dir_data/var_cov", sheet("var_cov") replace
putexcel A1 = matrix(V)

import excel "$dir_data/var_cov", sheet("var_cov") clear

describe
local no_vars = `r(k)'	
	
forvalues i = 1/2 {
	egen row_sum = rowtotal(*)
	drop if row_sum == 0 
	drop row_sum
	xpose, clear	
}	
	
mkmat v*, matrix(var)	

* Second stage
putexcel set "$dir_data/reg_wages_${country}", sheet("W1fb") modify
putexcel C2 = matrix(var)
		
restore	

* Initialize a counter for non-zero coefficients
local non_zero_count = 0
//local names : colnames b

* Loop through each element in `b` to count non-zero coefficients
forvalues i = 1/`no_vars' {
    if (b[1, `i'] != 0) {
        
		local non_zero_count = `non_zero_count' + 1
    
	}
}

* Create a new row vector to hold only non-zero coefficients
matrix nonzero_b = J(1, `non_zero_count', .)

* Populate nonzero_b with non-zero coefficients from b
local index = 1
forvalues i = 1/`no_vars' {
    if (b[1, `i'] != 0) {
        
		matrix nonzero_b[1, `index'] = b[1, `i']
        local index = `index' + 1
    
	}
}

putexcel set "$dir_data/reg_wages_${country}", sheet("W1fb") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 
	
	
preserve

import excel "$dir_data/reg_wages_${country}", sheet("W1fb") firstrow clear

drop if C == 0 // UPDATE
drop A 
drop W-AO

mkmat *, matrix(Females_LW)
putexcel set "$dir_work/reg_wages_${country}", sheet("W1fb") modify 
putexcel B2 = matrix(Females_LW)

restore 

* Labelling 
putexcel set "$dir_work/reg_wages_${country}", sheet("W1fb") modify 

local var_list L1_log_hourly_wage Dag Dag_sq Deh_c3_Medium Deh_c3_Low ///
	Deh_c3_Medium_Dag Deh_c3_Low_Dag Dhe_Fair Dhe_Good Dhe_VeryGood ///
	Dhe_Excellent PL4 PL5 PL6 PL10 Pt RealWageGrowth Y2020 Y2021 Constant ///
	InverseMillsRatio

putexcel A1 = "REGRESSOR"
putexcel B1 = "COEFFICIENT"

local i = 1 	
foreach var in `var_list' {
	local ++i
	
	putexcel A`i' = "`var'"
	
} 	

local i = 2 	
foreach var in `var_list' {
    local ++i

    if `i' <= 26 {
        local letter = char(64 + `i')  // Convert 1=A, 2=B, ..., 26=Z
        putexcel `letter'1 = "`var'"
    }
    else {
        local first = char(64 + int((`i' - 1) / 26))  // First letter: A-Z
        local second = char(65 + mod((`i' - 1), 26)) // Second letter: A-Z
        putexcel `first'`second'1 = "`var'"  // Correctly places AA-ZZ
    }
}

* Calculate RMSE 
// Note: Sigma reported in the estimated regressions is the standard deviation
//	 		of the residuals (=RMSE assuming residuals are normally distributed)
cap drop residuals squared_residuals  
gen residuals = lwage_hour - lwage_hour_hat
gen squared_residuals = residuals^2

preserve 

keep if `filter'
sum squared_residuals 
di "RMSE for Employed women: " sqrt(r(mean))

putexcel set "$dir_work/reg_RMSE_${country}.xlsx", sheet("${country}") modify
putexcel A4 = ("W1fb") B4 = (sqrt(r(mean))) 

restore 

* First stage
preserve

import excel "$dir_data/reg_wages_${country}", sheet("W1fb") firstrow clear

drop if W == 0 	// UPDATE
drop A 
drop C-V
drop AP

mkmat *, matrix(Females_LW)
putexcel set "$dir_work/reg_employmentSelection_${country}", ///
	sheet("W1fb-sel") modify 
putexcel B2 = matrix(Females_LW)

restore 

* Labelling 
putexcel set "$dir_work/reg_employmentSelection_${country}", ///
	sheet("W1fb-sel") modify 
	
local var_list Dag Dag_sq ///
	Deh_c3_Medium Deh_c3_Low Deh_c3_Medium_Dag  Deh_c3_Low_Dag ///
	Dcpst_Partnered D_Children Dhe_Fair Dhe_Good ///
	Dhe_VeryGood Dhe_Excellent PL4 PL5 PL6 PL10 Y2020 Y2021 ///
	Constant
	
putexcel A1 = "REGRESSOR"
putexcel B1 = "COEFFICIENT"

local i = 1 	
foreach var in `var_list' {
	local ++i
	
	putexcel A`i' = "`var'"
	
} 	

local i = 2 	
foreach var in `var_list' {
    local ++i

    if `i' <= 26 {
        local letter = char(64 + `i')  // Convert 1=A, 2=B, ..., 26=Z
        putexcel `letter'1 = "`var'"
    }
    else {
        local first = char(64 + int((`i' - 1) / 26))  // First letter: A-Z
        local second = char(65 + mod((`i' - 1), 26)) // Second letter: A-Z
        putexcel `first'`second'1 = "`var'"  // Correctly places AA-ZZ
    }
}

cap drop lambda


/*********************** WAGES: MEN, PREV WAGE OBSERVED ***********************/

global wage_eqn "lwage_hour L1.lwage_hour dag dagsq i.deh_c3 i.deh_c3#c.dag i.dhe i.drgn1 i.pt real_wage_growth y2020 y2021"
global seln_eqn "dag dagsq i.deh_c3 i.deh_c3#c.dag i.mar i.child i.dhe i.drgn1 y2020 y2021" 

heckman $wage_eqn if ${W1mb_if_condition}, select($seln_eqn) twostep

* Obtain predicted values (log wage) with selection correction
predict pred if ${W1mb_if_condition}, ycond 
	// ycond -> include IMR in prediction 
replace lwage_hour_hat = pred if ${W1mb_if_condition}

gen in_sample_mpw = e(sample)	

* Correct bias transforming from log to levels 
gen epsilon = rnormal()*e(sigma) 

replace pred_hourly_wage = exp(lwage_hour_hat + epsilon) if ${W1mb_if_condition} 	
	 
* Save sample for validation
save "$dir_data/Male_PW_sample", replace 

cap drop pred epsilon	
	
* Formatted results (almost)
* Note: Zeros values are eliminated 	
matrix b = e(b)	
matrix V = e(V)

* Store variance-covariance matrix 
preserve

putexcel set "$dir_data/var_cov", sheet("var_cov") replace
putexcel A1 = matrix(V)

import excel "$dir_data/var_cov", sheet("var_cov") clear

describe
local no_vars = `r(k)'	
	
forvalues i = 1/2 {
	egen row_sum = rowtotal(*)
	drop if row_sum == 0 
	drop row_sum
	xpose, clear	
}	
	
mkmat v*, matrix(var)	

* Second stage 
putexcel set "$dir_data/reg_wages_${country}", sheet("W1mb") modify
putexcel C2 = matrix(var)
		
restore	

* Store estimated coefficients 
* Initialize a counter for non-zero coefficients
local non_zero_count = 0
//local names : colnames b

*Loop through each element in `b` to count non-zero coefficients
forvalues i = 1/`no_vars' {
    if (b[1, `i'] != 0) {
	
        local non_zero_count = `non_zero_count' + 1
    
	}
}

* Create a new row vector to hold only non-zero coefficients
matrix nonzero_b = J(1, `non_zero_count', .)

* Populate nonzero_b with non-zero coefficients from b
local index = 1
forvalues i = 1/`no_vars' {
    if (b[1, `i'] != 0) {
	
        matrix nonzero_b[1, `index'] = b[1, `i']
        local index = `index' + 1
    
	}
}

putexcel set "$dir_data/reg_wages_${country}", sheet("W1mb") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 
		
preserve

import excel "$dir_data/reg_wages_${country}", sheet("W1mb") firstrow clear

drop if C == 0 // UPDATE
drop A 
drop W-AO

mkmat *, matrix(Males_LW)
putexcel set "$dir_work/reg_wages_${country}", sheet("W1mb") modify 
putexcel B2 = matrix(Males_LW)

restore 

* Labelling 
putexcel set "$dir_work/reg_wages_${country}", sheet("W1mb") modify 

local var_list L1_log_hourly_wage Dag Dag_sq Deh_c3_Medium Deh_c3_Low ///
	Deh_c3_Medium_Dag Deh_c3_Low_Dag Dhe_Fair Dhe_Good Dhe_VeryGood ///
	Dhe_Excellent PL4 PL5 PL6 PL10 Pt RealWageGrowth Y2020 Y2021 Constant ///
	InverseMillsRatio

putexcel A1 = "REGRESSOR"
putexcel B1 = "COEFFICIENT"

local i = 1 	
foreach var in `var_list' {
	local ++i
	
	putexcel A`i' = "`var'"
	
} 	

local i = 2 	
foreach var in `var_list' {
    local ++i

    if `i' <= 26 {
        local letter = char(64 + `i')  // Convert 1=A, 2=B, ..., 26=Z
        putexcel `letter'1 = "`var'"
    }
    else {
        local first = char(64 + int((`i' - 1) / 26))  // First letter: A-Z
        local second = char(65 + mod((`i' - 1), 26)) // Second letter: A-Z
        putexcel `first'`second'1 = "`var'"  // Correctly places AA-ZZ
    }
}

* Calculate RMSE 
// Note: Sigma reported in the estimated regressions is the standard deviation
//	 		of the residuals (=RMSE assuming residuals are normally distributed)
cap drop residuals squared_residuals  
gen residuals = lwage_hour - lwage_hour_hat
gen squared_residuals = residuals^2

preserve 

keep if `filter'
sum squared_residuals 
di "RMSE for Employed men: " sqrt(r(mean))

putexcel set "$dir_work/reg_RMSE_${country}.xlsx", sheet("${country}") modify
putexcel A5 = ("W1mb") B5 = (sqrt(r(mean))) 

restore 

* First stage
preserve

import excel "$dir_data/reg_wages_${country}", sheet("W1mb") firstrow clear

drop if W == 0 	// UPDATE
drop A 
drop C-V
drop AP

mkmat *, matrix(Males_LW)
putexcel set "$dir_work/reg_employmentSelection_${country}", ///
	sheet("W1mb-sel") modify 
putexcel B2 = matrix(Males_LW)

restore 

* Labelling 
putexcel set "$dir_work/reg_employmentSelection_${country}", ///
	sheet("W1mb-sel") modify 

local var_list Dag Dag_sq ///
	Deh_c3_Medium Deh_c3_Low Deh_c3_Medium_Dag  Deh_c3_Low_Dag ///
	Dcpst_Partnered D_Children Dhe_Fair Dhe_Good ///
	Dhe_VeryGood Dhe_Excellent PL4 PL5 PL6 PL10 Y2020 Y2021 ///
	Constant
	
putexcel A1 = "REGRESSOR"
putexcel B1 = "COEFFICIENT"

local i = 1 	
foreach var in `var_list' {
	local ++i
	
	putexcel A`i' = "`var'"
	
} 	

local i = 2 	
foreach var in `var_list' {
    local ++i

    if `i' <= 26 {
        local letter = char(64 + `i')  // Convert 1=A, 2=B, ..., 26=Z
        putexcel `letter'1 = "`var'"
    }
    else {
        local first = char(64 + int((`i' - 1) / 26))  // First letter: A-Z
        local second = char(65 + mod((`i' - 1), 26)) // Second letter: A-Z
        putexcel `first'`second'1 = "`var'"  // Correctly places AA-ZZ
    }
}

cap drop lambda
				
										
/*
* Analyse all 

analyseFit "esample == 1"
analyseFit "esample == 1 & dgn == 0"	// women
analyseFit "esample == 1 & dgn == 1"	// men


* Analyse fit per year:
forvalues year = 11/23 {
	di "Current year: `year'"
	analyseFit2 "esample == 1 & stm == `year'" "nocorr" "Year 20`year' all obs prv emp" "all_`year'_graph.png"
	analyseFit2 "esample == 1 & dgn == 0 & stm == `year'" "nocorr" "Year 20`year' women prv emp"	"women_`year'_graph.png"  // women
	analyseFit2 "esample == 1 & dgn == 1 & stm == `year'" "nocorr" "Year 20`year' men prv emp" "men_`year'_graph.png"	// men
	analyseFit2 "esample == 1 & dgn == 1 & deh_c3 == 1 & stm == `year'" "nocorr" "Year 20`year' men prv emp high ed" "men_highed_`year'_graph.png"	// men
}
*/

* Save for use in the do file estimating non-employment income

// use predicted wage for all 
// use the observed wage for those that are working today and not in any 
//	estimation sample above (first observation for an individual)

replace pred_hourly_wage = exp(lwage_hour) if missing(pred_hourly_wage)
// this need the propose to use in the pension estimation and matching 
// parameters

// WHAT IS THIS? 

/*
replace les_c3 = orig_les_c3 
drop orig_les_c3 
*/

save "$dir_data/${country}-_pooled_ipop_wages.dta", replace


capture log close 

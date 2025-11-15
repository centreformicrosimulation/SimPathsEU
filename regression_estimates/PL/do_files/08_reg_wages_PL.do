********************************************************************************
* PROJECT:  		ESPON 
* SECTION:			Wage regression 
* OBJECT: 			Heckman selection regressions 
* AUTHORS:			Daria Popova, Justin van de Ven, Ashley Burdett
* LAST UPDATE:		Feb 2025
* COUNTRY: 			Poland
* 
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
********************************************************************************
clear all
set more off
set mem 200m
set type double
//set maxvar 120000
set maxvar 30000


cap log close 

//log using "$dir_log/reg_wages.log", replace

global min_age = 16
global max_age = 75


* Import real wage growth index 
//do "$dir_do/import_unemp_rates.do"	//only need to run once, not sure where this is used atm...
 
import excel "$dir_external_data/PL_Wages.xlsx", sheet("Wages") firstrow clear 
	
drop D-N	
rename Year stm
replace stm = stm - 2000

/* Harmonised index of consumer prices (HICP)
Annual data (annual average index) 2015=100
All-items HICP
Source dataset: Eurostat (prc_hicp_aind)	
Unit Index, base year = 100
Last data update: 18/1/25
https://ec.europa.eu/eurostat/databrowser/view/prc_hicp_aind/default/table?lang=en&category=prc.prc_hicp*/
gen CPI = .

replace CPI = 92.7  	if stm == 10
replace CPI = 96.3  	if stm == 11
replace CPI = 99.8  	if stm == 12
replace CPI = 100.6  	if stm == 13
replace CPI = 100.7  	if stm == 14
replace CPI = 100    	if stm == 15
replace CPI = 99.8 		if stm == 16
replace CPI = 101.4 	if stm == 17
replace CPI = 102.6 	if stm == 18
replace CPI = 104.8 	if stm == 19
replace CPI = 108.6 	if stm == 20
replace CPI = 114.4 	if stm == 21
replace CPI = 129.4 	if stm == 22
replace CPI = 143.5 	if stm == 23

lab var CPI "HICP, all items, base 2015"

* Convert into real terms
gen r_LCI_rebased = LCI_rebased / CPI * 100

* Create real growth index with base year 2015
//AB: Already has a 2015 base but keep for future use
sum r_LCI_rebased if stm == 15
gen base2 = r(mean)

//gen real_wage_growth = r_avg_hr_w / base 
gen real_wage_growth = r_LCI_rebased / base2 

// Note: switching from 100 base to 1 base as that's what happens in the 
//simulation when rebasing indices
drop base LCI LCI_rebased

save "$dir_data/growth_rates", replace

* Call main dataset
use "$dir_input_data/PL-SILC_pooled_all_obs_02.dta", clear

//do "$dir_do/variable_update"

drop if dag < $min_age

label var yplgrs_dv "Gross personal employment income, IHS"

* Check to ensure that idperson and swv uniquely identify observations
sort idperson swv
gen chk = 0
replace chk = 1 if (idperson == idperson[_n-1] & swv == swv[_n-1])
drop if chk == 1

replace stm = stm - 2000
replace swv = swv - 2010

gen y2020 = (stm == 20)
gen y2021 = (stm == 21)

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

gen hrs0_m1 = hours[_n-1] == 0
gen hrs1_m1 = (hours[_n-1] >  0) * (hours[_n-1] <= 29)

* Hourly wage
* Screens the population to include individuals working 
gen yplgrs_dv_level = sinh(yplgrs_dv) // level of monthly wage 

gen wage_hour = .
replace wage_hour = yplgrs_dv_level / (hours * 4.3333)  if ///
	hours >= 1 & hours <= 100 // NB: hours is the weekly hours worked 
label var wage_hour "Hourly wage (Euro)"
	
* Alternatively could use the measure in the initial population 
//	obs_earnings_hourly
replace obs_earnings_hourly = . if obs_earnings_hourly == -9
replace l1_obs_earnings_hourly = . if l1_obs_earnings_hourly == -9
	
replace wage_hour = obs_earnings_hourly
	
* Winsorize
sum wage_hour, det
replace wage_hour = . if wage_hour <= 0
replace wage_hour = . if wage_hour >= 18.73116 // UPDATE

gen lwage_hour = ln(wage_hour)
label var lwage_hour "Log gross hourly wage"

gen lwage_hour_2 = lwage_hour^2
label var lwage_hour_2 "Squared log gross hourly wage"


* Recode economic status so consistent with wage information 
//replace les_c3 = 3 if lwage_hour == . & les_c3 ! = 2 

/*
Economic status is made up of better quality data therefore not clear that this 
should be over written. 
Try just excluding the observations that have missing wage information but 
report working in les_c3. 
Altered in_sample variable below
*/

* Part-time dummy
gen pt = (hours >  0) * (hours <= 25)
label var pt "Works part-time"

* Create exclusion restrictions 
* Relationship status (1=cohabiting)
gen mar = (dcpst == 1)
label var mar "In a partnership"

* Children
gen any02 = dnc02 > 0 & dnc02 != . 
label var any02 "Has children between 0-2 years old"

cap gen child = (dnc > 0 & dnc != .)
label var child "Has children"

//rename l1_les_c3 L1les_c3

drop hrs0_m1 hrs1_m1

sort idperson stm
xtset idperson stm

* Flag to identify observations to be included in the estimation sample 
// Need to have been observed at least once in the past 
bys idperson: gen obs_count = _N
gen in_sample = (obs_count > 1 & swv > 0) // was previously swv > 1

// Need to have future observation to have wage information 
sort idperson swv 
replace in_sample = 0 if idperson != idperson[_n+1]

// Omit obs from people who are missing wage information but report working 
replace in_sample = 0 if les_c3 == 1 & obs_earnings_hourly == . 

// Same for lagged info 
sort idperson stm
xtset idperson stm

replace in_sample = 0 if L1.les_c3 == 1 & L1.obs_earnings_hourly == . 

// Same for those who report zero wages 
gen orig_les_c3 = les_c3 
replace les_c3 = 3 if lwage_hour == . & les_c3 ! = 2 

gen L1les_c3 = L1.les_c3 
/*
replace in_sample = 0 if les_c3 == 1 & obs_earnings_hourly == 0 
replace in_sample = 0 if L1.les_c3 == 1 & L1.obs_earnings_hourly == 0 

Need the les_c3 assumption to get reasonable predicted values. 
If don't preserve these observations the predictions explode. 
*/

* Flag to distinguish the two samples (prev work and not)
capture drop previouslyWorking

gen previouslyWorking = (L1.lwage_hour != .) 
replace previouslyWorking = . if in_sample == 0 

recode deh_c3 /*dehm_c3 dehf_c3*/ drgn1 dhe L1les_c3 (-9=.)


* Prep storage 
capture drop lwage_hour_hat wage_hour_hat esample

gen lwage_hour_hat = .
gen wage_hour_hat = .
gen esample = .
gen pred_hourly_wage = .

* Set Excel file 
* Info sheet - first stage 
putexcel set "$dir_work/reg_employmentSelection_PL", sheet("Info") replace
putexcel A1 = "Description:"
putexcel B1 = "This file contains regression estimates from the first stage of the Heckman selection model used to estimates wages."

putexcel A4 = "Process:", bold
putexcel B4 = "Description:", bold
putexcel A5 = "PL_EmploymentSelection_FemaleNE"
putexcel B5 = "First stage Heckman selection estimates for women that do not have an observed wage in the previous year"
putexcel A6 = "PL_EmploymentSelection_MaleNE"
putexcel B6 = "First stage Heckman selection estimates for women that do not have an observed wage in the previous year"
putexcel A7 = "PL_EmploymentSelection_FemaleE"
putexcel B7 = "First stage Heckman selection estimates for women that have an observed wage in the previous year"
putexcel A8 = "PL_EmploymentSelection_MaleE"
putexcel B8 = "First stage Heckman selection estimates for men that have an observed wage in the previous year"

putexcel A11 = "Notes:", bold
putexcel B11 = "Estimated on panel data unlike the labour supply estimates"
putexcel B12 = "Predicted wages used as input into union parameters and income process estimates"
putexcel B13 = "Two-step Heckman command is used which does not permit weights"
putexcel B14 = "Regions: PL4 = Polnocno-Zachodni, PL5 = Poludniowo-Zachodni, PL6 = Polnocy, PL10 = Central + East. Poludniowy is the omitted category."
putexcel B15 = "Estimate the models without the lagged wage observation on the full working age sample. Choice made because otherwise the reduction in the sample size makes the sigma used when correcting the bias when transforming the log wages to wage levels too large."

* Info sheet - second stage 
putexcel set "$dir_work/reg_wages_PL", sheet("Info") replace
putexcel A1 = "Description:"
putexcel B1 = "This file contains regression estimates used to calculate potential wages for males and females in the simulation."

putexcel A4 = "Process:", bold
putexcel B4 = "Description:", bold
putexcel A5 = "Wages_FemalesNE"
putexcel B5 = "Heckman selection estimates using women that do not have an observed wage in the previous year"
putexcel A6 = "Wages_MalesNE"
putexcel B6 = "Heckman selection estimates using men that do not have an observed wage in the previous year"
putexcel A7 = "Wages_FemalesE"
putexcel B7 = "Heckman selection estimates using women that have an observed wage in the previous year"
putexcel A8 = "Wages_MalesE"
putexcel B8 = "Heckman selection estimates using men that have an observed wage in the previous year"

putexcel A11 = "Notes:", bold
putexcel B11 = "Estimated on panel data unlike the labour supply estimates"
putexcel B12 = "Predicted wages used as input into union parameters and income process estimates"
putexcel B13 = "Two-step Heckman command is used which does not permit weights"
putexcel B14 = "Regions: PL4 = Polnocno-Zachodni, PL5 = Poludniowo-Zachodni, PL6 = Polnocy, PL10 = Central + East. Poludniowy is the omitted category."
putexcel B15 = "Estimate the models without the lagged wage observation on the full working age sample. Choice made because otherwise the reduction in the sample size makes the sigma used when correcting the bias when transforming the log wages to wage levels too large."


*******************************************
* Wages: Women, no previous wage observed * 
*******************************************

* Estimate a predicted wage using a Heckman selection model 
* Sample: Working age (17-64) women who did not receive a wage in t-1
* DV: Log gross hourly wage 
* Note: The previouslyWorking variable ensures that we conly include 
* 		observations for which we could possibly observe a wage in t-1
* 		There is no DV specified in the selection equation therefore deteremines 
* 		selection based on whether the dependent variable is missing or not. 
* 		Because the sample size drops considerably in the second stage the lrg
* 		error ends up dominating the predicted values. Therefore decided to 
* 		use the full sample to obtain estimates.
 
global wage_eqn "lwage_hour dag dagsq i.deh_c3 i.deh_c3#c.dag i.dhe i.drgn1 i.pt real_wage_growth y2020 y2021"
global seln_eqn "i.L1les_c3 dag dagsq i.deh_c3 i.deh_c3#c.dag i.mar i.child i.dhe i.drgn1 y2020 y2021" 
local filter = "dgn == 0 & dag >= $min_age & dag <= $max_age & previouslyWorking == 0"
local filter2 = "dgn == 0 & dag >= $min_age & dag <= $max_age"


heckman $wage_eqn if `filter2', select($seln_eqn) twostep mills(lambda)

* Internal validation  
* Obtain predicted values (log wage) with selection correction
predict pred if `filter', ycond // ycond -> include IMR in prediction 
replace lwage_hour_hat = pred if `filter'

gen in_sample_fnpw = e(sample)	

* Correct bias when transforming from log to levels 
cap drop epsilon
gen epsilon = rnormal()*e(sigma) 

replace pred_hourly_wage = exp(lwage_hour_hat + epsilon) if `filter' 
 
* Save sample for later use (internal validation)
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
putexcel set "$dir_data/reg_wages_PL", sheet("Females_NLW") replace
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

putexcel set "$dir_data/reg_wages_PL", sheet("Females_NLW") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 

preserve

import excel "$dir_data/reg_wages_PL", sheet("Females_NLW") firstrow clear

drop if C == 0 // UPDATE 
drop A 
drop V-AP

mkmat *, matrix(Females_NLW)
putexcel set "$dir_work/reg_wages_PL", sheet("PL_Wages_FemalesNE") modify 
putexcel B2 = matrix(Females_NLW)

restore 

* Labelling 
putexcel set "$dir_work/reg_wages_PL", sheet("PL_Wages_FemalesNE") modify 

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

putexcel set "$dir_work/reg_RMSE_PL.xlsx", sheet("PL") replace
putexcel A1 = ("REGRESSOR") B1 = ("COEFFICIENT") ///
	A2 = ("Wages_FemalesNE") B2 = (sqrt(r(mean))) 
restore 

* First stage
preserve

import excel "$dir_data/reg_wages_PL", sheet("Females_NLW") firstrow clear

drop if V == 0 // UPDATE
drop A 
drop C-U
drop AQ

mkmat *, matrix(Females_NLW)
putexcel set "$dir_work/reg_employmentSelection_PL", ///
	sheet("PL_EmploymentSelection_FemaleNE") modify 
putexcel B2 = matrix(Females_NLW)

restore 

* Labelling 
putexcel set "$dir_work/reg_employmentSelection_PL", ///
	sheet("PL_EmploymentSelection_FemaleNE") modify 
	
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

*****************************************
* Wages: Men, no previous wage observed * 
*****************************************

* Estimate a predicted wage using a Heckman selection model 
* Sample: Working age (17-64) men who did not receive a wage in t-1
* Note: The previouslyWorking variable ensures that we only include 
* 			observations for which we could possibly observe a wage in t-1

global wage_eqn "lwage_hour dag dagsq i.deh_c3 i.deh_c3#c.dag i.dhe i.drgn1 i.pt real_wage_growth y2020 y2021" 
global seln_eqn "i.L1les_c3 dag dagsq i.deh_c3 i.deh_c3#c.dag i.mar i.child i.dhe i.drgn1 y2020 y2021" 
local filter = "dgn == 1 & dag >= $min_age & dag <= $max_age & previouslyWorking == 0"
local filter2 = "dgn == 1 & dag >= $min_age & dag <= $max_age"

heckman $wage_eqn if `filter2', select($seln_eqn) twostep mills(lambda)

* Obtain predicted values (log wage) with selection correction
predict pred if `filter', ycond // ycond -> include IMR in prediction 
replace lwage_hour_hat = pred if `filter'

gen in_sample_mnpw = e(sample)	

* Correct bias transforming from log to levels 
gen epsilon = rnormal()*e(sigma) 

replace pred_hourly_wage = exp(lwage_hour_hat + epsilon) if `filter' 
 
* Save sample for later use (internal validation)
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
putexcel set "$dir_data/reg_wages_PL", sheet("Males_NLW") modify
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

putexcel set "$dir_data/reg_wages_PL", sheet("Males_NLW") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 

preserve

import excel "$dir_data/reg_wages_PL", sheet("Males_NLW") firstrow clear

drop if C == 0 // UPDATE 
drop A 
drop V-AP

mkmat *, matrix(Males_NLW)
putexcel set "$dir_work/reg_wages_PL", sheet("PL_Wages_MalesNE") modify 
putexcel B2 = matrix(Males_NLW)

restore 

* Labelling 
putexcel set "$dir_work/reg_wages_PL", sheet("PL_Wages_MalesNE") modify 

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

putexcel set "$dir_work/reg_RMSE_PL.xlsx", sheet("PL") modify
putexcel A3 = ("Wages_MalesNE") B3 = (sqrt(r(mean))) 

restore 

* First stage
preserve

import excel "$dir_data/reg_wages_PL", sheet("Males_NLW") firstrow clear

drop if V == 0  // UPDATE
drop A 
drop C-U
drop AQ

mkmat *, matrix(Males_NLW)
putexcel set "$dir_work/reg_employmentSelection_PL", ///
	sheet("PL_EmploymentSelection_MaleNE") modify
putexcel B2 = matrix(Males_NLW)

restore 

* Labelling 
putexcel set "$dir_work/reg_employmentSelection_PL", ///
	sheet("PL_EmploymentSelection_MaleNE") modify 

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

****************************************
* Wages: Women, previous wage observed * 
****************************************

* Estimate a predicted wage using a Heckman selection model 
* Sample: Working age (17-64) women who receive a wage in t-1
* Note: The previouslyWorking variable ensures that we only include 
* 			observations for which we could possibly observe a wage in t-1

global wage_eqn "lwage_hour L1.lwage_hour dag dagsq i.deh_c3 i.deh_c3#c.dag i.dhe i.drgn1 i.pt real_wage_growth y2020 y2021" 
global seln_eqn "dag dagsq i.deh_c3 i.deh_c3#c.dag i.mar i.child i.dhe i.drgn1 y2020 y2021" 
local filter = "dgn == 0 & dag >= $min_age & dag <= $max_age  & previouslyWorking == 1"

heckman $wage_eqn if `filter', select($seln_eqn) twostep
	
* Internal validation  
* Obtain predicted values (log wage) with selection correction
predict pred if `filter', ycond // ycond -> include IMR in prediction 
replace lwage_hour_hat = pred if `filter'

gen in_sample_fpw = 1 if e(sample) == 1

* Correct bias transforming from log to levels 
gen epsilon = rnormal()*e(sigma) 

replace pred_hourly_wage = exp(lwage_hour_hat + epsilon) if `filter' 	

* Save sample for later use (internal validation)
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
putexcel set "$dir_data/reg_wages_PL", sheet("Females_LW") modify
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

putexcel set "$dir_data/reg_wages_PL", sheet("Females_LW") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 
	
	
preserve

import excel "$dir_data/reg_wages_PL", sheet("Females_LW") firstrow clear

drop if C == 0 // UPDATE
drop A 
drop W-AO

mkmat *, matrix(Females_LW)
putexcel set "$dir_work/reg_wages_PL", sheet("PL_Wages_FemalesE") modify 
putexcel B2 = matrix(Females_LW)

restore 

* Labelling 
putexcel set "$dir_work/reg_wages_PL", sheet("PL_Wages_FemalesE") modify 

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

putexcel set "$dir_work/reg_RMSE_PL.xlsx", sheet("PL") modify
putexcel A4 = ("Wages_FemalesE") B4 = (sqrt(r(mean))) 

restore 

* First stage
preserve

import excel "$dir_data/reg_wages_PL", sheet("Females_LW") firstrow clear

drop if W == 0 	// UPDATE
drop A 
drop C-V
drop AP

mkmat *, matrix(Females_LW)
putexcel set "$dir_work/reg_employmentSelection_PL", ////
	sheet("PL_EmploymentSelection_FemaleE") modify 
putexcel B2 = matrix(Females_LW)

restore 

* Labelling 
putexcel set "$dir_work/reg_employmentSelection_PL", ///
	sheet("PL_EmploymentSelection_FemaleE") modify 
	
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

**************************************
* Wages: Men, previous wage observed * 
**************************************

* Estimate a predicted wage using a Heckman selection model 
* Sample: Working age (17-64) men who receive a wage in t-1
* Note: The previouslyWorking variable ensures that we only include 
* 			observations for which we could possibly observe a wage in t-1

global wage_eqn "lwage_hour L1.lwage_hour dag dagsq i.deh_c3 i.deh_c3#c.dag i.dhe i.drgn1 i.pt real_wage_growth y2020 y2021"
global seln_eqn "dag dagsq i.deh_c3 i.deh_c3#c.dag i.mar i.child i.dhe i.drgn1 y2020 y2021" 
local filter = "dgn == 1 & dag >= $min_age & dag <= $max_age & previouslyWorking == 1"

heckman $wage_eqn if `filter', select($seln_eqn) twostep

* Obtain predicted values (log wage) with selection correction
predict pred if `filter', ycond // ycond -> include IMR in prediction 
replace lwage_hour_hat = pred if `filter'

gen in_sample_mpw = e(sample)	

* Correct bias transforming from log to levels 
gen epsilon = rnormal()*e(sigma) 

replace pred_hourly_wage = exp(lwage_hour_hat + epsilon) if `filter' 	
	 
* Save sample for later use (internal validation)
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
putexcel set "$dir_data/reg_wages_PL", sheet("Males_LW") modify
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

putexcel set "$dir_data/reg_wages_PL", sheet("Males_LW") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 
		
preserve

import excel "$dir_data/reg_wages_PL", sheet("Males_LW") firstrow clear

drop if C == 0 // UPDATE
drop A 
drop W-AO

mkmat *, matrix(Males_LW)
putexcel set "$dir_work/reg_wages_PL", sheet("PL_Wages_MalesE") modify 
putexcel B2 = matrix(Males_LW)

restore 

* Labelling 
putexcel set "$dir_work/reg_wages_PL", sheet("PL_Wages_MalesE") modify 

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

putexcel set "$dir_work/reg_RMSE_PL.xlsx", sheet("PL") modify
putexcel A5 = ("Wages_MalesE") B5 = (sqrt(r(mean))) 

restore 

* First stage
preserve

import excel "$dir_data/reg_wages_PL", sheet("Males_LW") firstrow clear

drop if W == 0 	// UPDATE
drop A 
drop C-V
drop AP

mkmat *, matrix(Males_LW)
putexcel set "$dir_work/reg_employmentSelection_PL", ///
	sheet("PL_EmploymentSelection_MaleE") modify 
putexcel B2 = matrix(Males_LW)

restore 

* Labelling 
putexcel set "$dir_work/reg_employmentSelection_PL", ///
	sheet("PL_EmploymentSelection_MaleE") modify 

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


replace les_c3 = orig_les_c3 
drop orig_les_c3 

save "$dir_data/PL-SILC_pooled_all_obs_03.dta", replace


capture log close 

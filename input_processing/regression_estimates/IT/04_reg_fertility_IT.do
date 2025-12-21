********************************************************************************
* PROJECT:  		ESPON 
* SECTION:			Fertility
* OBJECT: 			Having a child
* AUTHORS:			Daria Popova, Justin van de Ven, Ashley Burdett
* LAST UPDATE:		21/04/2024 (JV)
* COUNTRY: 			Poland 
*
* NOTES:			Simplified the fertiliy process for those in this initial 
* 						education spell. Exclude l.dnc, l.dnc02, li.ydses_c5 
* 						and model health as a continuous variable. 			
********************************************************************************
clear all
set more off
set mem 200m
set type double
//set maxvar 120000
set maxvar 30000

cap log close 
//log using "$dir_log/reg_fertility.log", replace

* Import fertility rate 
import excel "$dir_external_data/${country}_fert_rate", sheet("f_rate") ///
	firstrow clear 

rename Year swv

label var dplfr "Fertility_rate"

drop if swv == . 

save "$dir_data/fertility_rate", replace


* Call main dataset
use "$dir_input_data/${country}-SILC_pooled_all_obs_02.dta", clear

* Labeling and formating variables
label define jbf 1 "Employed" 2 "Student" 3 "Not Employed"

label define edd 1 "Degree"	2 "High school" ///
				3 "Other/No Qualification"

label define hht 1 "Couples with No Children" 2 "Couples with Children" ///
				3 "Single with No Children" 4 "Single with Children" 
			
label define gdr 1  "Male" 0 "Female"
				
label define yn	1 "Yes" 0 "No"

label variable dgn "Gender"
label variable dag "Age"
label variable dagsq "Age Squared"
label variable drgn1 "Region"
label variable dhhtp_c4 "Household Type: 4 Category"
label variable stm "Year"
label variable les_c3 "Employment Status: 3 Category" 
label variable dhe "Self-rated Health"
label variable deh_c3 "Educational Attainment: 3 Category"
label variable dnc "Number of Children in Household"
label variable dnc02 "Number of Children aged 0-2 in Household"
label variable ydses_c5 "Annual Household Income Quintile" 

label value dgn gdr
label value drgn1 rgna
label value dhhtp_c4 hht 
label value les_c3 jbf 
label value deh_c3 edd 
label value ded yn

drop if dag < 16

replace stm = stm - 2000

* Covid year dummies 
gen y2020 = (stm == 20)
gen y2021 = (stm == 21)

recode dhe dnc dnc02 deh_c3 les_c3 ydses_c5 dcpst drgn1 sprfm scedsmpl ///
	 dchpd (-9=. )

xtset idperson swv

tab dchpd
replace dchpd = 1 if dchpd == 2 | dchpd == 3

* Merge in fertility rate
merge m:1 swv using "$dir_data/fertility_rate"

drop _m

sort idperson swv 


* Set Excel file 
* Info sheet
putexcel set "$dir_work/reg_fertility_${country}", sheet("Info") replace
putexcel A1 = "Description:"
putexcel B1 = "Model parameters governing projection of fertility"

putexcel A4 = "Process:", bold
putexcel B4 = "Description:", bold
putexcel A5 = "F1a"
putexcel B5 = "Probit regression estimates of the probability of  having a child for women aged 18-44 in initial education spell"
putexcel A6 = "F1b"
putexcel B6 = "Probit regression estimates of probability of having a child for women aged 18-44 not in initial education spell"

putexcel A10 = "Notes:", bold
putexcel B10 = "Regions: ITF = South, ITG = Islands, ITH = Northeast, ITI = Central. Northwest (ITC) is the omitted region."

putexcel set "$dir_work/reg_fertility_${country}", sheet("Gof") modify
putexcel A1 = "Goodness of fit", bold		


**********************************************
* F1a - Having a child, in initial edu spell * 
**********************************************

* Process F1a: Probabiltiy of having a child 
* Sample: Women aged 18-44, in initial education spell education.
* DV: New born child dummy 

xtset idperson swv
tab dchpd if (sprfm == 1 & ded == 1) 
tab dchpd if (sprfm == 1 & ded == 1 & dag < 30) 

probit dchpd dag dhe ib1.dcpst if ///
	sprfm == 1 & ded == 1 [pweight = dimxwt], vce(robust)
	
gen in_sample = e(sample)	

predict p

save "$dir_data/F1a_sample", replace

scalar r2_p = e(r2_p) 
scalar N = e(N)	
scalar chi2 = e(chi2)
scalar ll = e(ll)	


* Results 	
* Note: Zeros eliminated 
matrix b = e(b)	
matrix V = e(V)


* Store variance-covariance matrix 
preserve

putexcel set "$dir_results/fertility/var_cov", sheet("var_cov") replace
putexcel A1 = matrix(V)

import excel "$dir_results/fertility/var_cov", sheet("var_cov") clear

describe
local no_vars = `r(k)'	
	
forvalues i = 1/2 {
	egen row_sum = rowtotal(*)
	drop if row_sum == 0 
	drop row_sum
	xpose, clear	
}	
	
mkmat v*, matrix(var)	
putexcel set "$dir_work/reg_fertility_${country}", sheet("F1a") modify
putexcel C2 = matrix(var)
		
restore	


* Store estimated coefficients 
// Initialize a counter for non-zero coefficients
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

putexcel set "$dir_work/reg_fertility_${country}", sheet("F1a") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 
	
	
* Labelling 
// Need to variable label when add new variable to model. Order matters. 
local var_list Dag Dhe Dcpst_Single  Constant

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
	
* Goodness of fit
putexcel set "$dir_work/reg_fertility_${country}", sheet("Gof") modify

putexcel A3 = "F1a - Fertility in initial education spell", bold		

putexcel A5 = "Pseudo R-squared" 
putexcel B5 = r2_p 
putexcel A6 = "N"
putexcel B6 = N 
putexcel E5 = "Chi^2"		
putexcel F5 = chi2
putexcel E6 = "Log likelihood"		
putexcel F6 = ll		

drop in_sample p
scalar drop r2_p N chi2 ll	
	
	
************************************************
* F1b - Having a child, left initial edu spell *
************************************************

* Process F1b: Probabiltiy of having a child 
* Sample:	Women aged 18-44, left initial education spell
* DV:	New born child dummy 
xtset idperson swv
tab dchpd if (sprfm == 1 & ded == 0) 

probit dchpd dag dagsq li.ydses_c5 l.dnc l.dnc02 ib1.dhe ib1.dcpst ///
	lib1.dcpst ib1.deh_c3 dplfr li.les_c3 i.drgn1 stm y2020 y2021 if ///
	(sprfm == 1 & ded == 0) [pweight = dimxwt], vce(robust)

gen in_sample = e(sample)	

predict p

save "$dir_data/F1b_sample", replace

scalar r2_p = e(r2_p) 
scalar N = e(N)	 
scalar chi2 = e(chi2)
scalar ll = e(ll)

	
* Results 
* Note: Zeros eliminated 
matrix b = e(b)	
matrix V = e(V)


* Store variance-covariance matrix 
preserve

putexcel set "$dir_results/fertility/var_cov", sheet("var_cov") replace
putexcel A1 = matrix(V)

import excel "$dir_results/fertility/var_cov", sheet("var_cov") clear

describe
local no_vars = `r(k)'	
	
forvalues i = 1/2 {
	egen row_sum = rowtotal(*)
	drop if row_sum == 0 
	drop row_sum
	xpose, clear	
}	
	
mkmat v*, matrix(var)	
putexcel set "$dir_work/reg_fertility_${country}", sheet("F1b") modify
putexcel C2 = matrix(var)
		
restore	


* Store estimated coefficients 
// Initialize a counter for non-zero coefficients
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

putexcel set "$dir_work/reg_fertility_${country}", sheet("F1b") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 	
 
* Labelling 
// Need to variable label when add new variable to model. Order matters. 
local var_list  Dag Dag_sq Ydses_c5_Q2_L1 Ydses_c5_Q3_L1 Ydses_c5_Q4_L1 ///
	Ydses_c5_Q5_L1 Dnc_L1 Dnc02_L1 Dhe_Fair Dhe_Good Dhe_VeryGood ///
	Dhe_Excellent Dcpst_Single Dcpst_PreviouslyPartnered Dcpst_Single_L1 ///
	Dcpst_PreviouslyPartnered_L1 Deh_c3_Medium Deh_c3_Low FertilityRate ///
	Les_c3_Student_L1 Les_c3_NotEmployed_L1 ITF ITG ITH ITI ///
	Year_transformed Y2020 Y2021 Constant

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
 
* Goodness of fit
putexcel set "$dir_work/reg_fertility_${country}", sheet("Gof") modify

putexcel A9 = "F1b - Fertility left initial education spell", bold		

putexcel A11 = "Pseudo R-squared" 
putexcel B11 = r2_p 
putexcel A12 = "N"
putexcel B12 = N 
putexcel E11 = "Chi^2"		
putexcel F11 = chi2
putexcel E12 = "Log likelihood"		
putexcel F12 = ll		

drop in_sample p
scalar drop r2_p N chi2 ll	
 
 
capture log close 

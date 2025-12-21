********************************************************************************
* PROJECT:  		ESPON 
* SECTION:			Partnership
* OBJECT: 			Entering a partnership & exiting a relationship 
*					
* AUTHORS:			Daria Popova, Justin van de Ven, Ashley Burdett
* LAST UPDATE:		Feb 2025
* COUNTRY: 			Italy 
*
* NOTES: 			Added new relationship dummy and new partnerhip status 
* 					duration variable in variable update script
* 					Can estimate those that are in initial education spell but 
* 					with continuous health and no lagged child young dummy
* 					(dnc02). Check if feasible to include 
* 					Unable to obtain estimate for upper hh income quintile in 
* 					union formation process for those in initial education 
* 					spell. 	
* 					Added interacted between gender and lagged economic activity 
* 					making the distinction between retired and not employed
* 					(les_c4).
********************************************************************************

clear all
set more off
set mem 200m
set type double
//set maxvar 120000
set maxvar 30000

cap log close 
//log using "$dir_log/reg_partnership.log", replace


use "$dir_input_data/${country}-SILC_pooled_all_obs_02.dta", clear

cap gen ypnbihs_dv_sq = ypnbihs_dv^2


* Labeling and formating variables
label define jbf 1 "Employed" 2 "Student" 3 "Not Employed"

label define gdr 1  "Male" 0 "Female"
						
label define yn	1 "Yes" 0 "No"

label define dces 1 "Both Employed" 2 "Employed, Spouse Not Employed" ///
				3 "Not Employed, Spouse Employed" 4 "Both Not Employed"

label define hht 1 "Couples with No Children" 2 "Couples with Children" ///
				3 "Single with No Children" 4 "Single with Children"

label variable dgn "Gender"
label variable dag "Age"
label variable dagsq "Age Squared"
label variable drgn1 "Region"
label variable stm "Year"
label variable les_c3 "Employment Status: 3 Category" 
label variable dhe "Self-rated Health"
label variable dcpen "Entered a new Partnership"
label variable dcpex "Partnership dissolution"
label variable deh_c3 "Educational Attainment: 3 Category"
label variable dnc "Number of Children in Household"
label variable dnc02 "Number of Children aged 0-2 in Household"
label variable ydses_c5 "Gross Annual Household Income Quintile" 
label variable lesdf_c4 "Differential Employment Status"
label variable ypnbihs_dv "Personal Non-benefit Gross Income"
label variable ypnbihs_dv_sq "Personal Non-benefit Gross Income Squared"
label variable ynbcpdf_dv "Differential Personal Non-Benefit Gross Income"
label variable dhhtp_c4 "Household Type: 4 Category"

label value dgn gdr
label value drgn1 rgna
label value les_c3 lessp_c3 jbf 
label value deh_c3 dehsp_c3 edd 
label value dcpen dcpex yn
label value lesdf_c4 dces
label value dhhtp_c4 hht

drop if dag < 16
replace stm = stm - 2000

* Covid dummies
gen y2020 = (stm == 20)
gen y2021 = (stm == 21)

recode dcpen dgn dag dagsq ydses_c5 dnc dnc02 dhe deh_c3 dehsp_c3 les_c3 ///
	les_c4 ypnbihs_dv ypnbihs_dv_sq dnc dnc02 dhe dhesp dcpyy dcpagdf ///
	dhhtp_c4 lesdf_c4 drgn1 stm dcpex (-9=. ) 
	
recode ynbcpdf_dv (-999=.)	

xtset idperson swv


* Check trend through time 
preserve

keep if inrange(dag, 18, 65)

gen partnered = (dcpst == 1)
gen single = (dcpst == 2)
ge prev_partnered = (dcpst == 3)

gen year = stm + 2000

collapse (mean) partnered  single prev_partnered, ///
	by(year)

twoway ///
(line partnered year, sort color(green) ///
	legend(label(1 "Partnered"))) ///
(line single year, sort color(blue) ///
	legend(label(2 "Single"))) ///
(line prev_partnered year, sort color(red) ///
	legend(label(3 "Previously partnered"))) ///
, title("Partnership status") xtitle("Year") ytitle("Share") ///
	note(Notes: Ages 18-65)

restore

graph drop _all 

* Set Excel file 
* Info sheet
putexcel set "$dir_work/reg_partnership_${country}", sheet("Info") replace
putexcel A1 = "Description:"
putexcel B1 = "Model parameters for relationship status projection"

putexcel A4 = "Process:", bold
putexcel B4 = "Description:", bold
putexcel A5 = "U1a"
putexcel B5 = "Probit regression estimates  probability of entering  a partnership - single respondents aged 18+ in initial education spell"
putexcel A6 = "U1b"
putexcel B6 = "Probit regression estimates of probability of entering a partnership - single respondents aged 18+ not in initial education spell"
putexcel A7 = "U2b"
putexcel B7 = "Probit regression estimates of probability of exiting a partnership - cohabiting women aged 18+ not in initial education spell"

putexcel A10 = "Notes:", bold
putexcel B10 = "Regions: ITF = South, ITG = Islands, ITH = Northeast, ITI = Central. Northwest (ITC) is the omitted region."

	
putexcel set "$dir_work/reg_partnership_${country}", sheet("Gof") modify
putexcel A1 = "Goodness of fit", bold		
	

****************************************************
* U1a: Partnership formation, in initial edu spell *
****************************************************

* Probability of entering a partnership. 
* Sample: All single respondents aged 18 +, in continuous education.
* DV: Enter partnership dummy 
* Note: Requirement of being single in the previous year is embedded in the 
* 		dependent variable  
* 		Only 17 observation of relationships forming when still in initial 
* 		education spell. 
xtset idperson swv
fre dcpen if (dag >= 18 & ded == 1 & ssscp != 1) 

probit dcpen i.dgn dag dagsq l.ydses_c5 dhe i.drgn1 stm ///
	if (dag >= 18 & ded == 1 & ssscp != 1) [pweight = dimxwt], vce(robust)
	
* Note: include health linearly and no number of children under 2 yo to obtain 
* 		estimates 		
gen in_sample = e(sample)	

predict p

save "$dir_data/U1a_sample", replace

scalar r2_p = e(r2_p) 
scalar N = e(N)	
scalar chi2 = e(chi2)
scalar ll = e(ll)	

		
* Results		
* Note: Zeros values are eliminated 
matrix b = e(b)	
matrix V = e(V)


* Store variance-covariance matrix 
preserve

putexcel set "$dir_results/partnership/var_cov", sheet("var_cov") replace
putexcel A1 = matrix(V)

import excel "$dir_results/partnership/var_cov", sheet("var_cov") clear

describe
local no_vars = `r(k)'	
	
forvalues i = 1/2 {
	egen row_sum = rowtotal(*)
	drop if row_sum == 0 
	drop row_sum
	xpose, clear	
}	
	
mkmat v*, matrix(var)	
putexcel set "$dir_work/reg_partnership_${country}", sheet("U1a") modify
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

// Create a new row vector to hold only non-zero coefficients
matrix nonzero_b = J(1, `non_zero_count', .)

* Populate nonzero_b with non-zero coefficients from b
local index = 1
forvalues i = 1/`no_vars' {
    if (b[1, `i'] != 0) {
        matrix nonzero_b[1, `index'] = b[1, `i']
        local index = `index' + 1
    }
}

putexcel set "$dir_work/reg_partnership_${country}", sheet("U1a") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 
	

* Labelling 
// Need to variable label when add new variable to model. Order matters. 
local var_list Dgn Dag Dag_sq Ydses_c5_L1 Dhe ///
	 ITI Year_transformed Constant

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
putexcel set "$dir_work/reg_partnership_${country}", sheet("Gof") modify

putexcel A3 = "U1a - Partnership formation, in initial education spell", ///
	bold		

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
 
 
********************************************************
* U1b: Partnership formation, not in initial edu spell *
********************************************************

* Process U1b: Probability of entering a partnership. 
* Sample: All respondents aged 18+, left initial education spell and not in a 
* 			same sex relationship 
* DV: Enter partnership dummy (requires not having been in a relationship last 
* 		year)	
* Note: Requirement of being single in the previous year is embedded in the 
* 			dependent variable  
* 		Income captured by hh quintiles. 
xtset idperson swv
fre dcpen if (dag >= 18 & ded == 0 & ssscp != 1)

probit dcpen dag dagsq ib1.deh_c3 i.dgn##li.les_c4 li.ydses_c5 l.dnc l.dnc02 ///
	i.dhe i.drgn1 stm y2020 y2021 if (dag >= 18 & ded == 0 & ssscp != 1) ///
	[pweight = dimxwt], vce(robust)
	
gen in_sample = e(sample)	

predict p

save "$dir_data/U1b_sample", replace

scalar r2_p = e(r2_p) 
scalar N = e(N)	
scalar chi2 = e(chi2)
scalar ll = e(ll)	
	
	
* Results 	
* Note: Zeros values are eliminated 
matrix b = e(b)	
matrix V = e(V)


*  Store variance-covariance matrix 
preserve

putexcel set "$dir_results/partnership/var_cov", sheet("var_cov") replace
putexcel A1 = matrix(V)

import excel "$dir_results/partnership/var_cov", sheet("var_cov") clear

describe
local no_vars = `r(k)'	
	
forvalues i = 1/2 {
	egen row_sum = rowtotal(*)
	drop if row_sum == 0 
	drop row_sum
	xpose, clear	
}	
	
mkmat v*, matrix(var)	
putexcel set "$dir_work/reg_partnership_${country}", sheet("U1b") modify
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

// Create a new row vector to hold only non-zero coefficients
matrix nonzero_b = J(1, `non_zero_count', .)

* Populate nonzero_b with non-zero coefficients from b
local index = 1
forvalues i = 1/`no_vars' {
    if (b[1, `i'] != 0) {
        matrix nonzero_b[1, `index'] = b[1, `i']
        local index = `index' + 1
    }
}

putexcel set "$dir_work/reg_partnership_${country}", sheet("U1b") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 
	
	
* Labelling 
// Need to variable label when add new variable to model. Order matters. 
local var_list Dag Dag_sq Deh_c3_Medium Deh_c3_Low Dgn Les_c4_Student_L1 ///
	Les_c4_NotEmployed_L1 Les_c4_Retired_L1 Les_c4_Student_L1_Dgn ///
	Les_c4_NotEmployed_L1_Dgn Les_c4_Retired_L1_Dgn Ydses_c5_Q2_L1 ///
	Ydses_c5_Q3_L1 Ydses_c5_Q4_L1 Ydses_c5_Q5_L1 Dnc_L1 Dnc02_L1 Dhe_Fair ///
	Dhe_Good Dhe_VeryGood Dhe_Excellent ITF ITG ITH ITI Year_transformed ///
	Y2020 Y2021 Constant

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
putexcel set "$dir_work/reg_partnership_${country}", sheet("Gof") modify

putexcel A9 = "U1b - Partnership formation, left initial education spell", ///
	bold		

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


**********************************************************
* U2b: Partnership termination, not in initial edu spell *
**********************************************************

* Process U2b: Probability of partnership break-up.
* Sample: 	Female member of a heterosexual couple in t-1 aged 18+ and not in 
* 			continuous education
* DV: Exit partnership dummy
* Note:	Requirement to be in a relationship last year is embedded in the DV.
* 		The ded condition refers to the female partner only. 
* 		If take away the ded condition doesn't make any difference because there
* 		are no splits by those in their initial education spell. 
xtset idperson swv	
fre dcpex if (dgn == 0 & dag >= 18 & ded == 0 & ssscp != 1) 
	
probit dcpex dag dagsq lib1.deh_c3 lib1.dehsp_c3 li.dhe li.dhesp ///
	l.dcpyy_st l.new_rel l.dcpagdf l.dnc l.dnc02 lib1.lesdf_c4 ///
	l.ypnbihs_dv l.ynbcpdf_dv i.drgn1 stm y2020 if ///
	(dgn == 0 & dag >= 18 & ded == 0 & ssscp != 1) [pweight = dimxwt], ///
	vce(robust)		

gen in_sample = e(sample)	

predict p

save "$dir_data/U2b_sample", replace

scalar r2_p = e(r2_p) 
scalar N = e(N)	 
scalar chi2 = e(chi2)
scalar ll = e(ll)


* Results 	
* Note: Zeros values are eliminated 	
matrix b = e(b)	
matrix V = e(V)

matrix list  V

*  Store variance-covariance matrix 
preserve

putexcel set "$dir_results/partnership/var_cov", sheet("var_cov") replace
putexcel A1 = matrix(V)

import excel "$dir_results/partnership/var_cov", sheet("var_cov") clear

describe
local no_vars = `r(k)'	
	
forvalues i = 1/2 {
	egen row_sum = rowtotal(*)
	drop if row_sum == 0 
	drop row_sum
	xpose, clear	
}	
	
mkmat v*, matrix(var)	
putexcel set "$dir_work/reg_partnership_${country}", sheet("U2b") modify
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

// Populate nonzero_b with non-zero coefficients from b
local index = 1
forvalues i = 1/`no_vars' {
    if (b[1, `i'] != 0) {
        matrix nonzero_b[1, `index'] = b[1, `i']
        local index = `index' + 1
    }
}

putexcel set "$dir_work/reg_partnership_${country}", sheet("U2b") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 

* Labelling 
// Need to variable label when add new variable to model. Order matters. 
local var_list Dag Dag_sq Deh_c3_Medium_L1 Deh_c3_Low_L1 Dehsp_c3_Medium_L1 ///
	Dehsp_c3_Low_L1 Dhe_Fair_L1 Dhe_Good_L1 Dhe_VeryGood_L1 Dhe_Excellent_L1 ///
	Dhesp_Fair_L1 Dhesp_Good_L1 Dhesp_VeryGood_L1 Dhesp_Excellent_L1 ///
	Dcpyy_L1 New_rel_L1 Dcpagdf_L1 Dnc_L1 Dnc02_L1 ///
	Lesdf_c4_EmployedSpouseNotEmployed_L1 ///
	Lesdf_c4_NotEmployedSpouseEmployed_L1 ///
	Lesdf_c4_BothNotEmployed_L1 Ypnbihs_dv_L1 Ynbcpdf_dv_L1 ITF ITG ITH ITI ///
	Year_transformed Y2020 Constant

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
putexcel set "$dir_work/reg_partnership_${country}", sheet("Gof") modify

putexcel A15 = ///
	"U2b - Partnership termination, left initial education spell", bold		

putexcel A17 = "Pseudo R-squared" 
putexcel B17 = r2_p 
putexcel A18 = "N"
putexcel B18 = N 
putexcel E17 = "Chi^2"		
putexcel F17 = chi2
putexcel E18 = "Log likelihood"		
putexcel F18 = ll		

drop in_sample p
scalar drop r2_p N chi2 ll	
	
	
capture log close 

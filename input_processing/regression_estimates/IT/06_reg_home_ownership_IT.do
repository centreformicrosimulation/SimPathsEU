********************************************************************************
* PROJECT:  		ESPON
* SECTION:			Home ownership 
* OBJECT: 			Probabilty of being a homeowner  
* AUTHORS:			Daria Popova, Justin van de Ven, Ashley Burdett
* LAST UPDATE:		21/04/2024 (JV)
* COUNTRY: 			Italy 
* 
* NOTES: 			Explored using les_c4 instead of les_c3. Didn't make much 
* 					difference to the estiamtes. 
********************************************************************************
clear all
set more off
set mem 200m
set type double
//set maxvar 120000
set maxvar 30000


cap log close 
log using "$dir_log/reg_home_ownership.log", replace


use "$dir_input_data/${country}-SILC_pooled_all_obs_02.dta", clear

//do "$dir_do/variable_update"


* Labeling and formating 

label define jbf 1 "Employed" 2 "Student" 3 "Not Employed"

label define edd 1 "Degree"	2 "High school" ///
					3 "Other/No Qualification"

label define gdr 1 "Male" 0 "Female"
						
label define yn	1 "Yes" 0 "No"

label define hht 1 "Couples with No Children" 2 "Couples with Children" ///
				3 "Single with No Children" 4 "Single with Children"

label variable dgn "Gender"
label variable dag "Age"
label variable dagsq "Age Squared"
label variable drgn1 "Region"
label variable stm "Year"
label variable les_c3 "Employment Status: 5 Category" 
label variable dhe "Self-rated Health"
label variable deh_c3 "Educational Attainment: 3 Category"
label variable dhhtp_c4 "Household Type: 4 Category"

label value dgn gdr
label value drgn1 rgna
label value les_c3 lessp_c3 jbf 
label value deh_c3 dehsp_c3 edd 
label value dcpen dcpex dlrtrd yn
label value dhhtp_c4 hht

drop if dag < 16
replace stm = stm - 2000

* Covid dummies
gen y2020 = (stm == 20)
gen y2021 = (stm == 21)

recode dhh_owned dgn dag dagsq les_c3 deh_c3 dhe yptciihs_dv ydses_c5 drgn1 ///
	dhhtp_c4 lessp_c3 stm les_c4 dhhtp_c8 (-9=.)
				
					
xtset idperson swv


* Set Excel file 
* Info sheet
putexcel set "$dir_work/reg_home_ownership_${country}", sheet("Info") replace
putexcel A1 = "Description:"
putexcel B1 = "Model parameters governing projection of home ownership"

putexcel A4 = "Process:", bold
putexcel B4 = "Description:", bold
putexcel A5 = "HO1a"
putexcel B5 = "Probit regression estimates o the probability of being a home owner, aged 18+"

putexcel A10 = "Notes:", bold
putexcel B10 = "Have combined dhhtp_c4 and lessp_c3 into a single variable with 8 cateogries, dhhtp_c8"
putexcel B10 = "Regions: ITF = South, ITG = Islands, ITH = Northeast, ITI = Central. Northwest (ITC) is the omitted region."


putexcel set "$dir_work/reg_home_ownership_${country}", sheet("Gof") modify
putexcel A1 = "Goodness of fit", bold		


************************
* HO1a: Home ownership *
************************

* Process HO1a: Probability of being a home owner 
* Sample: Individuals aged 18+
* DV: Home ownerhip dummy
fre dhh_owned if dag >= 18
	
probit dhh_owned dgn dag dagsq il.dhhtp_c8 il.les_c3  ///
	i.deh_c3 il.dhe il.ydses_c5 l.yptciihs_dv l.dhh_owned i.drgn1 stm y2020 ///
	y2021 if dag >= 18 [pweight = dimxwt], vce(cluster idperson)

gen in_sample = e(sample)	

predict p

save "$dir_data/HO1a_sample", replace

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

putexcel set "$dir_results/home_ownership/var_cov", sheet("var_cov") ///
	replace
putexcel A1 = matrix(V)

import excel "$dir_results/home_ownership/var_cov", sheet("var_cov") clear

describe
local no_vars = `r(k)'	
	
forvalues i = 1/2 {
	egen row_sum = rowtotal(*)
	drop if row_sum == 0 
	drop row_sum
	xpose, clear	
}	
	
mkmat v*, matrix(var)	
putexcel set "$dir_work/reg_home_ownership_${country}", sheet("HO1a") modify 
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

putexcel set "$dir_work/reg_home_ownership_${country}", sheet("HO1a") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 	
	
* Labelling 
local var_list Dgn Dag Dag_sq Dhhtp_c8_2_L1 Dhhtp_c8_3_L1 Dhhtp_c8_4_L1 ///
	Dhhtp_c8_5_L1 Dhhtp_c8_6_L1 Dhhtp_c8_7_L1 Dhhtp_c8_8_L1 Les_c3_Student_L1 ///
	Les_c3_NotEmployed_L1 Deh_c3_Medium Deh_c3_Low Dhe_Fair_L1 Dhe_Good_L1 ///
	Dhe_VeryGood_L1 Dhe_Excellent_L1 Ydses_c5_Q2_L1 Ydses_c5_Q3_L1 ///
	Ydses_c5_Q4_L1 Ydses_c5_Q5_L1 Yptciihs_dv_L1 Dhh_owned_L1 ITF ITG ITH ///
	ITI Year_transformed Y2020 Y2021 Constant

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
putexcel set "$dir_work/reg_home_ownership_${country}", sheet("Gof") modify

putexcel A3 = "HO1a - Home ownership", bold		

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

capture log close 

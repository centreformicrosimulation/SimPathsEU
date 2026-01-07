********************************************************************************
* PROJECT:  		ESPON
* SECTION:			Retirement  
* OBJECT: 			Probability of retiring by partnerhip status  
* AUTHORS:			Daria Popova, Justin van de Ven, Ashley Burdett, 
* 					Matteo Richiardi
* LAST UPDATE:		March 2025 (AB)
* COUNTRY: 			Italy 

* NOTES: 			Changed dependent variable so that not populated when cannot 
* 					transition to retirement 
* 
********************************************************************************
clear all
set more off
set mem 200m
set type double
//set maxvar 120000
set maxvar 30000

cap log close 
//log using "$dir_log/reg_retirement.log", replace


use "$dir_input_data/${country}-SILC_pooled_all_obs_02.dta", clear


* Labeling and formating variables

label define jbf 1 "Employed" 2 "Student" 3 "Not Employed"

label define edd 1 "Degree"	2 "High school" ///
				3 "Other/No Qualification"

label define gdr 1  "Male" 0 "Female"
						
label define yn	1 "Yes" 0 "No"

label define hht 1 "Couples with No Children" 2 "Couples with Children" ///
				3 "Single with No Children" 4 "Single with Children"

label variable dgn "Gender"
label variable dag "Age"
label variable dagsq "Age Squared"
label variable drgn1 "Region"
label variable stm "Year"
label variable les_c3 "Employment Status: 3 Category" 
label variable dhe "Self-rated Health"
label variable deh_c3 "Educational Attainment: 3 Category"
label variable dhhtp_c4 "Household Type: 4 Category"

label value dgn gdr
label value drgn1 rgna
label value les_c3 lessp_c3 jbf 
label value deh_c3 dehsp_c3 edd 
label value dcpen dcpex dlrtrd dagpns dagpns_sp yn
label value dhhtp_c4 hht

drop if dag < 16
replace stm = stm - 2000

gen y2020 = (stm == 20)
gen y2021 = (stm == 21)

recode dgn dag dagsq deh_c3 dagpns lesnr_c2 ydses_c5 dlltsd drgn1 stm ///
	dcpst drtren dagpns_sp lessp_c3 dlltsd_sp dcpst dagpns_y dagpns_y1 ///
	dagpns_y_sp dagpns_y1_sp (-9=.)

xtset idperson swv


* Set Excel file 
* Info sheet
putexcel set "$dir_work/reg_retirement_${country}", sheet("Info") replace
putexcel A1 = "Description:"
putexcel B1 = "Model parameters governing projection of retirement"

putexcel A4 = "Process:", bold
putexcel B4 = "Description:", bold
putexcel A5 = "R1a"
putexcel B5 = "Probit regression estimates of the probability of retiring, single individuals aged 50+ not yet retired"
putexcel A6 = "R1b"
putexcel B6 = "Probit regression estimates of the probability of retiring, cohabiting individuals aged 50+ not yet retired"
putexcel A10 = "Notes:", bold
putexcel B10 = "Regions: ITF = South, ITG = Islands, ITH = Northeast, ITI = Central. Northwest (ITC) is the omitted region."

putexcel set "$dir_work/reg_retirement_${country}", sheet("Gof") modify
putexcel A1 = "Goodness of fit", bold		

/*
*********************
* Age at retirement *
*********************

* Pooled
twoway (histogram dag if dgn == 1 & drtren == 1, fraction color(blue%50)) ///
	(histogram dag if dgn == 0 & drtren == 1, fraction color(red%50)), ///
	legend(label(1 "men") label(2 "women")) ///
	title("Age at retirement") ytitle("Frequency") ///
	name("retAll", replace)
	graph export "$dir_work/graphs/retirement_age_pooled.png", as(png) name(retAll) replace

		
* By year
forvalues y = 2010/2023 {
	twoway (histogram dag if dgn == 1 & drtren == 1 & swv == `y', fraction color(blue%50)) ///
		(histogram dag if dgn == 0 & drtren == 1 & swv == `y', fraction color(red%50)), ///
		legend(label(1 "men") label(2 "women")) ///
		title("Age at retirement, `y'") ytitle("Frequency") ///
		name("ret`y'", replace)	
}

graph combine ret2010 ret2011 ret2012 ret2013 ret2014 ret2015 ret2016 ret2017 ret2018 ret2019 ret2020 ret2021 ret2022 ret2023
*/

****************************
* R1a: Retirement - Single *
****************************

* Process R1a: Probability retire if single 
* Sample: Non-partnered individuals aged 50+ who are not yet retired.
* DV: Enter retirement dummy (have to not be retired last year)
probit drtren i.dgn dag dagsq i.dagpns_y i.dagpns_y1 ib1.deh_c3 ///
	i.dagpns li.lesnr_c2 li.ydses_c5 li.dlltsd i.drgn1 stm y2020 y2021 ///
	if ((dcpst == 2 | dcpst == 3) & dag >= 50) [pweight = dimxwt], vce(robust)
	
gen in_sample = e(sample)	

predict p

graph bar (mean) drtren p if in_sample, over(dag, label(labsize(vsmall)))  ///
	legend(label(1 "observed") label(2 "predicted"))

save "$dir_data/R1a_sample", replace

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

putexcel set "$dir_results/retirement/var_cov", sheet("var_cov") ///
	replace
putexcel A1 = matrix(V)

import excel "$dir_results/retirement/var_cov", sheet("var_cov") clear

describe
local no_vars = `r(k)'	
	
forvalues i = 1/2 {
	egen row_sum = rowtotal(*)
	drop if row_sum == 0 
	drop row_sum
	xpose, clear	
}	
	
mkmat v*, matrix(var)	
putexcel set "$dir_work/reg_retirement_${country}", sheet("R1a") modify
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

putexcel set "$dir_work/reg_retirement_${country}", sheet("R1a") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2)  

* Labelling 
// Need to variable label when add new variable to model. Order matters. 
local var_list Dgn Dag Dag_sq Elig_pen Elig_pen_L1 Deh_c3_Medium Deh_c3_Low ///
	Reached_Retirement_Age Les_c3_NotEmployed_L1  Ydses_c5_Q2_L1 ///
	Ydses_c5_Q3_L1 Ydses_c5_Q4_L1 Ydses_c5_Q5_L1 Dlltsd_L1 ITF ITG ITH ITI ///
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
putexcel set "$dir_work/reg_retirement_${country}", sheet("Gof") modify

putexcel A3 = "R1a - Retirement single", bold		

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

 
******************************
* R1b: Retirement, partnered *
******************************

* Process R1b: Probability retire 
* Sample: Partnered heterosexual individuals aged 50+ who are not yet retired
* DV: Enter retirement dummy (have to not be retired last year)
probit drtren i.dgn dag dagsq i.dagpns_y i.dagpns_y1 ib1.deh_c3 ///
	i.dagpns li.lesnr_c2 i.dagpns#li.lesnr_c2 li.ydses_c5 li.dlltsd ///
	i.dagpns_sp i.dagpns_y_sp i.dagpns_y1_sp li.lessp_c3 li.dlltsd_sp ///
	i.drgn1 stm y2020 y2021 if ///
	(ssscp != 1 & dcpst == 1 & dag >= 50) [pweight = dimxwt], vce(robust)

gen in_sample = e(sample)	

predict p

graph bar (mean) drtren p if in_sample, over(dag, label(labsize(vsmall)))  ///
	legend(label(1 "observed") label(2 "predicted"))

save "$dir_data/R1b_sample", replace

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

putexcel set "$dir_results/retirement/var_cov", sheet("var_cov") replace
putexcel A1 = matrix(V)

import excel "$dir_results/retirement/var_cov", sheet("var_cov") clear

describe
local no_vars = `r(k)'	
	
forvalues i = 1/2 {
	egen row_sum = rowtotal(*)
	drop if row_sum == 0 
	drop row_sum
	xpose, clear	
}	
	
mkmat v*, matrix(var)	
putexcel set "$dir_work/reg_retirement_${country}", sheet("R1b") modify
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

putexcel set "$dir_work/reg_retirement_${country}", sheet("R1b") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 
	
* Labelling 
// Need to variable label when add new variable to model. Order matters. 
local var_list Dgn Dag Dag_sq Elig_pen Elig_pen_L1 Deh_c3_Medium ///
	Deh_c3_Low Reached_Retirement_Age ///
	Les_c3_NotEmployed_L1 Reached_Retirement_Age_Les_c3_NotEmployed_L1 ///
	Ydses_c5_Q2_L1 Ydses_c5_Q3_L1 Ydses_c5_Q4_L1 Ydses_c5_Q5_L1 ///
	Dlltsd_L1 Reached_Retirement_Age_Sp Elig_pen_Sp Elig_pen_L1_Sp ///
	Lessp_c3_NotEmployed_L1 ///
	Dlltsdsp_L1 ITF ITG ITH ITI Year_transformed Y2020 Y2021 Constant

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
putexcel set "$dir_work/reg_retirement_${country}", sheet("Gof") modify

putexcel A9 = "R1b - Retirement partnered", bold		

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

graph drop _all

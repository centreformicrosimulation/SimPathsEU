********************************************************************************
* PROJECT:  		ESPON
* SECTION:			Non-employment/non-benefit income
* OBJECT: 			Final Regresion Models 
* AUTHORS:			Daria Popova, Justin van de Ven, Ashley Burdett
* LAST UPDATE:		Feb 2025 
* COUNTRY: 			Italy 

* NOTES: 			 
* 
* 					I3a - Capital income (in cont edu, selection & amount)
* 					I3b - Capital income (not in cont edu, selection & amount)
* 
* 					Estimate both 
* 					Explored using les_c4 instead of les_c3, but didn't make a 
* 						material difference. 
* 
********************************************************************************
clear all
set more off
set mem 200m
set type double
//set maxvar 120000
set maxvar 30000


cap log close 

//log using "$dir_log/reg_income.log", replace


* Call data with heckman wage estimates
use "$dir_data/${country}-SILC_pooled_all_obs_03.dta", clear 


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
label variable deh_c3 "Educational Attainment: 3 Category"
label variable dhhtp_c4 "Household Type: 4 Category"
label variable dnc "Number of Children in Household"
label variable dnc02 "Number of Children aged 0-2 in Household"
label variable dhe "Self-rated Health"
label variable ydses_c5 "Annual Household Income Quintile" 
label variable dlltsd "Long-term Sick or Disabled"
label variable dcpen "Entered a new Partnership"
label variable dcpex "Partnership dissolution"
label variable lesdf_c4 "Differential Employment Status"
label variable ypnbihs_dv "Personal Non-benefit Gross Income"
label variable ypnoab_lvl "Real pension income, level"
label variable ypnoab "Real pension income, IHS"

gen  ypnbihs_dv_sq = ypnbihs_dv^2 
 
label variable ypnbihs_dv_sq "Personal Non-benefit Gross Income Squared"
label variable ynbcpdf_dv "Differential Personal Non-Benefit Gross Income"

label value dgn gdr
label value les_c3 jbf 
label value deh_c3 edd 
label value dcpen dcpex yn
label value lesdf_c4 dces
label value ded dlltsd yn
label value dhhtp_c4 hht

drop if dag < 16
//replace stm = stm - 2000
sort stm

recode dgn dag dagsq dhe drgn1 stm scedsmpl deh_c3 les_c4 les_c3 les_c4 ///
	dhhtp_c4 dhe (-9=.)

sum yplgrs_dv ypncp ypnoab /*pred_hourly_wage*/

xtset idperson swv 

bys swv idhh: gen nwa = _N

* Trim the top captial income percentile
sum ypncp, det
scalar p99 = r(p99)

replace ypncp = . if ypncp >= p99

* Lagged variables 
/*
If lagged value missing fill in from the last previous observation that is 
 	not missing
*/

* Health 
xtset idperson swv 
gsort +idperson -stm

bys idperson: carryforward dhe if dag <= 16, replace 

sort idperson swv
bys idperson: gen dhe_L1 = l.dhe

// For those who still have L1.dhe missing, use current dhe
replace dhe_L1 = dhe if missing(dhe_L1) 

* Gross employment income (IHS, monthly)
// If no lag available, use the current observation 
bys idperson: gen yplgrs_L1 = l.yplgrs_dv
replace yplgrs_L1 = yplgrs_dv if missing(yplgrs_L1)

bys idperson: gen yplgrs_L2 = l2.yplgrs_dv
replace yplgrs_L2 = yplgrs_dv if missing(yplgrs_L2)

* Gross non-employment income (IHS, monthly)
// If no lag available, use the current observation 
bys idperson: gen ypncp_L1 = l.ypncp
replace ypncp_L1 = ypncp if missing(ypncp_L1)

bys idperson: gen ypncp_L2 = l2.ypncp
replace ypncp_L2 = ypncp if missing(ypncp_L2)

* Household type
// If no lag available, use the current observation 
bys idperson: gen dhhtp_c4_L1 = l.dhhtp_c4
replace dhhtp_c4_L1 = dhhtp_c4 if missing(dhhtp_c4_L1)

* Employment status 
xtset idperson swv 

bys idperson: gen les_c3_L1 = l.les_c3
replace les_c3_L1 = les_c3 if missing(les_c3_L1)

gen receives_ypncp = (ypncp > 0 & !missing(ypncp))


* Set Excel file 
* Info sheet
putexcel set "$dir_work/reg_income_${country}", sheet("Info") replace
putexcel A1 = "Description:"
putexcel B1 = "This file contains regression estiamtes used by process I3, capital income. The data suggests there is no private pension income "

putexcel A4 = "Process:", bold
putexcel B4 = "Description:", bold
putexcel A5 = "Process I3a selection"
putexcel B5 = "Logit regression estimates of the probability of receiving capital income - aged 16+ in initial education spell"
putexcel A6 = "Process I3b selection"
putexcel B6 = "Logit regression estimates of the probability of receiving capital income - aged 16+ not in initial education spell"
putexcel A7 = "Process I3a"
putexcel B7 = "OLS regression estimates (log) capital income amount - aged 16+ in initial education spell, who receive capital income"
putexcel A8 = "Process I3a"
putexcel B8 = "OLS regression estimates (log) capital income amount - aged 16+ not in initial education spell, who receive capital income"

putexcel A10 = "Notes:", bold
putexcel B10 = "Categorical health variable modelled as continuous"
putexcel B11 = "Regions: ITF = South, ITG = Islands, ITH = Northeast, ITI = Central. Northwest (ITC) is the omitted region."

* Goodness of fit
putexcel set "$dir_work/reg_income_${country}", sheet("Gof") modify

putexcel A1 = "Goodness of fit", bold

*****************************************************************
* I3a selection: Receiving capital income, in initial edu spell *
*****************************************************************
xtset idperson swv 
cap drop in_sample

* Process I3a: Probability of receiving capital income 
* Sample: All individuals 16+ that are in initial edu spell
* DV: Receiving capital income dummy
* Note: Capital income and employment income variables in IHS version 	
logit receives_ypncp i.dgn dag dagsq l.dhe l.yplgrs_dv l.ypncp i.drgn1 ///
	stm y2020 y2021 if ded == 1 & dag >= 16 [pweight = dimxwt], ///
	vce(cluster idperson) base	

gen in_sample = e(sample)	

predict p

save "$dir_data/I3a_selection_sample", replace

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

putexcel set "$dir_results/income/var_cov", sheet("var_cov") replace
putexcel A1 = matrix(V)

import excel "$dir_results/income/var_cov", sheet("var_cov") clear

describe
local no_vars = `r(k)'	
	
forvalues i = 1/2 {
	egen row_sum = rowtotal(*)
	drop if row_sum == 0 
	drop row_sum
	xpose, clear	
}	
	
mkmat v*, matrix(var)	
putexcel set "$dir_work/reg_income_${country}", sheet("I3a_selection") modify
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

putexcel set "$dir_work/reg_income_${country}", sheet("I3a_selection") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 
	
	
* Labelling 
// Need to variable label when add new variable to model. Order matters. 
local var_list Dgn Dag Dag_sq Dhe_L1 Yplgrs_dv_L1 Ypncp_L1 ITF ITG ITH ITI ///
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
putexcel set "$dir_work/reg_income_${country}", sheet("Gof") modify

putexcel A3 = ///
	"I3a selection - Receiving capital income in initial education spell ", ///
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
		
	
*********************************************************************
* I3b selection: Receiving capital income, not in initial edu spell *
*********************************************************************
xtset idperson swv 

* Process I3b: Probability of receiving capital income, not in initial edu spell
* Sample: All individuals 16+, not in initial edu spell
* DV: Receiving capital income dummy
* Note: Capital income and employment income variables in IHS version 	

logit receives_ypncp i.dgn dag dagsq ib1.deh_c3 li.les_c4 lib1.dhhtp_c4 ///
	l.dhe l.yplgrs_dv l.ypncp l2.yplgrs_dv l2.ypncp i.drgn1 stm y2020 ///
	y2021 if ded == 0 [pweight = dimxwt], vce(cluster idperson) base
	
gen in_sample = e(sample)
	
predict p

save "$dir_data/I3b_selection_sample", replace

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

putexcel set "$dir_results/income/var_cov", sheet("var_cov") replace
putexcel A1 = matrix(V)

import excel "$dir_results/income/var_cov", sheet("var_cov") clear

describe
local no_vars = `r(k)'	
	
forvalues i = 1/2 {
	egen row_sum = rowtotal(*)
	drop if row_sum == 0 
	drop row_sum
	xpose, clear	
}	
	
mkmat v*, matrix(var)	
putexcel set "$dir_work/reg_income_${country}", sheet("I3b_selection") modify
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

putexcel set "$dir_work/reg_income_${country}", sheet("I3b_selection") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 		
	
* Labelling 
// Need to variable label when add new variable to model. Order matters. 
local var_list Dgn Dag Dag_sq Deh_c3_Medium Deh_c3_Low Les_c4_Student_L1 ///
	Les_c4_NotEmployed_L1 Les_c4_Retired_L1 Dhhtp_c4_CoupleChildren_L1 ///
	Dhhtp_c4_SingleNoChildren_L1 Dhhtp_c4_SingleChildren_L1 ///
	Dhe_L1 Yplgrs_dv_L1 Ypncp_L1 Yplgrs_dv_L2 Ypncp_L2 ITF ITG ITH ITI ///
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
putexcel set "$dir_work/reg_income_${country}", sheet("Gof") modify

putexcel A9 = ///
	"I3b selection - Receiving capital income left initial education spell ", ///
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
	
*******************************************************
* I3a: Amount of capital income, in initial edu spell * 
*******************************************************
xtset idperson swv 

* Process I3a: Amount of capital income, in initial edu spell
* Sample: All individuals 16+ that received capital income, in initial education 
* 			spell
* DV: IHS of capital income 
gen ypncp_lvl = sinh(ypncp) 
gen ln_ypncp = ln(ypncp_lvl)

regress ln_ypncp i.dgn dag dagsq l.dhe l.yplgrs_dv l.ypncp i.drgn1 stm ///
	y2020 y2021 if dag >= 16 & receives_ypncp == 1 & ded == 1 ///
	[pweight = dimxwt], vce(cluster idperson) 

gen in_sample = e(sample)	

predict p

save "$dir_data/I3a_level_sample", replace

scalar r2_p = e(r2_p) 
scalar N = e(N)		
	
* Results 
* Note: Zeros values are eliminated 	
matrix b = e(b)	
matrix V = e(V)

* Store variance-covariance matrix 
preserve

putexcel set "$dir_results/income/var_cov", sheet("var_cov") replace
putexcel A1 = matrix(V)

import excel "$dir_results/income/var_cov", sheet("var_cov") clear

describe
local no_vars = `r(k)'	
	
forvalues i = 1/2 {
	egen row_sum = rowtotal(*)
	drop if row_sum == 0 
	drop row_sum
	xpose, clear	
}	
	
mkmat v*, matrix(var)	
putexcel set "$dir_work/reg_income_${country}", sheet("I3a_amount") modify
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

putexcel set "$dir_work/reg_income_${country}", sheet("I3a_amount") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 		
 	
* Labelling 
// Need to variable label when add new variable to model. Order matters. 
local var_list Dgn Dag Dhe_L1 Dhe_L1 Yplgrs_dv_L1 Ypncp_L1 ITF ITG ITH ITI ///
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
		
* Calculate RMSE
cap drop residuals squared_residuals  
predict  residuals , residuals
gen squared_residuals = residuals^2

preserve 
keep if ded == 1 & receives_ypncp == 1
sum squared_residuals [w = dimxwt]
di "RMSE for Amount of capital income" sqrt(r(mean))
putexcel set "$dir_work/reg_RMSE_${country}.xlsx", sheet("${country}") modify
putexcel A6 = ("I3a") B6 = (sqrt(r(mean))) 
restore 

* Goodness of fit
putexcel set "$dir_work/reg_income_${country}", sheet("Gof") modify

putexcel A15 = ///
	"I3a level - Receiving capital income in initial education spell ", ///
	bold		
	
putexcel A17 = "Pseudo R-squared" 
putexcel B17 = r2_p 
putexcel A18 = "N"
putexcel B18 = N 

drop in_sample p
scalar drop r2_p N 
	
	
***********************************************************
* I3b: Amount of capital income, not in initial edu spell * 
*********************************************************** 
xtset idperson swv 

* Process I3b: Amount of capital income, not in initial edu spell
* Sample: Individuals aged 16+ who are not in their initial education spell and 
* 	receive capital income.

regress ln_ypncp i.dgn dag dagsq ib1.deh_c3 li.les_c4 lib1.dhhtp_c4 l.dhe ///
	l.yplgrs_dv l.ypncp l2.yplgrs_dv l2.ypncp i.drgn1 stm y2020 y2021 ///
	if ded == 0 & receives_ypncp == 1 [pweight = dimxwt], ///
	vce(cluster idperson)
	
gen in_sample = e(sample)	

predict p

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

putexcel set "$dir_results/income/var_cov", sheet("var_cov") replace
putexcel A1 = matrix(V)

import excel "$dir_results/income/var_cov", sheet("var_cov") clear

describe
local no_vars = `r(k)'	
	
forvalues i = 1/2 {
	egen row_sum = rowtotal(*)
	drop if row_sum == 0 
	drop row_sum
	xpose, clear	
}	
	
mkmat v*, matrix(var)	
putexcel set "$dir_work/reg_income_${country}", sheet("I3b_amount") modify
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

putexcel set "$dir_work/reg_income_${country}", sheet("I3b_amount") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 		
	
* Labelling 
// Need to variable label when add new variable to model. Order matters. 
local var_list Dgn Dag Dag_sq Deh_c3_Medium Deh_c3_Low Les_c4_Student_L1 ///
	Les_c4_NotEmployed_L1 Les_c4_Retired_L1  Dhhtp_c4_CoupleChildren_L1 ///
	Dhhtp_c4_SingleNoChildren_L1  Dhhtp_c4_SingleChildren_L1 ///
	Dhe_L1  Yplgrs_dv_L1 Ypncp_L1 Yplgrs_dv_L2 Ypncp_L2 ITF ITG ITH ITI ///
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
	
* Calculate RMSE
cap drop residuals squared_residuals  
predict  residuals , residuals
gen squared_residuals = residuals^2

preserve 
keep if ded == 0 & receives_ypncp == 1
sum squared_residuals [w=dimxwt]
di "RMSE for Amount of capital income: not in education" sqrt(r(mean))
putexcel set "$dir_work/reg_RMSE_${country}.xlsx", sheet("${country}") modify
putexcel A7 = ("I3b") B7 = (sqrt(r(mean))) 
restore 


* Goodness of fit
putexcel set "$dir_work/reg_income_${country}", sheet("Gof") modify

putexcel A21 = ///
	"I3b level - Receiving capital income left initial education spell ", ///
	bold		
	
putexcel A23 = "Pseudo R-squared" 
putexcel B23 = r2_p 
putexcel A24 = "N"
putexcel B24 = N 

drop in_sample p
scalar drop r2_p N 

graph drop _all 



/*	
* Private pension income 

histogram ypnoab_lvl if ypnoab_lvl < 50 

gen ypnoab_cat = 0 if ypnoab_lvl == 0 
replace ypnoab_cat = 1 if ypnoab_lvl > 0 & ypnoab_lvl <= 1
replace ypnoab_cat = 2 if ypnoab_lvl > 1 & ypnoab_lvl <= 2
replace ypnoab_cat = 3 if ypnoab_lvl > 2 & ypnoab_lvl <= 3
replace ypnoab_cat = 4 if ypnoab_lvl > 3 & ypnoab_lvl <= 4
replace ypnoab_cat = 5 if ypnoab_lvl > 4 & ypnoab_lvl <= 5
replace ypnoab_cat = 6 if ypnoab_lvl > 4 & ypnoab_lvl != . 

tab ypnoab_cat if dag > 20

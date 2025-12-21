********************************************************************************
* PROJECT:  		ESPON 
* SECTION:			Education
* OBJECT: 			Final Probit Models 
* AUTHORS:			Daria Popova, Justin van de Ven, Ashley Burdett 
* LAST UPDATE:		12/2024 (AB)
* COUNTRY: 			Hungary 

* NOTES: 			Need to manually create the sheet with correctly formatted 
* 					results for process E2a. Only want one row for the estimates
* 					that satisfy the parrallel lines assumption for which the 
* 					regressor name should be followed by a *_. For the remaining 
* 					variables, the regressor name should be followed by the 
* 					an underscore and the relevant category name of the
* 			 		dependent variable. 
********************************************************************************
clear all
set more off
set mem 200m
set type double
//set maxvar 120000
set maxvar 30000

local model_specification_test = 0

cap log close 
//log using "$dir_log/reg_education.log", replace


use "$dir_input_data/HU-SILC_pooled_all_obs_02.dta", clear

//do "$dir_do/variable_update"


* Labeling and formating variables
label define jbf 1 "Employed" 2 "Student" 3 "Not Employed"

label define edd 1 "Degree"	2 "Other Higher/A-level/GCSE" ///
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

label value dgn gdr
label value les_c3 jbf 
label value ded yn
label value dhhtp_c4 hht

drop if dag < 16

replace stm = stm - 2000
fre stm 

gen y2020 = (stm == 20)
gen y2021 = (stm == 21)

* Check if all covariates are available in the data
recode ded dgn dag dagsq drgn1 stm deh_c3 les_c3 (-9=.) 

xtset idperson swv

* Graphical inspection 
preserve 

keep if l.ded == 1 & ded == 0 

tab stm deh_c3, row

gen year = stm + 2000

gen high = (deh_c3 == 1)
gen med = (deh_c3 == 2)
gen low = (deh_c3 == 3)

replace high = . if  deh_c3 == . 
replace med = . if  deh_c3 == . 
replace low = . if  deh_c3 == . 

collapse (mean) high med low [aw = dwt], by(year)

twoway ///
(line high year, sort color(green) ///
	legend(label(1 "High edu "))) ///
(line med year, sort color(blue) ///
	legend(label(2 "Medium edu"))) ///
(line low year, sort color(red) ///
	legend(label(3 "Low edu"))) ///
, title("Educational attainment of estimation sample") xtitle("Year") ///
	ytitle("Share") 

restore 


* Activity status 
preserve 

keep if inrange(dag, 18, 65)

gen employed = (les_c4 == 1)
gen student = (les_c4 == 2)
gen not_employed = (les_c4 == 3)
gen retired = (les_c4 == 4)

replace employed = . if les_c4 == -9 | les_c4 == . 
replace student = . if les_c4 == -9 | les_c4 == . 
replace not_employed = . if les_c4 == -9 | les_c4 == . 
replace retired = . if les_c4 == -9 | les_c4 == . 

gen year = stm + 2000

collapse (mean) employed student not_employed retired [aw = dwt], ///
	by(year)

twoway ///
(line employed year, sort color(green) ///
	legend(label(1 "Employed"))) ///
(line student year, sort color(blue) ///
	legend(label(2 "Student"))) ///
(line not_employed year, sort color(red) ///
	legend(label(3 "Not employed"))) ///
(line retired year, sort color(grey) ///
	legend(label(4 "Retired"))) ///	
, title("Activity status") xtitle("Year") ytitle("Share") ///
	note(Notes: Ages 18-65)

restore


graph drop _all 


* Set Excel file 
* Info sheet
putexcel set "$dir_work/reg_education_HU_raw", sheet("Info") replace
putexcel A1 = "Description:"
putexcel B1 = "Model parameters governing projection of education status"

putexcel A4 = "Process:", bold
putexcel B4 = "Description:", bold
putexcel A5 = "E1a"
putexcel B5 = "Probit regression estimates of remaining in continuous education - individuals aged 16-29 in initial education spell"
putexcel A6 = "E1b"
putexcel B6 = "Probit regression estimates of returning to education - individuals aged 16-35 not in initial education spell"
putexcel A7 = "E2a"
putexcel B7 = "Generalized ordered logit regression estimates of education attainment - individuals aged 16-29 exiting education that were in initial education spell in t-1 but not in t"
putexcel A10 = "Notes:", bold

putexcel set "$dir_work/reg_education_HU_raw", sheet("Gof") modify
putexcel A1 = "Goodness of fit", bold		


*******************************************************
* E1a: Probability of Leaving Initial Education Spell *
*******************************************************
xtset idperson swv
* Process E1a: Leaving the initial education spell. 
* Sample: Individuals aged 16-29 who have not left their initial education spell
* DV: In continuous education dummy 
* Note: Condition implies some persistence - educaiton for the last 2 years. 

fre ded if (dag >= 16 & dag <= 29 & l.ded == 1) 
// was in initial education spell in the previous wave 
// 78% remain in education 

probit ded i.dgn dag dagsq i.drgn1 stm y2020 y2021 if ///
	(dag >= 16 & dag <= 29 & l.ded == 1) [pweight = dimxwt], vce(robust)	
	
gen in_sample = e(sample)	

predict p

save "$dir_data/E1a_sample", replace

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

putexcel set "$dir_results/education/var_cov", sheet("var_cov") replace
putexcel A1 = matrix(V)

import excel "$dir_results/education/var_cov", sheet("var_cov") clear

describe
local no_vars = `r(k)'	
	
forvalues i = 1/2 {
	egen row_sum = rowtotal(*)
	drop if row_sum == 0 
	drop row_sum
	xpose, clear	
}	
	
mkmat v*, matrix(var)	
putexcel set "$dir_work/reg_education_HU_raw", sheet("E1a") modify
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

putexcel set "$dir_work/reg_education_HU_raw", sheet("E1a") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 


* Labelling 
local var_list Dgn Dag Dag_sq HUA HUB Year_transformed Y2020 Y2021 ///
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
	
* Goodness of fit
putexcel set "$dir_work/reg_education_HU_raw", sheet("Gof") modify

putexcel A3 = "E1a - Leaving initial education spell", bold		

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
	
	
**********************************************
* E1b: Probability of Returning to Education *
**********************************************
xtset idperson swv
* Process E1b: Retraining having previously entered the labour force. 
* Sample: Individuals aged 16-35 who have left their initial education spell 
*  			and not a student last year 
* DV: Return to education 

fre der if (dag >= 16 & dag <= 35 & ded == 0) 
// 99% remain out of education 

probit der i.dgn dag dagsq lib2.deh_c3 li.les_c3 l.dnc l.dnc02 ///
	 i.drgn1 stm y2020 y2021 if (dag >= 16 & dag <= 35 & ded == 0) ///
	 [pweight=dimlwt], vce(robust)

gen in_sample = e(sample)	

predict p

save "$dir_data/E1b_sample", replace

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

putexcel set "$dir_results/education/var_cov", sheet("var_cov") ///
	replace
putexcel A1 = matrix(V)

import excel "$dir_results/education/var_cov", sheet("var_cov") clear

describe
local no_vars = `r(k)'	
	
forvalues i = 1/2 {
	egen row_sum = rowtotal(*)
	drop if row_sum == 0 
	drop row_sum
	xpose, clear	
}	
	
mkmat v*, matrix(var)	
putexcel set "$dir_work/reg_education_HU_raw", sheet("E1b") modify
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

putexcel set "$dir_work/reg_education_HU_raw", sheet("E1b") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 
		
* Labelling 
// Need to variable label when add new variable to model. Order matters. 
local var_list Dgn Dag Dag_sq Deh_c3_High_L1 Deh_c3_Low_L1 ///
	Les_c3_NotEmployed_L1 Dnc_L1 Dnc02_L1 HUA HUB Year_transformed ///
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
putexcel set "$dir_work/reg_education_HU_raw", sheet("Gof") modify

putexcel A8 = "E1b - Returning to education", bold		

putexcel A10 = "Pseudo R-squared" 
putexcel B10 = r2_p 
putexcel A11 = "N"
putexcel B11 = N 
putexcel E10 = "Chi^2"		
putexcel F10 = chi2
putexcel E11 = "Log likelihood"		
putexcel F11 = ll
		
drop in_sample p
scalar drop r2_p N chi2 ll	


*************************************************
* E2a Educational Level After Leaving Education *
*************************************************
xtset idperson swv
* Process E2a: Educational level achieved when leaving the initial spell of 
* 				education  
* Sample: Those 16-29 who have left their initial education spell in current 
* 			year 
* DV: Education level (3 cat)  
* Note: Previously tried a multinomial probit, now use an ordered probit

fre deh_c3 if (dag >= 16 & dag <= 29) & l.ded == 1 & ded == 0

recode deh_c3 (1 = 3) (3 = 1), gen(deh_c3_recoded)	
lab def deh_c3_recoded 1 "Low" 2 "Medium" 3 "High"
lab val deh_c3_recoded deh_c3_recoded


* Model specification tests 

if `model_specification_test' == 1 {

	* Option 1 - Ordered logit  

	* Testing the parallel lines assumption 
	* 	- the model asssumes that coefs (apart for the constant) when estimating  
	* 		a series of binary probits for 1 vs higher, 1&2 vs higher, 1&2&3 vs 
	* 		higher
	*	- Brant test null: the slope coefficients are the same across response  
	* 		all categories (p<0.05 -> violating the prop odds assumption)

	sort idperson swv


	ologit deh_c3_recoded i.dgn dag dagsq i.drgn1 stm if ///
		dag >= 16 & dag <= 29 & l.ded == 1 & ded == 0 ///
		[pweight = dimxwt], vce(robust)
	 
	oparallel, ic
 
 
	* Option 2 - Linear model 

	xtset idperson swv

	reg deh_c3_recoded i.dgn dag dagsq i.drgn1 stm if ///
		dag >= 16 & dag <= 29 & l.ded == 1 & ded == 0 ///
		[pweight = dimxwt], vce(robust)


	// obtain distribution of predicted values plot 
	// make sure to add in sampling variance
	gen in_sample = e(sample)

	scalar sigma = e(rmse)
	gen epsilon = rnormal()*sigma
	sum epsilon 
	replace pred_edu = pred_edu + epsilon if in_sample == 1

	twoway (hist deh_c3_recoded if in_sample == 1 , lcolor(gs12) ///
		fcolor(gs12)) (hist pred_edu if in_sample == 1 , ///
		fcolor(none) lcolor(red)), xtitle (Education level) ///
		legend(lab(1 "Observed") lab( 2 "Predicted")) name(levels, replace) ///
		graphregion(color(white))

	drop in_sample pred_edu epsilon

	sort idperson swv
 
 
	* Option 3 - Generalized ordered logit  
	
	gologit2 deh_c3_recoded i.dgn dag dagsq i.drgn1 stm if ///
		dag >= 16 & dag <= 29 & l.ded == 1 & ded == 0 ///
		/*[pweight = dimxwt]*/, vce(robust) autofit 
	// does the	model produce any negative probabilities? 
	// if so, 
	//	1 - play around with the controls 
	//  2 - consider in the simulation converting the negative probabilities 
	//		to be zero and rescaling the cdf to sum to 1
	 
}


* Generalized ordered logit 

sort idperson swv

gologit2 deh_c3_recoded i.dgn dag dagsq i.drgn1 stm y2020 y2021 if ///
	dag >= 16 & dag <= 29 & l.ded == 1 & ded == 0 ///
	[pweight = dimxwt], /*vce(robust)*/ autofit 

gen in_sample = e(sample)
	
predict p1 p2 p3 
	
save "$dir_data/E2a_sample", replace

scalar r2_p = e(r2_p) 
scalar N = e(N)	 


* Results 
* Note: Zeros values are eliminated 
		
matrix b = e(b)	
matrix V = e(V)


*  Store variance-covariance matrix 

preserve

putexcel set "$dir_results/education/var_cov", sheet("var_cov") ///
	replace
putexcel A1 = matrix(V)

import excel "$dir_results/education/var_cov", sheet("var_cov") clear

describe
local no_vars = `r(k)'	
		
forvalues i = 1/2 {
	egen row_sum = rowtotal(*)
	drop if row_sum == 0 
	drop row_sum
	xpose, clear	
}	
		
mkmat v*, matrix(var)	
putexcel set "$dir_work/reg_education_HU_raw", sheet("E2a_raw") modify 
putexcel D3 = matrix(var)
			
restore	


* Store estimated coefficients 

// Initialize a counter for non-zero coefficients
local non_zero_count = 0
//local names : colnames b

// Loop through each element in `b` to count non-zero coefficients
forvalues i = 1/`no_vars' {
	if (b[1, `i'] != 0) {
		local non_zero_count = `non_zero_count' + 1
	}
}

// Create a new row vector to hold only non-zero coefficients
matrix nonzero_b = J(1, `non_zero_count', .)

// Populate nonzero_b with non-zero coefficients from b
local index = 1
forvalues i = 1/`no_vars' {
	if (b[1, `i'] != 0) {
		matrix nonzero_b[1, `index'] = b[1, `i']
		local index = `index' + 1
	}
}

putexcel set "$dir_work/reg_education_HU_raw", sheet("E2a_raw") modify
putexcel B2 = matrix(nonzero_b'), names nformat(number_d2) 
 

 * Labelling 
local no_coefs = 9 // number of coefs estimated per category
putexcel A2 = "CAT"
putexcel B2 = "REGRESSOR"
putexcel C2 = "COEFFICIENT"

 
forvalues i = 1/`no_coefs' {
	local n = 2 +`i'	
	putexcel A`n' = "Low"
}
	
forvalues i = 1/`no_coefs' {
	local n = 2 +`no_coefs' +`i'	
	putexcel A`n' = "Medium"
} 
 
 forvalues i = 0/1 {
	local n = 3 + `i'*`no_coefs'
	putexcel B`n' = "Dgn"
}

forvalues i = 0/1 {
	local n = 4 + `i'*`no_coefs'
	putexcel B`n' = "Dag"
}

forvalues i = 0/1 {
	local n = 5 + `i'*`no_coefs'
	putexcel B`n' = "Dag_sq"
}
	
forvalues i = 0/1 {
	local n = 6 + `i'*`no_coefs'
	putexcel B`n' = "HUA"
}

forvalues i = 0/1 {
	local n = 7 + `i'*`no_coefs'
	putexcel B`n' = "HUB"
}
	
forvalues i = 0/1 {
	local n = 8 + `i'*`no_coefs'
	putexcel B`n' = "Year_transformed"
}

forvalues i = 0/1 {
	local n = 9 + `i'*`no_coefs'
	putexcel B`n' = "Y2020"
}

forvalues i = 0/1 {
	local n = 10 + `i'*`no_coefs'
	putexcel B`n' = "Y2021"
}

forvalues i = 0/1 {
	local n = 11 + `i'*`no_coefs'
	putexcel B`n' = "Constant"
}	
	
putexcel B1 = "CAT"
	
local col_list_1 D1 E1 F1 G1 H1 I1 J1 K1 L1
 
local col_list_2 M1 N1 O1 P1 Q1 R1 S1 T1 U1 
	
foreach col in `col_list_1'{
	putexcel `col' = "Low"
} 
	
foreach col in `col_list_2'{
	putexcel `col' = "Medium"
} 
	
local var_list Dgn Dag Dag_sq HUA HUB Year_transformed Y2020 Y2021 Constant
local col_list_1a D2 E2 F2 G2 H2 I2 J2 K2 L2
local col_list_2a  M2 N2 O2 P2 Q2 R2 S2 T2 U2 

foreach col_list in col_list_1a col_list_2a {	
	local i = 1 
	
	foreach var in `var_list' {
		
		local list_1 = word("``col_list''", `i')
		putexcel  `list_1' = "`var'"
			
		local i = `i' + 1
	}
}


* Goodness of fit 
putexcel set "$dir_work/reg_education_HU_raw", sheet("Gof") modify

putexcel A13 = "E2a - Eduational attainment", bold		

putexcel A15 = "Pseudo R-squared" 
putexcel B15 = r2_p 
putexcel A16 = "N"
putexcel B16 = N 
		
drop in_sample	
scalar drop r2_p N	

	
cap log close

********************************************************************************
* PROJECT:  		ESPON 
* SECTION:			Health
* OBJECT: 			Health status and Disability
* AUTHORS:			Daria Popova, Justin van de Ven, Ashley Burdett
* LAST UPDATE:		Feb 2025
* COUNTRY: 			Italy 
* 
* NOTES: 			For the self rated health processes, H1a and H1b, produce 
* 					estimates of the generalized ordered logit model and 
* 					have the option to run specification tests. 
* 					The excel output of the generalized ordered logit model 
* 					needs to be adjusted manually in excel. 
* 					Only want one row for the estimates that satisfy the
* 					parrallel lines assumption for which the regressor name 
* 					should be followed by a *_. For the remaining variables,
* 					the regressor name should be followed by the an underscore
* 					and the relevant category name of the dependent variable. 		
* 					
* TO DOS:			Deal with negative predictions in H1a
********************************************************************************
clear all
set more off
set mem 200m
set type double
//set maxvar 120000
set maxvar 30000


local model_specification_test = 0


cap log close 
//log using "$dir_log/reg_health.log", replace


use "$dir_input_data/${country}-SILC_pooled_all_obs_02.dta", clear

//do "$dir_do/variable_update"


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
label variable ydses_c5 "Annual Household Income Quintile" 
label variable dlltsd "Long-term Sick or Disabled"

label value dgn gdr
label value drgn1 rgna
label value dhhtp_c4 hht 
label value les_c3 jbf 
label value deh_c3 edd 
label value ded yn

drop if dag < 16
replace stm = stm - 2000

* Covid dummies
gen y2020 = (stm == 20)
gen y2021 = (stm == 21)

recode dhe deh_c3 les_c3 les_c4 ydses_c5 dhhtp_c4 drgn1 stm  (0= .) (-9=. ) 
recode dgn dag dagsq (-9=.)

xtset idperson swv


* Set Excel file 
* Info sheet
putexcel set "$dir_work/reg_health_${country}_raw", sheet("Info") replace
putexcel A1 = "Description:"
putexcel B1 = "Model parameters governing projection self-reported health status"

putexcel A4 = "Process:", bold
putexcel B4 = "Description:", bold
putexcel A5 = "H1a"
putexcel B5 = "Generalized ordered logit regression estimates of self reported health status - individuals aged 16-29 in initial education spell"
putexcel B6 = "Covaraites that satisfy the parallel lines assumption have one estimate for all categories of the dependent variable and are present once in the table"
putexcel B7 = "Covariates that do not satisfy the parallel lines assumption have an estimate for each estimated category of the dependent variable. These covariates have the dependent variable category appended to their name."
putexcel A8 = "H1b"
putexcel B8 = "Generalized ordered logit regression estimates of self reported health status - individuals aged 16+ not in initial education spell"
putexcel B9 = "Covaraites that satisfy the parallel lines assumption have one estimate for all categories of the dependent variable and are present once in the table"
putexcel B10 = "Covariates that do not satisfy the parallel lines assumption have an estimate for each estimated category of the dependent variable. These covariates have the dependent variable category appended to their name."
putexcel A11 = "H2b"
putexcel B11 = "Probit regression estimates of the probability of being long-term sick or disabled - people aged 16+ not in initial education spell"
putexcel A14 = "Notes:", bold
putexcel B14 = "Regions: ITF = South, ITG = Islands, ITH = Northeast, ITI = Central. Northwest (ITC) is the omitted region."

putexcel set "$dir_work/reg_health_${country}_raw", sheet("Gof") modify
putexcel A1 = "Goodness of fit", bold		


********************************************
* H1a: Health status, in initial edu spell *
********************************************

* Process H1a: Probability of each self-rated health status for those who 
* 				have are in their initial education spell 
* Sample: 16-29 year olds who are in their initial education spell 
* DV: Categorical health status (5)	

* Generalized ordered logit			
sort idperson swv

gen l_ydses_c5 = ydses_c5[_n-1] if idperson == idperson[_n-1] & ///
	swv == swv[_n-1] + 1 

gen l_dhe = dhe[_n-1] if idperson == idperson[_n-1] & ///
	swv == swv[_n-1] + 1 
			
gologit2 dhe i.dgn dag dagsq l_ydses_c5 l_dhe i.drgn1 stm if ///
	dag >= 16 & dag <= 29 & ded == 1 & dhe_flag != 1 [pweight = dimxwt], autofit
	
gen in_sample = e(sample)
	
predict p1 p2 p3 p4 p5
	
save "$dir_data/H1a_sample", replace

scalar r2_p = e(r2_p) 
scalar N = e(N)	 
	
	
* Formatted results 
* Note: Zeros values are eliminated 	
matrix b = e(b)	
matrix V = e(V)


*  Store variance-covariance matrix 
preserve

putexcel set "$dir_results/health/var_cov", sheet("var_cov") ///
	replace
putexcel A1 = matrix(V)

import excel "$dir_results/health/var_cov", sheet("var_cov") clear

describe
local no_vars = `r(k)'	
		
forvalues i = 1/2 {
	egen row_sum = rowtotal(*)
	drop if row_sum == 0 
	drop row_sum
	xpose, clear	
}	
		
mkmat v*, matrix(var)	
putexcel set "$dir_work/reg_health_${country}_raw", sheet("H1a_raw") modify 
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

putexcel set "$dir_work/reg_health_${country}_raw", sheet("H1a_raw") modify
putexcel B2 = matrix(nonzero_b'), names nformat(number_d2) 	
	
	
* Labelling 
local no_coef = 11   //UPDATE, number of estimated coefficents 

putexcel A2 = "CAT"
putexcel B2 = "REGRESSOR"
putexcel C2 = "COEFFICIENT"
forvalues i = 1/`no_coef' {
	local n = 2+`i'	
	putexcel A`n' = "Poor"
}
forvalues i = 1/`no_coef' {
	local n = 2 + `no_coef'+`i'
	putexcel A`n' = "Fair"
}
forvalues i = 1/`no_coef' {
	local n = 2 + 2*`no_coef'+`i'	
	putexcel A`n' = "Good"
}
forvalues i = 1/`no_coef' {
	local n = 2 + 3*`no_coef'+`i'	
	putexcel A`n' = "Very good"
}
forvalues i = 0/3 {
	local n = 3 + `i'*`no_coef'
	putexcel B`n' = "Dgn"
}
forvalues i = 0/3 {
	local n = 4 + `i'*`no_coef'
	putexcel B`n' = "Dag"
}
forvalues i = 0/3 {
	local n = 5 + `i'*`no_coef'
	putexcel B`n' = "Dag_sq"
}
forvalues i = 0/3 {
	local n = 6 + `i'*`no_coef'
	putexcel B`n' = "Ydses_c5_L1"
}
forvalues i = 0/3 {
	local n = 7 + `i'*`no_coef'
	putexcel B`n' = "Dhe_L1"
}
forvalues i = 0/3 {
	local n = 8 + `i'*`no_coef'
	putexcel B`n' = "ITF"
}
forvalues i = 0/3 {
	local n = 9 + `i'*`no_coef'
	putexcel B`n' = "ITG"
}
forvalues i = 0/3 {
	local n = 10 + `i'*`no_coef'
	putexcel B`n' = "ITH"
}
forvalues i = 0/3 {
	local n = 11 + `i'*`no_coef'
	putexcel B`n' = "ITI"
}
forvalues i = 0/3 {
	local n = 12 + `i'*`no_coef'
	putexcel B`n' = "Year_transformed"
}
forvalues i = 0/3 {
	local n = 13 + `i'*`no_coef'
	putexcel B`n' = "Constant"
}

putexcel B1 = "CAT"

local col_list_1 D1 E1 F1 G1 H1 I1 J1 K1 L1 M1 N1
local col_list_2  O1 P1 Q1 R1 S1 T1 U1 V1 W1 X1 Y1
local col_list_3  Z1 AA1 AB1 AC1 AD1 AE1 AF1 AG1 AH1 AI1 AJ1
local col_list_4  AK1 AL1 AM1 AN1 AO1 AP1 AQ1 AR1 AS1 AT1 AU1
	
foreach col in `col_list_1'{
	putexcel `col' = "Poor"
} 
	
foreach col in `col_list_2'{
	putexcel `col' = "Fair"
} 

foreach col in `col_list_3'{
	putexcel `col' = "Good"
} 

foreach col in `col_list_4'{
	putexcel `col' = "Very_good"
} 

local var_list Dgn Dag Dag_sq Ydses_c5_L1 Dhe_L1 ITF ITG ITH ITI Year_transformed Constant
local col_list_1a D2 E2 F2 G2 H2 I2 J2 K2 L2 M2 N2
local col_list_2a O2 P2 Q2 R2 S2 T2 U2 V2 W2 X2 Y2
local col_list_3a Z2 AA2 AB2 AC2 AD2 AE2 AF2 AG2 AH2 AI2 AJ2
local col_list_4a AK2 AL2 AM2 AN2 AO2 AP2 AQ2 AR2 AS2 AT2 AU2
	
foreach col_list in col_list_1a col_list_2a col_list_3a col_list_4a {	
	local i = 1 
	
	foreach var in `var_list' {
		
		local list_1 = word("``col_list''", `i')
		putexcel  `list_1' = "`var'"
			
		local i = `i' + 1
	}
}	


* Goodness of fit 
putexcel set "$dir_work/reg_health_${country}_raw", sheet("Gof") modify

putexcel A3 = "H1a - Health status, in initial education spell", bold		

putexcel A5 = "Pseudo R-squared" 
putexcel B5 = r2_p 
putexcel A6 = "N"
putexcel B6 = N 
		
drop in_sample p1-p5
scalar drop r2_p N	


******************************************************
* Process H1b: Health status, left intital edu spell *
******************************************************

* Process H1b: Probability of each self-rated health status for those who 
* 				have left their initial education spell 
* Sample: 16 or older who have left their initial education spell 
* DV: Categorical health status (5)

* Generalized ordered logit	
sort idperson swv

capture drop l_ydses_c5 l_dhe

gen l_ydses_c5 = ydses_c5[_n-1] if idperson == idperson[_n-1] & ///
	swv == swv[_n-1] + 1 

gen l_dhe = dhe[_n-1] if idperson == idperson[_n-1] & ///
	swv == swv[_n-1] + 1 
		
gen l_les_c3 = les_c3[_n-1] if idperson == idperson[_n-1] & ///
	swv == swv[_n-1] + 1 
		
gen l_dhhtp_c4 = dhhtp_c4[_n-1] if idperson == idperson[_n-1] & ///
	swv == swv[_n-1] + 1 
		
gologit2 dhe i.dgn dag dagsq ib1.deh_c3 i.l_les_c3 i.l_ydses_c5 ///
	ib5.l_dhe ib1.l_dhhtp_c4 i.drgn1 stm y2021 if dhe_flag != 1 & ///
	dag >= 16 & ded == 0 [pweight = dimxwt], autofit
	
gen in_sample = e(sample)
	
predict p1 p2 p3 p4 p5 

save "$dir_data/H1b_sample", replace

scalar r2_p = e(r2_p) 
scalar N = e(N)	 

* Results
* Note: Zeros values are eliminated 
matrix b = e(b)	
matrix V = e(V)

*  Store variance-covariance matrix 
preserve

putexcel set "$dir_results/health/var_cov", sheet("var_cov") ///
	replace
putexcel A1 = matrix(V)

import excel "$dir_results/health/var_cov", sheet("var_cov") clear

describe
local no_vars = `r(k)'	
		
forvalues i = 1/2 {
	egen row_sum = rowtotal(*)
	drop if row_sum == 0 
	drop row_sum
	xpose, clear	
}	
		
mkmat v*, matrix(var)	
putexcel set "$dir_work/reg_health_${country}_raw", sheet("H1b_raw") modify 
putexcel D3 = matrix(var)
			
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

putexcel set "$dir_work/reg_health_${country}_raw", sheet("H1b_raw") modify
putexcel B2 = matrix(nonzero_b'), names nformat(number_d2) 	
	
* Labelling 
putexcel A2 = "CAT"
putexcel B2 = "REGRESSOR"
putexcel C2 = "COEFFICIENT"
	
local no_coef = 25	// UPDATE, number of estimated coefs per category 
	
forvalues i = 1/`no_coef' {
	local n = 2 +`i'	
	putexcel A`n' = "Poor"
}
forvalues i = 1/`no_coef'  {
	local n = 2 + `no_coef'+`i'	
	putexcel A`n' = "Fair"
}
forvalues i = 1/`no_coef'  {
	local n = 2 + 2*`no_coef'+`i'	
	putexcel A`n' = "Good"
}
forvalues i = 1/`no_coef'  {
	local n = 2 + 3*`no_coef'+`i'	
	putexcel A`n' = "Very good"
}

forvalues i = 0/3 {
	local n = 3 + `i'*`no_coef' 
	putexcel B`n' = "Dgn"
}
forvalues i = 0/3 {
	local n = 4 + `i'*`no_coef' 
	putexcel B`n' = "Dag"
}
forvalues i = 0/3 {
	local n = 5 + `i'*`no_coef' 
	putexcel B`n' = "Dag_sq"
}
forvalues i = 0/3 {
	local n = 6 + `i'*`no_coef' 
	putexcel B`n' = "Deh_c3_Medium"
}
forvalues i = 0/3 {
	local n = 7 + `i'*`no_coef' 
	putexcel B`n' = "Deh_c3_Low"
}
forvalues i = 0/3 {
	local n = 8 + `i'*`no_coef' 
	putexcel B`n' = "Les_c3_Student_L1"
}
forvalues i = 0/3 {
	local n = 9 + `i'*`no_coef' 
	putexcel B`n' = "Les_c3_NotEmployed_L1"
}
forvalues i = 0/3 {
	local n = 10 + `i'*`no_coef' 
	putexcel B`n' = "Ydses_c5_Q2_L1"
}
forvalues i = 0/3 {
	local n = 11 + `i'*`no_coef' 
	putexcel B`n' = "Ydses_c5_Q3_L1"
}
forvalues i = 0/3 {
	local n = 12 + `i'*`no_coef' 
	putexcel B`n' = "Ydses_c5_Q4_L1"
}
forvalues i = 0/3 {
	local n = 13 + `i'*`no_coef' 
	putexcel B`n' = "Ydses_c5_Q5_L1"
}	
forvalues i = 0/3 {
	local n = 14 + `i'*`no_coef' 
	putexcel B`n' = "Dhe_c5_1_L1"
}
forvalues i = 0/3 {
	local n = 15 + `i'*`no_coef' 
	putexcel B`n' = "Dhe_c5_2_L1"
}
forvalues i = 0/3 {
	local n = 16 + `i'*`no_coef' 
	putexcel B`n' = "Dhe_c5_3_L1"
}
forvalues i = 0/3 {
	local n = 17 + `i'*`no_coef' 
	putexcel B`n' = "Dhe_c5_4_L1"
}
forvalues i = 0/3 {
	local n = 18 + `i'*`no_coef' 
	putexcel B`n' = "Dhhtp_c4_CoupleChildren_L1"
}
forvalues i = 0/3 {
	local n = 19 + `i'*`no_coef' 
	putexcel B`n' = "Dhhtp_c4_SingleNoChildren_L1"
}
forvalues i = 0/3 {
	local n = 20 + `i'*`no_coef' 
	putexcel B`n' = "Dhhtp_c4_SingleChildren_L1"
}	
forvalues i = 0/3 {
	local n = 21 + `i'*`no_coef' 
	putexcel B`n' = "ITF"
}
forvalues i = 0/3 {
	local n = 22 + `i'*`no_coef' 
	putexcel B`n' = "ITG"
}
forvalues i = 0/3 {
	local n = 23 + `i'*`no_coef' 
	putexcel B`n' = "ITH"
}
forvalues i = 0/3 {
	local n = 24 + `i'*`no_coef' 
	putexcel B`n' = "ITI"
}
forvalues i = 0/3 {
	local n = 25 + `i'*`no_coef' 
	putexcel B`n' = "Year_transformed"
}
forvalues i = 0/3 {
	local n = 26 + `i'*`no_coef' 
	putexcel B`n' = "Y2021"
}
forvalues i = 0/3 {
	local n = 27 + `i'*`no_coef' 
	putexcel B`n' = "Constant"
}
putexcel B1 = "CAT"

local col_list_1 D1 E1 F1 G1 H1 I1 J1 K1 L1 M1 N1 O1 P1 Q1 R1 S1 T1 U1 ///
	V1 W1 X1 Y1 Z1 AA1 AB1 
		
local col_list_2 AC1 AD1 AE1 AF1 AG1 AH1 AI1 AJ1 AK1 AL1 AM1 ///
	AN1 AO1 AP1 AQ1 AR1 AS1 AT1 AU1 AV1 AW1 AX1 AY1	AZ1 BA1 BB1 BC1	

local col_list_3 BB1 BC1 BD1 BE1 BF1 BG1 BH1 BI1 BJ1 BK1 BL1 BM1 BN1 BO1 ///
	BP1 BQ1 BR1 BS1 BT1 BU1 BV1 BW1	BX1 BY1 BZ1 

local col_list_4 CA1 CB1 CC1 CD1 CE1 CF1 CG1 CH1 CI1 CJ1 CK1 CL1 CM1 CN1 ///
	CO1 CP1 CQ1 CR1 CS1 CT1 CU1	CV1 CW1 CX1 CY1 
		
foreach col in `col_list_1'{
	putexcel `col' = "Poor"
} 
foreach col in `col_list_2'{
	putexcel `col' = "Fair"
} 
foreach col in `col_list_3'{
	putexcel `col' = "Good"
} 
foreach col in `col_list_4'{
	putexcel `col' = "Very good"
} 
	
local var_list Dgn Dag Dag_sq Deh_c3_Medium Deh_c3_Low Les_c3_Student_L1 ///
	Les_c3_NotEmployed_L1 Ydses_c5_Q2_L1 Ydses_c5_Q3_L1 Ydses_c5_Q4_L1 ///
	Ydses_c5_Q5_L1 Dhe_c5_1_L1 Dhe_c5_2_L1 Dhe_c5_3_L1 Dhe_c5_4_L1 ///
	Dhhtp_c4_CoupleChildren_L1 Dhhtp_c4_SingleNoChildren_L1 ///
	Dhhtp_c4_SingleChildren_L1 ITF ITG ITH ITI Year_transformed Y2021 ///
	Constant 
	
local col_list_1a D2 E2 F2 G2 H2 I2 J2 K2 L2 M2 N2 O2 P2 Q2 R2 S2 T2 U2 ///
	V2 W2 X2 Y2 Z2 AA2 AB2 
		
local col_list_2a AC2 AD2 AE2 AF2 AG2 AH2 AI2 AJ2 AK2 AL2 AM2 ///
	AN2 AO2 AP2 AQ2 AR2 AS2 AT2 AU2 AV2 AW2 AX2 AY2	AZ2 BA2 BB2 BC2	

local col_list_3a BB2 BC2 BD2 BE2 BF2 BG2 BH2 BI2 BJ2 BK2 BL2 BM2 BN2 BO2 ///
	BP2 BQ2 BR2 BS2 BT2 BU2 BV2 BW2	BX2 BY2 BZ2 

local col_list_4a CA2 CB2 CC2 CD2 CE2 CF2 CG2 CH2 CI2 CJ2 CK2 CL2 CM2 CN2 ///
	CO2 CP2 CQ2 CR2 CS2 CT2 CU2	CV2 CW2 CX2 CY2 
	
foreach col_list in col_list_1a col_list_2a col_list_3a col_list_4a {
	local i = 1 
	
	foreach var in `var_list' {
		local list_1 = word("``col_list''", `i')
		putexcel  `list_1' = "`var'"
			
		local i = `i' + 1	
	}
}

* Goodness of fit 
putexcel set "$dir_work/reg_health_${country}_raw", sheet("Gof") modify

putexcel A9 = "H1b - Health status, left initial education spell", bold		

putexcel A11 = "Pseudo R-squared" 
putexcel B11 = r2_p 
putexcel A12 = "N"
putexcel B12 = N 
		
drop in_sample p1-p5
scalar drop r2_p N	
	
	
***********************************************************
* H2b: Long-term sick or disabled, left initial edu spell *
***********************************************************

* Process H2a: Probability of being long-term sick or disabled for those 
* 				not in continuous education.
* Sample: 16 or older who have left their initial education spell 
* DV: Long term sick/disabled dummy
fre dlltsd if (dag >= 16 & ded == 0)

probit dlltsd i.dgn dag dagsq ib1.deh_c3 li.ydses_c5 ib5.dhe ilb5.dhe ///
	l.dlltsd lib1.dhhtp_c4 i.drgn1 stm y2020 y2021 if (dag >= 16 & ded == 0) ///
	[pweight = dimxwt], vce(robust)
	
gen in_sample = e(sample)	

predict p

save "$dir_data/H2b_sample", replace

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

putexcel set "$dir_results/health/var_cov", sheet("var_cov") ///
	replace
putexcel A1 = matrix(V)

import excel "$dir_results/health/var_cov", sheet("var_cov") clear

describe
local no_vars = `r(k)'	
	
forvalues i = 1/2 {
	egen row_sum = rowtotal(*)
	drop if row_sum == 0 
	drop row_sum
	xpose, clear	
}	
	
mkmat v*, matrix(var)	
putexcel set "$dir_work/reg_health_${country}_raw", sheet("H2b") modify
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

putexcel set "$dir_work/reg_health_${country}_raw", sheet("H2b") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 	
	

* Labelling 
// Need to variable label when add new variable to model. Order matters. 
local var_list Dgn Dag Dag_sq Deh_c3_Medium Deh_c3_Low Ydses_c5_Q2_L1 ///	
	Ydses_c5_Q3_L1 Ydses_c5_Q4_L1 Ydses_c5_Q5_L1 Dhe_Fair Dhe_Good ///
	Dhe_VeryGood Dhe_Excellent Dhe_Fair_L1 Dhe_Good_L1 Dhe_VeryGood_L1 ///
	Dhe_Excellent_L1 Dlltsd_L1 Dhhtp_c4_CoupleChildren_L1 ///
	Dhhtp_c4_SingleNoChildren_L1 Dhhtp_c4_SingleChildren_L1 ITF ITG ITH ITI ///
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
putexcel set "$dir_work/reg_health_${country}_raw", sheet("Gof") modify

putexcel A15 = "H2b -  Long-term sick or disabled, left initial edu spell", bold		

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

********************************************************************************
* PROJECT:  		ESPON
* SECTION:			Non-employment/non-benefit income
* OBJECT: 			Final Regresion Models 
* AUTHORS:			Daria Popova, Justin van de Ven, Ashley Burdett
* LAST UPDATE:		21/04/2024 (JV)
* COUNTRY: 			Hungary 

* NOTES: 			No private pensions in the Hungarian data. 
* 
* 					I3a - Capital income (in cont edu, selection & amount)
* 					I3b - Capital income (not in cont edu, selection & amount)
* 
* 					Estimate both 
* 					Explored using les_c4 instead of les_c3, but didn't make a 
* 						material difference. 
* 
* 					Update the winsorization process if alter data 
********************************************************************************
clear all
set more off
set mem 200m
set type double
//set maxvar 120000
set maxvar 30000


cap log close 

log using "$dir_log/reg_income.log", replace


* Call data with heckman wage estimates
use "$dir_data/HU-SILC_pooled_all_obs_03.dta", clear 


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
label variable dhe "Self-rated Health"
label variable ydses_c5 "Annual Household Income Quintile" 
label variable dlltsd "Long-term Sick or Disabled"
label variable dcpen "Entered a new Partnership"
label variable dcpex "Partnership dissolution"
label variable lesdf_c4 "Differntial Employment Status"
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

sum yplgrs_dv ypncp ypnoab pred_hourly_wage

xtset idperson swv 

bys swv idhh: gen nwa = _N


* Winsorize capital income 
sum ypncp, det

replace ypncp = . if ypncp >  1.204006 //UPDATE


* Lagged variables 
// If lagged value missing fill in from the last previous observation that is 
// 	not missing


* Health 
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
bys idperson: gen les_c3_L1 = l.les_c3
replace les_c3_L1 = les_c3 if missing(les_c3_L1)


gen receives_ypncp = (ypncp > 0 & !missing(ypncp))


* Set Excel file 
* Info sheet
putexcel set "$dir_work/reg_income_HU", sheet("Info") replace
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


*****************************************************************
* I3a selection: Receiving capital income, in initial edu spell *
*****************************************************************

* Process I3a: Probability of receiving capital income 
* Sample: All individuals 16+ that are in initial edu spell
* DV: Receiving capital income dummy
* Note: Capital income and employment income variables in IHS version 	

logit receives_ypncp i.dgn dag dagsq l.dhe l.yplgrs_dv l.ypncp i.drgn1 ///
	stm if ded == 1 & dag >= 16 [pweight = dimxwt], vce(cluster idperson) base	

	
* Raw results 		
matrix results = r(table)
matrix results = results[1..6,1...]'
putexcel set "$dir_results/income/income", sheet("I3a_selection") ///
	replace
putexcel A1 = matrix(results), names nformat(number_d2)

matrix i1a = get(VCE)
matrix list i1a
putexcel set "$dir_results/income/income_vcm", sheet("I3a_selection VCE") ///
	replace
putexcel A1 = matrix(i1a), names


outreg2 stats(coef se pval) using "$dir_results/income/I3a_selection.doc", ///
	replace title("Process I3a selection: Probability of receiving capital income. Sample: Individuals aged 16+, in initial education spell") ///
	ctitle(Probability of capital income) label side dec(2) noparen ///
	addstat(R2, e(r2_p), Chi2, e(chi2), Log-likelihood, e(ll))	
		
	
capture drop in_sample	
gen in_sample = e(sample)

	
* Internal validation
// Pseudo R2     = 0.0682

* Obtain predicted values 
predict p

gen rnd = runiform() 	
		
gen pred_receives_ypncp = 0 if in_sample == 1	
replace pred_receives_ypncp = 1 if inrange(p,rnd,1)


* Compare pred proportion and observed proportion
tab receives_ypncp if in_sample == 1	
tab pred_receives_ypncp if in_sample == 1
		
tab pred_receives_ypncp receives_ypncp if in_sample == 1
		
tab receives_ypncp, matcell(freq_table_obs)	
tab pred_receives_ypncp, matcell(freq_table_pred) 

preserve 
keep if in_sample == 1 
tabulate receives_ypncp, matcell(freq_matrix)
matrix pct_matrix = (freq_matrix / _N) * 100

putexcel set "$dir_internal_validation/internal_validation_income", ///
	sheet("I3a_selection") replace

putexcel A1 = "Capital income, selection, in initial education spell", bold		

putexcel A3 = "1 - Distribution", bold

putexcel A5 = "Observations", bold		
putexcel B7 = "%"	
putexcel A8 = "Doesn't receives capital income"		
putexcel A9 = "Receives capital income"	
putexcel B8 = matrix(pct_matrix) 
restore 

preserve 
keep if in_sample == 1 
tabulate pred_receives_ypncp, matcell(freq_matrix)
matrix pct_matrix = (freq_matrix / _N) * 100

putexcel E5 = "Predictions", bold
putexcel F7 = "%"				
putexcel E8 = "Doesn't receives capital income"		
putexcel E9 = "Receives capital income"	
putexcel F8 = matrix(pct_matrix) 
restore
		
		
* % correctly predicted
gen diff = 0 if in_sample == 1 
replace diff = 1 if in_sample == 1 & receives_ypncp	!= pred_receives_ypncp
		
preserve 
keep if in_sample == 1 
tabulate diff, matcell(freq_matrix)
matrix pct_matrix = (freq_matrix / _N) * 100

putexcel A13 = "2 - Individual observations ", bold
putexcel A15 = "% correctly predicted", bold
putexcel A17 = "Correct"		
putexcel A18 = "Incorrect"	

putexcel B17 = matrix(pct_matrix) 
restore
				
tab diff	
// 32%
		
drop diff pred_receives_ypncp rnd p in_sample	
	
* Formatted results 
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
putexcel set "$dir_work/reg_income_HU", sheet("I3a_selection") modify
putexcel C2 = matrix(var)
		
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

putexcel set "$dir_work/reg_income_HU", sheet("I3a_selection") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 
	
	
* Labelling 
	
putexcel A1 = "REGRESSOR"
putexcel A2 = "Dgn"
putexcel A3 = "Dag"
putexcel A4 = "Dag_sq"	
putexcel A5 = "Dhe_L1"
putexcel A6 = "Yplgrs_dv_L1"
putexcel A7 = "Ypncp_L1"	
putexcel A8 = "HUA"
putexcel A9 = "HUB"
putexcel A10 = "Year_transformed"
putexcel A11 = "Constant"

putexcel B1 = "COEFFICIENT"
putexcel C1 = "Dgn"
putexcel D1 = "Dag"
putexcel E1 = "Dag_sq"	
putexcel F1 = "Dhe_L1"
putexcel G1 = "Yplgrs_dv_L1"
putexcel H1 = "Ypncp_L1"	
putexcel I1 = "HUA"
putexcel J1 = "HUB"
putexcel K1 = "Year_transformed"
putexcel L1 = "Constant"
	
	
*********************************************************************
* I3b selection: Receiving capital income, not in initial edu spell *
*********************************************************************

* Process I3b: Probability of receiving capital income, not in initial edu spell
* Sample: All individuals 16+, not in initial edu spell
* DV: Receiving capital income dummy
* Note: Capital income and employment income variables in IHS version 	

logit receives_ypncp i.dgn dag dagsq ib1.deh_c3 li.les_c4 lib1.dhhtp_c4 ///
	l.dhe l.yplgrs_dv l.ypncp l2.yplgrs_dv l2.ypncp i.drgn1 stm if ///
	ded == 0 [pweight = dimxwt], vce(cluster idperson) base
	
* Raw results 	
	
matrix results = r(table)
matrix results = results[1..6,1...]'
putexcel set "$dir_results/income/income", sheet("I3b_selection") modify
putexcel A1 = matrix(results), names nformat(number_d2)

matrix i1a = get(VCE)
matrix list i1a
putexcel set "$dir_results/income/income_vcm", sheet("I3b_selection VCE") ///
	modify
putexcel A1 = matrix(i1a), names


outreg2 stats(coef se pval) using "$dir_results/income/I3b_selection.doc", ///
	replace title("Process I3a selection: Probability of receiving capital income. Sample: Individuals aged 16+, not in initial education spell") ///
	ctitle(Probability of capital income) label side dec(2) noparen ///
	addstat(R2, e(r2_p), Chi2, e(chi2), Log-likelihood, e(ll))	
	
	
capture drop in_sample			
gen in_sample = e(sample)
	

* Internal validation
		

// Pseudo R2     = 0.1064

* Obtain predicted values 

predict p

gen rnd = runiform() 	
		
gen pred_receives_ypncp = 0 if in_sample == 1	
replace pred_receives_ypncp = 1 if inrange(p,rnd,1)


* Compare pred proportion and observed proportion
tab receives_ypncp if in_sample == 1	
tab pred_receives_ypncp if in_sample == 1
// 15% v 14%
	
		
* % correctly predicted
gen diff = 0 if in_sample == 1 
replace diff = 1 if in_sample == 1 & receives_ypncp	!= pred_receives_ypncp
		
tab diff	
// 23%
		
drop diff pred_receives_ypncp rnd p in_sample	
	

* Formatted results 
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
putexcel set "$dir_work/reg_income_HU", sheet("I3b_selection") modify
putexcel C2 = matrix(var)
		
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

putexcel set "$dir_work/reg_income_HU", sheet("I3b_selection") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 		
	
	
* Labelling 
putexcel A1 = "REGRESSOR"
putexcel A2 = "Dgn"
putexcel A3 = "Dag"
putexcel A4 = "Dag_sq"
putexcel A5 = "Deh_c3_Medium"
putexcel A6 = "Deh_c3_Low"
putexcel A7 = "Les_c4_Student_L1"
putexcel A8 = "Les_c4_NotEmployed_L1"
putexcel A9 = "Les_c4_Retired_L1"
putexcel A10 = "Dhhtp_c4_CoupleChildren_L1"	
putexcel A11 = "Dhhtp_c4_SingleNoChildren_L1"	
putexcel A12 = "Dhhtp_c4_SingleChildren_L1"	
putexcel A13 = "Dhe_L1"
putexcel A14 = "Yplgrs_dv_L1"
putexcel A15 = "Ypncp_L1"	
putexcel A16 = "Yplgrs_dv_L2"
putexcel A17 = "Ypncp_L2"	
putexcel A18 = "HUA"
putexcel A19 = "HUB"
putexcel A20 = "Year_transformed"
putexcel A21 = "Constant"

putexcel B1 = "COEFFICIENT"
putexcel C1 = "Dgn"
putexcel D1 = "Dag"
putexcel E1 = "Dag_sq"	
putexcel F1 = "Deh_c3_Medium"
putexcel G1 = "Deh_c3_Low"
putexcel H1 = "Les_c4_Student_L1"
putexcel I1 = "Les_c4_NotEmployed_L1"
putexcel J1 = "Les_c4_Retired_L1"
putexcel K1 = "Dhhtp_c4_CoupleChildren_L1"	
putexcel L1 = "Dhhtp_c4_SingleNoChildren_L1"	
putexcel M1 = "Dhhtp_c4_SingleChildren_L1"	
putexcel N1 = "Dhe_L1"
putexcel O1 = "Yplgrs_dv_L1"
putexcel P1 = "Ypncp_L1"	
putexcel Q1 = "Yplgrs_dv_L2"
putexcel R1 = "Ypncp_L2"	
putexcel S1 = "HUA"
putexcel T1 = "HUB"
putexcel U1 = "Year_transformed"
putexcel V1 = "Constant"

	
*******************************************************
* I3a: Amount of capital income, in initial edu spell * 
*******************************************************
	
* Process I3a: Amount of capital income, in initial edu spell
* Sample: All individuals 16+ that received capital income, in initial education 
* 			spell
* DV: IHS of capital income 

gen ypncp_lvl = sinh(ypncp) 
gen ln_ypncp = ln(ypncp_lvl)

regress ln_ypncp i.dgn dag dagsq l.dhe l.yplgrs_dv l.ypncp i.drgn1 stm if ///
	dag >= 16 & receives_ypncp == 1 & ded == 1 [pweight = dimxwt], ///
	vce(cluster idperson) 
	

* Raw results	
matrix results = r(table)
matrix results = results[1..6,1...]'
putexcel set "$dir_results/income/income", sheet("I3a_amount") modify
putexcel A1 = matrix(results), names nformat(number_d2)

matrix i1a = get(VCE)
matrix list i1a
putexcel set "$dir_results/income/HU_income_split_vcm", ///
	sheet("I3a_amount VCE") modify
putexcel A1 = matrix(i1a), names

outreg2 stats(coef se pval) using "$dir_results/income/I3a_amount.doc", ///
	replace title("Process I3a: Amount of capital income. Sample: Individuals aged 16+, in initial education spell") ///
	ctitle(Amount of capital income) label side dec(2) noparen addstat(R2, ///
	e(r2), RMSE, e(rmse))
	
	
capture drop in_sample			
gen in_sample = e(sample)
	
	
* Internal validation
* Compare distribution of predicted vs observed 
predict x_beta_hat if in_sample == 1 


* Add random component 
scalar sigma = e(rmse)	

capture drop epsilon 
gen epsilon = rnormal()*sigma
sum epsilon

gen pred_ypncp = x_beta_hat + epsilon if in_sample == 1 

twoway (hist ln_ypncp if in_sample == 1, lcolor(gs12) fcolor(gs12)) ///
	(hist pred_ypncp if in_sample == 1 /*& pred_ypncp > 0*/, fcolor(none) lcolor(red)), ///
	xtitle (Log capital income (Euro)) legend(lab(1 "Observed") ///
	lab( 2 "Predicted")) name(log, replace)
		
graph export "$dir_internal_validation/I3a_capital_income_in_edu_pred_vs_obs.pdf", ///
	as(pdf) replace	
		
drop in_sample x_beta_hat epsilon pred_ypncp	
	
	 
* Formatted results 
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
putexcel set "$dir_work/reg_income_HU", sheet("I3a_amount") modify
putexcel C2 = matrix(var)
		
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

putexcel set "$dir_work/reg_income_HU", sheet("I3a_amount") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 		
 

* Labelling 
putexcel A1 = "REGRESSOR"
putexcel A2 = "Dgn"
putexcel A3 = "Dag"
putexcel A4 = "Dag_sq"	
putexcel A5 = "Dhe_L1"
putexcel A6 = "Yplgrs_dv_L1"
putexcel A7 = "Ypncp_L1"	
putexcel A8 = "HUA"
putexcel A9 = "HUB"
putexcel A10 = "Year_transformed"
putexcel A11 = "Constant"

putexcel B1 = "COEFFICIENT"
putexcel C1 = "Dgn"
putexcel D1 = "Dag"
putexcel E1 = "Dag_sq"	
putexcel F1 = "Dhe_L1"
putexcel G1 = "Yplgrs_dv_L1"
putexcel H1 = "Ypncp_L1"	
putexcel I1 = "HUA"
putexcel J1 = "HUB"
putexcel K1 = "Year_transformed"
putexcel L1 = "Constant" 
 
 
* Calculate RMSE

cap drop residuals squared_residuals  
predict  residuals , residuals
gen squared_residuals = residuals^2

preserve 
keep if ded == 1 & receives_ypncp == 1
sum squared_residuals [w = dimxwt]
di "RMSE for Amount of capital income" sqrt(r(mean))
putexcel set "$dir_work/reg_RMSE_HU.xlsx", sheet("HU") modify
putexcel A6 = ("I3a") B6 = (sqrt(r(mean))) 
restore 

	
***********************************************************
* I3b: Amount of capital income, not in initial edu spell * 
*********************************************************** 

* Process I3b: Amount of capital income, not in initial edu spell
* Sample: Individuals aged 16+ who are not in their initial education spell and 
* 	receive capital income.

regress ln_ypncp i.dgn dag dagsq ib1.deh_c3 li.les_c4 lib1.dhhtp_c4 l.dhe ///
	l.yplgrs_dv l.ypncp l2.yplgrs_dv l2.ypncp i.drgn1 stm ///
	if ded == 0 & receives_ypncp == 1 [pweight = dimxwt], ///
	vce(cluster idperson)
	
	
* Raw results 	
matrix results = r(table)
matrix results = results[1..6,1...]'
putexcel set "$dir_results/income/income", sheet("I3b_amount") modify
putexcel A1 = matrix(results), names nformat(number_d2)

matrix i1a = get(VCE)
matrix list i1a
putexcel set "$dir_results/income/income_vcm", sheet("I3b VCE") modify
putexcel A1 = matrix(i1a), names

outreg2 stats(coef se pval) using "$dir_results/income/I3b_amount.doc", ///
	replace title("Process I3b: Amount of capital income. Sample: Individuals aged 16+ who are not in continuous education and receive capital income.") ///
	ctitle(Amount of capital income) label side dec(2) noparen addstat(R2, ///
	e(r2), RMSE, e(rmse))

	
capture drop in_sample	
gen in_sample = e(sample)	
	
	
* Internal validation
	
* Compare distribution of predicted vs observed 
predict x_beta_hat if in_sample == 1 


* Add random component 
scalar sigma = e(rmse)	

capture drop epsilon 
gen epsilon = rnormal()*sigma
sum epsilon

gen pred_ypncp = x_beta_hat + epsilon if in_sample == 1 

twoway (hist ln_ypncp if in_sample == 1, lcolor(gs12) fcolor(gs12)) ///
	(hist pred_ypncp if in_sample == 1 /*& pred_ypncp > 0*/, fcolor(none) lcolor(red)), ///
	xtitle (Log capital income (Euro)) legend(lab(1 "Observed") ///
	lab( 2 "Predicted")) name(log, replace)
		
graph export "$dir_internal_validation/I3b_capital_income_left_edu_pred_vs_obs.pdf", ///
	as(pdf) replace		
		
drop in_sample x_beta_hat epsilon pred_ypncp	

	
* Formatted results 
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
putexcel set "$dir_work/reg_income_HU", sheet("I3b_amount") modify
putexcel C2 = matrix(var)
		
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

putexcel set "$dir_work/reg_income_HU", sheet("I3b_amount") modify
putexcel A1 = matrix(nonzero_b'), names nformat(number_d2) 		
 
 
* Labelling 	
putexcel A1 = "REGRESSOR"
putexcel A2 = "Dgn"
putexcel A3 = "Dag"
putexcel A4 = "Dag_sq"
putexcel A5 = "Deh_c3_Medium"
putexcel A6 = "Deh_c3_Low"
putexcel A7 = "Les_c4_Student_L1"
putexcel A8 = "Les_c4_NotEmployed_L1"
putexcel A9 = "Les_c4_Retired_L1"
putexcel A10 = "Dhhtp_c4_CoupleChildren_L1"	
putexcel A11 = "Dhhtp_c4_SingleNoChildren_L1"	
putexcel A12 = "Dhhtp_c4_SingleChildren_L1"	
putexcel A13 = "Dhe_L1"
putexcel A14 = "Yplgrs_dv_L1"
putexcel A15 = "Ypncp_L1"	
putexcel A16 = "Yplgrs_dv_L2"
putexcel A17 = "Ypncp_L2"	
putexcel A18 = "HUA"
putexcel A19 = "HUB"
putexcel A20 = "Year_transformed"
putexcel A21 = "Constant"

putexcel B1 = "COEFFICIENT"
putexcel C1 = "Dgn"
putexcel D1 = "Dag"
putexcel E1 = "Dag_sq"	
putexcel F1 = "Deh_c3_Medium"
putexcel G1 = "Deh_c3_Low"
putexcel H1 = "Les_c3_Student_L1"
putexcel I1 = "Les_c3_NotEmployed_L1"
putexcel J1 = "Les_c4_Retired_L1"
putexcel K1 = "Dhhtp_c4_CoupleChildren_L1"	
putexcel L1 = "Dhhtp_c4_SingleNoChildren_L1"	
putexcel M1 = "Dhhtp_c4_SingleChildren_L1"	
putexcel N1 = "Dhe_L1"
putexcel O1 = "Yplgrs_dv_L1"
putexcel P1 = "Ypncp_L1"	
putexcel Q1 = "Yplgrs_dv_L2"
putexcel R1 = "Ypncp_L2"	
putexcel S1 = "HUA"
putexcel T1 = "HUB"
putexcel U1 = "Year_transformed"
putexcel V1 = "Constant"
  

* Calculate RMSE
cap drop residuals squared_residuals  
predict  residuals , residuals
gen squared_residuals = residuals^2

preserve 
keep if ded == 0 & receives_ypncp == 1
sum squared_residuals [w=dimxwt]
di "RMSE for Amount of capital income: not in education" sqrt(r(mean))
putexcel set "$dir_work/reg_RMSE_HU.xlsx", sheet("HU") modify
putexcel A7 = ("I3b") B7 = (sqrt(r(mean))) 
restore 
	
graph drop _all 	

/*******************************************************************************
* PROJECT:  		SimPaths EU 
* SECTION:			Partnership
* OBJECT: 			Entering a partnership & exiting a relationship 
* AUTHORS:			Daria Popova, Justin van de Ven, Ashley Burdett
*					Aleksandra Kolndrekaj 
* LAST UPDATE:		Jan 2026
* COUNTRY: 			Poland 
********************************************************************************
* NOTES: 			
*******************************************************************************/

clear all
set more off
set mem 200m
set type double
set maxvar 30000

* Set off log file 
cap log close 
log using "$dir_log/reg_partnership.log", replace


/********************************* SET EXCEL FILE *****************************/

* Info sheet
putexcel set "$dir_work/reg_partnership_${country}", sheet("Info") replace
putexcel A1 = "Description:", bold
putexcel B1 = "Model parameters for relationship status projection"

putexcel A2 = "Authors:", bold
putexcel B2 = "Ashley Burdett, Aleksandra Kolndrekaj" 	
putexcel A3 = "Last edit:", bold
putexcel B3 = "12 Jan 2016 AB"

putexcel A5 = "Process:", bold
putexcel B5 = "Description:", bold
putexcel A6 = "U1"
putexcel B6 = "Probit regression estimates  probability of entering  a partnership - single respondents aged 18+ "

putexcel A7 = "U2"
putexcel B7 = "Probit regression estimates of probability of exiting a partnership - cohabiting women aged 18+, not in a same sex relationship"

putexcel A10 = "Notes:", bold
putexcel B10 = "Regions: PL4 = Polnocno-Zachodni, PL5 = Poludniowo-Zachodni, PL6 = Polnocy, PL10 = Central + East. Poludniowy is the omitted category."

	
putexcel set "$dir_work/reg_partnership_${country}", sheet("Gof") modify
putexcel A1 = "Goodness of fit", bold		
	

/********************************* PREPARE DATA *******************************/

* Load data 
use "$dir_input_data/${country}_pooled_ipop", clear

* Ensure missing is missing
recode dcpen dgn dag dagsq ydses_c5 dnc dnc02 dhe deh_c3 deh_c4 dehsp_c3   ///
	dehsp_c4 les_c3 les_c4 ypnbihs_dv dnc dnc02 dhe dhesp dcpyy dcpagdf ///
	dhhtp_c4 lesdf_c4 drgn1 stm dcpex dcpyy_st* (-9=.) 

* Sample selection 
drop if dag < 16

* Adjust variables 

* Adjust time 
replace stm = stm - 2000

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


recode ynbcpdf_dv (-999=.)	
cap gen ypnbihs_dv_sq = ypnbihs_dv^2
	

* Labeling and formating variables
label def jbf 1 "Employed" 2 "Student" 3 "Not Employed"
label def gdr 1  "Male" 0 "Female"
label def yn	1 "Yes" 0 "No"
label def dces 1 "Both Employed" 2 "Employed, Spouse Not Employed" ///
				3 "Not Employed, Spouse Employed" 4 "Both Not Employed"
label def hht 1 "Couples with No Children" 2 "Couples with Children" ///
				3 "Single with No Children" 4 "Single with Children"

label val dgn gdr
label val drgn1 rgna
label val les_c3 lessp_c3 jbf 
label val deh_c3 dehsp_c3 edd 
label val dcpen dcpex yn
label val lesdf_c4 dces
label val dhhtp_c4 hht				
				
label var dgn "Gender"
label var dag "Age"
label var dagsq "Age Squared"
label var drgn1 "Region"
label var stm "Year"
label var les_c3 "Employment Status: 3 Category" 
label var dhe "Self-rated Health"
label var dcpen "Entered a new Partnership"
label var dcpex "Partnership dissolution"
label var deh_c3 "Educational Attainment: 3 Category"
label var dnc "Number of Children in Household"
label var dnc02 "Number of Children aged 0-2 in Household"
label var ydses_c5 "Gross Annual Household Income Quintile" 
label var lesdf_c4 "Differential Employment Status"
label var ypnbihs_dv "Personal Non-benefit Gross Income"
label var ypnbihs_dv_sq "Personal Non-benefit Gross Income Squared"
label var ynbcpdf_dv "Differential Personal Non-Benefit Gross Income"
label var dhhtp_c4 "Household Type: 4 Category"


* Alter names and create dummies for automatic labelling 
gen Dgn = dgn 

gen Dag = dag  

gen  Dag_sq = dagsq 

tab drgn1, gen(${country}) 
rename PL5 PL10 
rename PL4 PL6
rename PL3 PL5 
rename PL2 PL4
rename PL1 PL2

global regions "i.PL4 i.PL5 i.PL6 i.PL10"

tab deh_c3, gen(Deh_c3_)
rename Deh_c3_1 Deh_c3_High
rename Deh_c3_2 Deh_c3_Medium
rename Deh_c3_3 Deh_c3_Low

tab deh_c4, gen(Deh_c4_)
rename Deh_c4_1 Deh_c4_Na
rename Deh_c4_2 Deh_c4_High
rename Deh_c4_3 Deh_c4_Medium
rename Deh_c4_4 Deh_c4_Low

tab les_c3, gen(Les_c3_)
rename Les_c3_1 Les_c3_Employed
rename Les_c3_2 Les_c3_Student
rename Les_c3_3 Les_c3_NotEmployed

tab les_c4, gen(Les_c4_)
rename Les_c4_1 Les_c4_Employed
rename Les_c4_2 Les_c4_Student
rename Les_c4_3 Les_c4_NotEmployed
rename Les_c4_4 Les_c4_Retired

tab ydses_c5, gen(Ydses_c5_Q)

tab dhe, gen(Dhe_)
rename Dhe_1 Dhe_Poor
rename Dhe_2 Dhe_Fair
rename Dhe_3 Dhe_Good
rename Dhe_4 Dhe_VeryGood
rename Dhe_5 Dhe_Excellent

tab dhesp, gen(Dhesp_)
rename Dhesp_1 Dhesp_Poor
rename Dhesp_2 Dhesp_Fair
rename Dhesp_3 Dhesp_Good
rename Dhesp_4 Dhesp_VeryGood
rename Dhesp_5 Dhesp_Excellent

tab dehsp_c3, gen(Dehsp_c3_)
rename Dehsp_c3_1 Dehsp_c3_High
rename Dehsp_c3_2 Dehsp_c3_Medium
rename Dehsp_c3_3 Dehsp_c3_Low

tab dehsp_c4, gen(Dehsp_c4_)
rename Dehsp_c4_1 Dehsp_c4_Na
rename Dehsp_c4_2 Dehsp_c4_High
rename Dehsp_c4_3 Dehsp_c4_Medium
rename Dehsp_c4_4 Dehsp_c4_Low

tab lesdf_c4, gen(Lesdf_c4_)
rename Lesdf_c4_1 Lesdf_c4_BothEmployed
rename Lesdf_c4_2 Lesdf_c4_EmpSpouseNotEmp
rename Lesdf_c4_3 Lesdf_c4_NotEmpSpouseEmp
rename Lesdf_c4_4 Lesdf_c4_BothNotEmployed

gen Dnc = dnc

gen Dnc02 = dnc02

gen Year_transformed = stm  
gen Year_transformed_sq = stm * stm 

gen Y2011 = y2011
gen Y2012 = y2012  
gen Y2013 = y2013  
gen Y2014 = y2014 
gen Y2015 = y2015 
gen Y2016 = y2016
gen Y2017 = y2017
gen Y2018 = y2018
gen Y2019 = y2019  
gen Y2020 = y2020  
gen Y2021 = y2021 
gen Y2022 = y2022 
gen Y2023 = y2023

gen Dhe = dhe 

gen Ded = ded

gen Ydses_c5 = ydses_c5 

gen New_rel = new_rel

gen Dcpyy = dcpyy_st 

gen Dcpagdf = dcpagdf

gen Ypnbihs_dv = ypnbihs_dv

gen Ynbcpdf_dv = ynbcpdf_dv


* Generate lagged variables
xtset idperson swv

gen L1_Dnc = l.Dnc

gen L1_Dehsp_c3_Medium = l.Dehsp_c3_Medium

* Generate interactions
gen Les_c4_Student_Dgn = Dgn * Les_c4_Student
gen Les_c4_NotEmployed_Dgn = Dgn * Les_c4_NotEmployed
gen Les_c4_Retired_Dgn = Dgn * Les_c4_Retired

gen Ded_Dag =  Ded * Dag 
gen Ded_Dag_sq = Ded * Dag_sq 
gen Ded_Dgn = Ded * Dgn

gen Ded_Dnc_L1 = Ded * l.Dnc

gen Ded_Dnc02_L1 = Ded *l.Dnc02

forvalues i = 1(1)5 {
	
	gen Ded_Ydses_c5_Q`i'_L1 = Ded * l.Ydses_c5_Q`i'

}

gen Ded_Dehsp_c4_Na_L1 = l.Dehsp_c4_Na * Ded 
gen Ded_Dehsp_c4_High_L1 = l.Dehsp_c4_High * Ded 
gen Ded_Dehsp_c4_Medium_L1 = l.Dehsp_c4_Medium * Ded 
gen Ded_Dehsp_c4_Low_L1 = l.Dehsp_c4_Low * Ded 

gen Ded_Dhesp_Good_L1 = l.Dhesp_Good * Ded
gen Ded_Dhesp_Fair_L1 = l.Dhesp_Fair * Ded  

gen Ded_Dhe_Fair_L1 = l.Dhe_Fair*Ded 
gen Ded_Dhe_Good_L1 = l.Dhe_Good*Ded 
gen Ded_Dhe_VeryGood_L1 = l.Dhe_VeryGood*Ded 
gen Ded_Dhe_Excellent_L1 = l.Dhe_Excellent*Ded 


/********************************** ESTIMATION ********************************/

/******************** U1: PROBABILITY FORMING PARTNERSHIP *********************/
 
xtset idperson swv
fre dcpen if (dag >= 18 & ssscp != 1)

* Estimation 
probit dcpen c.Dag c.Dag_sq Dgn lc.Dnc lc.Dnc02 li.Ydses_c5_Q2 ///
	li.Ydses_c5_Q3 li.Ydses_c5_Q4 li.Ydses_c5_Q5 /*Ded_Dag*/ Ded_Dag_sq ///
	Ded_Dgn Ded_Dnc_L1 Ded_Dnc02_L1 Ded_Ydses_c5_Q2_L1  Ded_Ydses_c5_Q3_L1 ///
	Ded_Ydses_c5_Q4_L1 Ded_Ydses_c5_Q5_L1 i.Deh_c4_Na i.Deh_c4_High ///
	i.Deh_c4_Low li.Les_c4_Student li.Les_c4_NotEmployed ///
	li.Les_c4_Retired li.Les_c4_Student_Dgn li.Les_c4_NotEmployed_Dgn ///
	li.Les_c4_Retired_Dgn i.Dhe_Fair i.Dhe_Good i.Dhe_VeryGood ///
	i.Dhe_Excellent $regions Year_transformed if ///
	${u1_if_condition} [pw=dwt], vce(robust)
	
* Save raw results 
matrix results = r(table)
matrix results = results[1..6,1...]'

putexcel set "$dir_raw_results/partnership/partnership", ///
	sheet("Process U1") replace
putexcel A3 = matrix(results), names nformat(number_d2) 
putexcel J4 = matrix(e(V))

outreg2 stats(coef se pval) using ///
	"$dir_raw_results/partnership/U1.doc", replace ///
title("Process U1: Probability Form partnership") ///
	ctitle(Form partnership) label side dec(2) noparen ///
	addstat(R2, e(r2_p), Chi2, e(chi2), Log-likelihood, e(ll)) ///
	addnote(`"Note: Regression if condition = (${u1_if_condition})"')		
	
* Save sample inclusion indicator and predicted probabilities	
gen in_sample = e(sample)	
predict p

* Save sample for later use (internal validation)
save "$dir_data/U1_sample", replace

* Store model summary statistics	
scalar r2_p = e(r2_p) 
scalar N_sample = e(N)	
scalar chi2 = e(chi2)
scalar ll = e(ll)	
	
* Store results in Excel 

* Store estimates in matrices
matrix b = e(b)	
matrix V = e(V)

* Eliminate rows and columns containing zeros (baseline cats) 
mata:
	// Call matrices into mata 
    V = st_matrix("V")
    b = st_matrix("b")

    // Find which coefficients are nonzero
    keep = (b :!= 0)
	
	// Eliminate zeros
	b_trimmed = select(b, keep)
    V_trimmed = select(V, keep)
    V_trimmed = select(V_trimmed', keep)'

	// Inspection
	b_trimmed 
	V_trimmed 
	
    // Return to Stata
    st_matrix("b_trimmed", b_trimmed')
    st_matrix("V_trimmed", V_trimmed)
	st_matrix("nonzero_b_flag", keep)
end	

* Eigenvalue tests for var-cov invertablility in SimPaths
matrix symeigen X lambda = V_trimmed

scalar max_eig = lambda[1,1]

scalar min_ratio = lambda[1, colsof(lambda)] / max_eig

* Outcome of max eigenvalue test 
if max_eig < 1.0e-12 {
	
    display as error "CRITICAL ERROR: Maximum eigenvalue is too small (`max_eig')."
    display as error "The Variance-Covariance matrix is likely singular."
    exit 999

}

display "Stability Check Passed: Max Eigenvalue is " max_eig

* Outcome of eigenvalue ratio test 
if min_ratio < 1.0e-12 {
	
    display as error "Matrix is ill-conditioned. Min/Max ratio: " min_ratio
    exit 506

}

display "Stability Check Passed. Min/Max ratio: " min_ratio

* Export into Excel 
putexcel set "$dir_work/reg_partnership_${country}", sheet("U1") modify
putexcel B2 = matrix(b_trimmed)
putexcel C2 = matrix(V_trimmed)


* Labels 
putexcel set "$dir_work/reg_partnership_${country}", sheet("U1") modify

putexcel A1 = "REGRESSOR"
putexcel B1 = "COEFFICIENT"

* Use frame and Mata to extract nice labels from colstripe of e(b)
frame create temp_frame
frame temp_frame: {

    mata: 
		// Import matrices from Stata
		nonzero_b_flag = st_matrix("nonzero_b_flag")'
		stripe = st_matrixcolstripe("e(b)")
		
		// Extract and variable and category names
		varnames = stripe[.,2]
		varnames_no_bl = select(varnames, nonzero_b_flag :== 1)
		
		// Create label vector
		labels_no_bl = usubinstr(varnames_no_bl, "1.", "", 1)
		labels_no_bl = regexr(labels_no_bl, "^_cons", "Constant")
		labels_no_bl = regexm(labels_no_bl, "^L\.") :* (regexr(labels_no_bl, "^L\.", "") :+ "_L1") :+ (!regexm(labels_no_bl, "^L\.") :* labels_no_bl)
		labels_no_bl = regexm(labels_no_bl, "^1L.") :* (regexr(labels_no_bl, "^1L.", "") :+ "_L1") :+ (!regexm(labels_no_bl, "1L.") :* labels_no_bl)
		labels_no_bl = regexr(labels_no_bl, "_Dgn_L1$", "_Dgn")
		
		labels_no_bl
		
		nonzero_labels_structure = "v1"\labels_no_bl
		
		// Create temp file 
		fh = fopen("$dir_work/temp_labels.txt", "w")
		for (i=1; i<=rows(nonzero_labels_structure); i++) {
			fput(fh, nonzero_labels_structure[i])
		}
		fclose(fh)
    end

    * Import cleaned labels into Stata
    import delimited "$dir_work/temp_labels.txt", clear varnames(1) encoding(utf8)
	
	gen n = _n
    
    * Export labels to Excel
	putexcel set "$dir_work/reg_partnership_${country}", sheet("U1") modify
	
	* Vertical labels
    summarize n, meanonly
	local N = r(max)+1
	forvalue i = 2/`N' {
	
		local j = `i' - 1
		putexcel A`i' = v1[`j'] 
	
	}
	
	* Horizontal labels 
	summarize n, meanonly
	local N = r(max) + 1  // Adjusted since we're working across columns

	forvalues j = 1/`N' {
	
		local n = `j'+2 // Shift by 2 to start from column C
		local col ""
		
		while `n' > 0 {
		
			local rem = mod(`n' - 1, 26)
			local col = char(65 + `rem') + "`col'"
			local n = floor((`n' - 1)/26)
		
		}

		putexcel `col'1 = v1[`j']
	}
	
    * Clean up
    erase "$dir_work/temp_labels.txt"
	
}

* Export model fit statistics
putexcel set "$dir_work/reg_partnership_${country}", sheet("Gof") modify

putexcel A5 = "U1 - Partnership formation", ///
	bold		

putexcel A7 = "Pseudo R-squared" 
putexcel B7 = r2_p 
putexcel A8 = "N"
putexcel B8 = N_sample 
putexcel E7 = "Chi^2"		
putexcel F7 = chi2
putexcel E8 = "Log likelihood"		
putexcel F8 = ll		

		
* Clean up 		
drop in_sample p
scalar drop _all
matrix drop _all
frame drop temp_frame 	


/******************* U2: PROBABILITY TERMINATE PARTNERSHIP ********************/

xtset idperson swv	
fre dcpex if (dgn == 0 & dag >= 18 & ssscp != 1) 
	

* Estimation 
probit dcpex Dag Dag_sq Ded_Dag Ded_Dag_sq li.Dehsp_c4_Na li.Dehsp_c4_Medium ///
	li.Dehsp_c4_Low li.Dhesp_Fair li.Dhesp_Good li.Dhe_Fair li.Dhe_Good ///
	li.Dhe_VeryGood li.Dhe_Excellent Ded_Dehsp_c4_Na_L1 ///
	Ded_Dehsp_c4_Medium_L1 Ded_Dehsp_c4_Low_L1 Ded_Dhesp_Fair_L1 ///
	Ded_Dhesp_Good_L1 li.Deh_c4_Na li.Deh_c4_Low li.Deh_c4_High ///
	li.Dhesp_VeryGood li.Dhesp_Excellent l.Dcpyy l.New_rel l.Dcpagdf l.Dnc ///
	l.Dnc02 li.Lesdf_c4_EmpSpouseNotEmp li.Lesdf_c4_NotEmpSpouseEmp ///
	li.Lesdf_c4_BothNotEmployed l.Ypnbihs_dv l.Ynbcpdf_dv $regions ///
	Year_transformed if ${u2_if_condition} ///
	[pw=dwt], vce(robust)
	
* Save raw results 
matrix results = r(table)
matrix results = results[1..6,1...]'

putexcel set "$dir_raw_results/partnership/partnership", sheet("Process U2") ///
	modify
putexcel A3 = matrix(results), names nformat(number_d2) 
putexcel J4 = matrix(e(V))

outreg2 stats(coef se pval) using ///
	"$dir_raw_results/partnership/U2.doc", replace ///
title("Process U2: Probability Terminating Partnership") ///
	ctitle(End partnership) label side dec(2) noparen ///
	addstat(R2, e(r2_p), Chi2, e(chi2), Log-likelihood, e(ll)) ///
	addnote(`"Note: Regression if condition = (${u2_if_condition})"')		
	
* Save sample inclusion indicator and predicted probabilities		
gen in_sample = e(sample)	
predict p

* Save sample for later use (internal validation)
save "$dir_data/U2_sample", replace

* Store model summary statistics
scalar r2_p = e(r2_p) 
scalar N_sample = e(N)	 
scalar chi2 = e(chi2)
scalar ll = e(ll)

* Store results in Excel 

* Store estimates
matrix b = e(b)	
matrix V = e(V)

* Eliminate rows and columns containing zeros (baseline cats) 
mata:
	// Call matrices into mata 
    V = st_matrix("V")
    b = st_matrix("b")

    // Find which coefficients are nonzero
    keep = (b :!= 0)
	
	// Eliminate zeros
	b_trimmed = select(b, keep)
    V_trimmed = select(V, keep)
    V_trimmed = select(V_trimmed', keep)'

	// Inspection
	b_trimmed 
	V_trimmed 
	
    // Return to Stata
    st_matrix("b_trimmed", b_trimmed')
    st_matrix("V_trimmed", V_trimmed)
	st_matrix("nonzero_b_flag", keep)
end	

* Eigenvalue tests for var-cov invertablility in SimPaths
matrix symeigen X lambda = V_trimmed

scalar max_eig = lambda[1,1]

scalar min_ratio = lambda[1, colsof(lambda)] / max_eig

* Outcome of max eigenvalue test 
if max_eig < 1.0e-12 {
	
    display as error "CRITICAL ERROR: Maximum eigenvalue is too small (`max_eig')."
    display as error "The Variance-Covariance matrix is likely singular."
    exit 999

}

display "Stability Check Passed: Max Eigenvalue is " max_eig

* Outcome of eigenvalue ratio test 
if min_ratio < 1.0e-12 {
	
    display as error "Matrix is ill-conditioned. Min/Max ratio: " min_ratio
    exit 506

}

display "Stability Check Passed. Min/Max ratio: " min_ratio

* Export into Excel 
putexcel set "$dir_work/reg_partnership_${country}", sheet("U2") modify
putexcel B2 = matrix(b_trimmed)
putexcel C2 = matrix(V_trimmed)

* Labels 
putexcel set "$dir_work/reg_partnership_${country}", sheet("U2") modify

putexcel A1 = "REGRESSOR"
putexcel B1 = "COEFFICIENT"

* Use frame and Mata to extract nice labels from colstripe of e(b)
frame create temp_frame
frame temp_frame: {

    mata: 
		// Import matrices from Stata
		nonzero_b_flag = st_matrix("nonzero_b_flag")'
		stripe = st_matrixcolstripe("e(b)")
		
		// Extract and variable and category names
		varnames = stripe[.,2]
		varnames_no_bl = select(varnames, nonzero_b_flag :== 1)
		
		// Create label vector
		labels_no_bl = usubinstr(varnames_no_bl, "1.", "", 1)
		labels_no_bl = regexr(labels_no_bl, "^_cons", "Constant")
		labels_no_bl = regexm(labels_no_bl, "^L\.") :* (regexr(labels_no_bl, "^L\.", "") :+ "_L1") :+ (!regexm(labels_no_bl, "^L\.") :* labels_no_bl)
		labels_no_bl = regexm(labels_no_bl, "^c\.") :* (regexr(labels_no_bl, "^c\.", "") :+ "") :+ (!regexm(labels_no_bl, "^c\.") :* labels_no_bl)
		labels_no_bl = regexm(labels_no_bl, "^1L.") :* (regexr(labels_no_bl, "^1L.", "") :+ "_L1") :+ (!regexm(labels_no_bl, "1L.") :* labels_no_bl)
		labels_no_bl = regexr(labels_no_bl, "_Dgn_L1$", "_Dgn")
		
		labels_no_bl = regexr(labels_no_bl, "EmpSpouseNotEmp_L1$", "EmployedSpouseNotEmployed_L1")
		labels_no_bl = regexr(labels_no_bl, "NotEmpSpouseEmp_L1$", "NotEmployedSpouseEmployed_L1")
		
		labels_no_bl
		
		nonzero_labels_structure = "v1"\labels_no_bl
		
		// Create temp file 
		fh = fopen("$dir_work/temp_labels.txt", "w")
		for (i=1; i<=rows(nonzero_labels_structure); i++) {
			fput(fh, nonzero_labels_structure[i])
		}
		fclose(fh)
    end

    * Import cleaned labels into Stata
    import delimited "$dir_work/temp_labels.txt", clear varnames(1) encoding(utf8)
	
	gen n = _n
    
    * Export labels to Excel
	putexcel set "$dir_work/reg_partnership_${country}", sheet("U2") modify
	
	* Vertical labels
    summarize n, meanonly
	local N = r(max)+1
	forvalue i = 2/`N' {
		local j = `i' - 1
		putexcel A`i' = v1[`j'] 
	}
	
	* Horizontal labels 
	summarize n, meanonly
	local N = r(max) + 1  // Adjusted since we're working across columns

	forvalues j = 1/`N' {
		local n = `j'+2 // Shift by 2 to start from column C
		local col ""
		
		while `n' > 0 {
			local rem = mod(`n' - 1, 26)
			local col = char(65 + `rem') + "`col'"
			local n = floor((`n' - 1)/26)
		}

		putexcel `col'1 = v1[`j']
	}
	
    * Clean up
    erase "$dir_work//temp_labels.txt"
}

* Export model fit statistics
putexcel set "$dir_work/reg_partnership_${country}", sheet("Gof") modify

putexcel A11 = ///
	"U2 - Partnership termination", bold		

putexcel A13 = "Pseudo R-squared" 
putexcel B13 = r2_p 
putexcel A14 = "N"
putexcel B14 = N_sample 
putexcel E13 = "Chi^2"		
putexcel F13 = chi2
putexcel E14 = "Log likelihood"		
putexcel F14 = ll			

		
* Clean up 		
drop in_sample p
scalar drop _all
matrix drop _all
frame drop temp_frame 	

capture log close 

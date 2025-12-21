********************************************************************************
* PROJECT:  		ESPON 
* SECTION:			Partnership
* OBJECT: 			Entering a partnership & exiting a relationship 
*					
* AUTHORS:			Daria Popova, Justin van de Ven, Ashley Burdett
* LAST UPDATE:		Feb 2025
* COUNTRY: 			Greece 
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

* Sample selection 
drop if dag < 16

* Adjust variables 
cap gen ypnbihs_dv_sq = ypnbihs_dv^2

replace stm = stm - 2000
fre stm 

forvalues y = 10/23 {
	
	gen Y20`y' = (stm == `y')
	
}

gen Y2022_2023 = (stm == 22| stm == 23)

* Ensure missing is missing
recode dcpen dgn dag dagsq ydses_c5 dnc dnc02 dhe deh_c3 dehsp_c3 les_c3 ///
	les_c4 ypnbihs_dv ypnbihs_dv_sq dnc dnc02 dhe dhesp dcpyy dcpagdf ///
	dhhtp_c4 lesdf_c4 drgn1 stm dcpex dcpyy_st* (-9=. ) 
	
recode ynbcpdf_dv (-999=.)	

* Labeling and formating variables
label def jbf 1 "Employed" 2 "Student" 3 "Not Employed"
label def gdr 1  "Male" 0 "Female"
label def yn	1 "Yes" 0 "No"
label def dces 1 "Both Employed" 2 "Employed, Spouse Not Employed" ///
				3 "Not Employed, Spouse Employed" 4 "Both Not Employed"
label def hht 1 "Couples with No Children" 2 "Couples with Children" ///
				3 "Single with No Children" 4 "Single with Children"

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

label val dgn gdr
label val drgn1 rgna
label val les_c3 lessp_c3 jbf 
label val deh_c3 dehsp_c3 edd 
label val dcpen dcpex yn
label val lesdf_c4 dces
label val dhhtp_c4 hht

* Alter names and create dummies for automatic labelling 
gen Dgn = dgn 

gen Dag = dag  

gen  Dag_sq = dagsq 

tab drgn1, gen(EL) 
rename EL3 EL7
rename EL2 EL4 
rename EL1 EL3

tab deh_c3, gen(Deh_c3_)
rename Deh_c3_1 Deh_c3_High
rename Deh_c3_2 Deh_c3_Medium
rename Deh_c3_3 Deh_c3_Low

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

tab lesdf_c4, gen(Lesdf_c4_)
rename Lesdf_c4_1 Lesdf_c4_BothEmployed
rename Lesdf_c4_2 Lesdf_c4_EmpSpouseNotEmp
rename Lesdf_c4_3 Lesdf_c4_NotEmpSpouseEmp
rename Lesdf_c4_4 Lesdf_c4_BothNotEmployed

gen Dnc = dnc

gen Dnc02 = dnc02

gen Year_transformed = stm  

gen Dhe = dhe 

gen Ydses_c5 = ydses_c5 

gen New_rel = new_rel

gen Dcpyy = dcpyy_st 

gen Dcpagdf = dcpagdf

gen Ypnbihs_dv = ypnbihs_dv

gen Ynbcpdf_dv = ynbcpdf_dv

* Generate interactions
gen Les_c4_Student_L1_Dgn = Dgn * Les_c4_Student
gen Les_c4_NotEmployed_L1_Dgn = Dgn * Les_c4_NotEmployed
gen Les_c4_Retired_L1_Dgn = Dgn * Les_c4_Retired

* Set data
xtset idperson swv


* Set Excel file 
* Info sheet
putexcel set "$dir_work/reg_partnership_${country}", sheet("Info") replace
putexcel A1 = "Description:"
putexcel B1 = "Model parameters for relationship status projection"

putexcel A4 = "Process:", bold
putexcel B4 = "Description:", bold
putexcel A5 = "U1a"
putexcel B5 = "Probit regression estimates  probability of entering  a partnership - single respondents aged 18-29 and  in initial education spell"
putexcel A6 = "U1b"
putexcel B6 = "Probit regression estimates of probability of entering a partnership - single respondents aged 18+ and not in initial education spell"
putexcel A7 = "U2b"
putexcel B7 = "Probit regression estimates of probability of exiting a partnership - cohabiting women aged 18+ and not in initial education spell"

putexcel A10 = "Notes:", bold
putexcel B10 = "Regions: EL3 = Attika (omitted), EL4 = Aegean Islands, EL7 = Central and Northern Greece"

	
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

xtset idperson swv
fre dcpen if (dag >= 18 & ded == 1 & ssscp != 1) 

/*
probit dcpen i.dgn dag dagsq l.ydses_c5 dhe i.drgn1 stm ///
	if (dag >= 18 & ded == 1 & ssscp != 1) [pweight = dimxwt], vce(robust)
*/

probit dcpen i.Dgn Dag Dag_sq l.Ydses_c5 Dhe i.EL4 i.EL7  ///
	Y2022_2023  ///
	if (dag >= 18 & ded == 1 & ssscp != 1) [pweight = dimxwt], vce(robust)	
	
* Note: include health linearly and no number of children under 2 yo to obtain 
* 		estimates 		

* Save sample inclusion indicator and predicted probabilities	
gen in_sample = e(sample)	
predict p

* Save sample for later use (internal validation)
save "$dir_data/U1a_sample", replace

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

* Export into Excel 
putexcel set "$dir_work/reg_partnership_${country}", sheet("U1a") modify
putexcel B2 = matrix(b_trimmed)
putexcel C2 = matrix(V_trimmed)


* Labels 
putexcel set "$dir_work/reg_partnership_${country}", sheet("U1a") modify

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
    import delimited "$dir_work/temp_labels.txt", clear varnames(1) ///
		encoding(utf8)
	
	gen n = _n
    
    * Export labels to Excel
	putexcel set "$dir_work/reg_partnership_${country}", sheet("U1a") modify
	
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

putexcel A3 = "U1a - Partnership formation in initial educaiton spell", bold		

putexcel A5 = "Pseudo R-squared" 
putexcel B5 = r2_p 
putexcel A6 = "N"
putexcel B6 = N_sample 
putexcel E5 = "Chi^2"		
putexcel F5 = chi2
putexcel E6 = "Log likelihood"		
putexcel F6 = ll
		
* Clean up 		
drop in_sample p
scalar drop _all
matrix drop _all
frame drop temp_frame 

 
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

/*
probit dcpen dag dagsq ib1.deh_c3 i.dgn##li.les_c4 /// 
	li.ydses_c5 l.dnc l.dnc02 ///
	i.dhe i.drgn1 stm y2020 y2021 if (dag >= 18 & ded == 0 & ssscp != 1) ///
	[pweight = dimxwt], vce(robust)
*/	
	
probit dcpen Dag Dag_sq i.Deh_c3_Medium i.Deh_c3_Low i.Dgn ///
	li.Les_c4_Student li.Les_c4_NotEmployed li.Les_c4_Retired /// 
	li.Les_c4_Student_L1_Dgn li.Les_c4_NotEmployed_L1_Dgn ///
	li.Les_c4_Retired_L1_Dgn /// 
	li.Ydses_c5_Q2 li.Ydses_c5_Q3 ///
	li.Ydses_c5_Q4 li.Ydses_c5_Q5 l.Dnc l.Dnc02 ///
	i.Dhe_Fair i.Dhe_Good i.Dhe_VeryGood i.Dhe_Excellent ///
	i.EL4 i.EL7 Y2012-Y2021 Y2022_2023 if ///
	(dag >= 18 & ded == 0 & ssscp != 1) [pweight = dimxwt], vce(robust)	
	
* Save sample inclusion indicator and predicted probabilities	
gen in_sample = e(sample)	
predict p

* Save sample for later use (internal validation)
save "$dir_data/U1b_sample", replace

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

* Export into Excel 
putexcel set "$dir_work/reg_partnership_${country}", sheet("U1b") modify
putexcel B2 = matrix(b_trimmed)
putexcel C2 = matrix(V_trimmed)


* Labels 
putexcel set "$dir_work/reg_partnership_${country}", sheet("U1b") modify

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
    import delimited "$dir_work/temp_labels.txt", clear varnames(1) ///
		encoding(utf8)
	
	gen n = _n
    
    * Export labels to Excel
	putexcel set "$dir_work/reg_partnership_${country}", sheet("U1b") modify
	
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

putexcel A9 = "U1b - Partnership formation, left initial education spell", ///
	bold		

putexcel A11 = "Pseudo R-squared" 
putexcel B11 = r2_p 
putexcel A12 = "N"
putexcel B12 = N_sample 
putexcel E11 = "Chi^2"		
putexcel F11 = chi2
putexcel E12 = "Log likelihood"		
putexcel F12 = ll		

		
* Clean up 		
drop in_sample p
scalar drop _all
matrix drop _all
frame drop temp_frame 	

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
	
/*	
probit dcpex dag dagsq lib1.deh_c3 lib1.dehsp_c3 li.dhe li.dhesp ///
	l.dcpyy_st l.new_rel l.dcpagdf l.dnc l.dnc02 lib1.lesdf_c4 ///
	l.ypnbihs_dv l.ynbcpdf_dv i.drgn1 stm y2020 if ///
	(dgn == 0 & dag >= 18 & ded == 0 & ssscp != 1) [pweight = dimxwt], ///
	vce(robust)		
*/	
	
probit dcpex Dag Dag_sq li.Deh_c3_Medium li.Deh_c3_Low ///
	li.Dehsp_c3_Medium li.Dehsp_c3_Low li.Dhe_Fair li.Dhe_Good ///
	li.Dhe_VeryGood li.Dhe_Excellent li.Dhesp_Fair li.Dhesp_Good ///
	li.Dhesp_VeryGood li.Dhesp_Excellent l.Dcpyy l.New_rel l.Dcpagdf ///
	l.Dnc l.Dnc02 li.Lesdf_c4_EmpSpouseNotEmp ///
	li.Lesdf_c4_NotEmpSpouseEmp li.Lesdf_c4_BothNotEmployed ///
	l.Ypnbihs_dv l.Ynbcpdf_dv i.EL4 i.EL7 Y2012-Y2021 Y2022_2023 if ///
	(dgn == 0 & dag >= 18 & ded == 0 & ssscp != 1) [pweight = dimxwt], ///
	vce(robust)		
	
	
* Save sample inclusion indicator and predicted probabilities		
gen in_sample = e(sample)	
predict p

* Save sample for later use (internal validation)
save "$dir_data/U2b_sample", replace

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

* Export into Excel 
putexcel set "$dir_work/reg_partnership_${country}", sheet("U2b") modify
putexcel B2 = matrix(b_trimmed)
putexcel C2 = matrix(V_trimmed)

* Labels 
putexcel set "$dir_work/reg_partnership_${country}", sheet("U2b") modify

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
    import delimited "$dir_work/temp_labels.txt", clear varnames(1) ///
		encoding(utf8)
	
	gen n = _n
    
    * Export labels to Excel
	putexcel set "$dir_work/reg_partnership_${country}", sheet("U2b") modify
	
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

putexcel A15 = ///
	"U2b - Partnership termination, left initial education spell", bold		

putexcel A17 = "Pseudo R-squared" 
putexcel B17 = r2_p 
putexcel A18 = "N"
putexcel B18 = N_sample 
putexcel E17 = "Chi^2"		
putexcel F17 = chi2
putexcel E18 = "Log likelihood"		
putexcel F18 = ll			

		
* Clean up 		
drop in_sample p
scalar drop _all
matrix drop _all
frame drop temp_frame 	

	
capture log close 

cap erase "$dir_work/temp.dta"

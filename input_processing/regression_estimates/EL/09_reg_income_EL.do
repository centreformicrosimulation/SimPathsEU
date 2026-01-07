********************************************************************************
* PROJECT:  		ESPON
* SECTION:			Non-employment/non-benefit income
* OBJECT: 			Final Regresion Models 
* AUTHORS:			Daria Popova, Justin van de Ven, Ashley Burdett
* LAST UPDATE:		Feb 2025 
* COUNTRY: 			Greece 

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

* Sample selection 
drop if dag < 16

* Adjust variables	
sum yplgrs_dv ypncp ypnoab /*pred_hourly_wage*/

bys swv idhh: gen nwa = _N

gen ypncp_lvl = sinh(ypncp) 
gen ln_ypncp = ln(ypncp_lvl)

* Trim the top captial income percentile
sum ypncp, det
scalar p99 = r(p99)

replace ypncp = . if ypncp >= p99

gen receives_ypncp = (ypncp > 0 & !missing(ypncp))

gen  ypnbihs_dv_sq = ypnbihs_dv^2 


* Ensure missing is missing 
recode dgn dag dagsq dhe drgn1 stm scedsmpl deh_c3 les_c4 les_c3 les_c4 ///
	dhhtp_c4 dhe (-9=.)

* Labeling and formating variables
label def jbf 1 "Employed" 2 "Student" 3 "Not Employed"
label def edd 1 "Degree"	2 "High school" ///
				3 "Other/No Qualification"		
label def gdr 1  "Male" 0 "Female"
		
label def yn	1 "Yes" 0 "No"
label def hht 1 "Couples with No Children" 2 "Couples with Children" ///
				3 "Single with No Children" 4 "Single with Children" 

label var dgn "Gender"
label var dag "Age"
label var dagsq "Age Squared"
label var drgn1 "Region"
label var stm "Year"
label var les_c3 "Employment Status: 3 Category" 
label var deh_c3 "Educational Attainment: 3 Category"
label var dhhtp_c4 "Household Type: 4 Category"
label var dnc "Number of Children in Household"
label var dnc02 "Number of Children aged 0-2 in Household"
label var dhe "Self-rated Health"
label var ydses_c5 "Annual Household Income Quintile" 
label var dlltsd "Long-term Sick or Disabled"
label var dcpen "Entered a new Partnership"
label var dcpex "Partnership dissolution"
label var lesdf_c4 "Differential Employment Status"
label var ypnbihs_dv "Personal Non-benefit Gross Income"
label var ypnoab_lvl "Real pension income, level"
label var ypnoab "Real pension income, IHS"
label var ypnbihs_dv_sq "Personal Non-benefit Gross Income Squared"
label var ynbcpdf_dv "Differential Personal Non-Benefit Gross Income"

label val dgn gdr
label val les_c3 jbf 
label val deh_c3 edd 
label val dcpen dcpex yn
label val lesdf_c4 dces
label val ded dlltsd yn
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

tab dhhtp_c4, gen(Dhhtp_c4_)
rename Dhhtp_c4_1 Dhhtp_c4_CoupleNoChildren
rename Dhhtp_c4_2 Dhhtp_c4_CoupleChildren
rename Dhhtp_c4_3 Dhhtp_c4_SingleNoChildren
rename Dhhtp_c4_4 Dhhtp_c4_SingleChildren

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

gen Yplgrs_dv = yplgrs_dv

gen Ypncp = ypncp

* Set data 
xtset idperson swv


* Set Excel file 
* Info sheet
putexcel set "$dir_work/reg_income_${country}", sheet("Info") replace
putexcel A1 = "Description:"
putexcel B1 = "This file contains regression estimates used by process I3, capital income. The data suggests there is no private pension income "

putexcel A4 = "Process:", bold
putexcel B4 = "Description:", bold
putexcel A5 = "Process I3a selection"
putexcel B5 = "Logit regression estimates of the probability of receiving capital income - aged 18-29 and in initial education spell"
putexcel A6 = "Process I3b selection"
putexcel B6 = "Logit regression estimates of the probability of receiving capital income - aged 19+ and not in initial education spell"
putexcel A7 = "Process I3a"
putexcel B7 = "OLS regression estimates (log) capital income amount - aged 18-29 and in initial education spell, who receive capital income"
putexcel A8 = "Process I3a"
putexcel B8 = "OLS regression estimates (log) capital income amount - aged 19+ and not in initial education spell, who receive capital income"

putexcel A10 = "Notes:", bold
putexcel B10 = "Categorical health variable modelled as continuous"
putexcel B11 = "Regions: EL3 = Attika (omitted), EL4 = Aegean Islands, EL7 = Central and Northern Greece"

* Goodness of fit
putexcel set "$dir_work/reg_income_${country}", sheet("Gof") modify

putexcel A1 = "Goodness of fit", bold

*****************************************************************
* I3a selection: Receiving capital income, in initial edu spell *
*****************************************************************
xtset idperson swv 
cap drop in_sample

* Process I3a: Probability of receiving capital income 
* Sample: All individuals 18-29 that are in initial edu spell
* DV: Receiving capital income dummy
* Note: Capital income and employment income variables in IHS version 
/*	
logit receives_ypncp i.dgn dag dagsq l.dhe l.yplgrs_dv l.ypncp i.drgn1 ///
	stm y2020 y2021 if ded == 1 & dag >= 16 [pweight = dimxwt], ///
	vce(cluster idperson) base	
*/

logit receives_ypncp i.Dgn Dag Dag_sq l.Dhe l.Yplgrs_dv l.Ypncp ///
	i.EL4 i.EL7 Y2012-Y2021 Y2022_2023 if ded == 1 & dag >= 16 ///
	[pweight = dimxwt], vce(cluster idperson) base	
	
* Save sample inclusion indicator and predicted probabilities		
gen in_sample = e(sample)	
predict p

* Save sample for later use (internal validation)
save "$dir_data/I3a_selection_sample", replace

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
putexcel set "$dir_work/reg_income_${country}", sheet("I3a_selection") modify
putexcel B2 = matrix(b_trimmed)
putexcel C2 = matrix(V_trimmed)


* Labels 
putexcel set "$dir_work/reg_income_${country}", sheet("I3a_selection") modify

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
	putexcel set "$dir_work/reg_income_${country}", sheet("I3a_selection") ///
		modify
	
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
putexcel set "$dir_work/reg_income_${country}", sheet("Gof") modify

putexcel A3 = ///
	"I3a selection - Receiving capital income in initial education spell ", ///
	bold		
	
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
		
	
*********************************************************************
* I3b selection: Receiving capital income, not in initial edu spell *
*********************************************************************
xtset idperson swv 

* Process I3b: Probability of receiving capital income, not in initial edu spell
* Sample: All individuals 18+, not in initial edu spell
* DV: Receiving capital income dummy
* Note: Capital income and employment income variables in IHS version 	

/*
logit receives_ypncp i.dgn dag dagsq ib1.deh_c3 li.les_c4 lib1.dhhtp_c4 ///
	l.dhe l.yplgrs_dv l.ypncp l2.yplgrs_dv l2.ypncp i.drgn1 stm y2020 ///
	y2021 if ded == 0 [pweight = dimxwt], vce(cluster idperson) base
*/

logit receives_ypncp i.Dgn Dag Dag_sq i.Deh_c3_Medium i.Deh_c3_Low ///
	li.Les_c4_Student li.Les_c4_NotEmployed li.Les_c4_Retired ///
	li.Dhhtp_c4_CoupleChildren li.Dhhtp_c4_SingleNoChildren ///
	li.Dhhtp_c4_SingleChildren l.Dhe l.Yplgrs_dv l.Ypncp l2.Yplgrs_dv ///
	l2.Ypncp i.EL4 i.EL7 Y2013-Y2021 Y2022_2023 if ///
	ded == 0 [pweight = dimxwt], vce(cluster idperson) base
	
* Save sample inclusion indicator and predicted probabilities	
gen in_sample = e(sample)	
predict p

* Save sample for later use (internal validation)
save "$dir_data/I3b_selection_sample", replace

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
putexcel set "$dir_work/reg_income_${country}", sheet("I3b_selection") modify
putexcel B2 = matrix(b_trimmed)
putexcel C2 = matrix(V_trimmed)


* Labels 
putexcel set "$dir_work/reg_income_${country}", sheet("I3b_selection") modify

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
		labels_no_bl = regexm(labels_no_bl, "^L2\.") :* (regexr(labels_no_bl, "^L2\.", "") :+ "_L2") :+ (!regexm(labels_no_bl, "^L2\.") :* labels_no_bl)

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
	putexcel set "$dir_work/reg_income_${country}", sheet("I3b_selection") ///
		modify
	
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
putexcel set "$dir_work/reg_income_${country}", sheet("Gof") modify

putexcel A9 = ///
"I3b selection - Receiving capital income left initial education spell ", ///
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
	
	
*******************************************************
* I3a: Amount of capital income, in initial edu spell * 
*******************************************************
xtset idperson swv 

* Process I3a: Amount of capital income, in initial edu spell
* Sample: All individuals 18-29 that received capital income, in initial  
* 			education spell
* DV: IHS of capital income 
/*
regress ln_ypncp i.dgn dag dagsq l.dhe l.yplgrs_dv l.ypncp i.drgn1 stm ///
	y2020 y2021 if dag >= 16 & receives_ypncp == 1 & ded == 1 ///
	[pweight = dimxwt], vce(cluster idperson) 
*/

regress ln_ypncp i.Dgn Dag Dag_sq l.Dhe l.Yplgrs_dv l.Ypncp ///
	i.EL4 i.EL7 Y2012-Y2021 Y2022_2023 ///
	if dag >= 16 & receives_ypncp == 1 & ded == 1 ///
	[pweight = dimxwt], vce(cluster idperson) 
	
* Save sample inclusion indicator and predicted probabilities	
gen in_sample = e(sample)	
predict p 
gen sigma = e(rmse)

* Save sample for later use (internal validation)
save "$dir_data/I3a_level_sample", replace

* Store model summary statistics
scalar r2 = e(r2) 
scalar N_sample = e(N)		
	
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
putexcel set "$dir_work/reg_income_${country}", sheet("I3a_amount") modify
putexcel B2 = matrix(b_trimmed)
putexcel C2 = matrix(V_trimmed)


* Labels 
putexcel set "$dir_work/reg_income_${country}", sheet("I3a_amount") modify

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
	putexcel set "$dir_work/reg_income_${country}", sheet("I3a_amount") modify
	
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

* Export model fit statistics
putexcel set "$dir_work/reg_income_${country}", sheet("Gof") modify

putexcel A15 = ///
	"I3a level - Receiving capital income in initial education spell ", ///
	bold		
	
putexcel A17 = "R-squared" 
putexcel B17 = r2 
putexcel A18 = "N"
putexcel B18 = N_sample 
		
* Clean up 		
drop in_sample p sigma
scalar drop _all
matrix drop _all
frame drop temp_frame 

	
***********************************************************
* I3b: Amount of capital income, not in initial edu spell * 
*********************************************************** 
xtset idperson swv 

* Process I3b: Amount of capital income, not in initial edu spell
* Sample: Individuals aged 18+ who are not in their initial education spell and 
* 	receive capital income.

/*
regress ln_ypncp i.dgn dag dagsq ib1.deh_c3 li.les_c4 lib1.dhhtp_c4 l.dhe ///
	l.yplgrs_dv l.ypncp l2.yplgrs_dv l2.ypncp i.drgn1 stm y2020 y2021 ///
	if ded == 0 & receives_ypncp == 1 [pweight = dimxwt], ///
	vce(cluster idperson)
*/

regress ln_ypncp i.Dgn Dag Dag_sq i.Deh_c3_Medium i.Deh_c3_Low ///
	li.Les_c4_Student li.Les_c4_NotEmployed li.Les_c4_Retired /// 
	li.Dhhtp_c4_CoupleChildren li.Dhhtp_c4_SingleNoChildren ///
	li.Dhhtp_c4_SingleChildren l.Dhe l.Yplgrs_dv l.Ypncp l2.Yplgrs_dv ///
	l2.Ypncp i.EL4 i.EL7 Y2013-Y2021 Y2022_2023 if ///
	ded == 0 & receives_ypncp == 1 [pweight = dimxwt], vce(cluster idperson)

* Save sample inclusion indicator and predicted probabilities	  
gen in_sample = e(sample)	
predict p 
gen sigma = e(rmse)

* Save sample for later use (internal validation)
save "$dir_data/I3b_level_sample", replace

* Store model summary statistics
scalar r2 = e(r2) 
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
putexcel set "$dir_work/reg_income_${country}", sheet("I3b_amount") modify
putexcel B2 = matrix(b_trimmed)
putexcel C2 = matrix(V_trimmed)


* Labels 
putexcel set "$dir_work/reg_income_${country}", sheet("I3b_amount") modify

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
		labels_no_bl = regexm(labels_no_bl, "^L2\.") :* (regexr(labels_no_bl, "^L2\.", "") :+ "_L2") :+ (!regexm(labels_no_bl, "^L2\.") :* labels_no_bl)

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
	putexcel set "$dir_work/reg_income_${country}", sheet("I3b_amount") modify
	
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

* Export model fit statistics
putexcel set "$dir_work/reg_income_${country}", sheet("Gof") modify

putexcel A21 = ///
	"I3b level - Receiving capital income left initial education spell ", ///
	bold		
	
putexcel A23 = "R-squared" 
putexcel B23 = r2 
putexcel A24 = "N"
putexcel B24 = N_sample 

		
* Clean up 		
drop in_sample p
scalar drop _all
matrix drop _all
frame drop temp_frame 	



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

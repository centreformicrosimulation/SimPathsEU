********************************************************************************
* PROJECT:  		SimPaths EU
* SECTION:			Non-employment/non-benefit income
* OBJECT: 			Final Regresion Models 
* AUTHORS:			Daria Popova, Justin van de Ven, Ashley Burdett
* LAST UPDATE:		January 2026
* COUNTRY: 			Poland  
********************************************************************************
* NOTES: 			 
* 					I1a - Capital income (in cont edu, selection & amount)
* 					I1b - Capital income (not in cont edu, selection & amount)
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
set maxvar 30000

* Set off log
cap log close 
log using "$dir_log/reg_income.log", replace


/********************************* SET EXCEL FILE *****************************/

* Info sheet
putexcel set "$dir_work/reg_income_${country}", sheet("Info") replace
putexcel A1 = "Description:", bold
putexcel B1 = "This file contains regression estimates used by process I3, capital income. The data suggests there is no private pension income "

putexcel A2 = "Authors:", bold
putexcel B2 = "Ashley Burdett, Aleksandra Kolndrekaj" 	
putexcel A3 = "Last edit:", bold
putexcel B3 = "12 Jan 2016 AB"

putexcel A5 = "Process:", bold
putexcel B5 = "Description:", bold

putexcel A6 = "Process I1a"
putexcel B6 = "Logit regression estimates of the probability of receiving capital income "

putexcel A8 = "Process I1b"
putexcel B8 = "OLS regression estimates (ihs) capital income amount -  who receive capital income"

putexcel A12 = "Notes:", bold
putexcel B12 = "Categorical health variable modelled as continuous"
putexcel B12 = "Regions: PL4 = Polnocno-Zachodni, PL5 = Poludniowo-Zachodni, PL6 = Polnocy, PL10 = Central + East. Poludniowy is the omitted category."

* Goodness of fit
putexcel set "$dir_work/reg_income_${country}", sheet("Gof") modify

putexcel A1 = "Goodness of fit", bold


/********************************* PREPARE DATA *******************************/

* Load data 
use "$dir_input_data/${country}_pooled_ipop", clear 

* Ensure missing is missing 
recode dgn dag dagsq dhe drgn1 stm scedsmpl deh_c3 deh_c4 les_c4 les_c3 ///
	dhhtp_c4 dhe (-9=.)

* Remove children 
drop if dag < 16

* Adjust variables	

sum yplgrs_dv ypncp ypnoab /*pred_hourly_wage*/

* Time variables 
* Year dummies
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

bys swv idhh: gen nwa = _N

gen ypncp_lvl = sinh(ypncp) 


* Trim the top captial income percentile
sum ypncp, det
scalar p99 = r(p99)

replace ypncp = . if ypncp >= p99


gen receives_ypncp = (ypncp > 0 & !missing(ypncp))

gen  ypnbihs_dv_sq = ypnbihs_dv^2 


* Labeling and formating variables
label def jbf 1 "Employed" 2 "Student" 3 "Not Employed"
label def edd 1 "Degree"	2 "High school" ///
				3 "Other/No Qualification"		
label def gdr 1  "Male" 0 "Female"
		
label def yn	1 "Yes" 0 "No"
label def hht 1 "Couples with No Children" 2 "Couples with Children" ///
				3 "Single with No Children" 4 "Single with Children" 

label val dgn gdr
label val les_c3 jbf 
label val deh_c3 edd 
label val dcpen dcpex yn
label val lesdf_c4 dces
label val ded dlltsd yn
label val dhhtp_c4 hht
				
				
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
label var ypncp "Gross real monthly personal non-emp capital income, asinh"

* Alter names and create dummies for automatic labelling 
gen Dgn = dgn 

gen Ded= ded

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

gen Year_transformed = stm - 2000

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

gen Ydses_c5 = ydses_c5 

gen New_rel = new_rel

gen Dcpyy = dcpyy_st 

gen Dcpagdf = dcpagdf

gen Ypnbihs_dv = ypnbihs_dv

gen Ynbcpdf_dv = ynbcpdf_dv

gen Yplgrs_dv = yplgrs_dv

gen Ypncp = ypncp

gen Ln_Ypncp=ln_ypncp

* Age centred
gen Dag_c20 = dag - 20
gen Dag_c20_sq = Dag_c20^2

gen Dag_c42 = dag - 42
gen Dag_c42_sq = Dag_c42^2

* Generate interactions 

gen Ded_Dgn = Ded * Dgn
gen Ded_Dag =  Ded * Dag 
gen Ded_Dag_sq = Ded *Dag_sq 
gen Ded_Dag_c20 = Ded * Dag_c20
gen Ded_Dag_c20_sq = Ded * Dag_c20_sq

xtset idperson swv

gen Ded_Dhe_Fair_L1 = l.Dhe_Fair * Ded 
gen Ded_Dhe_Good_L1 = l.Dhe_Good * Ded
gen Ded_Dhe_VeryGood_L1 = l.Dhe_VeryGood * Ded 
gen Ded_Dhe_Excellent_L1 = l.Dhe_Excellent * Ded 
	
gen Ded_Ypncp_L1 = l.Ypncp * Ded
gen Ded_Yplgrs_dv_L1 = l.Yplgrs_dv * Ded
gen Ded_Yplgrs_dv_L2 = l2.Yplgrs_dv * Ded
gen Ded_Ypncp_L2 = l2.Ypncp * Ded

gen Ded_Ln_Ypncp_L1 = l.Ln_Ypncp * Ded
gen Ded_Ln_Ypncp_L2 = l2.Ln_Ypncp * Ded

* Set data 
xtset idperson swv
		
	
/********************************** ESTIMATION ********************************/

/*************** I1a: PROBABILITY OF RECEIVEING CAPITAL INCOME ****************/
	
/*
logit receives_ypncp i.dgn dag dagsq ib1.deh_c3 li.les_c4 lib1.dhhtp_c4 ///
	l.dhe l.yplgrs_dv l.ypncp l2.yplgrs_dv l2.ypncp i.drgn1 stm Y2020 ///
	Y2021 if ded == 0 [pweight = dimxwt], vce(cluster idperson) base
removed for multicollinearity issues Ded_Dag*/

logit receives_ypncp i.Dgn c.Dag c.Dag c.Dag_sq l.Dhe_Poor l.Dhe_Fair ///
	l.Dhe_Good l.Dhe_VeryGood l.Dhe_Excellent lc.Ypncp lc.Yplgrs_dv ///
	l2c.Yplgrs_dv l2c.Ypncp Ded_Dgn Ded_Dag_sq ///
	Ded_Dhe_Fair_L1 Ded_Dhe_Good_L1 Ded_Dhe_VeryGood_L1 Ded_Dhe_Excellent_L1 ///
	Ded_Ypncp_L1 Ded_Yplgrs_dv_L1 Ded_Yplgrs_dv_L2 Ded_Ypncp_L2 ///
	i.Deh_c4_Low i.Deh_c4_Medium i.Deh_c4_High ///
	li.Les_c4_Student li.Les_c4_NotEmployed li.Les_c4_Retired ///
	li.Dhhtp_c4_CoupleChildren li.Dhhtp_c4_SingleNoChildren ///
	li.Dhhtp_c4_SingleChildren $regions Year_transformed Y2020 Y2021 if ///
	 ${i1a_if_condition} [pweight = dwt], ///
	 vce(cluster idperson) base


* Save raw results 
matrix results = r(table)
matrix results = results[1..6,1...]'

putexcel set "$dir_raw_results/income/income", ///
	sheet("Process Capital selection") replace
putexcel A3 = matrix(results), names nformat(number_d2) 
putexcel J4 = matrix(e(V))

outreg2 stats(coef se pval) using ///
	"$dir_raw_results/income/Selection.doc", replace ///
title("Process I1a: Probability Receiving Capital Income") ///
	ctitle(Receives capital income) label side dec(2) noparen ///
	addstat(R2, e(r2_p), Chi2, e(chi2), Log-likelihood, e(ll)) ///
	addnote(`"Note: Regression if condition = (${i1a_if_condition})"')		 
	
	
* Save sample inclusion indicator and predicted probabilities	
gen in_sample = e(sample)	
predict p

* Save sample for estiamte validation
save "$dir_data/I1_selection_sample", replace

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
putexcel set "$dir_work/reg_income_${country}", sheet("I1a") modify
putexcel B2 = matrix(b_trimmed)
putexcel C2 = matrix(V_trimmed)


* Labels 
putexcel set "$dir_work/reg_income_${country}", sheet("I1a") modify

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
	putexcel set "$dir_work/reg_income_${country}", sheet("I1a") ///
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

putexcel A5 = ///
	"I1a - Receiving capital income ", ///
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
	
	
/********************** I1b: AMOUNT OF CAPITAL INCOME *************************/

xtset idperson swv 

reg ln_ypncp i.Dgn c.Dag c.Dag c.Dag_sq l.Dhe_Fair l.Dhe_Good l.Dhe_VeryGood ///
	l.Dhe_Excellent lc.Ln_Ypncp lc.Yplgrs_dv l2c.Yplgrs_dv l2c.Ln_Ypncp ///
	Ded_Dgn /*Ded_Dag Ded_Dag_sq*//*Ded_Dhe_Fair_L1 Ded_Dhe_Good_L1 ///
	Ded_Dhe_VeryGood_L1 Ded_Dhe_Excellent_L1 */ Ded_Ln_Ypncp_L1 ///
	Ded_Yplgrs_dv_L1 Ded_Yplgrs_dv_L2 Ded_Ln_Ypncp_L2 i.Deh_c4_Low ///
	i.Deh_c4_Medium i.Deh_c4_High li.Les_c4_Student li.Les_c4_NotEmployed ///
	li.Les_c4_Retired li.Dhhtp_c4_CoupleChildren ///
	li.Dhhtp_c4_SingleNoChildren li.Dhhtp_c4_SingleChildren $regions ///
	Year_transformed Y2020 Y2021 if ${i1b_if_condition} [pw=dwt], ///
	vce(cluster idperson)
	
* Save raw results 
matrix results = r(table)
matrix results = results[1..6,1...]'

putexcel set "$dir_raw_results/income/income", ///
	sheet("Process I1b") modify
putexcel A3 = matrix(results), names nformat(number_d2) 
putexcel J4 = matrix(e(V))

outreg2 stats(coef se pval) using ///
	"$dir_raw_results/income/Amount.doc", replace ///
title("Process I1b: Capital Income Amount") ///
	ctitle(Capital amount) label side dec(2) noparen ///
	addstat("R2", e(r2)) ///
	addnote(`"Note: Regression if condition = (${i1b_if_condition})"')	
	
	
* Save sample inclusion indicator and predicted probabilities	  
gen in_sample = e(sample)	
predict p
gen sigma = e(rmse)

* Save sample for estimate validation
save "$dir_data/I1_level_sample", replace

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
putexcel set "$dir_work/reg_income_${country}", sheet("I1b") modify
putexcel B2 = matrix(b_trimmed)
putexcel C2 = matrix(V_trimmed)


* Labels 
putexcel set "$dir_work/reg_income_${country}", sheet("I1b") modify

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
	putexcel set "$dir_work/reg_income_${country}", sheet("I1b") modify
	
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
keep if receives_ypncp == 1
sum squared_residuals [w = dwt]
di "RMSE for Amount of capital income" sqrt(r(mean))
putexcel set "$dir_work/reg_RMSE_${country}.xlsx", sheet("${country}") modify
putexcel A7 = ("I3") B7 = (sqrt(r(mean))) 
restore 

* Export model fit statistics
putexcel set "$dir_work/reg_income_${country}", sheet("Gof") modify

putexcel A11 = ///
	"I1b - Capital income amount", ///
	bold		
	
putexcel A13 = "R-squared" 
putexcel B13 = r2 
putexcel A14 = "N"
putexcel B14 = N_sample 
		
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

/*******************************************************************************
* PROJECT:  		SimPaths EU 
* SECTION:			Home ownership 
* OBJECT: 			Probabilty of being a homeowner  
* AUTHORS:			Daria Popova, Justin van de Ven, Ashley Burdett, 
* 					Aleksandra Kolndrekaj
* LAST UPDATE:		January 2026 AB
* COUNTRY: 			Poland
********************************************************************************
* NOTES: 			
*******************************************************************************/

clear all
set more off
set mem 200m
set type double
set maxvar 30000

* Set off log 
cap log close 
//log using "$dir_log/reg_home_ownership.log", replace


/********************************* SET EXCEL FILE *****************************/

* Info sheet
putexcel set "$dir_work/reg_home_ownership_${country}", sheet("Info") replace
putexcel A1 = "Description:", bold
putexcel B1 = "Model parameters governing projection of home ownership"

putexcel A2 = "Authors:", bold
putexcel B2 = "Ashley Burdett, Aleksandra Kolndrekaj" 	
putexcel A3 = "Last edit:", bold
putexcel B3 = "12 Jan 2016 AB"

putexcel A5 = "Process:", bold
putexcel B5 = "Description:", bold
putexcel A6 = "HO1"
putexcel B6 = "Probit regression estimates of the probability of being a home owner, aged 18+, head of benefit unit"

putexcel A10 = "Notes:", bold
putexcel B10 = "Have combined dhhtp_c4 and lessp_c3 into a single variable with 8 cateogries, dhhtp_c8"
putexcel B11 = "Regions: PL4 = Polnocno-Zachodni, PL5 = Poludniowo-Zachodni, PL6 = Polnocy, PL10 = Central + East. Poludniowy is the omitted category."
putexcel B12 = "Estimated on the sample of benefit unit heads." 


putexcel set "$dir_work/reg_home_ownership_${country}", sheet("Gof") modify
putexcel A1 = "Goodness of fit", bold	


/********************************* PREPARE DATA *******************************/

* Load data 
use "$dir_input_data/${country}_pooled_ipop.dta", clear

* Ensure missing is missing 
recode dhh_owned dgn dag dagsq les_c3 deh_c3 deh_c4 dhe yptciihs_dv  ///
	ydses_c5 drgn1 dhhtp_c4 lessp_c3 stm les_c4 dhhtp_c8 (-9=.)

* Set data 
xtset idperson swv
sort idperson swv 	
	
* Remove children
drop if dag < 16

* Adjust variables
* Time variables 
* Year centered around 2000 (- helps to avoid invertability issue)
replace stm = stm - 2000
fre stm 

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

* Only keep head of benefit unit 
egen tag_bu_wave = tag(idbenefitunit swv)
count if tag_bu_wave
local n_bu_before = r(N)
display "Number of benefit unit–wave combinations BEFORE selecting head: `n_bu_before'"

* Sort benefit unit members within each wave:
* 1. Highest non-benefit income (ypnbihs_dv)
* 2. Highest age (dag)
* 3. Lowest idperson (idperson)
gsort idbenefitunit swv -ypnbihs_dv -dag idperson 

* Tag the first person (the "head") per benefit unit and wave
bysort idbenefitunit swv: gen benunit_head = (_n == 1)

* Keep only benefit unit heads
keep if benunit_head == 1

* Count unique benefit-unit–wave combinations AFTER head selection
drop tag_bu_wave
egen tag_bu_wave = tag(idbenefitunit swv)
count if tag_bu_wave
local n_bu_after = r(N)
display "Number of benefit unit–wave combinations AFTER selecting head: `n_bu_after'"

* Ensure benefit unit–wave counts match before and after head selection
assert `n_bu_before' == `n_bu_after'

* Verify only one head per benefit unit per wave
by idbenefitunit swv, sort: gen n = _N
assert n == 1

sort idperson swv

* Labeling and formating variables
label def jbf 1 "Employed" 2 "Student" 3 "Not Employed"
label def edd 1 "Degree"	2 "High school" ///
					3 "Other/No Qualification"
label def gdr 1 "Male" 0 "Female"
label def yn	1 "Yes" 0 "No"
label def hht 1 "Couples with No Children" 2 "Couples with Children" ///
				3 "Single with No Children" 4 "Single with Children"

label val dgn gdr
label val drgn1 rgna
label val les_c3 lessp_c3 jbf 
label val deh_c3 dehsp_c3 edd 
label val dcpen dcpex dlrtrd yn
label val dhhtp_c4 hht				
				
label var dgn "Gender"
label var dag "Age"
label var dagsq "Age Squared"
label var drgn1 "Region"
label var stm "Year"
label var les_c3 "Employment Status: 5 Category" 
label var dhe "Self-rated Health"
label var deh_c3 "Educational Attainment: 3 Category"
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

tab lesdf_c4, gen(Lesdf_c4_)
rename Lesdf_c4_1 Lesdf_c4_BothEmployed
rename Lesdf_c4_2 Lesdf_c4_EmpSpouseNotEmp
rename Lesdf_c4_3 Lesdf_c4_NotEmpSpouseEmp
rename Lesdf_c4_4 Lesdf_c4_BothNotEmployed

tab dcpst, gen(Dcpst_)
rename Dcpst_1 Dcpst_Partnered
rename Dcpst_2 Dcpst_Single

tab dhhtp_c8, gen(Dhhtp_c8_)

gen Dnc = dnc

gen Dnc02 = dnc02

gen Year_transformed = stm  

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
gen Y2223 = (stm == 22 | stm == 23)

gen Dhe = dhe 

gen Ydses_c5 = ydses_c5 

gen New_rel = new_rel

gen Dcpyy = dcpyy_st 

gen Dcpagdf = dcpagdf

gen Ypnbihs_dv = ypnbihs_dv

gen Ynbcpdf_dv = ynbcpdf_dv

gen Yptciihs_dv = yptciihs_dv

gen Dhh_owned = dhh_owned

* Generate interactions
gen Les_c4_Student_L1_Dgn = Dgn * Les_c4_Student
gen Les_c4_NotEmployed_L1_Dgn = Dgn * Les_c4_NotEmployed
gen Les_c4_Retired_L1_Dgn = Dgn * Les_c4_Retired	


/********************************** ESTIMATION ********************************/

/********************** HO1: PROBABILITY OF OWNING HOME ***********************/

xtset idperson swv

* Estimation 
probit dhh_owned_ind i.Dgn Dag Dag_sq il.Dhhtp_c8_2 il.Dhhtp_c8_3 ///
	il.Dhhtp_c8_4 il.Dhhtp_c8_5 il.Dhhtp_c8_6 il.Dhhtp_c8_7 il.Dhhtp_c8_8 ///
	il.Les_c3_Student il.Les_c3_NotEmployed i.Deh_c4_Na ///
	i.Deh_c4_Medium i.Deh_c4_Low il.Dhe_Fair il.Dhe_Good il.Dhe_VeryGood ///
	il.Dhe_Excellent li.Ydses_c5_Q2 li.Ydses_c5_Q3 li.Ydses_c5_Q4 ///
	li.Ydses_c5_Q5 l.Yptciihs_dv l.Dhh_owned $regions Year_transformed ///
	Y2020 Y2021 if ${ho1_if_condition} [pw=dwt], vce(cluster idperson)

* Save raw results 
matrix results = r(table)
matrix results = results[1..6,1...]'

putexcel set "$dir_raw_results/home_ownership/home_ownership", ///
	sheet("Process HO1") replace
putexcel A3 = matrix(results), names nformat(number_d2) 
putexcel J4 = matrix(e(V))

outreg2 stats(coef se pval) using ///
	"$dir_raw_results/home_ownership/HO1.doc", replace ///
title("Process H01: Probability Own Home") ///
	ctitle(Own home) label side dec(2) noparen ///
	addstat(R2, e(r2_p), Chi2, e(chi2), Log-likelihood, e(ll)) ///
	addnote(`"Note: Regression if condition = (${ho1_if_condition}). Only estimated on benefit unit heads."')		
	
* Save sample inclusion indicator and predicted probabilities				
gen in_sample = e(sample)	
predict p

* Save sample for stimate validation
save "$dir_data/HO1a_sample", replace

* Store model summary statistics
scalar r2_p = e(r2_p) 
scalar N_sample = e(N)	
scalar chi2 = e(chi2)
scalar ll = e(ll)	


* Store results in Excel 

* Store estimates
matrix b = e(b)	
matrix V = e(V)

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
putexcel set "$dir_work/reg_home_ownership_${country}", sheet("HO1") modify 
putexcel B2 = matrix(b_trimmed)
putexcel C2 = matrix(V_trimmed)

* Labels 
putexcel set "$dir_work/reg_home_ownership_${country}", sheet("HO1") modify 

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
	putexcel set "$dir_work/reg_home_ownership_${country}", sheet("HO1") modify 
	
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
putexcel set "$dir_work/reg_home_ownership_${country}", sheet("Gof") modify

putexcel A3 = "HO1 - Home ownership", bold		

putexcel A5 = "Pseudo R-squared" 
putexcel B5 = r2_p 
putexcel A6 = "N"
putexcel B6 = N_sample 
putexcel E5 = "Chi^2"		
putexcel F5 = chi2
putexcel E6 = "Log likelihood"		
putexcel F6 = ll		

drop in_sample p
scalar drop r2_p N_sample chi2 ll	

capture log close 

********************************************************************************
* PROJECT:  		ESPON 
* SECTION:			Fertility
* OBJECT: 			Having a child
* AUTHORS:			Daria Popova, Justin van de Ven, Ashley Burdett
* LAST UPDATE:		21/04/2024 (JV)
* COUNTRY: 			Greece 
*
* NOTES:			Simplified the fertiliy process for those in this initial 
* 						education spell. Exclude l.dnc, l.dnc02, li.ydses_c5 
* 						and model health as a continuous variable. 		
* 
* 					Unable to obtain estimates for the subsample that are in 
* 						there initial education spell as only one birth observed 
* 						in the data. 
********************************************************************************
clear all
set more off
set mem 200m
set type double
//set maxvar 120000
set maxvar 30000

cap log close 
//log using "$dir_log/reg_fertility.log", replace

* Import fertility rate 
import excel "$dir_external_data/${country}_fertility_rate", sheet("f_rate") ///
	firstrow clear 

rename Year swv
rename GFR dplfr

label var dplfr "Fertility_rate"

drop if swv == . 
drop if swv > 2023

save "$dir_data/fertility_rate", replace


* Call main dataset
use "$dir_input_data/${country}-SILC_pooled_all_obs_02.dta", clear

* Sample selection 
drop if dag < 16

* Adjust variables 
* Year dummies 
forvalues y = 10/23 {
	
	gen Y20`y' = (stm == 20`y')
	
}

gen Y2022_2023 = (stm == 2022| stm == 2023)

tab dchpd
replace dchpd = 1 if dchpd == 2 | dchpd == 3 | dchpd == 4 | dchpd == 5 

* Ensure missing is missing 
recode dhe dnc dnc02 deh_c3 les_c3 ydses_c5 dcpst drgn1 sprfm scedsmpl ///
	 dchpd (-9=. )


* Labeling and formating variables
label def jbf 1 "Employed" 2 "Student" 3 "Not Employed"
label def edd 1 "Degree"	2 "High school" ///
				3 "Other/No Qualification"
label def hht 1 "Couples with No Children" 2 "Couples with Children" ///
				3 "Single with No Children" 4 "Single with Children" 
label def gdr 1  "Male" 0 "Female"
label def yn	1 "Yes" 0 "No"

label var dgn "Gender"
label var dag "Age"
label var dagsq "Age Squared"
label var drgn1 "Region"
label var dhhtp_c4 "Household Type: 4 Category"
label var stm "Year"
label var les_c3 "Employment Status: 3 Category" 
label var dhe "Self-rated Health"
label var deh_c3 "Educational Attainment: 3 Category"
label var dnc "Number of Children in Household"
label var dnc02 "Number of Children aged 0-2 in Household"
label var ydses_c5 "Annual Household Income Quintile" 

label val dgn gdr
label val drgn1 rgna
label val dhhtp_c4 hht 
label val les_c3 jbf 
label val deh_c3 edd 
label val ded yn

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

tab dcpst, gen(Dcpst_)
rename Dcpst_1 Dcpst_Partnered
rename Dcpst_2 Dcpst_Single
rename Dcpst_3 Dcpst_PreviouslyPartnered

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

* Merge in fertility rate
merge m:1 swv using "$dir_data/fertility_rate"

drop _m

gen FertilityRate = dplfr

sort idperson swv 


* Set Excel file 
* Info sheet
putexcel set "$dir_work/reg_fertility_${country}", sheet("Info") replace
putexcel A1 = "Description:"
putexcel B1 = "Model parameters governing projection of fertility"

putexcel A4 = "Process:", bold
putexcel B4 = "Description:", bold
putexcel A5 = "F1a"
putexcel B5 = "UNABLE TO OBTAIN ESTIMATES: Probit regression estimates of the probability of  having a child for women aged 18-29 in initial education spell"
putexcel A6 = "F1b"
putexcel B6 = "Probit regression estimates of probability of having a child for women aged 18-45 who are not in initial education spell"

putexcel A10 = "Notes:", bold
putexcel B10 = "Regions: EL3 = Attika (omitted), EL4 = Aegean Islands, EL7 = Central and Northern Greece"

putexcel set "$dir_work/reg_fertility_${country}", sheet("Gof") modify
putexcel A1 = "Goodness of fit", bold		


**********************************************
* F1a - Having a child, in initial edu spell * 
**********************************************
/*
* Process F1a: Probability of having a child 
* Sample: Women aged 18-44, in initial education spell education.
* DV: New born child dummy 

xtset idperson swv
tab dchpd if (sprfm == 1 & ded == 1) 
tab dchpd if (sprfm == 1 & ded == 1 & dag < 30) 

/*
probit dchpd dag dhe ib1.dcpst if ///
	sprfm == 1 & ded == 1 [pweight = dimxwt], vce(robust)
*/

probit dchpd Dag Dhe i.Dcpst_Single i.Dcpst_PreviouslyPartnered if ///
	sprfm == 1 & ded == 1 [pweight = dimxwt], vce(robust)
	
* Save sample inclusion indicator and predicted probabilities	
gen in_sample = e(sample)	
predict p

* Save sample for later use (internal validation)
save "$dir_data/F1a_sample", replace

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
putexcel set "$dir_work/reg_fertility_${country}", sheet("F1a") modify
putexcel B2 = matrix(b_trimmed)
putexcel C2 = matrix(V_trimmed)

* Labels
putexcel set "$dir_work/reg_fertility_${country}", sheet("F1a") modify

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
	putexcel set "$dir_work/reg_fertility_${country}", sheet("F1a") modify
	
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
putexcel set "$dir_work/reg_fertility_${country}", sheet("Gof") modify

putexcel A3 = "F1a - Fertility in initial education spell", bold		

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
*/
	
************************************************
* F1b - Having a child, left initial edu spell *
************************************************

* Process F1b: Probabiltiy of having a child 
* Sample:	Women aged 18-45, left initial education spell
* DV:	New born child dummy 
xtset idperson swv
tab dchpd if (sprfm == 1 & ded == 0) 

/*
probit dchpd dag dagsq li.ydses_c5 l.dnc l.dnc02 ib1.dhe ib1.dcpst ///
	lib1.dcpst ib1.deh_c3 dplfr li.les_c3 i.drgn1 stm y2020 y2021 if ///
	(sprfm == 1 & ded == 0) [pweight = dimxwt], vce(robust)
*/
probit dchpd Dag Dag_sq li.Ydses_c5_Q2 li.Ydses_c5_Q3 ///
	li.Ydses_c5_Q4 li.Ydses_c5_Q5 l.Dnc l.Dnc02 ///
	i.Dhe_Fair i.Dhe_Good i.Dhe_VeryGood i.Dhe_Excellent ///
	i.Dcpst_Single i.Dcpst_PreviouslyPartnered ///
	li.Dcpst_Single li.Dcpst_PreviouslyPartnered ///
	i.Deh_c3_Medium i.Deh_c3_Low FertilityRate li.Les_c3_Student ///
	li.Les_c3_NotEmployed i.EL4 i.EL7 Y2012-Y2021 Y2022_2023 if ///
	(sprfm == 1 & ded == 0) [pweight = dimxwt], vce(robust)
	
* Save sample inclusion indicator and predicted probabilities			
gen in_sample = e(sample)	
predict p

* Save sample for later use (internal validation)
save "$dir_data/F1b_sample", replace

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

* Export into Excel 
putexcel set "$dir_work/reg_fertility_${country}", sheet("F1b") modify
putexcel B2 = matrix(b_trimmed)
putexcel C2 = matrix(V_trimmed)

* Labels 
putexcel set "$dir_work/reg_fertility_${country}", sheet("F1b") modify

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
    import delimited "$dir_work/temp_labels.txt", clear varnames(1) encoding(utf8)
	
	gen n = _n
    
    * Export labels to Excel
	putexcel set "$dir_work/reg_fertility_${country}", sheet("F1b") modify
	
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
putexcel set "$dir_work/reg_fertility_${country}", sheet("Gof") modify

putexcel A9 = "F1b - Fertility left initial education spell", bold		

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

	
capture log close 

cap erase "$dir_work/temp.dta"


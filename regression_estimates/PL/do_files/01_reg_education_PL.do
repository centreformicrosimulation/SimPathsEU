********************************************************************************
* PROJECT:  		ESPON 
* SECTION:			Education
* OBJECT: 			Final Probit Models 
* AUTHORS:			Daria Popova, Justin van de Ven, Ashley Burdett 
* LAST UPDATE:		May 2025
* COUNTRY: 			Poland 

* NOTES: 			Process E2a - Slight discrepancy with previous gologit 
* 						estimates. 
* 					Try adding time trend to educational attainment. 
********************************************************************************
clear all
set more off
set mem 200m
set type double
//set maxvar 120000
set maxvar 30000

local model_specification_test = 0

cap log close 
log using "$dir_log/reg_education.log", replace


use "$dir_input_data/${country}-SILC_pooled_all_obs_02.dta", clear

//do "$dir_do/variable_update"

* Sample selection 
drop if dag < 16

* Adjust variables 
replace stm = stm - 2000
fre stm 

gen y2020 = (stm == 20)
gen y2021 = (stm == 21)

* Ensure missing is missing
recode ded dgn dag dagsq drgn1 stm deh_c3 les_c3 (-9=.) 

* Labeling and formating variables
label def jbf 1 "Employed" 2 "Student" 3 "Not Employed"			
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

label val dgn gdr
label val les_c3 jbf 
label val ded yn
label val dhhtp_c4 hht


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
rename Deh_c3_3 Deh_c3_Low

tab les_c3, gen(Les_c3_)
rename Les_c3_1 Les_c3_Employed
rename Les_c3_2 Les_c3_Student
rename Les_c3_3 Les_c3_NotEmployed

gen Dnc = dnc

gen Dnc02 = dnc02

gen Year_transformed = stm  

gen Y2020 = y2020  
gen Y2021 = y2021 

* Set data 
xtset idperson swv

* Set Excel file 
* Info sheet
putexcel set "$dir_work/reg_education_${country}", sheet("Info") replace
putexcel A1 = "Description:"
putexcel B1 = "Model parameters governing projection of education status"

putexcel A4 = "Process:", bold
putexcel B4 = "Description:", bold
putexcel A5 = "E1a"
putexcel B5 = "Probit regression estimates of remaining in continuous education - individuals aged 16-29 in initial education spell."
putexcel A6 = "E1b"
putexcel B6 = "Probit regression estimates of returning to education - individuals aged 16-35 not in initial education spell."
putexcel A7 = "E2a"
putexcel B7 = "Generalized ordered logit regression estimates of education attainment - individuals aged 16-29 exiting education that were in initial education spell in t-1 but not in t."
putexcel A8 = "E2a_raw"
putexcel B8 = "Raw generalized ordered logit regression estimates of education attainment - individuals aged 16-29 exiting education that were in initial education spell in t-1 but not in t. Useful for the 'Gologit predictor' file."

putexcel A10 = "Notes:", bold
putexcel B10 = "Regions: PL4 = Polnocno-Zachodni, PL5 = Poludniowo-Zachodni, PL6 = Polnocy, PL10 = Central + East. Poludniowy is the omitted category."

putexcel set "$dir_work/reg_education_${country}", sheet("Gof") modify
putexcel A1 = "Goodness of fit", bold		


*******************************************************
* E1a: Probability of Leaving Initial Education Spell *
*******************************************************
* Process E1a: Leaving the initial education spell. 
* Sample: Individuals aged 16-29 who have not left their initial education spell
* DV: In continuous education dummy 
* Note: Condition implies some persistence - education for the last 2 years. 

xtset idperson swv
fre ded if (dag >= 16 & dag <= 29 & l.ded == 1) 
// was in initial education spell in the previous wave 
// 75% remain in education 

probit ded i.Dgn Dag Dag_sq $regions Year_transformed ///
	Y2020 Y2021 if ///
	(dag >= 16 & dag <= 29 & l.ded == 1) [pweight = dimxwt], vce(robust)	
	
* Save sample inclusion indicator and predicted probabilities	
gen in_sample = e(sample)	
predict p

* Save sample for later use (internal validation)
save "$dir_data/E1a_sample", replace

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
putexcel set "$dir_work/reg_education_${country}", sheet("E1a") modify
putexcel B2 = matrix(b_trimmed)
putexcel C2 = matrix(V_trimmed)


* Labels 
preserve
putexcel set "$dir_work/reg_education_${country}", sheet("E1a") modify 	

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
    putexcel set "$dir_work/reg_education_${country}", sheet("E1a") modify 	
	
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
		local col = char(66 + `j')  // 66 = ASCII for 'B', so D=68, E=69, etc.
		putexcel `col'1 = v1[`j']
	}
	
    * Clean up
    erase "$dir_work/temp_labels.txt"
}

restore 
	
* Export model fit statistics
putexcel set "$dir_work/reg_education_${country}", sheet("Gof") modify

putexcel A3 = "E1a - Leaving initial education spell", bold		

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
	
**********************************************
* E1b: Probability of Returning to Education *
**********************************************

* Process E1b: Retraining having previously entered the labour force. 
* Sample: Individuals aged 16-35 who have left their initial education spell 
*  			and not a student last year 
* DV: Return to education 

xtset idperson swv

fre der if (dag >= 16 & dag <= 35 & ded == 0) 

probit der i.Dgn Dag Dag_sq li.Deh_c3_High li.Deh_c3_Low ///
	li.Les_c3_Student li.Les_c3_NotEmployed l.Dnc l.Dnc02 ///
	 $regions Year_transformed ///
	Y2020 Y2021 if (dag >= 16 & dag <= 35 & ded == 0) ///
	 [pweight=dimlwt], vce(robust)

* Save sample inclusion indicator and predicted probabilities	 
gen in_sample = e(sample)	
predict p

* Save sample for later use (internal validation)
save "$dir_data/E1b_sample", replace

* Store model summary statistics
scalar r2_p = e(r2_p) 
scalar N_sample = e(N)	 
scalar chi2 = e(chi2)
scalar ll = e(ll)
	 
* Prepare to store results in Excel 

* Eliminate rows and columns containing zeros (baseline cats) 
matrix b = e(b)	
matrix V = e(V)


mata:
    V = st_matrix("V")
    b = st_matrix("b")

    // Find which coefficients are nonzero
    keep = (b :!= 0)
	
	// Eliminate zeros
	b_trimmed = select(b, keep)
    V_trimmed = select(V, keep)
    V_trimmed = select(V_trimmed', keep)'

	b_trimmed 
	V_trimmed 
	
    // Return to Stata
    st_matrix("b_trimmed", b_trimmed')
    st_matrix("V_trimmed", V_trimmed)
	st_matrix("nonzero_b_flag", keep)
end	

* Export into Excel 
putexcel set "$dir_work/reg_education_${country}", sheet("E1b") modify
putexcel B2 = matrix(b_trimmed)
putexcel C2 = matrix(V_trimmed)


* Labels 
putexcel set "$dir_work/reg_education_${country}", sheet("E1b") modify 	

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
    import delimited "$dir_work/temp_labels.txt", clear varnames(1) encoding(utf8)
	
	gen n = _n
    
    * Export labels to Excel
    putexcel set "$dir_work/reg_education_${country}", sheet("E1b") modify 	
	
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
		local col = char(66 + `j')  // 66 = ASCII for 'B', so D=68, E=69, etc.
		putexcel `col'1 = v1[`j']
	}
	
    * Clean up
    erase "$dir_work/temp_labels.txt"
}

* Export model fit statistics
putexcel set "$dir_work/reg_education_${country}", sheet("Gof") modify

putexcel A8 = "E1b - Returning to education", bold		

putexcel A10 = "Pseudo R-squared" 
putexcel B10 = r2_p 
putexcel A11 = "N"
putexcel B11 = N_sample 
putexcel E10 = "Chi^2"		
putexcel F10 = chi2
putexcel E11 = "Log likelihood"		
putexcel F11 = ll
		
* Clean up 		
drop in_sample p
scalar drop _all
matrix drop _all
frame drop temp_frame 	


*************************************************
* E2a Educational Level After Leaving Education *
*************************************************

* Process E2a: Educational level achieved when leaving the initial spell of 
* 				education  
* Sample: Those 16-29 who have just left their initial education spell in  
* 				current year 
* DV: Education level (3 cat)  
* Note: Previously tried a multinomial probit, now use an ordered probit
* Impute the dependent variable for PL, therefore limit the estimation sample 
* to those with complete observations. 

fre deh_c3 if (Dag >= 16 & Dag <= 29) & l.ded == 1 & ded == 0

recode deh_c3 (1 = 3) (3 = 1), gen(deh_c3_recoded)	
lab def deh_c3_recoded 1 "Low" 2 "Medium" 3 "High"
lab val deh_c3_recoded deh_c3_recoded


* Generalized ordered logit 
sort idperson swv
xtset idperson swv

gologit2 deh_c3_recoded i.Dgn Dag Dag_sq $regions /*Year_transformed*/ Y2020 ///
	Y2021 if dag >= 16 & dag <= 29 & l.ded == 1 & ded == 0 & dhe_flag != 1  ///
	[pweight = dimxwt], autofit 

* Save sample inclusion indicator and predicted probabilities	
gen in_sample = e(sample)	
predict p1 p2 p3 

* Save sample for later use (internal validation)
save "$dir_data/E2a_sample", replace

* Store model summary statistics	
scalar r2_p = e(r2_p) 
scalar N_sample = e(N)	 

* Store results in Excel 

* Store estimates in matrices
matrix b = e(b)	
matrix V = e(V)

* Raw output 
putexcel set "$dir_work/reg_education_${country}", sheet("E2a_raw") modify
putexcel A1 = matrix(b'), names nformat(number_d2) 
putexcel A1 =  "CATEGORY"
putexcel B1 =  "REGRESSOR"
putexcel C1 =  "COEFFICIENT"

* Estimated coefficients 
scalar no_coefs_all = colsof(b)

* Eliminate rows and columns containing zeros (baseline cats) 
mata:
	// Call matrices into mata 
    b = st_matrix("b")

    // Find which coefficients are nonzero
    keep = (b :!= 0)
	
    // Eliminate zeros	
	nonzero_b = select(b, keep)
	
	nonzero_b 
	
    // Return to Stata
    st_matrix("nonzero_b", nonzero_b)
	st_matrix("nonzero_b_flag", keep)
end	

* Inspect
matrix list b 
matrix list nonzero_b
matrix list nonzero_b_flag

* Save dimensions
scalar no_nonzero_b = colsof(nonzero_b)
scalar no_nonzero_b_per = no_nonzero_b / 2

* Address repetition of proportional odds covariates

* Generate repetition/unique observation flag
mata:
	// Import matrices into mata
	nonzero_b_mata = st_matrix("nonzero_b")

	// Generate binary vector =1 if coefficient repeated 
	n = cols(nonzero_b_mata)
	repetition_flag = J(n, 1, 0)

	// use tolerance based comparison to avoid precision errors 
	tol = 1e-8

		for (i = 1; i <= n; i++) {
			for (j = 1; j <= n; j++) {
				if (i != j && abs(nonzero_b_mata[i] - nonzero_b_mata[j]) < tol) {
					repetition_flag[i] = 1
					break
				}
			}
	}
	repetition_flag

	// Generate binary vector =1 if coefficient not repeated 
	unique_flag  = 1 :- repetition_flag

	// Return to Stata
	st_matrix("repetition_flag", repetition_flag')
	st_matrix("unique_flag", unique_flag')

end

* Generate vector to multiply the coef vector with to eliminate the repetitions 
* of coefficients for vars that satify the proportional odds assumptions
matrix structure_a = J(1,no_nonzero_b_per,1)
matrix structure_b = unique_flag[1,no_nonzero_b_per+1..no_nonzero_b]
matrix structure = structure_a, structure_b

* Inspect
matrix list structure_a
matrix list structure_b
matrix list structure
matrix list nonzero_b

* Eliminate repetitions 
mata:
	// Call matrices into mata 
	var = st_matrix("var")
	structure = st_matrix("structure")
	nonzero_b = st_matrix("nonzero_b")
	
	// Convert reptitions into zeros 
	b_structure = structure :* nonzero_b

	b_structure 
	
	// Eliminate zeros 
	keep = (b_structure :!= 0)
	
	nonzero_b_structure = select(b_structure, keep)
	
	// Export to Stata
	st_matrix("b_structure", b_structure)
	st_matrix("nonzero_b_structure", nonzero_b_structure)

end

matrix list nonzero_b_structure

* Export into Excel 
putexcel set "$dir_work/reg_education_${country}", sheet("E2a") modify
putexcel A1 = matrix(nonzero_b_structure'), names nformat(number_d2) 


* Variance-covariance matrix 
* Eliminate zeros (baseline categories)
mata:
    V = st_matrix("V")
    b = st_matrix("b")

    // Find which coefficients are nonzero
    keep = (b :!= 0)
	
	// Eliminate zeros 
    V_trimmed = select(V, keep)
    V_trimmed = select(V_trimmed', keep)'

	V_trimmed 
	
    // Return to Stata
    st_matrix("var", V_trimmed)
end			

matrix list var


* Address repetition due to proportional odds being satisfied for some covars
matrix square_structure_a = J(no_nonzero_b,1,1) * structure
matrix square_structure_b = square_structure_a'

matrix list square_structure_a
matrix list square_structure_b
mata:
	// Call matrices into mata 
	var = st_matrix("var")
	
	// Create structure matrix (0 = eliminate)
	square_structure_a = st_matrix("square_structure_a")
	square_structure_b = st_matrix("square_structure_b")
	
	// Element-by-element multiplication
	square_structure = square_structure_a :* square_structure_b 
	var_structure = square_structure :* var
	
	// Eliminate zeros 
	row_keep = rowsum(abs(var_structure)) :!= 0
	col_keep = colsum(abs(var_structure)) :!= 0

	nonzero_var_structure = select(select(var_structure, row_keep), col_keep)

	// Return to Stata
	st_matrix("nonzero_var_structure", nonzero_var_structure)
end

matrix list nonzero_var_structure

* Export to Excel 
putexcel set "$dir_work/reg_education_${country}", sheet("E2a") modify 
putexcel C2 = matrix(nonzero_var_structure)
		
			
* Labels

putexcel set "$dir_work/reg_education_${country}", sheet("E2a") modify 	

putexcel A1 = "REGRESSOR"
putexcel B1 = "COEFFICIENT"

preserve 
* Create temporary frame - Main file 
frame create temp_frame
frame temp_frame: {
    
    mata: 
		// Import matrices from Stata
		nonzero_b_flag = st_matrix("nonzero_b_flag")'
		unique_flag = st_matrix("unique_flag")'
		structure = st_matrix("structure")'
		stripe = st_matrixcolstripe("e(b)")
		
		// Extract variable and category names
		catnames = stripe[.,1]
		varnames = stripe[.,2]
		varnames_no_bl = select(varnames, nonzero_b_flag :== 1)
		catnames_no_bl = select(catnames, nonzero_b_flag :== 1)
		
		// Create and clean labels 
		labels_no_bl = varnames_no_bl :+ "_" :+ (catnames_no_bl :* (unique_flag[1::rows(varnames_no_bl)] :!= 0))
		labels_no_bl = usubinstr(labels_no_bl, "1.", "", 1)
		labels_no_bl = regexr(labels_no_bl, "^_cons", "Constant")
		nonzero_labels_structure = select(labels_no_bl, structure[1::rows(labels_no_bl)] :== 1)
		
		// Add v1
		nonzero_labels_structure = "v1"\nonzero_labels_structure
		
		// Create temp file with results
		fh = fopen("$dir_work/temp_labels.txt", "w")
		for (i=1; i<=rows(nonzero_labels_structure); i++) {
			fput(fh, nonzero_labels_structure[i])
		}
		fclose(fh)
    end
    
    * Import cleaned labels into Stata as new dataset
    import delimited "$dir_work/temp_labels.txt", clear varnames(1) encoding(utf8)
	gen n = _n
    
    * Export labels to Excel
    putexcel set "$dir_work/reg_education_${country}", sheet("E2a") modify 	
	
	* Vertical labels
    sum n, meanonly
	local N = r(max)+1
	forvalue i = 2/`N' {
		local j = `i' - 1
		putexcel A`i' = v1[`j'] 
	}
	
	* Horizontal labels
	sum n, meanonly
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
	
    *Clean up
    erase "$dir_work/temp_labels.txt"
}

* Export model fit statistics
putexcel set "$dir_work/reg_education_${country}", sheet("Gof") modify

putexcel A13 = "E2a - Educational attainment", bold		

putexcel A15 = "Pseudo R-squared" 
putexcel B15 = r2_p 
putexcel A16 = "N"
putexcel B16 = N_sample 
		
drop in_sample	
scalar drop r2_p N_sample	


restore 


	
cap log close

cap erase "$dir_work/temp.dta"

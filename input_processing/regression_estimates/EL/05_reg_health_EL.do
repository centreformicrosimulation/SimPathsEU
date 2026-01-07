********************************************************************************
* PROJECT:  		ESPON 
* SECTION:			Health
* OBJECT: 			Health status and Disability
* AUTHORS:			Daria Popova, Justin van de Ven, Ashley Burdett
* LAST UPDATE:		Feb 2025
* COUNTRY: 			Greece 
* 
* NOTES: 			
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

* Sample selection 
drop if dag < 16

* Adjust variables 
replace stm = stm - 2000

* Year dummies 
forvalues y = 10/23 {
	
	gen Y20`y' = (stm == `y')
	
}

gen Y2022_2023 = (stm == 22| stm == 23)


sort idperson stm 

* Ensure missing is missing 
recode dhe deh_c3 les_c3 les_c4 ydses_c5 dhhtp_c4 drgn1 stm  (0= .) (-9=. ) 
recode dgn dag dagsq (-9=.)

* Generate lags
gen l_ydses_c5 = ydses_c5[_n-1] if idperson == idperson[_n-1] & ///
	swv == swv[_n-1] + 1 

gen l_dhe = dhe[_n-1] if idperson == idperson[_n-1] & ///
	swv == swv[_n-1] + 1 
		
gen l_les_c3 = les_c3[_n-1] if idperson == idperson[_n-1] & ///
	swv == swv[_n-1] + 1 
		
gen l_dhhtp_c4 = dhhtp_c4[_n-1] if idperson == idperson[_n-1] & ///
	swv == swv[_n-1] + 1 	


* Labeling and formating variables
label def jbf 1 "Employed" 2 "Student" 3 "Not Employed"
label def edd 1 "Degree"	2 "High school" ///
					3 "Other/No Qualification"
label def hht 1 "Couples with No Children" 2 "Couples with Children" ///
				3 "Single with No Children" 4 "Single with Children"
label def gdr 1  "Male" 0 "Female"				
label def yn	1 "Yes" 0 "No"
label def dhe 1 "Poor" 2"Fair" 3"Good" 4"VeryGood" 5"Excellent", modify 

label var dgn "Gender"
label var dag "Age"
label var dagsq "Age Squared"
label var drgn1 "Region"
label var dhhtp_c4 "Household Type: 4 Category"
label var stm "Year"
label var les_c3 "Employment Status: 3 Category" 
label var dhe "Self-rated Health"
label var deh_c3 "Educational Attainment: 3 Category"
label var ydses_c5 "Annual Household Income Quintile" 
label var dlltsd "Long-term Sick or Disabled"

label val dgn gdr
label val drgn1 rgna
label val dhhtp_c4 hht 
label val les_c3 jbf 
label val deh_c3 edd 
label val ded yn
label var dhe dhe

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

tab l_les_c3, gen(L_Les_c3_)
rename L_Les_c3_1 L_Les_c3_Employed
rename L_Les_c3_2 L_Les_c3_Student
rename L_Les_c3_3 L_Les_c3_NotEmployed

tab les_c4, gen(Les_c4_)
rename Les_c4_1 Les_c4_Employed
rename Les_c4_2 Les_c4_Student
rename Les_c4_3 Les_c4_NotEmployed
rename Les_c4_4 Les_c4_Retired

tab ydses_c5, gen(Ydses_c5_Q)

tab l_ydses_c5, gen(L_Ydses_c5_Q)

tab dhe, gen(Dhe_)
rename Dhe_1 Dhe_Poor
rename Dhe_2 Dhe_Fair
rename Dhe_3 Dhe_Good
rename Dhe_4 Dhe_VeryGood
rename Dhe_5 Dhe_Excellent

tab l_dhe, gen(L_Dhe_c5_)

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

tab l_dhhtp_c4, gen(L_Dhhtp_c4_)
rename L_Dhhtp_c4_1 L_Dhhtp_c4_CoupleNoChildren
rename L_Dhhtp_c4_2 L_Dhhtp_c4_CoupleChildren
rename L_Dhhtp_c4_3 L_Dhhtp_c4_SingleNoChildren
rename L_Dhhtp_c4_4 L_Dhhtp_c4_SingleChildren

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

gen L_Ydses_c5 = l_ydses_c5

gen L_Dhe = l_dhe

gen Dlltsd = dlltsd

* Set data 
xtset idperson swv


* Set Excel file 
* Info sheet
putexcel set "$dir_work/reg_health_${country}", sheet("Info") replace
putexcel A1 = "Description:"
putexcel B1 = "Model parameters governing projection self-reported health status"

putexcel A4 = "Process:", bold
putexcel B4 = "Description:", bold
putexcel A5 = "H1a"
putexcel B5 = "Generalized ordered logit regression estimates of self reported health status - individuals aged 16-29 in initial education spell"
putexcel B6 = "Covariates that satisfy the parallel lines assumption have one estimate for all categories of the dependent variable and are present once in the table"
putexcel B7 = "Covariates that do not satisfy the parallel lines assumption have an estimate for each estimated category of the dependent variable. These covariates have the dependent variable category appended to their name."
putexcel A8 = "H1b"
putexcel B8 = "Generalized ordered logit regression estimates of self reported health status - individuals aged 16+ not in initial education spell"
putexcel B9 = "Covariates that satisfy the parallel lines assumption have one estimate for all categories of the dependent variable and are present once in the table"
putexcel B10 = "Covariates that do not satisfy the parallel lines assumption have an estimate for each estimated category of the dependent variable. These covariates have the dependent variable category appended to their name."
putexcel A11 = "H2b"
putexcel B11 = "Probit regression estimates of the probability of being long-term sick or disabled - people aged 16+ not in initial education spell"
putexcel A12 = "H1a_raw"
putexcel B12 = "Raw generalized ordered logit regression estimates of self reported health status - individuals aged 16-29 in initial education spell. Useful for the 'Gologit predictor' file."
putexcel A13 = "H1b_raw"
putexcel B13 = "Raw generalized ordered logit regression estimates of self reported health status - individuals aged 16+ not in initial education spell. Useful for the 'Gologit predictor' file."

putexcel A15 = "Notes:", bold
putexcel B15 = "Regions: EL3 = Attika (omitted), EL4 = Aegean Islands, EL7 = Central and Northern Greece"

putexcel set "$dir_work/reg_health_${country}", sheet("Gof") modify
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
/*			
gologit2 dhe i.dgn dag dagsq l_ydses_c5 l_dhe i.drgn1 stm if ///
	dag >= 16 & dag <= 29 & ded == 1 & dhe_flag != 1 [pweight = dimxwt], autofit
*/
	
gologit2 dhe i.Dgn Dag Dag_sq L_Ydses_c5 L_Dhe i.EL4 i.EL7 ///
	Y2022_2023 if dag >= 16 & dag <= 29 & ded == 1 & dhe_flag != 1 ///
	[pweight = dimxwt], autofit
	
* Save sample inclusion indicator and predicted probabilities		
gen in_sample = e(sample)
predict p1 p2 p3 p4 p5
	
* Save sample for later use (internal validation)	
save "$dir_data/H1a_sample", replace

* Store model summary statistics
scalar r2_p = e(r2_p) 
scalar N_sample = e(N)	 
	
	
* Store results in Excel 

* Store estimates in matrices
matrix b = e(b)	
matrix V = e(V)

* Raw output 
putexcel set "$dir_work/reg_health_${country}", sheet("H1a_raw") modify
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

	// Inspect
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
scalar no_nonzero_b_per = no_nonzero_b / 4 // number of categories-1 

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

* Generate vector to multiply the coef vector with to eliminate the 
* repetitions of coefficients for vars that satify the proportional odds assumptions
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
putexcel set "$dir_work/reg_health_${country}", sheet("H1a") modify
putexcel A1 = matrix(nonzero_b_structure'), names nformat(number_d2) 


* Variance-covariance matrix 
* ELiminate zeros (baseline categories)
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
putexcel set "$dir_work/reg_health_${country}", sheet("H1a") modify
putexcel C2 = matrix(nonzero_var_structure)
		
			
* Labels
putexcel set "$dir_work/reg_health_${country}", sheet("H1a") modify

putexcel A1 = "REGRESSOR"
putexcel B1 = "COEFFICIENT"

* Create temporary frame
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
		// Address lags
		labels_no_bl = regexm(varnames_no_bl, "^L_") :* (regexr(varnames_no_bl, "^L_", "") :+ "_L1") :+ (!regexm(varnames_no_bl, "^L_") :* varnames_no_bl)
		
		// Add category 
		labels_no_bl = labels_no_bl :+ "_" :+ (catnames_no_bl :* (unique_flag[1::rows(labels_no_bl)] :!= 0))
		
		// Remove 1. 
		labels_no_bl = usubinstr(labels_no_bl, "1.", "", 1)
		
		// Constant 
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
    putexcel set "$dir_work/reg_health_${country}", sheet("H1a") modify
	
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
putexcel set "$dir_work/reg_health_${country}", sheet("Gof") modify

putexcel A3 = "H1a - Health status, in initial education spell", bold		

putexcel A5 = "Pseudo R-squared" 
putexcel B5 = r2_p 
putexcel A6 = "N"
putexcel B6 = N_sample
		
* Clean up 		
drop in_sample p1 p2 p3 p4 p5 
scalar drop _all
matrix drop _all
frame drop temp_frame 	


******************************************************
* Process H1b: Health status, left intital edu spell *
******************************************************

* Process H1b: Probability of each self-rated health status for those who 
* 				have left their initial education spell 
* Sample: 16 or older who have left their initial education spell 
* DV: Categorical health status (5)

* Generalized ordered logit	
sort idperson swv
/*		
gologit2 dhe i.dgn dag dagsq ib1.deh_c3 i.l_les_c3 i.l_ydses_c5 ///
	ib5.l_dhe ib1.l_dhhtp_c4 i.drgn1 stm y2021 if dhe_flag != 1 & ///
	dag >= 16 & ded == 0 [pweight = dimxwt], autofit
*/
	
gologit2 dhe i.Dgn Dag Dag_sq i.Deh_c3_Medium i.Deh_c3_Low ///
	i.L_Les_c3_Student i.L_Les_c3_NotEmployed i.L_Ydses_c5_Q2 ///
	i.L_Ydses_c5_Q3 i.L_Ydses_c5_Q4 i.L_Ydses_c5_Q5 ///
	i.L_Dhe_c5_1 i.L_Dhe_c5_2 i.L_Dhe_c5_3 i.L_Dhe_c5_4 ///
	i.L_Dhhtp_c4_CoupleChildren i.L_Dhhtp_c4_SingleNoChildren ///
	i.L_Dhhtp_c4_SingleChildren ///
	i.EL4 i.EL7 Y2012-Y2021 Y2022_2023 if dhe_flag != 1 & ///
	dag >= 16 & ded == 0 [pweight = dimxwt], autofit
	
* Save sample inclusion indicator and predicted probabilities		
gen in_sample = e(sample)	
predict p1 p2 p3 p4 p5 

* Save sample for later use (internal validation)
save "$dir_data/H1b_sample", replace

* Store model summary statistics
scalar r2_p = e(r2_p) 
scalar N_sample = e(N)	 

* Store results in Excel 

* Store estimates in matrices
matrix b = e(b)	
matrix V = e(V)

* Raw output 
putexcel set "$dir_work/reg_health_${country}", sheet("H1b_raw") modify
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

	// Inspect
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
scalar no_nonzero_b_per = no_nonzero_b / 4 // number of categories-1 

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
				if (i != j && abs(nonzero_b_mata[i] - nonzero_b_mata[j]) < tol){
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
putexcel set "$dir_work/reg_health_${country}", sheet("H1b") modify
putexcel A1 = matrix(nonzero_b_structure'), names nformat(number_d2) 


* Variance-covariance matrix 
* ELiminate zeros (baseline categories)
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
putexcel set "$dir_work/reg_health_${country}", sheet("H1b") modify
putexcel C2 = matrix(nonzero_var_structure)
		
			
* Labels
putexcel set "$dir_work/reg_health_${country}", sheet("H1b") modify

putexcel A1 = "REGRESSOR"
putexcel B1 = "COEFFICIENT"

* Create temporary frame
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
		// Address lags
		labels_no_bl = regexm(varnames_no_bl, "^L_") :* (regexr(varnames_no_bl, "^L_", "") :+ "_L1") :+ (!regexm(varnames_no_bl, "^L_") :* varnames_no_bl)
		labels_no_bl = regexm(varnames_no_bl, "^1.L_") :* (regexr(varnames_no_bl, "^1.L_", "") :+ "_L1") :+ (!regexm(varnames_no_bl, "^1.L_") :* varnames_no_bl)

		// Add category 
		labels_no_bl = labels_no_bl :+ "_" :+ (catnames_no_bl :* (unique_flag[1::rows(labels_no_bl)] :!= 0))
		
		// Remove 1. 
		labels_no_bl = usubinstr(labels_no_bl, "1.", "", 1)
		
		// Constant 
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
    import delimited "$dir_work/temp_labels.txt", clear varnames(1) ///
		encoding(utf8)
	gen n = _n
    
    * Export labels to Excel
    putexcel set "$dir_work/reg_health_${country}", sheet("H1b") modify
	
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
putexcel set "$dir_work/reg_health_${country}", sheet("Gof") modify

putexcel A9 = "H1b - Health status, left initial education spell", bold		

putexcel A11 = "Pseudo R-squared" 
putexcel B11 = r2_p 
putexcel A12 = "N"
putexcel B12 = N_sample
		
* Clean up 		
drop in_sample p1 p2 p3 p4 p5 
scalar drop _all
matrix drop _all
frame drop temp_frame 

	
***********************************************************
* H2b: Long-term sick or disabled, left initial edu spell *
***********************************************************
xtset idperson stm
* Process H2a: Probability of being long-term sick or disabled for those 
* 				not in continuous education.
* Sample: 16 or older who have left their initial education spell 
* DV: Long term sick/disabled dummy
fre dlltsd if (dag >= 16 & ded == 0)

/*
probit dlltsd i.dgn dag dagsq ib1.deh_c3 li.ydses_c5 ib5.dhe ilb5.dhe ///
	l.dlltsd lib1.dhhtp_c4 i.drgn1 stm y2020 y2021 if (dag >= 16 & ded == 0) ///
	[pweight = dimxwt], vce(robust)	
*/	
probit dlltsd i.Dgn Dag Dag_sq i.Deh_c3_Medium i.Deh_c3_Low ///
	li.Ydses_c5_Q2 li.Ydses_c5_Q3 li.Ydses_c5_Q4 li.Ydses_c5_Q5 ///
	i.Dhe_Poor i.Dhe_Fair i.Dhe_Good i.Dhe_VeryGood ///
	li.Dhe_Poor li.Dhe_Fair li.Dhe_Good li.Dhe_VeryGood ///
	l.Dlltsd li.Dhhtp_c4_CoupleChildren li.Dhhtp_c4_SingleNoChildren ///
	li.Dhhtp_c4_SingleChildren /// 
	i.EL4 i.EL7 Y2012-Y2021 Y2022_2023  if (dag >= 16 & ded == 0) ///
	[pweight = dimxwt], vce(robust)
	
* Save sample inclusion indicator and predicted probabilities	
gen in_sample = e(sample)	
predict p

* Save sample for later use (internal validation)
save "$dir_data/H2b_sample", replace

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
putexcel set "$dir_work/reg_health_${country}", sheet("H2b") modify
putexcel B2 = matrix(b_trimmed)
putexcel C2 = matrix(V_trimmed)


* Labels 
putexcel set "$dir_work/reg_health_${country}", sheet("H2b") modify

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
	putexcel set "$dir_work/reg_health_${country}", sheet("H2b") modify
	
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
putexcel set "$dir_work/reg_health_${country}", sheet("Gof") modify

putexcel A15 = "H2b -  Long-term sick or disabled, left initial edu spell", bold		
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

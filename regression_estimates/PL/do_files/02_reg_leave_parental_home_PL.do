/*******************************************************************************
* PROJECT:  		SimPaths EU
* SECTION:			Leaving the Parental Home
* OBJECT: 			Probit Model 
* AUTHORS:			Daria Popova, Justin van de Ven, Ashley Burdett
* LAST UPDATE:		Oct 2025
* COUNTRY: 			Poland  
* 
* NOTES: 			Process only estiamted on those who have left their initial 
* 					education spell. 
* 					Definition of the dependent variable aligns with that of
*					the adult child flag. 
*
*					https://notesfrompoland.com/2024/07/03/one-third-of-poles-aged-25-34-live-with-parents/?utm_source=chatgpt.com
* 
*******************************************************************************/
clear all
set more off
set mem 200m
set type double
//set maxvar 120000
set maxvar 30000


cap log close 
//log using "$dir_log/reg_leaveParentalHome.log", replace


use "$dir_input_data/${country}-SILC_pooled_all_obs_02.dta", clear

* Sample selection 
drop if dag < 16

* Adjust variables 
replace stm = stm - 2000

gen y2020 = (stm == 20)
gen y2021 = (stm == 21)
gen y2018 = (stm == 18)

* Ensure missing is missing
recode dlftphm dgn dag dagsq deh_c3 les_c4 les_c3 ydses_c5 drgn1 stm (-9=.) 

* Labeling and formating variables
label def jbg 1 "Employed" 2 "Student" 3 "Not employed" 4 "Retired"
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
label var les_c4 "Employment Status: 4 Category" 
label var dhe "Self-rated Health"
label var deh_c3 "Educational Attainment: 3 Category"
label var ydses_c5 "Annual Household Income Quintile" 
label var dlltsd "Long-term Sick or Disabled"

label val dgn gdr
label val drgn1 rgna
label val dhhtp_c4 hht 
label val les_c4 jbg 
label val deh_c3 edd 
label val ded yn

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

tab les_c3, gen(Les_c3_)
rename Les_c3_1 Les_c3_Employed
rename Les_c3_2 Les_c3_Student
rename Les_c3_3 Les_c3_NotEmployed

tab ydses_c5, gen(Ydses_c5_Q)

gen Dnc = dnc

gen Dnc02 = dnc02

gen Year_transformed = stm  

gen Y2018 = y2018
gen Y2020 = y2020  
gen Y2021 = y2021 

* Set data 
xtset idperson swv


* Set Excel file 
* Info sheet
putexcel set "$dir_work/reg_leave_parental_home_${country}", sheet("Info") ///
	replace
putexcel A1 = "Description:"
putexcel B1 = "Model parameters governing leaving parental home process"

putexcel A4 = "Process:", bold
putexcel B4 = "Description:", bold
putexcel A5 = "P1a"
putexcel B5 = "Probit regression estimates for leaving the parental home - [S] not in initial education spell, [DV] adult child in t-1 to be eligable, not adult child in t if transition."

putexcel A10 = "Notes:", bold
putexcel B10 = "Regions: PL4 = Polnocno-Zachodni, PL5 = Poludniowo-Zachodni, PL6 = Polnocy, PL10 = Central + East. Poludniowy is the omitted category."
putexcel B11 = "Data, longitudinal EU-SILC using information from 2010 (lagged info)-2023. "


putexcel set "$dir_work/reg_leave_parental_home_${country}", sheet("Gof") modify
putexcel A1 = "Goodness of fit", bold		


********************************************************************************
* Process P1a: Leave Parental Home 
********************************************************************************
* Process P1a: Probability of leaving the parental home. 
* Sample: All respondents adult child in t-1 and not currently in initial 
* 			education spell 
* DV: Observed transitioning from adult child to non-adult child

xtset idperson swv		
fre dlftphm if (ded == 0 & dag >= 18) 
	
/*
probit dlftphm i.dgn dag dagsq ib1.deh_c3 li.les_c3 li.ydses_c5 i.drgn1 stm ///
	y2020 if (ded == 0 & dag >= 18 & dcpst != 1) [pweight = dimxwt], ///
	vce(robust)
*/
probit dlftphm i.Dgn Dag Dag_sq i.Deh_c3_Medium i.Deh_c3_Low ///
	li.Les_c3_Student li.Les_c3_NotEmployed li.Ydses_c5_Q2 li.Ydses_c5_Q3 ///
	li.Ydses_c5_Q4 li.Ydses_c5_Q5 $regions Year_transformed ///
	i.Y2018 i.Y2020 i.Y2021 if (ded == 0 & dag < 60) [pw = dimxwt], vce(robust)
	
* Save sample inclusion indicator and predicted probabilities	
gen in_sample = e(sample)	
predict p

* Save sample for later use (internal validation)
save "$dir_data/P1a_sample", replace
	
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
putexcel set "$dir_work/reg_leave_parental_home_${country}", sheet("P1a") modify
putexcel B2 = matrix(b_trimmed)
putexcel C2 = matrix(V_trimmed)


* Labels 
putexcel set "$dir_work/reg_leave_parental_home_${country}", sheet("P1a") modify

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
	putexcel set "$dir_work/reg_leave_parental_home_${country}", ///
		sheet("P1a") modify
	
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
putexcel set "$dir_work/reg_leave_parental_home_${country}", sheet("Gof") modify

putexcel A3 = "P1a - Leaving the parental home ", bold		

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

capture log close 

cap erase "$dir_work/temp.dta"


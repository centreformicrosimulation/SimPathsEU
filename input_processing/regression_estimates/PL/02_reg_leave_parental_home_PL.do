/*******************************************************************************
* PROJECT:  		SimPaths EU
* SECTION:			Leaving the Parental Home
* OBJECT: 			Probit Model 
* AUTHORS:			Daria Popova, Justin van de Ven, Ashley Burdett
*					Aleksandra Kolndrekaj 
* LAST UPDATE:		January 2026
* COUNTRY: 			Poland  
********************************************************************************
* NOTES: 			
*				https://notesfrompoland.com/2024/07/03/one-third-of-poles-aged-25-34-live-with-parents/?utm_source=chatgpt.com
* 
*******************************************************************************/

clear all
set more off
set mem 200m
set type double
set maxvar 30000

* Set off log 
cap log close 
log using "$dir_log/reg_leaveParentalHome.log", replace

			
/********************************* SET EXCEL FILE *****************************/

* Info sheet
putexcel set "$dir_work/reg_leave_parental_home_${country}", sheet("Info") ///
	replace
putexcel A1 = "Description:", bold
putexcel B1 = "Model parameters governing leaving parental home process"

putexcel A2 = "Authors:", bold
putexcel B2 = "Ashley Burdett, Aleksandra Kolndrekaj" 	
putexcel A3 = "Last edit:", bold
putexcel B3 = "12 Jan 2016 AB"

putexcel A5 = "Process:", bold
putexcel B5 = "Description:", bold
putexcel A6 = "P1"
putexcel B6 = "Probit regression estimates for leaving the parental home, transitioning out of adult child status"

putexcel A11 = "Notes:", bold
putexcel B11 = "Regions: PL4 = Polnocno-Zachodni, PL5 = Poludniowo-Zachodni, PL6 = Polnocy, PL10 = Central + East. Poludniowy is the omitted category." 
putexcel B11 = "DV is synchronised with the adult child definition"

putexcel set "$dir_work/reg_leave_parental_home_${country}", sheet("Gof") modify
putexcel A1 = "Goodness of fit", bold		


/********************************* PREPARE DATA *******************************/

* Load data
use "$dir_input_data/${country}_pooled_ipop", clear

* Ensure missing is missing 
recode dlftphm ded dgn dag drgn1 stm deh_c3 deh_c4 les_c4 les_c3 ydses_c5 ///
	(-9=.) 

* Set data 
xtset idperson swv
sort idperson swv 

* Remove children 
drop if dag < 15

* Adjust variables 
* Time variables 
* Centre year around 2000 
replace stm = stm - 2000

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


* Labeling and formating variables
label def jbg 1 "Employed" 2 "Student" 3 "Not employed" 4 "Retired"
label def edd 1 "Degree"	2 "High school" ///
				3 "Other/No Qualification"
label def hht 1 "Couples with No Children" 2 "Couples with Children" ///
				3 "Single with No Children" 4 "Single with Children"
label def gdr 1  "Male" 0 "Female"
label def yn	1 "Yes" 0 "No"

label val dgn gdr
label val drgn1 rgna
label val dhhtp_c4 hht 
label val les_c4 jbg 
label val deh_c3 edd 
label val ded yn

label var dgn "Gender"
label var dag "Age"
label var dagsq "Age Squared"
label var drgn1 "Region"
label var dhhtp_c4 "Household Type: 4 Category"
label var stm "Year"
label var les_c4 "Employment Status: 4 Category" 
label var dhe "Self-rated Health"
label var deh_c3 "Educational Attainment: 3 Category"
label var deh_c4 "Educational Attainment: 4 Category"
label var ydses_c5 "Annual Household Income Quintile" 
label var dlltsd "Long-term Sick or Disabled"

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

tab ydses_c5, gen(Ydses_c5_Q)

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


/********************************** ESTIMATION ********************************/

/**************** P1: PROBABILITY OF LEAVING THE PARENTAL HOME ****************/

xtset idperson swv		
fre dlftphm if (ded == 0 & dag >= 18) 
	
* Estimation
probit dlftphm i.Dgn Dag Dag_sq i.Deh_c3_Medium i.Deh_c3_Low ///
	li.Les_c3_Student li.Les_c3_NotEmployed li.Ydses_c5_Q2 li.Ydses_c5_Q3 ///
	li.Ydses_c5_Q4 li.Ydses_c5_Q5 $regions Year_transformed ///
	Year_transformed_sq i.Y2016 i.Y2018 if ${p1_if_condition} [pw=dwt], ///
	vce(robust)
	
	
* Save raw results 
matrix results = r(table)
matrix results = results[1..6,1...]'

putexcel set "$dir_raw_results/leave_parental_home/leave_parental_home", ///
	sheet("Process P1") replace
putexcel A3 = matrix(results), names nformat(number_d2) 
putexcel J4 = matrix(e(V))

outreg2 stats(coef se pval) using ///
	"$dir_raw_results/leave_parental_home/P1.doc", replace ///
title("Process P1: Probability Leave the Parental Home") ///
	ctitle(Leave home) label side dec(2) noparen ///
	addstat(R2, e(r2_p), Chi2, e(chi2), Log-likelihood, e(ll)) ///
	addnote(`"Note: Regression if condition = (${p1_if_condition})"')	
	
* Save sample inclusion indicator and predicted probabilities	
gen in_sample = e(sample)	
predict p

* Save sample for estiamte validation
save "$dir_data/P1_sample", replace
	
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
putexcel set "$dir_work/reg_leave_parental_home_${country}", sheet("P1") modify
putexcel B2 = matrix(b_trimmed)
putexcel C2 = matrix(V_trimmed)


* Labels 
putexcel set "$dir_work/reg_leave_parental_home_${country}", sheet("P1") modify

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
		sheet("P1") modify
	
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

putexcel A3 = "P1 - Leaving the parental home ", bold		

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


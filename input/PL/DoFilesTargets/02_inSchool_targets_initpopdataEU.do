/*******************************************************************************
* PROJECT:        SimPaths EU
* SECTION:        ALIGNMENT PROCEDURES
*
* AUTHORS:        Codex
* LAST UPDATE:    11/03/2026
* COUNTRY:        EU
*
* DATA:           Initial populations
*
* DESCRIPTION:    This do-file constructs student targets for different
*                groups of the population using initial population data.
*                It:
*                  - Imports initial population CSV files by year
*                  - Computes student ratio to total population for each year
*                  - Exports the results to Excel
*
* NOTE:           This EU version uses legacy variable names from the initial
*                populations (e.g., idperson, dag, les_c4, dwt).
*
* SET-UP:         1. Update the working directory path (global dir_w)
*                 2. Copy the relevant input data into the /input_data folder
*                    under the country-specific subdirectory
*
*******************************************************************************/

clear all


* --- DEFINE GLOBALS -------------------------------------------------------- *

* Working directory (project root)
//global dir_w "/Users/pineapple/Library/CloudStorage/OneDrive-UniversityofEssex/WorkCEMPA/SimPathsEU/SimPathsTargets"
global dir_w "/Users/pineapple/IdeaProjects/SimPathsEU_APR"

* Country code and time span for which targets are produced
global country = "PL"
global min_year 2011
global max_year 2023

* Directory structure
global dir_input_data   "$dir_w/input/${country}/InitialPopulations"
global dir_working_data "$dir_w/input/${country}/DoFilesTargets/working_data"
global dir_output       "$dir_w/input/${country}/DoFilesTargets"

* Initialise file that will store student shares for all years
clear
save "${dir_working_data}/student_shares_${country}_initpopdata.dta", emptyok replace

* ========================================================================== *

// Loop over all years in the requested range
foreach y of numlist $min_year/$max_year {

	* Build file name for the given year and import initial population data
	local file = subinstr("population_initial_${country}_YYYY.csv","YYYY","`y'",.)
	import delimited using "${dir_input_data}/`file'", clear

	bys idperson: keep if _n == 1 // keep one obs per idperson

	// Alignment target: share of students among 16-29 age group, defined in SimPathsModel.java
	gen byte isStudent = (les_c4 == 2 & dag >= 16 & dag <= 29)
    collapse (mean) student_share = isStudent if (les_c4 != . & dag >= 16 & dag <= 29) [pw = dwt]

	gen year = `y'

	* Append to cumulative file for all years
	append using "${dir_working_data}/student_shares_${country}_initpopdata.dta"
	duplicates drop
	save "${dir_working_data}/student_shares_${country}_initpopdata.dta", replace

}

* -------------------------------------------------------------------------- *
* POST-PROCESSING: export aggregated results to Excel
* -------------------------------------------------------------------------- *


use "${dir_working_data}/student_shares_${country}_initpopdata.dta", clear

* Sort by year for neat export
sort year

* Create/overwrite Excel file that will hold all sheets
putexcel set "${dir_output}/alignment_targets_inSchool.xlsx", replace


* Build separate matrices for year and share (written with explicit Excel formats)
mkmat year,          matrix(Yr)
mkmat student_share, matrix(Sh)

* Point putexcel at the output file and the group-specific sheet
putexcel set "${dir_output}/alignment_targets_inSchool.xlsx", sheet("students") modify

* Write headers
putexcel A1=("year") B1=("student_share")

* Write data: years as integers, shares with 7 decimal places
putexcel A2=matrix(Yr), nformat("0")
putexcel B2=matrix(Sh), nformat("0.000000")

* --- INFO SHEET ------------------------------------------------------------ *
local today "`c(current_date)'"
putexcel set "${dir_output}/alignment_targets_inSchool.xlsx", sheet("info") modify
putexcel A1=("Field")       B1=("Value")
putexcel A2=("Target")      B2=("Share of students among persons aged 16-29 with non-missing labour status")
putexcel A3=("Population")  B3=("Persons aged 16-29 with non-missing les_c4")
putexcel A4=("Definition")  B4=("les_c4 == 2 (Student) & dag >= 16 & dag <= 29")
putexcel A5=("Age filter")  B5=("16-29 (matching SimPathsModel inSchool alignment window)")
putexcel A6=("Weighting")   B6=("Population weights (dwt)")
putexcel A7=("Source")      B7=("EU-SILC-based SimPaths initial populations")
putexcel A8=("Country")     B8=("${country}")
putexcel A9=("Years")       B9=("${min_year}-${max_year}")
putexcel A10=("Do-file")    B10=("02_inSchool_targets_initpopdataEU.do")
putexcel A11=("Produced")   B11=("`today'")


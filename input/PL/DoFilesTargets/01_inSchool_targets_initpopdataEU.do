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
global dir_w "/Users/pineapple/Library/CloudStorage/OneDrive-UniversityofEssex/WorkCEMPA/SimPathsEU/inSchool_targets_GitHub"


* Country code and time span for which targets are produced
global country = "PL"
global min_year 2011
global max_year 2023

* Directory structure
global dir_input_data   "$dir_w/${country}/input_data"
global dir_working_data "$dir_w/${country}/working_data"
global dir_output       "$dir_w/${country}"


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
putexcel set "${dir_output}/inSchool_targets.xlsx", replace


* Build a matrix of all rows for the two variables (year, student_share)
mkmat year student_share, matrix(M)

* Point putexcel at the output file and the group-specific sheet
putexcel set "${dir_output}/inSchool_targets.xlsx", sheet("students") modify

* Write headers
putexcel A1=("year") B1=("student_share")

* Write data from matrix M (Stata 15+ supports varlists here)
putexcel A2=matrix(M)


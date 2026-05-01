********************************************************************************
* PROJECT:  		SimPaths EU  
* SECTION:			Validation of estimates
* OBJECT: 			Master
* AUTHORS:			Ashley Burdett, Aleksandra Kolndrekaj 
* LAST UPDATE:		Jan 2026
* COUNTRY: 			Poland  
********************************************************************************
* NOTES: 			
********************************************************************************

clear all
set more off
macro drop _all 
set type double
set maxvar 30000
set matsize 1000


/*******************************************************************************
* DEFINE DIRECTORIES
*******************************************************************************/

//*C:/Users/Aleksandra/Box
//*/Users/ashleyburdett/Library/CloudStorage/Box-Box/CeMPA shared area/_SimPaths/_SimPathsEU/validation/01_estimate_validation/PL/TIDIED/with_time_trend

* Individual main path 
global dir_ind "/Users/ashleyburdett/Library/CloudStorage/Box-Box"


* Working directory which contains sub-folders and will contain formatted output 
global dir_work "/Users/ashleyburdett/Library/CloudStorage/Box-Box/CeMPA shared area/_SimPaths/_SimPathsEU/validation/01_estimate_validation/PL/with_time_trend"

* Directory which contains do files
global dir_do "$dir_work/do_files"

* Directory which contains data files generated in the do files 
global dir_data "/Users/ashleyburdett/Library/CloudStorage/Box-Box/CeMPA shared area/_SimPaths/_SimPathsEU/input_processing/regression_estimates/PL/with_time_trend/data"

* Directory containing internal validation output
global dir_internal_validation "$dir_work/graphs"


/*******************************************************************************
* DEFINTE PARAMETERS
*******************************************************************************/

global country "PL"

global first_sim_year "2011"

global last_sim_year "2023"


/*******************************************************************************
* DEFINE PARAMETERS & PROCESS IF CONDITIONS 
*******************************************************************************/

do "$dir_ind/CeMPA shared area/_SimPaths/_SimPathsEU/input_processing/00_master_conditions.do"


/*******************************************************************************
* RUN FILES
*******************************************************************************/

do "$dir_do/01_estimate_validation_education_PL.do"

do "$dir_do/02_estimate_validation_leave_parental_home_PL.do"

do "$dir_do/03_estimate_validation_partnership_PL.do"

do "$dir_do/04_estimate_validation_fertility_PL.do"

do "$dir_do/05_estimate_validation_health_PL.do"

do "$dir_do/06_estimate_validation_home_ownership_PL.do"

do "$dir_do/07_estimate_validation_retirement_PL.do"

do "$dir_do/08_estimate_validation_wages_PL.do"

do "$dir_do/09_estimate_validation_income_PL.do"



********************************************************************************
* PROJECT:              SimPaths EU 
* DO-FILE NAME:         00_master_PL.do
* DESCRIPTION:          Main do-file to set estimates the parameters for 
* 							SimPaths for Poland using EU-SILC.
********************************************************************************
* COUNTRY:              Poland
* DATA:         	    GESIS - EU SILC			
* AUTHORS: 				Daria Popova, Justin van de Ven, Ashley Burdett
* LAST UPDATE:          June 2025

* NOTES: 				Discrepancies with ordered logit estiamtes 
* 						(E2a, H1a H1b) 
* 
* 						
********************************************************************************

* Stata packages to install 
/*
ssc install fre
ssc install tsspell 
ssc install carryforward 
ssc install outreg2
*/

clear all
set more off
macro drop _all 
set type double
set maxvar 30000
set matsize 1000


/*******************************************************************************
* DEFINE DIRECTORIES
*******************************************************************************/

* Working directory which contains sub-folders and will contain formatted output 
global dir_work "/Users/ashleyburdett/Library/CloudStorage/Box-Box/CeMPA shared area/_SimPaths/_SimpathsEU/regression_estimates/PL"

//"/Users/ashleyburdett/Documents/ESPON/PL/regression_estimates"
//"/Users/ashleyburdett/Library/CloudStorage/Box-Box/CeMPA shared area/ESPON - OVERLAP/_countries/PL/regression_estimates"

* Directory which contains do files
global dir_do "$dir_work/do_files"

* Directory which contains data files generated in the do files 
global dir_data "$dir_work/data"

* Directory which contains log files 
global dir_log "$dir_work/logs"

* Directory which contains raw results
global dir_results "$dir_work/raw_results"

* Directory which contains EU-SILC input dataset
global dir_input_data "/Users/ashleyburdett/Library/CloudStorage/Box-Box/CeMPA shared area/_SimPaths/_SimPathsEU/initial_populations/PL/data"

* Directory containing external input data 
global dir_external_data "/Users/ashleyburdett/Library/CloudStorage/Box-Box/CeMPA shared area/projects - completed/ESPON - OVERLAP/_countries/PL/regression_estimates/external_data"

* Directory containing internal validation output
global dir_internal_validation "$dir_work/internal_validation/graphs"


/*******************************************************************************
* GLOBALS
*******************************************************************************/

global country "PL"


/*******************************************************************************
* ESTIMATION FILES
*******************************************************************************/

do "$dir_do/01_reg_education_${country}.do"	

do "$dir_do/02_reg_leave_parental_home_${country}.do"

do "$dir_do/03_reg_partnership_${country}.do"

do "$dir_do/04_reg_fertility_${country}.do"
 
do "$dir_do/05_reg_health_${country}.do"	

do "$dir_do/06_reg_home_ownership_${country}.do"

do "$dir_do/07_reg_retirement_${country}.do"

do "$dir_do/08_reg_wages_${country}.do"

do "$dir_do/09_reg_income_${country}.do"

do "$dir_do/10_parametric_matching_process_${country}.do"


/*******************************************************************************
* INTERNAL VALIDATION FILES
*******************************************************************************/

do "$dir_work/dir_internal_validation/01_int_val_education_${country}.do"	

do "$dir_work/dir_internal_validation/02_int_val_leave_parental_home_${country}.do"	

do "$dir_work/dir_internal_validation/03_int_val_partnership_${country}.do"	

do "$dir_work/dir_internal_validation/04_int_val_fertility_${country}.do"	

do "$dir_work/dir_internal_validation/05_int_val_health_${country}.do"	

do "$dir_work/dir_internal_validation/06_int_val_home_ownership_${country}.do"	

do "$dir_work/dir_internal_validation/07_int_val_retirement_${country}.do"	

do "$dir_work/dir_internal_validation/08_int_val_wages_${country}.do"	

do "$dir_work/dir_internal_validation/07_int_val_income_${country}.do"	



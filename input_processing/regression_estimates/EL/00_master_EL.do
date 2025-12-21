********************************************************************************
* PROJECT:              ESPON 
* DO-FILE NAME:         00_master_EL.do
* DESCRIPTION:          Main do-file to set estimates the parameters for 
* 							SimPaths for Greece using EU-SILC.
********************************************************************************
* COUNTRY:              Greece
* DATA:         	    GESIS - EU SILC			
* AUTHORS: 				Daria Popova, Justin van de Ven, Ashley Burdett
* LAST UPDATE:          April 2025

* NOTES: 				Output formatting automated. 
* 						The income and union parameter do file must be run after
* 						the wage estimates are obtain because they use 
* 						predicted wages. The order of the remaining files is
* 						arbitrary. 
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
global dir_work "/Users/ashleyburdett/Library/CloudStorage/Box-Box/CeMPA shared area/ESPON - OVERLAP/_countries/EL/regression_estimates"

* Directory which contains do files
global dir_do "$dir_work/do_files"

* Directory which contains data files generated in the do files 
global dir_data "$dir_work/data"

* Directory which contains log files 
global dir_log "$dir_work/logs"

* Directory which contains EU-SILC input dataset
global dir_input_data "/Users/ashleyburdett/Library/CloudStorage/Box-Box/CeMPA shared area/ESPON - OVERLAP/_countries/EL/initial_populations/data"
//"/Users/ashleyburdett/Library/CloudStorage/Box-Box/ESPON - OVERLAP/_countries/EL/initial_populations/data"

* Directory containing external input data 
global dir_external_data "$dir_work/external_data"

* Directory containing internal validation do files 
global dir_do_internal_validation "$dir_work/internal_validation/do_files"

* Directory containing internal validation graphs 
global dir_internal_validation "$dir_work/internal_validation/graphs"


/*******************************************************************************
* SET GLOBALS
*******************************************************************************/

global country "EL"


/*******************************************************************************
* ESTIMATION FILES
*******************************************************************************/

do "$dir_do/01_reg_education_EL.do"	

do "$dir_do/02_reg_leave_parental_home_EL.do"

do "$dir_do/03_reg_partnership_EL.do"

do "$dir_do/04_reg_fertility_EL.do"
 
do "$dir_do/05_reg_health_EL.do"	

do "$dir_do/06_reg_home_ownership_EL.do"

do "$dir_do/07_reg_retirement_EL.do"

do "$dir_do/08_reg_wages_EL.do"

do "$dir_do/09_reg_income_EL.do"

do "$dir_do/10_parametric_matching_process_EL.do"


/*******************************************************************************
* INTERNAL VALIDATION FILES
*******************************************************************************/

do "$dir_do_internal_validation/01_int_val_education_EL.do"	

do "$dir_do_internal_validation/02_int_val_leave_parental_home_EL.do"	

do "$dir_do_internal_validation/03_int_val_partnership_EL.do"	

do "$dir_do_internal_validation/04_int_val_fertility_EL.do"	

do "$dir_do_internal_validation/05_int_val_health_EL.do"	

do "$dir_do_internal_validation/06_int_val_home_ownership_EL.do"	

do "$dir_do_internal_validation/07_int_val_retirement_EL.do"	

do "$dir_do_internal_validation/08_int_val_wages_EL.do"	

do "$dir_do_internal_validation/09_int_val_income_EL.do"	

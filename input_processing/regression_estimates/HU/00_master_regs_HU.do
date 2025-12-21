********************************************************************************
* PROJECT:              ESPON 
* DO-FILE NAME:         master_regs_HU.do
* DESCRIPTION:          Main do-file to set estimates the parameters for 
* 							SimPaths for Hungary using EU-SILC.
********************************************************************************
* COUNTRY:              Hungary
* DATA:         	    GESIS - EU SILC			
* AUTHORS: 				Daria Popova, Justin van de Ven, Ashley Burdett
* LAST UPDATE:          24 March 2025

* NOTES: 				Output formatting automated, however if you decide to 
* 						add or take-away variables from the processes you 
* 						will need to update the labelling in the excel files. 
* 						Further the excel files containing the genernalized
* 				 		ordered logit estimates (education and health) requires
* 		 				manual formattting as noted in the top of the 
* 						relevant do files. 
* 						The income and union parameter do file must be run after
* 						the wage estimates are obtain because they use 
* 						predicted wages. The order of the remaining files is
* 						arbitrary. 
********************************************************************************

* Install Stata packages

ssc install fre
ssc install tsspell 
ssc install carryforward 
ssc install outreg2

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
global dir_work "/Users/ashleyburdett/Library/CloudStorage/Box-Box/CeMPA shared area/ESPON - OVERLAP/_countries/HU/regression_estimates"

* Directory which contains do files
global dir_do "$dir_work/do_files"

* Directory which contains data files generated in the do files 
global dir_data "$dir_work/data"

* Directory which contains log files 
global dir_log "$dir_work/logs"

* Directory which contains raw results
global dir_results "$dir_work/raw_results"

* Directory which contains EU-SILC input dataset
global dir_input_data "/Users/ashleyburdett/Library/CloudStorage/Box-Box/CeMPA shared area/ESPON - OVERLAP/_countries/HU/initial_populations/data"

* Directory containing external input data 
global dir_external_data "$dir_work/external_data"

* Directory containing internal validation 
global dir_internal_validation "$dir_work/internal_validation/graphs"


/*******************************************************************************
* ESTIMATION FILES
*******************************************************************************/

do "$dir_do/01_reg_education_HU.do"	

do "$dir_do/02_reg_leave_parental_home_HU.do"

do "$dir_do/03_reg_partnership_HU.do"

do "$dir_do/04_reg_fertility_HU.do"
 
do "$dir_do/05_reg_health_HU.do"	

do "$dir_do/06_reg_home_ownership_HU.do"

do "$dir_do/07_reg_retirement_HU.do"

do "$dir_do/08_reg_wages_HU.do"

do "$dir_do/09_reg_income_HU.do"

do "$dir_do/10_union_parametrisation/parametric_matching_process_HU.do"


/*******************************************************************************
* INTERNAL VALIDATION FILES
*******************************************************************************/

do "$dir_work/dir_internal_validation/int_val_education_HU.do"	

do "$dir_work/dir_internal_validation/int_val_leave_parental_home_HU.do"	

do "$dir_work/dir_internal_validation/int_val_partnership_HU.do"	

do "$dir_work/dir_internal_validation/int_val_fertility_HU.do"	

do "$dir_work/dir_internal_validation/int_val_health_HU.do"	

do "$dir_work/dir_internal_validation/int_val_home_ownership_HU.do"	

do "$dir_work/dir_internal_validation/int_val_retirement_HU.do"	




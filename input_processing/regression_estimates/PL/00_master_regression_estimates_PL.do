/*******************************************************************************
* PROJECT:              SimPaths EU 
* DO-FILE NAME:         00_master_PL.do
* DESCRIPTION:          Main do-file to set estimates the parameters for 
* 							SimPaths for Poland using EU-SILC.
* COUNTRY:              Poland
* DATA:         	    GESIS - EU SILC			
* AUTHORS: 				Daria Popova, Justin van de Ven, Ashley Burdett
* LAST UPDATE:          Jannuary 2026
********************************************************************************
* NOTES: 				
* 			
*******************************************************************************/

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

//"C:/Users/ak25793/Box"
//"/Users/ashleyburdett/Library/CloudStorage/Box-Box"

global dir_individual "C:/Users/ak25793/Box"

* Working directory which contains sub-folders and will contain formatted output 
global dir_work "$dir_individual/CeMPA shared area/_SimPaths/_SimpathsEU/regression_estimates/PL/with_time_trend"

//"/Users/ashleyburdett/Documents/SimPaths_EU/PL/regression_estimates"
//"/Users/ashleyburdett/Library/CloudStorage/Box-Box/CeMPA shared area/_SimPaths/_SimpathsEU/regression_estimates/PL"

* Directory which contains do files
global dir_do "$dir_work/do_files"

* Directory which contains data files generated in the do files 
global dir_data "$dir_work/data"

* Directory which contains log files 
global dir_log "$dir_work/logs"

* Directory which contains raw results
global dir_raw_results "$dir_work/raw_results"

* Directory which contains EU-SILC input dataset
global dir_input_data "$dir_individual/CeMPA shared area/_SimPaths/_SimPathsEU/initial_populations/PL/data"

* Directory containing external input data 
global dir_external_data "/Users/ashleyburdett/Library/CloudStorage/Box-Box/CeMPA shared area/projects - completed/ESPON - OVERLAP/_countries/PL/regression_estimates/external_data"

* Directory containing internal validation output
global dir_internal_validation "$dir_work/internal_validation/graphs"


/*******************************************************************************
* DEFINTE PARAMETERS
*******************************************************************************/

global country "PL"

global first_sim_year "2011"

global last_sim_year "2023"


* Define threshold ages
/*
Ages used for specifying samples. 

ENSURE THE SAME AS THE GLOBALS USED IN THE INTIIAL POPULATIONS MASTER FILE 
*/
 	
* Age become an adult in various dimensions	
global age_becomes_responsible 18 

global age_becomes_semi_responsible 16 

global age_seek_employment 16 
	
global age_leave_school 16 

global age_form_partnership 18 

global age_have_child_min 18 	

global age_leave_parental_home 18

global age_own_home 18

* Age can/must/cannot make various transitions 	
global age_max_dep_child 17     

global age_adult 18 

global age_can_retire 50

global age_force_retire 75             

global age_force_leave_spell1_edu 30   

global age_have_child_max 49  	// allow this to be led by the data  

global age_cannot_separate 79


/*******************************************************************************
* PROCESS IF CONDITIONS 
*******************************************************************************/

* Education 
global e1a_if_condition "dag >= ${age_leave_school} & dag < ${age_force_leave_spell1_edu} & l.les_c4 == 2 & flag_deceased != 1"

global e1b_if_condition "dag >= ${age_leave_school} & l.les_c4 != 4 & l.les_c4 != 2 & flag_deceased != 1"

global e2_if_condition "dag >= ${age_leave_school} & l.les_c4 == 2 & les_c4 != 2 & flag_deceased != 1"

* Leave the parental home 
global p1_if_condition "ded == 0 & dag >= ${age_leave_parental_home} & flag_deceased != 1"

* Partnership 
global u1_if_condition "dag >= ${age_form_partnership} & ssscp != 1 & flag_deceased != 1"

global u2_if_condition "dgn == 0 & dag >= ${age_form_partnership} & l.ssscp != 1 & dag < ${age_cannot_separate} & flag_deceased != 1 & flag_deceased != 1"

* Fertility 
global f1_if_condition "dag >= ${age_have_child_min} & dag <= ${age_have_child_max} & dgn == 0 & flag_deceased != 1"

* Health 
global h1_if_condition "dag >= ${age_becomes_semi_responsible} & flag_dhe_imp == 0 & flag_deceased != 1"

global h2_if_condition "dag >= ${age_becomes_semi_responsible} & ded == 0 & flag_deceased != 1"

* Home ownership
global ho1_if_condition "dag >= ${age_own_home} & flag_deceased != 1"

* Retirment 
global r1a_if_condition "dcpst == 2  & dag >= ${age_can_retire} & flag_deceased != 1"

global r1b_if_condition "ssscp != 1 & dcpst == 1 & dag >= ${age_can_retire} & flag_deceased != 1"

* WAGES
global W1fa_if_condition "dgn == 0 & dag >= ${age_seek_employment} & dag <= ${age_force_retire} & flag_deceased != 1"

global W1ma_if_condition "dgn == 1 & dag >= ${age_seek_employment} & dag <= ${age_force_retire} & flag_deceased != 1"

global W1fb_if_condition "dgn == 0 & dag >= ${age_seek_employment} & dag <= ${age_force_retire} & previouslyWorking == 1 & flag_deceased != 1"

global W1mb_if_condition "dgn == 1 & dag >= ${age_seek_employment} & dag <= ${age_force_retire} & previouslyWorking == 1 & flag_deceased != 1"

* CAPITAL INCOME 
global i1a_if_condition "dag >= ${age_becomes_semi_responsible} & flag_deceased != 1" 

global i1b_if_condition "dag >= ${age_becomes_semi_responsible} & receives_ypncp == 1 & flag_deceased != 1" 


/*******************************************************************************
* EXECUTE FILES
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


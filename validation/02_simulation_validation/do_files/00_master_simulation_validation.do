/*******************************************************************************
* PROJECT:  		SimPaths EU 
* SECTION:			Validation
* OBJECT: 			Master file - longitudinal SILC
* AUTHORS:			Ashley Burdett 
* LAST UPDATE:		11/2025 (AB)
* COUNTRY: 			Poland 
********************************************************************************
* NOTES: 			This master do file organises do files used for validating 
* 					SimPaths model using EU-SILC data for Poland. This version 
* 					utilizes longitudinal SILC data from the initial populations
* 					
* 					
* 					Copy and paste the relevant simulated output do files into 
* 					the data subfolder. 
*******************************************************************************/
clear all

set logtype smcl
set more off
set mem 200m
set type double


/*******************************************************************************
* DEFINE GLOBALS
*******************************************************************************/

global country = "PL"		 						
global country_lower = "pl"
display in y "Country selected: ${country}"

global silc_UDB = "UDB_c"	


/*******************************************************************************
* DEFINE DIRECTORIES
*******************************************************************************/


* Ashley 

* VM
//global path "C:\Users\aburde\Box\CeMPA shared area\ESPON - OVERLAP\_countries\IT\validation"

* Mac
global path "/Users/ashleyburdett/Library/CloudStorage/Box-Box/CeMPA shared area/_SimPaths/_SimPathsEU/validation/02_simulation_output_validation/PL"


///Users/ashleyburdett/Library/CloudStorage/Box-Box/CeMPA shared area/_SimPaths/_SimPathsEU/validation/PL/validation
//"/Users/ashleyburdett/Library/CloudStorage/Box-Box/CeMPA shared area/ESPON - OVERLAP/_countries/${country}/validation"
//"/Users/ashleyburdett/Documents/ESPON/${country}/validation"

//global dir_data  "$path/data" //folder where  output files  stored
global dir_do_files "$path/longitudinal_SILC/do_files"  //folder where do-files are stored 
//global dir_work  "$path/data" //folder where  output files  stored
//global dir_data "$path/data"

global dir_simulated_data "$path/data"
global dir_work "/$path/data"
global dir_data "$path/data"

global dir_init_pop_data "/Users/ashleyburdett/Library/CloudStorage/Box-Box/CeMPA shared area/_SimPaths/_SimPathsEU/initial_populations/PL/data"

global dir_output_files "$path/longitudinal_SILC/graphs" //folder where validations graphs are stored 


/*******************************************************************************
* DEFINE SAMPLE PARAMETERS
*******************************************************************************/

global use_assert "0"

* Trim outliers
global trim_outliers true

* Min age of individuals included in plots
global min_age 18

* Max age of individuals included in plots
global max_age 65

* Observations up to and including this simulated year will be kept in the sample
global max_year 2023

* Define age to become responsible as defined in the simulation
global age_become_responsible 16

* Set labour supply categories 
global ls_cat "ZERO TWENTY FORTY FIFTY" 
// works if the genders are symmetric
// still need to alter code in specific do files to print graphs 

global ls_cat_labour "TWENTY FORTY FIFTY" 

/*******************************************************************************
CALL WORKER DO FILES 
*******************************************************************************/

* Prepare observed data
do "${dir_do_files}/02_prepare_EU_SILC_data.do"
do "${dir_do_files}/04_create_EU_SILC_validation_targets.do"

* Prepare simulated data
do "${dir_do_files}/01_prepare_simulated_data.do"
do "${dir_do_files}/05_create_simulated_validation_targets.do"
 
* Prepare EUROMOD data 
//do "${dir_do_files}/07_create_euromod_validation_targets.do"

* Plot figures
do "${dir_do_files}/06_01_plot_activity_status.do"
do "${dir_do_files}/06_02_plot_education_level.do"
do "${dir_do_files}/06_03_plot_gross_income.do"
do "${dir_do_files}/06_04_plot_gross_labour_income.do"
do "${dir_do_files}/06_05_plot_capital_income.do"
do "${dir_do_files}/06_07_plot_disposable_income.do"
do "${dir_do_files}/06_08_plot_equivalised_disposable_income.do"
do "${dir_do_files}/06_09_plot_hourly_wages.do"
do "${dir_do_files}/06_10_plot_hours_worked.do"
do "${dir_do_files}/06_11_plot_income_shares.do" 
do "${dir_do_files}/06_12_plot_partnership_status.do"
do "${dir_do_files}/06_13_plot_health.do"
do "${dir_do_files}/06_14_plot_at_risk_of_poverty.do"
do "${dir_do_files}/06_15_plot_income_ratios.do"
do "${dir_do_files}/06_16_plot_number_children.do"
do "${dir_do_files}/06_17_plot_disability"

* Calculate other statistics
do "${dir_do_files}/07_01_correlations.do"


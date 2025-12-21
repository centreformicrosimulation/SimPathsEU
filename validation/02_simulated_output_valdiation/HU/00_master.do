********************************************************************************
* PROJECT:  		ESPON 
* SECTION:			Validation
* OBJECT: 			Master file
* AUTHORS:			Patryk Bronka, Ashley Burdett 
* LAST UPDATE:		12/2024 (PB)
* COUNTRY: 			Hungary 

* NOTES: 			This master do file organises do files used for validating 
* 					SimPaths model using EU-SILC data for Hungary. 
********************************************************************************
clear all

set logtype smcl
set more off
set mem 200m
set type double


/*******************************************************************************
* DEFINE GLOBALS
*******************************************************************************/

global country = "HU"		 						
global country_lower = "hu"
display in y "Country selected: ${country}"

global silc_UDB = "UDB_c"	


/*******************************************************************************
* DEFINE DIRECTORIES
*******************************************************************************/

/*
* Working directory
global dir_work "C:\Users\Patryk\Documents\validation_work"

* Directory which contains do files
global dir_do_files "C:\Users\Patryk\Box\_SimPaths\_papers\paper_descriptive\validation-UK\Validation_do_files"

* Directory which contains output files (graphs produced by these do files)
global dir_output_files "C:\Users\Patryk\Box\ESPON - OVERLAP\_countries\UK\validation\2011_2019_alignment_off_new_ls"

* Directory which contains simulated output 
*global dir_simulated_data "C:\Users\Patryk\git\SimPathsFork\output\20231120000148_615" // 20 runs with pop alignment, new weights, cohabitation alignment, and labour supply utility function adjustment

global dir_simulated_data "C:\Users\Patryk\git\SimPathsFork\output\20240611221158_0" 

* Directory which contains UKMOD input files 
global dir_ukmod_data "C:\Users\Patryk\Box\_SimPaths\_papers\paper_descriptive\validation-UK\PB"

* Directory which contains UKHLS data
global dir_ukhls_data "C:\Users\Patryk\Documents\UKHLS\UKDA-6614-stata\stata\stata13_se\ukhls"

* Directory which contains FRS data
globa dir_frs "C:\Users\Patryk\Documents\validation_FRS"
*/ 


/*
*Patryk
global path "C:\Users\Patryk\Box\ESPON - OVERLAP\_countries\HU\validation"
global dir_data "${path}\data"
global dir_do_files "${path}\do"
* Directory which contains simulated output 
global dir_simulated_data "C:\Users\Patryk\git\SimPaths_HU\output\for_validation" 
global dir_work "C:\Users\Patryk\Documents\validation_work"
global dir_output_files "$path/graphs" //folder where validations graphs are stored 
global EUSILC_original_crosssection "C:\Users\Patryk\Box\data\EU_SILC\2023\Cross_23_09\Cross"  //folder where original EU-SILC data are stored 
*/

/*
* Daria
global path "D:\Dasha\ESSEX\ESPON 2024\HU\validation"
global EUSILC_original_crosssection "D:\Dasha\EU-original-data\Cross_23_09\Cross"  //folder where original EU-SILC data are stored
global dir_data  "${path}\data" //folder where  output files *will be* stored
global dir_do_files "${path}\do"  //folder where do-files are stored 
*/

* Ashley 
/*
Currently save data locally 
*/

* VM
//global path "C:\Users\aburde\Box\ESPON - OVERLAP\_countries\HU\validation"

* Mac
global path "/Users/ashleyburdett/Documents/ESPON/HU/validation"

global EUSILC_original_crosssection "N:\CeMPA\data\EU_SILC\2024\_Cross_2004-2023_full_set\_Cross_2004-2023_full_set"  //folder where original EU-SILC data are stored

//global dir_data  "$path/data" //folder where  output files  stored
global dir_do_files "$path/do_files"  //folder where do-files are stored 
global dir_work  "$path/data" //folder where  output files  stored

global dir_simulated_data "/Users/ashleyburdett/Documents/ESPON/${country}/validation/data"

//global dir_euromod_data "/Users/ashleyburdett/Library/CloudStorage/Box-Box/ESPON_shared_files/EM_files"

global dir_work "/Users/ashleyburdett/Documents/ESPON/${country}/validation/data"
global dir_data "/Users/ashleyburdett/Documents/ESPON/${country}/validation/data"

// /Users/ashleyburdett/Documents/ESPON/PL/validation/data  //local
// /Users/ashleyburdett/Library/CloudStorage/Box-Box/ESPON_shared_files/${country}/validation 	// Box data share

global dir_output_files "/Users/ashleyburdett/Documents/ESPON/HU/validation/graphs" //folder where validations graphs are stored 

// /Users/ashleyburdett/Documents/ESPON/HU/validation/graphs  	// local
// $path/graphs		// Box project folder 

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
global age_become_responsible 18

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
do "${dir_do_files}/03_create_EU_SILC_benefit_units.do"
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


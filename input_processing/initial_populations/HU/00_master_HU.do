
********************************************************************************
* PROJECT:             	ESPON
* DO-FILE NAME:        	00_master.do
* DESCRIPTION:         	Main do-file to set the main parameters (country, paths)
*  						and call sub-scripts to construct dataset for 
* 						analysis of Hungary. 
********************************************************************************
* COUNTRY:              HU
* DATA:         	    Longitudinal EU-SILC UDB version, 2005 - 2023
* AUTHORS: 				Clare Fenwick, Daria Popova, Ashley Burdett
* LAST UPDATE:          Jan 2025
* 
* NOTES: 				Before running these files the cumulative panel for each 
* 						file type (D,H,R,P) needs to be constructed.  
* 						These are created following the procedure set out in 
* 						GESIS Papers 2022/10. The files to undertake this 
* 						procedure are contained in the "GESIS set-ups" subfolder 
* 						contained in the same folder as this file. 
* 
* 						The updated Master*.dta flies are stored locally which 
* 						are needed to run the first do file (EP machine)
* 						
********************************************************************************

* Stata packages to install 
ssc install fre
ssc install tsspell 
ssc install carryforward 
ssc install outreg2
ssc install filelist

clear all
set more off
set type double
set maxvar 30000
set matsize 1000

/*******************************************************************************
* DEFINE DIRECTORIES
*******************************************************************************/

* Working directory
global dir_work "C:/Users/ak25793/Box/CeMPA shared area/ESPON - OVERLAP/_countries/HU/initial_populations"
//"/Users/aburdett/Library/CloudStorage/Box-Box/myBox/Ashley_ESPON/_countries/HU/initial_populations"
//"C:\Users\aburde\Box\myBox\Ashley_ESPON\_countries\HU\initial_populations"
//"/Users/aburdett/Library/CloudStorage/Box-Box/ESPON - OVERLAP/_countries/HU/initial_populations"

* Directory containing do files
global dir_do "$dir_work/do_files"

* Directory containing data files 
global dir_data "$dir_work/data" 

* Directory containing log files 
global dir_log "$dir_work/log"

* Directory containing graphs 
global dir_graphs "$dir_work/graphs"

* Directory containing 2005-2023 EU-SILC panel data (master*.dta)
global dir_long_eusilc "C:/Users/ak25793/Box/CeMPA shared area/ESPON - OVERLAP/_countries/Cumulative Longitudional Dataset (all countries)/2005_2023_panel/data"

* Directory containing 2005-2020 EU-SILC panel data (master*.dta)
global dir_long_eusilc_05_20 "/C:/Users/ak25793/Box/CeMPA shared area/ESPON - OVERLAP/_countries/Cumulative Longitudional Dataset (all countries)/2005_2020_panel"
//"/Users/aburdett/Library/CloudStorage/Box-Box/ESPON - OVERLAP/_countries/Cumulative Longitudional Dataset (all countries)/2005_2020_panel"
//"C:\Users\aburde\Box\ESPON - OVERLAP\_countries\Cumulative Longitudional Dataset (all countries)\2005_2020_panel"

* Directory containing 2005-2020 PL panel 
global dir_data_05_20 "$dir_data/orig_panel_2005_2020"


/*******************************************************************************
* DEFINE OTHER GLOBAL VARIABLES
*******************************************************************************/

* Define age to become responsible as defined in the simulation
global age_become_responsible 18

global country "HU" 

global firstSimYear "2011"

global lastSimYear "2023"


/*******************************************************************************
* ROUTE TO WORKER FILES 
*******************************************************************************/
//do "$dir_do/01_prepare_pooled_data_HU.do"

do "$dir_do/02_create_variables_HU.do"

do "$dir_do/02_02_Age_elderly_HU.do"

do "$dir_do/03_create_benefit_units_HU.do"

do "$dir_do/04_reweight_HU.do"

do "$dir_do/05_drop_hholds_and_slice_HU.do"

do "$dir_do/06_check_yearly_data_HU.do"


/*******************************************************************************
* END OF FILE
*******************************************************************************/

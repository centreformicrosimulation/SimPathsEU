/*******************************************************************************
* PROJECT:             	SimPaths EU
* DO-FILE NAME:        	00_master.do
* DESCRIPTION:         	Main do-file to set the main parameters (country, paths)
*  						and call sub-scripts to construct dataset for 
* 						analysis of Poland. 
********************************************************************************
* COUNTRY:              PL
* DATA:         	    Longitudinal EU-SILC UDB version, 2005 - 2020 
* AUTHORS: 				Clare Fenwick, Daria Popova, Ashley Burdett, 
* 						Aleksandra Kolndrekaj
* LAST UPDATE:          Jan 2026 AB
* 
********************************************************************************
* NOTES:
*   Before running these files, the cumulative panel for each file type 
* 	(D, H, R, P) must be constructed. These cumulative panels should be created 
* 	following the procedure set out in *GESIS Papers 2022/10*. The do-files to 
* 	perform this procedure are contained in the "GESIS set-ups" subfolder 
* 	located in the same directory as this file.
*
*   Currently, compiling the master* files is done separately to avoid data  
*   storage constraints.
*
*   -----------------------------------------------------------------------
*    Assumptions imposed to align the SILC data with simulation rules:
*   -----------------------------------------------------------------------
*
*   - Retirement:
*       - Treated as an absorbing state
*       - Must retire by a specified maximum age
*       - Cannot retire before a specified minimum age
*
*   - Education:
*       - Leave education no earlier than a specified minimum age
*       - Must leave the initial education spell by a specified maximum age
*       - Cannot return to education after retirement
*
*   - Work:
*       - Can work from a specified minimum age
*       - Activity status and hours of work populated consistently:
*           → Assume not working if report hours = 0 
*           → Assume hours = 0 if not working
* 		- If missing partial information, don't assume the missing is 0 and 
* 			impute (hot-deck)
*
*   - Leaving the parental home:
*       - Can leave from a specified minimum age
* 		- Become the effective head of hh even when living with parents when 
* 			paretns retire or reach state retirment age
*
*   - Home ownership:
*       - Can own a home from a specified minimum age
*
*   - Partnership formation:
*       - Can form a partnership from a specified minimum age
*
*   - Disability:
*       - Treated as a subsample of the not-employed population
*
*   The relevant age thresholds are defined in globals defined in "DEFINE 
* 	PARAMETERS" section below. 
* 	Throughout also construct relevant flags and produce a log file 
* 	"flag_descriptives.xlsx" to see the extent of the adjustments to the raw 
* 	data. 
*
*   -----------------------------------------------------------------------
*    Additional notes on implementation: 
*   -----------------------------------------------------------------------
*
*   - Impute health score (generalized ordered logit model).
*   - Constructing age is not straight forward as not directly reported in the 
* 	  data, therefore: 
*       → Use interview age (RX010) where available
*       → Otherwise use age at end of interview year (PX020). This results in 
* 			upward bias of age.
*   - Set education = 0 (na) while in initial education spell. 
*
*   -----------------------------------------------------------------------
*   Remaining disparities between initial populations and simulation rules:
*   -----------------------------------------------------------------------
*
*   - Ages at which females can have a child. [Be informed by the sample?]
*	  Permit teenage mothers in this script (deal with in 03_ )
*   - A few higher/older education spells (30+) that last multiple years 
*     in the simulation can only return to education for single year spells. 
* 	- Number of children vars (all ages or 0-2) don't account for feasibility 
* 		of age at birth of the mother. 
*
*******************************************************************************/

/*
* Stata packages to install 
ssc install fre
ssc install tsspell 
ssc install carryforward 
ssc install outreg2
ssc install filelist
*/

clear all
set more off
set type double
set maxvar 30000
set matsize 1000

/*******************************************************************************
* DEFINE DIRECTORIES
*******************************************************************************/

* Individual
global dir_ind "/Users/ashleyburdett/Library/CloudStorage/Box-Box"

// Ashley - /Users/ashleyburdett/Library/CloudStorage/Box-Box
// Aleksandra - C:/Users/ak25793/Box

* Working directory
global dir_work "$dir_ind/CeMPA shared area/_SimPaths/_SimPathsEU/initial_populations/PL"

* Directory containing do files
global dir_do "$dir_work/do_files"

* Directory containing data files 
global dir_data "$dir_work/data" 

* Directory containing log files 
global dir_log "$dir_work/log"

* Directory containing graphs 
global dir_graphs "$dir_work/graphs"

* Directory containing 2005-2023 EU-SILC paneldata 
global dir_long_eusilc "$dir_ind/CeMPA shared area/projects - completed/ESPON - OVERLAP/_countries/Cumulative Longitudional Dataset (all countries)/2005_2023_panel/data"
// location the master*.dta files that make up the EU-SILC panel 

//"/Users/aburdett/Library/CloudStorage/Box-Box/ESPON - OVERLAP/_countries/Cumulative Longitudional Dataset (all countries)/2005_2023_panel/data"

* Directory containing 2005-2020 EU-SILC paneldata 
global dir_long_eusilc_05_20 "$dir_ind/CeMPA shared area/projects - completed/ESPON - OVERLAP/_countries/Cumulative Longitudional Dataset (all countries)/2005_2020_panel"

* Directory containing 2005-2020 PL panel 
global dir_data_05_20 "$dir_data/orig_panel_2005_2020"


/*******************************************************************************
* DEFINE PARAMETERS & PROCESS IF CONDITIONS
*******************************************************************************/

do "$dir_ind/CeMPA shared area/_SimPaths/_SimPathsEU/00_master_conditions.do"


/*******************************************************************************
* EXECUTE FILES
*******************************************************************************/
//do "$dir_do/01_prepare_pooled_data.do"

do "$dir_do/02_create_variables_PL.do"

do "$dir_do/03_create_benefit_units_PL.do"

do "$dir_do/04_reweight_PL.do"

do "$dir_do/05_drop_hholds_and_slice_PL.do"

do "$dir_do/06_check_yearly_data_PL.do"


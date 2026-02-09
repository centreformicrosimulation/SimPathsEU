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
*    Assumptions imposed to align the initial populations with simulation rules:
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
* 	Throughout also construct relevant flags and produce a log file "xxxx" to 
* 	see the extent of the adjustments to the raw data. 
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
*   - Impute education status using lagged observation and generalized ordered 
* 	  logit. [Have a more compete version if necessary]
*   - Set education = 0 (na) while in initial education spell. 
*
*   -----------------------------------------------------------------------
*   Remaining disparities between initial populations and simulation rules:
*   -----------------------------------------------------------------------
*
*   - Ages at which females can have a child. [Be informed by the sample?]
	  Permit teenage mothers in this script (deal with in 03_ )
*   - A few higher/older education spells (30+) that last multiple years, whilst 
*     in the simulation can only return to education for single year spells. 
*   - Wages: currently have missing wages if not working however the timing 
* 		mismatch in SILC leaves some additional  missing values [impute?]
* 	- Should we have people becoming adults at 18 or 16 for income/number of 
* 		children purposes?
* 		Considered a child if live with parents until 18 and in ft education? 
* 	- Don't impose monotoncity on reported educational attainment information.  
* 	- Number of children vars (all ages or 0-2) don't account for feasibility 
* 		of age at birth of the mother. 
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

// Ashley - /Users/ashleyburdett/Library/CloudStorage/Box-Box
// Aleksandra - C:/Users/ak25793/Box

* Working directory
global dir_work "/Users/ashleyburdett/Library/CloudStorage/Box-Box/CeMPA shared area/_SimPaths/_SimPathsEU/initial_populations/PL"

* Directory containing do files
global dir_do "$dir_work/do_files"

* Directory containing data files 
global dir_data "$dir_work/data" 

* Directory containing log files 
global dir_log "$dir_work/log"

* Directory containing graphs 
global dir_graphs "$dir_work/graphs"

* Directory containing 2005-2023 EU-SILC paneldata 
global dir_long_eusilc "/Users/ashleyburdett/Library/CloudStorage/Box-Box/CeMPA shared area/projects - completed/ESPON - OVERLAP/_countries/Cumulative Longitudional Dataset (all countries)/2005_2023_panel/data"
// location the master*.dta files that make up the EU-SILC panel 

//"/Users/aburdett/Library/CloudStorage/Box-Box/ESPON - OVERLAP/_countries/Cumulative Longitudional Dataset (all countries)/2005_2023_panel/data"

* Directory containing 2005-2020 EU-SILC paneldata 
global dir_long_eusilc_05_20 "/Users/ashleyburdett/Library/CloudStorage/Box-Box/CeMPA shared area/projects - completed/ESPON - OVERLAP/_countries/Cumulative Longitudional Dataset (all countries)/2005_2020_panel"

* Directory containing 2005-2020 PL panel 
global dir_data_05_20 "$dir_data/orig_panel_2005_2020"


/*******************************************************************************
* DEFINE PARAMETERS
*******************************************************************************/

global country "PL" 

global first_sim_year "2011"

global last_sim_year "2023"


* Define threshold ages
/*
The thresholds defined below ensure consistency between the assumptions 
applied in the simulation and the structure of the initial population data. 
They specify the ages at which certain life-course transitions are permitted 
or enforced within the model. These limits reflect both modelling conventions 
and empirical considerations drawn from observed data.
*/
 	
* Age become an adult in various dimensions	
global age_becomes_responsible 18 

global age_seek_employment 16 
	
global age_leave_school 16 

global age_form_partnership 18 

global age_have_child_min 18 	

global age_leave_parental_home 18

	
* Age can/must/cannot make various transitions 	
global age_max_dep_child 17     

global age_adult 18 

global age_can_retire 50

global age_force_retire 75             

global age_force_leave_spell1_edu 30   

global age_have_child_max 49  	// allow this to be led by the data  


* Age in samples 
global age_sample_min 16
 	       
		   
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

global h2_if_condition "dag >= ${age_becomes_semi_responsible} & ded == 0 & les_c4 != 4 & flag_deceased != 1"

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
//do "$dir_do/01_prepare_pooled_data.do"

do "$dir_do/02_create_variables_PL.do"

do "$dir_do/03_create_benefit_units_PL.do"

do "$dir_do/04_reweight_PL.do"

do "$dir_do/05_drop_hholds_and_slice_PL.do"

do "$dir_do/06_check_yearly_data_PL.do"


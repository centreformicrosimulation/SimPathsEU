/*******************************************************************************
SUMMARY — 03_create_masterR.do 

This file builds the master personal register (R) panel for EU-SILC 2005–2023.
It follows the same two-step structure as 02_create_masterH.do, with two key
differences reflecting that R is a person-level (not household-level) file:

STEP 1 
	Create clean annual R files (one block per release year, 2023 down to 2005)
	For each year, the raw R data file is read and merged m:1 with the 
	corresponding YYYYD.dta (many persons per household, hence m:1 not 1:1). 
	Keeping only _merge == 3 selects the correct sample — the D file has already 
	handled all cross-release deduplication, so the R file inherits a clean s
	ample through this merge.
	A unique personal ID (upid) is then constructed by concatenating the first 7
	characters of the household uhid with the individual pid. This ensures upid 
	is unique across releases. Each block saves a YYYYR.dta file.

STEP 2 
	Assemble the full panel
	The 2023R.dta is loaded and the annual YYYYR files from 2022 back to 2005 
	are merged in sequentially using year, upid, and uhid. 
	The merge is done in batches with intermediate saves due to memory 
	requirements. 
	Superfluous D-file variables are dropped and a numeric group identifier 
	(upidnum) is added before the final masterR.dta is saved to the 2024 release 
	folder.

NOTE: This file must be run after 01_create_masterD.do. All cross-release 
deduplication logic resides in the D file; this file trusts and relies on its 
output.

*******************************************************************************/


/* 2023 */	

	clear
	local filen : dir "${datapath}/EU-SILC/19 L-2023/"  files "udb_l23r_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/19 L-2023/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }

	tostring rb030, replace format("%15.0f")
	tostring rb040, replace 
	gen year = rb010
	gen hid = rb040
	gen pid = rb030 
	gen country = rb020
	sort year country hid 
	
	/*checking for duplicates or errors in id*/
	duplicates report country year hid pid 
	duplicates report country year pid
	
	/*merge with IDs from house hold register (D file) and drop households that are only in the D file, but not in the R file */
	merge m:1 year country hid using "${datapath}/EU-SILC/19 L-2023/2023D.dta"
	keep if _merge == 3 
	drop _merge 
	
	/*generate personal IDs that are unique across all releases by taking the last 2 digits of pid (personal number) and merging it to uhid*/
	/*keep in mind that there are some individuals present in more than one family, so there are duplicates in pid alone but not in uhid and upid */
	gen suhid = substr(uhid,1,7)
	gen upid = suhid + pid 
	drop suhid
	
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/19 L-2023/2023R", replace

/* 2022 */		
	clear
	local filen : dir "${datapath}/EU-SILC/18 L-2022/"  files "udb_l22r_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/18 L-2022/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }

	tostring rb030, replace format("%15.0f")
	tostring rb040, replace 
	gen year = rb010
	gen hid = rb040
	gen pid = rb030 
	gen country = rb020
	sort year country hid 
	
	/*checking for duplicates or errors in id*/
	duplicates report country year hid pid 
	duplicates report country year pid
	
	/*merge with IDs from house hold register (D file) and drop households that are only in the D file, but not in the R file */
	merge m:1 year country hid using "${datapath}/EU-SILC/18 L-2022/2022D.dta"
	keep if _merge == 3 
	drop _merge 
	
	/*genereate personal IDs that are unique across all releases by taking the last 2 digits of pid (personal number) and merging it to uhid*/
	/*keep in mind that there are some individuals present in more than one family, so there are duplicates in pid alone but not in uhid and upid */
	gen suhid = substr(uhid,1,7)
	gen upid = suhid + pid 
	drop suhid
	
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/18 L-2022/2022R", replace
	
/* 2021 */		
	clear
	local filen : dir "${datapath}/EU-SILC/17 L-2021/"  files "udb_l21r_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/17 L-2021/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }

	tostring rb030, replace format("%15.0f")
	tostring rb040, replace 
	gen year = rb010
	gen hid = rb040
	gen pid = rb030 
	gen country = rb020
	sort year country hid 
	
	/*checking for duplicates or errors in id*/
	duplicates report country year hid pid 
	duplicates report country year pid
	
	/*merge with IDs from house hold register (D file) and drop households that are only in the D file, but not in the R file */
	merge m:1 year country hid using "${datapath}/EU-SILC/17 L-2021/2021D.dta"
	keep if _merge == 3 
	drop _merge 
	
	/*genereate personal IDs that are unique across all releases by taking the last 2 digits of pid (personal number) and merging it to uhid*/
	/*keep in mind that there are some individuals present in more than one family, so there are duplicates in pid alone but not in uhid and upid */
	gen suhid = substr(uhid,1,7)
	gen upid = suhid + pid 
	drop suhid
	
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/17 L-2021/2021R", replace
	
/* 2020 */	
	clear
	local filen : dir "${datapath}/EU-SILC/16 L-2020/"  files "udb_l20r_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/16 L-2020/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }

	tostring rb030, replace format("%15.0f")
	tostring rb040, replace 
	gen year = rb010
	gen hid = rb040
	gen pid = rb030 
	gen country = rb020
	sort year country hid 
	
	/*checking for duplicates or errors in id*/
	duplicates report country year hid pid 
	duplicates report country year pid
	
	/*merge with IDs from house hold register (D file) and drop households that are only in the D file, but not in the R file */
	merge m:1 year country hid using "${datapath}/EU-SILC/16 L-2020/2020D.dta"
	keep if _merge == 3 
	drop _merge 
	
	/*generate personal IDs that are unique across all releases by taking the last 2 digits of pid (personal number) and merging it to uhid*/
	/*keep in mind that there are some individuals present in more than one family, so there are duplicates in pid alone but not in uhid and upid */
	gen suhid = substr(uhid,1,7)
	gen upid = suhid + pid 
	drop suhid
	
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/16 L-2020/2020R", replace

/* 2019 */		
	clear
	local filen : dir "${datapath}/EU-SILC/15 L-2019/"  files "udb_l19r_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/15 L-2019/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }

	tostring rb030, replace format("%15.0f")
	tostring rb040, replace 
	gen year = rb010
	gen hid = rb040
	gen pid = rb030 
	gen country = rb020
	sort year country hid 
	
	/*checking for duplicates or errors in id*/
	duplicates report country year hid pid 
	duplicates report country year pid
	
	/*merge with IDs from house hold register (D file) and drop households that are only in the D file, but not in the R file */
	merge m:1 year country hid using "${datapath}/EU-SILC/15 L-2019/2019D.dta"
	keep if _merge == 3 
	drop _merge 
	
	/*genereate personal IDs that are unique across all releases by taking the last 2 digits of pid (personal number) and merging it to uhid*/
	/*keep in mind that there are some individuals present in more than one family, so there are duplicates in pid alone but not in uhid and upid */
	gen suhid = substr(uhid,1,7)
	gen upid = suhid + pid 
	drop suhid
	
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/15 L-2019/2019R", replace
	
/* 2018 */		
	clear
	local filen : dir "${datapath}/EU-SILC/14 L-2018/"  files "udb_l18r_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/14 L-2018/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }

	tostring rb030, replace format("%15.0f")
	tostring rb040, replace 
	gen year = rb010
	gen hid = rb040
	gen pid = rb030 
	gen country = rb020
	sort year country hid 
	
	/*checking for duplicates or errors in id*/
	duplicates report country year hid pid 
	duplicates report country year pid
	
	/*merge with IDs from house hold register (D file) and drop households that are only in the D file, but not in the R file */
	merge m:1 year country hid using "${datapath}/EU-SILC/14 L-2018/2018D.dta"
	keep if _merge == 3 
	drop _merge 
	
	/*genereate personal IDs that are unique across all releases by taking the last 2 digits of pid (personal number) and merging it to uhid*/
	/*keep in mind that there are some individuals present in more than one family, so there are duplicates in pid alone but not in uhid and upid */
	gen suhid = substr(uhid,1,7)
	gen upid = suhid + pid 
	drop suhid
	
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/14 L-2018/2018R", replace

/* 2017 */		
	clear
	local filen : dir "${datapath}/EU-SILC/13 L-2017/"  files "udb_l17r_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/13 L-2017/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }

	tostring rb030, replace format("%15.0f")
	tostring rb040, replace 
	gen year = rb010
	gen hid = rb040
	gen pid = rb030 
	gen country = rb020
	sort year country hid 
	/*checking for duplicates or errors in id*/
	duplicates report country year hid pid 
	duplicates report country year pid
	/*merge with IDs from house hold register (D file) and drop households that are only in the D file, but not in the R file */
	merge m:1 year country hid using "${datapath}/EU-SILC/13 L-2017/2017D.dta"
	keep if _merge == 3 
	drop _merge 
	/*genereate personal IDs that are unique across all releases by taking the last 2 digits of pid (personal number) and merging it to uhid*/
	/*keep in mind that there are some individuals present in more than one family, so there are duplicates in pid alone but not in uhid and upid */
	gen suhid = substr(uhid,1,7)
	gen upid = suhid + pid 
	drop suhid
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/13 L-2017/2017R", replace

/* 2016 */		
	clear
	local filen : dir "${datapath}/EU-SILC/12 L-2016/"  files "udb_l16r_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/12 L-2016/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }

	tostring rb030, replace format("%15.0f") 
	tostring rb040, replace 
	gen year = rb010
	gen hid = rb040
	gen pid = rb030 
	gen country = rb020
	sort year country hid 
	/*checking for duplicates or errors in id*/
	duplicates report country year hid pid 
	duplicates report country year pid
	/*merge with IDs from house hold register (D file) and drop households that are only in the D file, but not in the R file */
	merge m:1 year country hid using "${datapath}/EU-SILC/12 L-2016/2016D.dta"
	keep if _merge == 3 
	drop _merge 
	/*genereate personal IDs that are unique across all releases by taking the last 2 digits of pid (personal number) and merging it to uhid*/
	/*keep in mind that there are some individuals present in more than one family, so there are duplicates in pid alone but not in uhid and upid */
	gen suhid = substr(uhid,1,7)
	gen upid = suhid + pid 
	drop suhid
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/12 L-2016/2016R", replace

/* 2015 */		
	clear
	local filen : dir "${datapath}/EU-SILC/11 L-2015/"  files "udb_l15r_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/11 L-2015/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	

	tostring rb030, replace format("%15.0f") 
	tostring rb040, replace 
	gen year = rb010
	gen hid = rb040
	gen pid = rb030 
	gen country = rb020
	sort year country hid 
	/*checking for duplicates or errors in id*/
	duplicates report country year hid pid 
	duplicates report country year pid
	/*merge with IDs from house hold register (D file) and drop households that are only in the D file, but not in the R file */
	merge m:1 year country hid using "${datapath}/EU-SILC/11 L-2015/2015D.dta"
	keep if _merge == 3 
	drop _merge 
	/*genereate personal IDs that are unique across all releases by taking the last 2 digits of pid (personal number) and merging it to uhid*/
	/*keep in mind that there are some individuals present in more than one family, so there are duplicates in pid alone but not in uhid and upid */
	gen suhid = substr(uhid,1,7)
	gen upid = suhid + pid 
	drop suhid
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/11 L-2015/2015R", replace

	
/* 2014 */
	clear
	local filen : dir "${datapath}/EU-SILC/10 L-2014/"  files "udb_l14r_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/10 L-2014/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
use `"`fileln'"', clear
	
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	

	tostring rb030, replace format("%15.0f") 
	tostring rb040, replace 
	gen year = rb010
	gen hid = rb040
	gen pid = rb030 
	gen country = rb020
	sort year country hid 
	/*checking for duplicates or errors in id*/
	duplicates report country year hid pid
 	duplicates report country year pid
	/*merge with IDs from house hold register (D file) and drop households that are only in the D file, but not in the R file */
	merge m:1 year country hid using "${datapath}/EU-SILC/10 L-2014/2014D.dta"
	keep if _merge == 3 
	drop _merge 
	/*genereate personal IDs that are unique across all releases by taking the first 7 numbers of uhid and adding them to pid*/
	/*keep in mind that there are some individuals present in more than one family, so there are duplicates in upid alone but not in uhid and upid */
	gen suhid = substr(uhid, 1, 7)
	gen upid = suhid + pid 
	drop suhid
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/10 L-2014/2014R", replace
	
/* 2013 */
	clear
	local filen : dir "${datapath}/EU-SILC/9 L-2013/"  files "udb_l13r_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/9 L-2013/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
use `"`fileln'"', clear
	
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	

	tostring rb030, replace format("%15.0f") 
	tostring rb040, replace 
	gen year = rb010
	gen hid = rb040
	gen pid = rb030 
	gen country = rb020
	sort year country hid 
	/*checking for duplicates or errors in id*/
	duplicates report country year hid pid
 	duplicates report country year pid
	/*merge with IDs from house hold register (D file) and drop households that are only in the D file, but not in the R file */
	merge m:1 year country hid using "${datapath}/EU-SILC/9 L-2013/2013D.dta"
	keep if _merge == 3 
	drop _merge 
	/*genereate personal IDs that are unique across all releases by taking the first 7 numbers of uhid and adding them to pid*/
	/*keep in mind that there are some individuals present in more than one family, so there are duplicates in upid alone but not in uhid and upid */
	gen suhid = substr(uhid, 1, 7)
	gen upid = suhid + pid 
	drop suhid
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/9 L-2013/2013R", replace
	
/* 2012 */
	clear
	local filen : dir "${datapath}/EU-SILC/8 L-2012/"  files "udb_l12r_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/8 L-2012/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
use `"`fileln'"', clear
	
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring rb030, replace format("%15.0f") 
	tostring rb040, replace 
	gen year = rb010
	gen hid = rb040
	gen pid = rb030 
	gen country = rb020
	sort year country hid 
	/*checking for duplicates or errors in id*/
	duplicates report country year hid pid
 	duplicates report country year pid
	/*merge with IDs from house hold register (D file) and drop households that are only in the D file, but not in the R file */
	merge m:1 year country hid using "${datapath}/EU-SILC/8 L-2012/2012D.dta"
	keep if _merge == 3 
	drop _merge 
	/*genereate personal IDs that are unique across all releases by taking the first 7 numbers of uhid and adding them to pid*/
	/*keep in mind that there are some individuals present in more than one family, so there are duplicates in upid alone but not in uhid and upid */
	gen suhid = substr(uhid, 1, 7)
	gen upid = suhid + pid 
	drop suhid
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/8 L-2012/2012R", replace
	
/* 2011 */
	clear
	local filen : dir "${datapath}/EU-SILC/7 L-2011/"  files "udb_l11r_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/7 L-2011/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
use `"`fileln'"', clear
	
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring rb030, replace format("%15.0f")
	tostring rb040, replace 
	gen year = rb010
	gen hid = rb040
	gen pid = rb030 
	gen country = rb020
	sort year country hid 
	/*checking for duplicates or errors in id*/
	duplicates report country year hid pid
 	duplicates report country year pid
	/*merge with IDs from house hold register (D file) and drop households that are only in the D file, but not in the R file */
	merge m:1 year country hid using "${datapath}/EU-SILC/7 L-2011/2011D.dta"
	keep if _merge == 3 
	drop _merge 
	/*genereate personal IDs that are unique across all releases by taking the first 7 numbers of uhid and adding them to pid*/
	/*keep in mind that there are some individuals present in more than one family, so there are duplicates in upid alone but not in uhid and upid */
	gen suhid = substr(uhid, 1, 7)
	gen upid = suhid + pid 
	drop suhid
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/7 L-2011/2011R", replace
	
/* 2010 */
	clear
	local filen : dir "${datapath}/EU-SILC/6 L-2010/"  files "udb_l10r_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/6 L-2010/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
use `"`fileln'"', clear
	
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring rb030, replace format("%15.0f")
	tostring rb040, replace 
	gen year = rb010
	gen hid = rb040
	gen pid = rb030 
	gen country = rb020
	sort year country hid 
	/*checking for duplicates or errors in id*/
	duplicates report country year hid pid
 	duplicates report country year pid
	/*merge with IDs from house hold register (D file) and drop households that are only in the D file, but not in the R file */
	merge m:1 year country hid using "${datapath}/EU-SILC/6 L-2010/2010D.dta"
	keep if _merge == 3 
	drop _merge 
	/*genereate personal IDs that are unique across all releases by taking the first 7 numbers of uhid and adding them to pid*/
	/*keep in mind that there are some individuals present in more than one family, so there are duplicates in upid alone but not in uhid and upid */
	gen suhid = substr(uhid, 1, 7)
	gen upid = suhid + pid 
	drop suhid
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/6 L-2010/2010R", replace
	
/* 2009 */
	clear
	local filen : dir "${datapath}/EU-SILC/5 L-2009/"  files "udb_l09r_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/5 L-2009/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
use `"`fileln'"', clear
	
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring rb030, replace format("%15.0f")
	tostring rb040, replace 
	gen year = rb010
	gen hid = rb040
	gen pid = rb030 
	gen country = rb020
	sort year country hid 
	/*checking for duplicates or errors in id*/
	duplicates report country year hid pid
 	duplicates report country year pid
	/*merge with IDs from house hold register (D file) and drop households that are only in the D file, but not in the R file */
	merge m:1 year country hid using "${datapath}/EU-SILC/5 L-2009/2009D.dta"
	keep if _merge == 3 
	drop _merge 
	/*genereate personal IDs that are unique across all releases by taking the first 7 numbers of uhid and adding them to pid*/
	/*keep in mind that there are some individuals present in more than one family, so there are duplicates in upid alone but not in uhid and upid */
	gen suhid = substr(uhid, 1, 7)
	gen upid = suhid + pid 
	drop suhid
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/5 L-2009/2009R", replace
		
/* 2008 */
	clear
	local filen : dir "${datapath}/EU-SILC/4 L-2008/"  files "udb_l08r_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/4 L-2008/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
use `"`fileln'"', clear
	
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring rb030, replace format("%15.0f")
	tostring rb040, replace 
	gen year = rb010
	gen hid = rb040
	gen pid = rb030 
	gen country = rb020
	sort year country hid 
	/*checking for duplicates or errors in id*/
	duplicates report country year hid pid
 	duplicates report country year pid
	/*merge with IDs from house hold register (D file) and drop households that are only in the D file, but not in the R file */
	merge m:1 year country hid using "${datapath}/EU-SILC/4 L-2008/2008D.dta"
	keep if _merge == 3 
	drop _merge 
	/*genereate personal IDs that are unique across all releases by taking the first 7 numbers of uhid and adding them to pid*/
	/*keep in mind that there are some individuals present in more than one family, so there are duplicates in upid alone but not in uhid and upid */
	gen suhid = substr(uhid, 1, 7)
	gen upid = suhid + pid 
	drop suhid
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/4 L-2008/2008R", replace
	
/* 2008 */
	clear
	local filen : dir "${datapath}/EU-SILC/3 L-2007/"  files "udb_l07r_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/3 L-2007/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring rb030, replace format("%15.0f")
	tostring rb040, replace 
	gen year = rb010
	gen hid = rb040
	gen pid = rb030 
	gen country = rb020
	sort year country hid 
	/*checking for duplicates or errors in id*/
	duplicates report country year hid pid
 	duplicates report country year pid
	/*merge with IDs from house hold register (D file) and drop households that are only in the D file, but not in the R file */
	merge m:1 year country hid using "${datapath}/EU-SILC/3 L-2007/2007D.dta"
	keep if _merge == 3 
	drop _merge 
	/*genereate personal IDs that are unique across all releases by taking the first 7 numbers of uhid and adding them to pid*/
	/*keep in mind that there are some individuals present in more than one family, so there are duplicates in upid alone but not in uhid and upid */
	gen suhid = substr(uhid, 1, 7)
	gen upid = suhid + pid 
	drop suhid
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/3 L-2007/2007R", replace
		
/* 2006 */
	clear
	local filen : dir "${datapath}/EU-SILC/2 L-2006/"  files "udb_l06r_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/2 L-2006/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring rb030, replace format("%15.0f")
	tostring rb040, replace 
	gen year = rb010
	gen hid = rb040
	gen pid = rb030 
	gen country = rb020
	sort year country hid 
	/*checking for duplicates or errors in id*/
	duplicates report country year hid pid
 	duplicates report country year pid
	/*merge with IDs from house hold register (D file) and drop households that are only in the D file, but not in the R file */
	merge m:1 year country hid using "${datapath}/EU-SILC/2 L-2006/2006D.dta"
	keep if _merge == 3 
	drop _merge 
	/*genereate personal IDs that are unique across all releases by taking the first 7 numbers of uhid and adding them to pid*/
	/*keep in mind that there are some individuals present in more than one family, so there are duplicates in upid alone but not in uhid and upid */
	gen suhid = substr(uhid, 1, 7)
	gen upid = suhid + pid 
	drop suhid
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/2 L-2006/2006R", replace
			
/* 2005 */
	clear
	local filen : dir "${datapath}/EU-SILC/1 L-2005/"  files "udb_l05r_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/1 L-2005/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
use `"`fileln'"', clear
	
	
	local new_var=lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	tostring rb030, replace format("%15.0f")
	tostring rb040, replace 
	gen year = rb010
	gen hid = rb040
	gen pid = rb030 
	gen country = rb020
	sort year country hid 
	/*checking for duplicates or errors in id*/
	duplicates report country year hid pid 	
	duplicates report country year pid
	/*merge with IDs from house hold register (D file) and drop households that are only in the D file, but not in the R file */
	merge m:1 year country hid using "${datapath}/EU-SILC/1 L-2005/2005D.dta"
	keep if _merge == 3 
	drop _merge 
	/*genereate personal IDs that are unique across all releases by taking the first 7 numbers of uhid and adding them to pid*/
	/*keep in mind that there are some individuals present in more than one family, so there are duplicates in upid alone but not in uhid and upid */
	gen suhid = substr(uhid, 1, 7)
	gen upid = suhid + pid 
	drop suhid
	/*this is the masterfileR where to add data from previous releases to */
	save "${datapath}/EU-SILC/1 L-2005/2005R", replace
	
	/*merge data from all releases into one masterfile. 
	!! this process is memory intensive. */
	
	use "${datapath}/EU-SILC/19 L-2023/2023R.dta", clear

	merge 1:1 year upid uhid using "${datapath}/EU-SILC/18 L-2022/2022R.dta"
	drop _merge
	merge 1:1 year upid uhid using "${datapath}/EU-SILC/17 L-2021/2021R.dta"
	drop _merge
	merge 1:1 year upid uhid using "${datapath}/EU-SILC/16 L-2020/2020R.dta"
	drop _merge
	save "${datapath}/EU-SILC/19 L-2023/masterR.dta", replace
	clear
	
	use "${datapath}/EU-SILC/19 L-2023/masterR.dta", clear

	merge 1:1 year upid uhid using "${datapath}/EU-SILC/15 L-2019/2019R.dta"
	drop _merge
	merge 1:1 year upid uhid using "${datapath}/EU-SILC/14 L-2018/2018R.dta"
	drop _merge
	merge 1:1 year upid uhid using "${datapath}/EU-SILC/13 L-2017/2017R.dta"
	drop _merge
	merge 1:1 year upid uhid using "${datapath}/EU-SILC/12 L-2016/2016R.dta"
	drop _merge
	merge 1:1 year upid uhid using "${datapath}/EU-SILC/11 L-2015/2015R.dta"
	drop _merge
	save "${datapath}/EU-SILC/19 L-2023/masterR.dta", replace
	clear
	
	use "${datapath}/EU-SILC/19 L-2023/masterR.dta", clear
	
	merge 1:1 year upid uhid using "${datapath}/EU-SILC/10 L-2014/2014R.dta"
	drop _merge
	merge 1:1 year upid uhid using "${datapath}/EU-SILC/9 L-2013/2013R.dta"
	drop _merge
	merge 1:1 year upid uhid using "${datapath}/EU-SILC/8 L-2012/2012R.dta"
	drop _merge
	merge 1:1 year upid uhid using "${datapath}/EU-SILC/7 L-2011/2011R.dta"
	drop _merge
	merge 1:1 year upid uhid using "${datapath}/EU-SILC/6 L-2010/2010R.dta"
	drop _merge
	merge 1:1 year upid uhid using "${datapath}/EU-SILC/5 L-2009/2009R.dta"
	drop _merge
	save "${datapath}/EU-SILC/19 L-2023/masterR.dta", replace
	clear
	
	use "${datapath}/EU-SILC/19 L-2023/masterR.dta", clear
	merge 1:1 year upid uhid using "${datapath}/EU-SILC/4 L-2008/2008R.dta"
	drop _merge
	merge 1:1 year upid uhid using "${datapath}/EU-SILC/3 L-2007/2007R.dta"
	drop _merge
	save "${datapath}/EU-SILC/19 L-2023/masterR.dta", replace
	clear
	
	use "${datapath}/EU-SILC/19 L-2023/masterR.dta", clear
	merge 1:1 year upid uhid using "${datapath}/EU-SILC/2 L-2006/2006R.dta"
	drop _merge
	save "${datapath}/EU-SILC/19 L-2023/masterR.dta", replace
	clear
	
	use "${datapath}/EU-SILC/19 L-2023/masterR.dta", clear
	merge 1:1 year upid uhid using "${datapath}/EU-SILC/1 L-2005/2005R.dta"
	drop _merge

	/* drop superflous variables*/
	drop db010 db020 db030 db040 db040_f db060 db060_f db062 db062_f db070 db070_f db075 db075_f db095 db095_f db100 db100_f db110 db110_f ///
	nrtgrp* slctd_rtgrp drpout_year drpout_year* slctd_urtgrp* slctd_uhid*  maxgrp lgstgrp drpout_year* ///
    db090 db090_f nrtgrp2013  merge*  
	
	/*adding upidnum*/
	egen upidnum = group(upid)
	save "${datapath}/EU-SILC/19 L-2023/masterR.dta", replace

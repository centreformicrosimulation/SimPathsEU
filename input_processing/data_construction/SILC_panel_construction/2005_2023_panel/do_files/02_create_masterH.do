/*******************************************************************************
SUMMARY — 02_create_masterH.do 

This do-file builds the master household (H) panel dataset for EU-SILC 2005-2023
It runs in two steps:

STEP 1 
	Create clean annual H files (one block per release year, 2023 down to 2005)
	For each year, the raw H data file is read and merged 1:1 with the 
	corresponding YYYYD.dta produced by 01_create_masterD.do. 
	Keeping only _merge == 3 selects the correct sample: the D file has already 
	handled all cross-release deduplication and rotation group selection, so the 
	H file inherits a clean sample through this merge.
	Each annual block saves a YYYYH.dta file containing both H and D variables 
	for the selected households in that release year. 
	The 2023 block is the master year and also saves masterH.dta.

STEP 2  
	Assemble the full panel
	The 2023 masterH.dta is loaded and the annual YYYYH.dta files from 2022 back 
	to 2005 are merged in sequentially using year and uhid. Because the D file 
	ensured uhid is unique across releases, the 1:1 merges produce no 
	duplicates. 
	Superfluous D-file variables are dropped and the combined dataset is saved 
	as the final masterH.dta in the 2024 release folder.

NOTE: This file must be run after 01_create_masterD.do. All cross-release 
deduplication logic resides in the D file; this file trusts and relies on its 
output.
*******************************************************************************/
	
/* 2023 */
	clear
	local filen : dir "${datapath}/EU-SILC/19 L-2023/"  files "udb_l23h_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/19 L-2023/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }

	* block Stata from displaying IDs in exponential format*
	tostring hb030, replace
	gen year = hb010
	gen hid = hb030 
	gen country = hb020 
	sort year country hid 
	
	*checking for duplicates or errors in hid*
	duplicates report country year hid 
	
	/* select observations/households by merging with selected rotational groups from the D file */
	merge 1:1 year country hid using "${datapath}/EU-SILC/19 L-2023/2023D.dta"
	keep if _merge == 3
	drop _merge
	destring hb100 , replace force
	save "${datapath}/EU-SILC/19 L-2023/masterH.dta", replace
	
/* 2022 */	
	clear
	local filen : dir "${datapath}/EU-SILC/18 L-2022/"  files "udb_l22h_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/18 L-2022/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	* block Stata from displaying IDs in exponential format*
	tostring hb030, replace
	gen year = hb010
	gen hid = hb030 
	gen country = hb020 
	sort year country hid 
	
	*checking for duplicates or errors in hid*
	duplicates report country year hid 
	
	/* select observations/households by merging with selected rotational groups from the D file */
	merge 1:1 year country hid using "${datapath}/EU-SILC/18 L-2022/2022D.dta"
	keep if _merge == 3
	drop _merge
	destring hb100 , replace force
	save "${datapath}/EU-SILC/18 L-2022/2022H.dta", replace

/* 2021 */
	clear
	local filen : dir "${datapath}/EU-SILC/17 L-2021/"  files "udb_l21h_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/17 L-2021/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear

	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	

	* block Stata from displaying IDs in exponential format*
	tostring hb030, replace
	gen year = hb010
	gen hid = hb030 
	gen country = hb020 
	sort year country hid 
	*checking for duplicates or errors in hid*
	duplicates report country year hid 
	/* select observations/households by merging with selected rotational groups from the D file */
	merge 1:1 year country hid using "${datapath}/EU-SILC/17 L-2021/2021D.dta"
	keep if _merge == 3
	drop _merge
	destring hb100 , replace force
	save "${datapath}/EU-SILC/17 L-2021/2021H.dta", replace
	
/* 2020 */
	clear
	local filen : dir "${datapath}/EU-SILC/16 L-2020/"  files "udb_l20h_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/16 L-2020/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	* block Stata from displaying IDs in exponential format*
	tostring hb030, replace
	gen year = hb010
	gen hid = hb030 
	gen country = hb020 
	sort year country hid 
	
	*checking for duplicates or errors in hid*
	duplicates report country year hid 
	
	/* select observations/households by merging with selected rotational groups from the D file */
	merge 1:1 year country hid using "${datapath}/EU-SILC/16 L-2020/2020D.dta"
	keep if _merge == 3
	drop _merge
	destring hb100 , replace force
	save "${datapath}/EU-SILC/16 L-2020/2020H.dta", replace
	
/* 2019 */	
	clear
	local filen : dir "${datapath}/EU-SILC/15 L-2019/"  files "udb_l19h_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/15 L-2019/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	

	* block Stata from displaying IDs in exponential format*
	tostring hb030, replace
	gen year = hb010
	gen hid = hb030 
	gen country = hb020 
	sort year country hid 
	
	*checking for duplicates or errors in hid*
	duplicates report country year hid 
	
	/* select observations/households by merging with selected rotational groups from the D file */
	merge 1:1 year country hid using "${datapath}/EU-SILC/15 L-2019/2019D.dta"
	keep if _merge == 3
	drop _merge
	destring hb100 , replace force
	save "${datapath}/EU-SILC/15 L-2019/2019H.dta", replace

/* 2018 */
	clear
	local filen : dir "${datapath}/EU-SILC/14 L-2018/"  files "udb_l18h_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/14 L-2018/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	

	* block Stata from displaying IDs in exponential format*
	tostring hb030, replace
	gen year = hb010
	gen hid = hb030 
	gen country = hb020 
	sort year country hid 
	*checking for duplicates or errors in hid*
	duplicates report country year hid 
	/* select observations/households by merging with selected rotational groups from the D file */
	merge 1:1 year country hid using "${datapath}/EU-SILC/14 L-2018/2018D.dta"
	keep if _merge == 3
	drop _merge
	destring hb100 , replace force
	save "${datapath}/EU-SILC/14 L-2018/2018H.dta", replace

/* 2017 */
	clear
	local filen : dir "${datapath}/EU-SILC/13 L-2017/"  files "udb_l17h_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/13 L-2017/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	

	* block Stata from displaying IDs in exponential format*
	tostring hb030, replace
	gen year = hb010
	gen hid = hb030 
	gen country = hb020 
	sort year country hid 
	*checking for duplicates or errors in hid*
	duplicates report country year hid 
	/* select observations/households by merging with selected rotational groups from the D file */
	merge 1:1 year country hid using "${datapath}/EU-SILC/13 L-2017/2017D.dta"
	keep if _merge == 3
	drop _merge
	destring hb100 , replace force
	save "${datapath}/EU-SILC/13 L-2017/2017H.dta", replace

/* 2016 */	
	clear
	local filen : dir "${datapath}/EU-SILC/12 L-2016/"  files "udb_l16h_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/12 L-2016/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	

	* block Stata from displaying IDs in exponential format*
	tostring hb030, replace
	gen year = hb010
	gen hid = hb030 
	gen country = hb020 
	sort year country hid 
	*checking for duplicates or errors in hid*
	duplicates report country year hid 
	/* select observations/households by merging with selected rotational groups from the D file */
	merge 1:1 year country hid using "${datapath}/EU-SILC/12 L-2016/2016D.dta"
	keep if _merge == 3
	drop _merge
	destring hb100 , replace force
	save "${datapath}/EU-SILC/12 L-2016/2016H.dta", replace
	
/* 2015 */
	clear
	local filen : dir "${datapath}/EU-SILC/11 L-2015/"  files "udb_l15h_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/11 L-2015/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	

	* block Stata from displaying IDs in exponential format*
	tostring hb030, replace
	gen year = hb010
	gen hid = hb030 
	gen country = hb020 
	sort year country hid 
	*checking for duplicates or errors in hid*
	duplicates report country year hid 
	/* select observations/households by merging with selected rotational groups from the D file */
	merge 1:1 year country hid using "${datapath}/EU-SILC/11 L-2015/2015D.dta"
	keep if _merge == 3
	drop _merge
	destring hb100 , replace force
	save "${datapath}/EU-SILC/11 L-2015/2015H.dta", replace

/* 2014 */
	clear
	local filen : dir "${datapath}/EU-SILC/10 L-2014/" files "udb_l14h_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/10 L-2014/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	/* block Stata from displaying IDs in exponential format */
	tostring hb030, replace
	gen year = hb010
	gen hid = hb030 
	tostring hid, replace
	gen country = hb020 
	sort year country hid 
	/* checking for duplicates or errors in hid */
	duplicates report country year hid 
	/* select observations/households by merging with selected rotational groups from the D file */
	merge 1:1 year country hid using "${datapath}/EU-SILC/10 L-2014/2014D.dta"
	keep if _merge == 3
	drop _merge
	destring hb100 , replace force
	save "${datapath}/EU-SILC/10 L-2014/2014H.dta", replace

/* 2013 */	
	clear
	local filen : dir "${datapath}/EU-SILC/9 L-2013/" files "udb_l13h_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/9 L-2013/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
use `"`fileln'"', clear
	
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	/* block Stata from displaying IDs in exponential format */
	tostring hb030, replace
	gen year = hb010
	gen hid = hb030 
	tostring hid, replace
	gen country = hb020 
	sort year country hid 
	/* checking for duplicates or errors in hid */
	duplicates report country year hid 
	/* select observations/households by merging with selected rotational groups from the D file */
		
	merge 1:1 year country hid using "${datapath}/EU-SILC/9 L-2013/2013D.dta"
	keep if _merge == 3
	drop _merge
	destring hb100 , replace force
	save "${datapath}/EU-SILC/9 L-2013/2013H.dta", replace
	
	clear
	local filen : dir "${datapath}/EU-SILC/8 L-2012/" files "udb_l12h_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/8 L-2012/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
	use `"`fileln'"', clear
	
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	

	/* block Stata from displaying IDs in exponential format */
	tostring hb030, replace
	gen year = hb010
	gen hid = hb030 
	tostring hid, replace
	gen country = hb020 
	sort year country hid 
	/* checking for duplicates or errors in hid */
	duplicates report country year hid 
	/* select observations/households by merging with selected rotational groups from the D file */
	merge 1:1 year country hid using "${datapath}/EU-SILC/8 L-2012/2012D.dta"
	keep if _merge == 3
	drop _merge
	destring hb100 , replace force
	save "${datapath}/EU-SILC/8 L-2012/2012H.dta", replace
	
/* 2011 */	
	clear
	local filen : dir "${datapath}/EU-SILC/7 L-2011/" files "udb_l11h_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/7 L-2011/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
use `"`fileln'"', clear
	
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	/* block Stata from displaying IDs in exponential format */
	tostring hb030, replace
	gen year = hb010
	gen hid = hb030 
	tostring hid, replace
	gen country = hb020 
	sort year country hid 
	/* checking for duplicates or errors in hid */
	duplicates report country year hid 
	/* select observations/households by merging with selected rotational groups from the D file */
	merge 1:1 year country hid using "${datapath}/EU-SILC/7 L-2011/2011D.dta"
	keep if _merge == 3
	drop _merge
	destring hb100 , replace force
	save "${datapath}/EU-SILC/7 L-2011/2011H.dta", replace
	
/* 2010 */	
	clear
	local filen : dir "${datapath}/EU-SILC/6 L-2010/" files "udb_l10h_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/6 L-2010/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
use `"`fileln'"', clear
	
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	

	/* block Stata from displaying IDs in exponential format */
	tostring hb030, replace
	gen year = hb010
	gen hid = hb030 
	tostring hid, replace
	gen country = hb020 
	sort year country hid 
	/* checking for duplicates or errors in hid */
	duplicates report country year hid 
	/* select observations/households by merging with selected rotational groups from the D file */
		
	merge 1:1 year country hid using "${datapath}/EU-SILC/6 L-2010/2010D.dta"
	keep if _merge == 3
	drop _merge
	destring hb100 , replace force
	save "${datapath}/EU-SILC/6 L-2010/2010H.dta", replace
	
/* 2009 */ 	
	clear
	local filen : dir "${datapath}/EU-SILC/5 L-2009/" files "udb_l09h_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/5 L-2009/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
use `"`fileln'"', clear
	
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	/* block Stata from displaying IDs in exponential format */
	tostring hb030, replace
	gen year = hb010
	gen hid = hb030 
	tostring hid, replace
	gen country = hb020 
	sort year country hid 
	/* checking for duplicates or errors in hid */
	duplicates report country year hid 
	/* select observations/households by merging with selected rotational groups from the D file */
	merge 1:1 year country hid using "${datapath}/EU-SILC/5 L-2009/2009D.dta"
	keep if _merge == 3
	drop _merge
	destring hb100 , replace force
	save "${datapath}/EU-SILC/5 L-2009/2009H.dta", replace
	
/* 2008 */ 	
	clear
	local filen : dir "${datapath}/EU-SILC/4 L-2008/" files "udb_l08h_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/4 L-2008/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
use `"`fileln'"', clear
	
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	

	/* block Stata from displaying IDs in exponential format */
	tostring hb030, replace
	gen year = hb010
	gen hid = hb030 
	tostring hid, replace
	gen country = hb020 
	sort year country hid 
	/* checking for duplicates or errors in hid */
	duplicates report country year hid 
	/* select observations/households by merging with selected rotational groups from the D file */
	merge 1:1 year country hid using "${datapath}/EU-SILC/4 L-2008/2008D.dta"
	keep if _merge == 3
	drop _merge
	destring hb100 , replace force
	save "${datapath}/EU-SILC/4 L-2008/2008H.dta", replace
	
/* 2007 */ 	
	clear
	local filen : dir "${datapath}/EU-SILC/3 L-2007/" files "udb_l07h_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/3 L-2007/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
use `"`fileln'"', clear
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	/* block Stata from displaying IDs in exponential format */
	tostring hb030, replace
	gen year = hb010
	gen hid = hb030 
	tostring hid, replace
	gen country = hb020 
	sort year country hid 
	/* checking for duplicates or errors in hid */
	duplicates report country year hid 
	* select observations/households by merging with selected rotational groups from the D file */
	merge 1:1 year country hid using "${datapath}/EU-SILC/3 L-2007/2007D.dta"
	keep if _merge == 3
	drop _merge
	destring hb100 , replace force
	save "${datapath}/EU-SILC/3 L-2007/2007H.dta", replace
	
/* 2006 */ 	
	clear
	local filen : dir "${datapath}/EU-SILC/2 L-2006/" files "udb_l06h_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/2 L-2006/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
use `"`fileln'"', clear
	
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	

	/* block Stata from displaying IDs in exponential format */
	tostring hb030, replace
	gen year = hb010
	gen hid = hb030 
	tostring hid, replace
	gen country = hb020 
	sort year country hid 
	/* checking for duplicates or errors in hid */
	duplicates report country year hid 
	
	/* select observations/households by merging with selected rotational groups from the D file */
	merge 1:1 year country hid using "${datapath}/EU-SILC/2 L-2006/2006D.dta"
	keep if _merge == 3
	drop _merge
	destring hb100 , replace force
	save "${datapath}/EU-SILC/2 L-2006/2006H.dta", replace
	
/* 2005 */ 	
	clear
	local filen : dir "${datapath}/EU-SILC/1 L-2005/" files "udb_l05h_ver*"
	display `filen'
	local filel "${datapath}/EU-SILC/1 L-2005/"
	display `"`filel'"'
	local fileln : display `"`filel'"' `filen'
use `"`fileln'"', clear
	
	
	local new_var = lower("`var'")

    foreach var of varlist _all {
    	local new_var = lower("`var'")
    	cap rename `var' `new_var'
    }
	
	/* block Stata from displaying IDs in exponential format */
	tostring hb030, replace
	gen year = hb010
	gen hid = hb030 
	tostring hid, replace
	gen country = hb020 
	sort year country hid 
	/* checking for duplicates or errors in hid */
	duplicates report country year hid 
	/* select observations/households by merging with selected rotational groups from the D file */
	merge 1:1 year country hid using "${datapath}/EU-SILC/1 L-2005/2005D.dta"
	keep if _merge == 3
	drop _merge
	destring hb100 , replace force
	save "${datapath}/EU-SILC/1 L-2005/2005H.dta", replace

	
	/* merge masterH with the 20XXH files from previous releases */
	use "${datapath}/EU-SILC/19 L-2023/masterH.dta", clear
	merge 1:1 year uhid using "${datapath}/EU-SILC/18 L-2022/2022H.dta"
	drop _merge	
	merge 1:1 year uhid using "${datapath}/EU-SILC/17 L-2021/2021H.dta"
	drop _merge	
	merge 1:1 year uhid using "${datapath}/EU-SILC/16 L-2020/2020H.dta"
	drop _merge	
	merge 1:1 year uhid using "${datapath}/EU-SILC/15 L-2019/2019H.dta"
	drop _merge	
	merge 1:1 year uhid using "${datapath}/EU-SILC/14 L-2018/2018H.dta"
	drop _merge
	merge 1:1 year uhid using "${datapath}/EU-SILC/13 L-2017/2017H.dta"
	drop _merge
	merge 1:1 year uhid using "${datapath}/EU-SILC/12 L-2016/2016H.dta"
	drop _merge
	merge 1:1 year uhid using "${datapath}/EU-SILC/11 L-2015/2015H.dta"
	drop _merge
	merge 1:1 year uhid using "${datapath}/EU-SILC/10 L-2014/2014H.dta"
	drop _merge
	merge 1:1 year uhid using "${datapath}/EU-SILC/9 L-2013/2013H.dta"
	drop _merge
	merge 1:1 year uhid using "${datapath}/EU-SILC/8 L-2012/2012H.dta"
	drop _merge
	merge 1:1 year uhid using "${datapath}/EU-SILC/7 L-2011/2011H.dta"
	drop _merge
	merge 1:1 year uhid using "${datapath}/EU-SILC/6 L-2010/2010H.dta"
	drop _merge
	merge 1:1 year uhid using "${datapath}/EU-SILC/5 L-2009/2009H.dta"
	drop _merge
	merge 1:1 year uhid using "${datapath}/EU-SILC/4 L-2008/2008H.dta"
	drop _merge
	merge 1:1 year uhid using "${datapath}/EU-SILC/3 L-2007/2007H.dta"
	drop _merge
	merge 1:1 year uhid using "${datapath}/EU-SILC/2 L-2006/2006H.dta"
	drop _merge
	merge 1:1 year uhid using "${datapath}/EU-SILC/1 L-2005/2005H.dta"
	drop _merge
	
	/* drop superflous variables */
	drop db010 db020 db030 db040 db040_f db060 db060_f db062 db062_f db070 db070_f db075 db075_f db095 db095_f db100 db100_f db110 db110_f ///
	nrtgrp* slctd_rtgrp drpout_year drpout_year* slctd_uhid* slctd_urtgrp* ///
	maxgrp lgstgrp db090 db090_f merge* 

	save "${datapath}/EU-SILC/19 L-2023/masterH.dta", replace


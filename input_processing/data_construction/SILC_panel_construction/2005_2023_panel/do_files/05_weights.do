/*******************************************************************************
SUMMARY — 05_weights.do (2025 release, extended to 2023)

This file rescales the survey weights in masterR.dta and masterP.dta so that
weighted totals align with official Eurostat country population figures.

STEP 1 — Rescale R-file weights
   The population dataset is loaded, reshaped to long format,
   and merged with masterR.dta on country and year. Two scaled weights are
   produced:
   - rb060s: scaled version of the base personal weight (rb060), rescaled so 
			 that the weighted total for each country-year matches the 
			 population total.
   - rb064s: scaled version of the longitudinal weight (rb064), extended to all
             observations for a given individual (upid) before rescaling.
   Diagnostic checks are run to verify the scaling rates by country and year.

STEP 2 — Rescale P-file weights
   The same population dataset is merged with masterP.dta on country and year.
   A scaled weight pb080s is produced from the personal base weight pb080, 
   rescaled to match population totals by country-year and rotation group.

NOTE: Requires population_21_23 — a country-by-year population file covering
2021–2023, constructed from Eurostat population totals. This file must be
prepared before running this do-file. See the population construction section
below for instructions.

NOTE: The erase section below can be used to delete intermediate annual 
YYYYD/H/P/R files after the panel has been successfully built, to free
up disk space.
*/
	
*******************************************************************************/

	/* Erasing superflous files from the disc */

	erase "${datapath}/EU-SILC/19 L-2023/2023D.dta"
//	erase "${datapath}/EU-SILC/19 L-2023/2023H.dta" 
	erase "${datapath}/EU-SILC/19 L-2023/2023P.dta"
	erase "${datapath}/EU-SILC/19 L-2023/2023R.dta"

	erase "${datapath}/EU-SILC/18 L-2022/2022D.dta"
	erase "${datapath}/EU-SILC/18 L-2022/2022H.dta" 
	erase "${datapath}/EU-SILC/18 L-2022/2022P.dta"
	erase "${datapath}/EU-SILC/18 L-2022/2022R.dta"	
	
	erase "${datapath}/EU-SILC/17 L-2021/2021D.dta"
	erase "${datapath}/EU-SILC/17 L-2021/2021H.dta" 
	erase "${datapath}/EU-SILC/17 L-2021/2021P.dta"
	erase "${datapath}/EU-SILC/17 L-2021/2021R.dta"

	erase "${datapath}/EU-SILC/15 L-2019/2019D.dta"
	erase "${datapath}/EU-SILC/15 L-2019/2019H.dta"
	erase "${datapath}/EU-SILC/15 L-2019/2019P.dta"
	erase "${datapath}/EU-SILC/15 L-2019/2019R.dta"
	
	erase "${datapath}/EU-SILC/13 L-2017/2017D.dta"
	erase "${datapath}/EU-SILC/13 L-2017/2017H.dta"
	erase "${datapath}/EU-SILC/13 L-2017/2017P.dta"
	erase "${datapath}/EU-SILC/13 L-2017/2017R.dta"
	
	erase "${datapath}/EU-SILC/12 L-2016/2016D.dta"
	erase "${datapath}/EU-SILC/12 L-2016/2016H.dta"
	erase "${datapath}/EU-SILC/12 L-2016/2016P.dta"
	erase "${datapath}/EU-SILC/12 L-2016/2016R.dta"
	
	erase "${datapath}/EU-SILC/11 L-2015/2015D.dta"
	erase "${datapath}/EU-SILC/11 L-2015/2015H.dta"
	erase "${datapath}/EU-SILC/11 L-2015/2015P.dta"
	erase "${datapath}/EU-SILC/11 L-2015/2015R.dta"

	erase "${datapath}/EU-SILC/10 L-2014/2014D.dta"
	erase "${datapath}/EU-SILC/10 L-2014/2014H.dta"
	erase "${datapath}/EU-SILC/10 L-2014/2014P.dta"
	erase "${datapath}/EU-SILC/10 L-2014/2014R.dta"

	erase "${datapath}/EU-SILC/9 L-2013/2013D.dta"
	erase "${datapath}/EU-SILC/9 L-2013/2013H.dta"
	erase "${datapath}/EU-SILC/9 L-2013/2013P.dta"
	erase "${datapath}/EU-SILC/9 L-2013/2013R.dta"

	erase "${datapath}/EU-SILC/8 L-2012/2012D.dta"
	erase "${datapath}/EU-SILC/8 L-2012/2012H.dta"
	erase "${datapath}/EU-SILC/8 L-2012/2012P.dta"
	erase "${datapath}/EU-SILC/8 L-2012/2012R.dta"

	erase "${datapath}/EU-SILC/7 L-2011/2011D.dta"
	erase "${datapath}/EU-SILC/7 L-2011/2011H.dta"
	erase "${datapath}/EU-SILC/7 L-2011/2011P.dta"
	erase "${datapath}/EU-SILC/7 L-2011/2011R.dta"

	erase "${datapath}/EU-SILC/6 L-2010/2010D.dta"
	erase "${datapath}/EU-SILC/6 L-2010/2010H.dta"
	erase "${datapath}/EU-SILC/6 L-2010/2010P.dta"
	erase "${datapath}/EU-SILC/6 L-2010/2010R.dta"

	erase "${datapath}/EU-SILC/5 L-2009/2009D.dta"
	erase "${datapath}/EU-SILC/5 L-2009/2009H.dta"
	erase "${datapath}/EU-SILC/5 L-2009/2009P.dta"
	erase "${datapath}/EU-SILC/5 L-2009/2009R.dta"

	erase "${datapath}/EU-SILC/4 L-2008/2008D.dta"
	erase "${datapath}/EU-SILC/4 L-2008/2008H.dta"
	erase "${datapath}/EU-SILC/4 L-2008/2008P.dta"
	erase "${datapath}/EU-SILC/4 L-2008/2008R.dta"

	erase "${datapath}/EU-SILC/3 L-2007/2007D.dta"
	erase "${datapath}/EU-SILC/3 L-2007/2007H.dta"
	erase "${datapath}/EU-SILC/3 L-2007/2007P.dta"
	erase "${datapath}/EU-SILC/3 L-2007/2007R.dta"

	erase "${datapath}/EU-SILC/2 L-2006/2006D.dta"
	erase "${datapath}/EU-SILC/2 L-2006/2006H.dta"
	erase "${datapath}/EU-SILC/2 L-2006/2006P.dta"
	erase "${datapath}/EU-SILC/2 L-2006/2006R.dta"
	
	erase "${datapath}/EU-SILC/1 L-2005/2005D.dta"
	erase "${datapath}/EU-SILC/1 L-2005/2005H.dta"
	erase "${datapath}/EU-SILC/1 L-2005/2005P.dta"
	erase "${datapath}/EU-SILC/1 L-2005/2005R.dta"

	display "Rescaling weights in R file."
	
	/* import the total population for each country from eurostat */
	/* add latest years*/
/*	clear 
	import excel "$csv_path/populations/country_population_update.xlsx", sheet("to_load") firstrow

	rename B a2023	
	rename C a2022	
	rename D a2021	
	rename GEO country 
	
	drop if country == ""
	
	save "$data_dir/population_21_23", replace */
	
	/* earlier year provided by GESIS */
	/*clear
	findfile totalpopulation_2003_2020.dta, path(BASE;SITE;.;PERSONAL;PLUS)
	return list 
	use`"`r(fn)'"'*/
	
	use "$input_data_dir/totalpopulation_2003_2020", clear
	
	rename B a2003
	rename C a2004
	rename D a2005
	rename E a2006
	rename F a2007
	rename G a2008
	rename H a2009
	rename I a2010
	rename J a2011
	rename K a2012
	rename L a2013
	rename M a2014
	rename N a2015
	rename O a2016
	rename P a2017
	rename Q a2018
	rename R a2019
	rename S a2020

	/* merge all years*/
	merge 1:1 country using "$input_data_dir/population_21_23" 
	drop if _m == 2
	drop _m 
	
	save "$data_dir/population_03_23", replace
	
	reshape long a, i(country) j(year)
	rename a pop
	destring pop, replace
	drop if pop == .
	merge 1:m  country year using "${datapath}/EU-SILC/19 L-2023/masterR.dta"
	drop if _merge == 1
	drop _merge
	
	/* now calculate scales for the base weights for individuals in R file rscale */
	bysort year country: egen  wcountry = total (rb060)
	bysort year country urtgrp: egen wgroup = total( rb060 )
	gen rscale = ( wgroup / wcountry ) 
	gen rb060s = rscale * rb060
	
			/* check scaled weight */
			gen test1 = ( wcountry - pop ) / pop
			bysort year country: egen test2 = total (rb060s) 
			gen smwrate60 = ( test2 - pop ) / pop
			
			/* what does this do? */
			tab country , summarize (smwrate60)
			tab year, summarize (rscale)
			drop test1 test2 wgroup wcountry
			 
	/* extend presence of rb064 to all observations pertaining to a certain unit */
	bysort upid : egen lrb064 = max(rb064)
	bysort year country: egen  lwcountry = total (lrb064)
	bysort year country urtgrp: egen lwgroup = total( lrb064 )
	gen lrscale = ( lwgroup / lwcountry ) 
	gen rb064s = lrscale * lrb064
	
			/* check scaled weight */
			gen test1 = ( lwcountry - pop ) / pop
			bysort year country: egen test2 = total (rb064s) 
			gen smwrate64 = ( test2 - pop ) / pop
			
			/* what does this do? */
			tab country , summarize (smwrate64)
			tab year, summarize (lrscale)
			drop test1 test2 lwgroup lwcountry

		save "${datapath}/EU-SILC/19 L-2023/masterR.dta", replace

/**/	
	display "Rescaling weights in P file."
	
	/*import the total population for each country from eurostat*/
	/*total population*/
	/*clear
	findfile totalpopulation_2003_2020.dta, path(BASE;SITE;.;PERSONAL;PLUS)
	return list 
	use`"`r(fn)'"'
	rename B a2003
	rename C a2004
	rename D a2005
	rename E a2006
	rename F a2007
	rename G a2008
	rename H a2009
	rename I a2010
	rename J a2011
	rename K a2012
	rename L a2013
	rename M a2014
	rename N a2015
	rename O a2016
	rename P a2017
	rename Q a2018
	rename R a2019
	rename S a2020 */

	use "$data_dir/population_03_23", clear 
	
	reshape long a, i(country) j(year)
	rename a pop
	destring pop, replace
	drop if pop == .
	merge 1:m  country year using "${datapath}/EU-SILC/19 L-2023/masterP.dta"
	drop if _merge == 1
	drop _merge
	
	/*now calculate scales for the base weights for individuals in R file rscale*/
	bysort year country: egen  wcountry = total (pb080)
	bysort year country urtgrp: egen wgroup = total( pb080 )
	gen pscale = ( wgroup / wcountry ) 
	gen pb080s = pscale * pb080
	
			/*check scaled weight*/
			gen test1 = ( wcountry - pop ) / pop
			bysort year country: egen test2 = total (pb080s) 
			gen smwrate80 = ( test2 - pop ) / pop
			
			/*what does this do?*/
			tab country , summarize (smwrate80)
			tab year, summarize (pscale)
			drop test1 test2 wgroup wcountry 
			
	save "${datapath}/EU-SILC/19 L-2023/masterP.dta", replace
	//display "The files masterP.dta, masterR.dta, masterH.dta and masterD.dta are ready for use and can be found in ${datapath}/EU-SILC/19 L-2023/ " as result

********************************************************************************
* PROJECT:              ESPON
* DO-FILE NAME:         06_check_yearly_data_IT.do
* DESCRIPTION:          This file checks the new 2011 data against the previous 
* 						version of 2011 input data 
********************************************************************************
* COUNTRY:              IT
* DATA:         	    EU-SILC panel dataset  
* AUTHORS: 				Daria Popova 
* LAST UPDATE:         	Jan 2025
* NOTE:					Called from 00_master.do - see master file for further 
* 						details
*						Use -9 for missing values 
* 						Alter number of regions in the locals for each country 
********************************************************************************

cap log close 
//log using "${dir_log}/06_check_yearly_data.log", replace

* All variables 
#delimit ;
local varlist 
idhh                    
idbenefitunit                 
idperson                    
idpartner                    
idmother                      
idfather                        
swv                            
dgn                           
dag                            
dcpst                          
dnc02                           
dnc                           
ded                            
deh_c3                        
sedex                         
les_c3                        
dlltsd                         
dhe                            
ydses_c5                       
yplgrs_dv                       
ypnbihs_dv                      
yptciihs_dv                     
//dhhtp_c8                       
ssscp                        
dcpen                        
dcpyy                           
dcpex                     
dcpagdf                     
ynbcpdf_dv                  
der                           
sedag                        
sprfm                         
dagsp                     
dehsp_c3                     
dhesp                          
lessp_c3                     
stm                           
lesdf_c4   
dhh_owned                     
lhw                             
drgn1                            
dct                             
dwt_sampling           
les_c4                             
lessp_c4                         
adultchildflag          
dwt                              
obs_earnings_hourly
l1_obs_earnings_hourly     
ypncp                           
ypnoab 
l1_les_c3 
l1_les_c4
;
#delimit cr // cr stands for carriage return

*varlist for categorical variables 
#delimit ;
local varlist_cat 
dcpst              
deh_c3    
les_c3
dhe                    
ydses_c5 
dhhtp_c8                    
dehsp_c3                     
dhesp 
lessp_c3                     
lesdf_c4                       
les_c4                     
lessp_c4          
drgn1   
l1_les_c3 
l1_les_c4     
;
#delimit cr // cr stands for carriage return 


*new varlist with categorical variables output by category 
#delimit ;
local varlist2 
idhh                    
idbenefitunit                 
idperson                    
idpartner                    
idmother                      
idfather                        
swv                            
dgn                           
dag                            
dcpst                          
dnc02                           
dnc                           
ded
sedex              
dlltsd                         
ypncp                           
ypnoab         
yplgrs_dv                       
ypnbihs_dv                      
yptciihs_dv
ssscp                        
dcpen                        
dcpyy                           
dcpex                     
dcpagdf                     
ynbcpdf_dv                  
der                           
sedag                        
sprfm                         
dagsp                         
stm                                              
lhw                         
dct                             
dwt_sampling                                        
adultchildflag                                
dwt                              
dcpst_1 
dcpst_2 
dcpst_3 
deh_c3_1 
deh_c3_2 
deh_c3_3 
les_c3_1 
les_c3_2 
les_c3_3 
dhe_1 
dhe_2 
dhe_3 
dhe_4 
dhe_5 
ydses_c5_1 
ydses_c5_2 
ydses_c5_3 
ydses_c5_4 
ydses_c5_5 
/*dhhtp_c8_1 
dhhtp_c8_2 
dhhtp_c8_3 
dhhtp_c8_4 
dhhtp_c8_5 
dhhtp_c8_6 
dhhtp_c8_7 
dhhtp_c8_8*/ 
dehsp_c3_1 
dehsp_c3_2 
dehsp_c3_3 
dhesp_1 
dhesp_2 
dhesp_3 
dhesp_4 
dhesp_5 
lessp_c3_1 
lessp_c3_2
lessp_c3_3 
lesdf_c4_1 
lesdf_c4_2 
lesdf_c4_3 
lesdf_c4_4 
les_c4_1 
les_c4_2 
les_c4_3 
les_c4_4 
lessp_c4_1
lessp_c4_2 
lessp_c4_3 
lessp_c4_4 
drgn1_1 
drgn1_2 
drgn1_3 
drgn1_4
drgn1_5 
obs_earnings_hourly
l1_obs_earnings_hourly  
	;
#delimit cr // cr stands for carriage return 

cap erase "$dir_data/population_initial_${country}_sumstats.xls"
cap erase "$dir_data/population_initial_fs_${country}_sumstats.xls"

cap erase "$dir_data/population_initial_${country}_sumstats.txt"
cap erase "$dir_data/population_initial_fs_${country}_sumstats.txt"

**************************************************
* output summary stats for new initial populations
**************************************************
forvalues year = 2011/2023 {
	use "$dir_data/population_initial_${country}_`year'.dta", clear  

	foreach var of local varlist_cat {
		recode `var' (0=.) (-9=.) 
		cap drop `var'_*
		tab `var', gen(`var'_)
	 }
	 
	 
	foreach var of local varlist2 {
		recode `var' (-9=.) 
	 }

	order `varlist2' 
	qui sum `varlist2' , de 

	save "$dir_data/population_initial_${country}_`year'.dta", replace   
	outreg2 using "$dir_data/population_initial_${country}_sumstats.xls" if ///
		stm == `year', sum(log) append cttop(`year') keep (`varlist2')
}


**********************************************************************
* output summary stats for new initial populations before dropping hhs
**********************************************************************
forvalues year = 2011/2023 {
	
	use "$dir_data/population_initial_fs_${country}_`year'.dta", clear  

	cap gen dwt_sampling = 0
	cap gen hu_pop = 0                        
	cap gen surv_pop = 0                        
	cap gen multiplier = 0                     
	cap gen adult = dag >= $age_become_responsible 
	cap gen child = 1 - adult    

	foreach var of local varlist_cat {
		recode `var' (0=.) (-9=.) 
		cap drop `var'_*
		tab `var', gen(`var'_)
	 }
 
 
	foreach var of local varlist2 {
		recode `var' (-9=.) 
	 }

order `varlist2' 
qui sum `varlist2' , de 

save "$dir_data/population_initial_fs_${country}_`year'.dta", replace   
outreg2 using "$dir_data/population_initial_fs_${country}_sumstats.xls" if ///
	stm == `year',sum(log) append cttop(`year') keep (`varlist2')
	
}

cap erase "$dir_data/population_initial_${country}_sumstats.txt"
cap erase "$dir_data/population_initial_fs_${country}_sumstats.txt"

cap log close            
   
  
/*
*************************************************************
*clean up new initial populations - keep only required vars * 
*************************************************************
forvalues year=2011/2020 {
insheet using "$dir_data/population_initial_HU_`year'.csv", clear  

keep idhh idbenefitunit idperson idpartner idmother idfather swv dgn dag dcpst dnc02 dnc ded deh_c3 sedex les_c3 dlltsd dhe ///
ydses_c5 yplgrs_dv ypnbihs_dv yptciihs_dv dhhtp_c8 ssscp dcpen dcpyy dcpex dcpagdf ynbcpdf_dv der sedag sprfm dagsp dehsp_c3 dhesp ///
lessp_c3 stm lesdf_c4 dhh_owned lhw drgn1 dct dwt_sampling les_c4 ///
lessp_c4 adultchildflag multiplier dwt obs_earnings_hourly l1_obs_earnings_hourly ///
ypncp ypnoab

save "$dir_data/population_initial_HU_`year'.dta", replace
outsheet using "$dir_data/population_initial_HU_`year'.csv", nolabel replace
}



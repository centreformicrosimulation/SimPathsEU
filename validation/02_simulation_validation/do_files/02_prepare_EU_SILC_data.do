/*******************************************************************************
* PROJECT:  		SimPaths EU 
* SECTION:			Validation
* OBJECT:			SILC data pre-processing
* AUTHORS:			Daria Popova, Ashley Burdett
* LAST UPDATE:		Nov 2025 (AB)
* COUNTRY: 			Poland 

* NOTES: 			This file computes the additional variables needed from SILC 
* 					that are not in the initial populations data. 
*						- disposable income 
* 
*******************************************************************************/

* Annual individual real disposable income 

use "$dir_init_pop_data/02_pre_drop.dta", clear 

gen valid_y_disp_ind_yr  = (hy020/hhsize - py021g) 

replace valid_y_disp_ind_yr  = (hy020/hhsize) if py021g == . 

replace valid_y_disp_ind_yr  = 0 if valid_y_disp_ind_yr  < 0 
assert valid_y_disp_ind_yr  >= 0 

replace valid_y_disp_ind_yr  = valid_y_disp_ind_yr  / (CPI/100)

keep valid_y_disp_ind_yr  idperson swv



save "$dir_data/silc_ind_dispos_y.dta", replace

*----------------------------------------------------------------------
**Estimate the 78+ joint age distribution based on SHARE dataset
* author: aleksandra kolndrekaj a.kolndrekaj@essex.ac.uk
* Start date: 30/09/25
* Last modification date: 30/09/25
* Country: Italy
*----------------------------------------------------------------------
*  AGE DIFFERENCES obtained from SHARE
*			0. male		1. female		
*  16. Italy			
*    Mean	5.2331234	-2.058018	
*    SD		4.6438638	3.8363997	
*	Corr	0.53
*------------------------------------------------------------------------
*	Log of age distribution, for 78+ distribution of age is right skewed
*			0. male		1. female	
*  16. Italy		
*    Mean	4.4072034	4.3965734
*    SD		0.0425461	0.0369068

*STEP 0: Flag top-coded observations
*-------------------------------------------------------
gen topcoded78 =1 if dag == 78

*-------------------------------------------------------
* STEP 1: Assign gender-specific skewed distribution parameters
* (from SHARE dataset) Poland
*dgn 0 female 1 male
*-------------------------------------------------------
gen meanlog = .
gen sdlog   = .

replace meanlog = 4.4 if dgn==1 & topcoded78==1
replace sdlog   = 0.04 if dgn==1 & topcoded78==1

replace meanlog = 4.4 if dgn==0 & topcoded78==1
replace sdlog   = 0.04 if dgn==0 & topcoded78==1

*-------------------------------------------------------
* STEP 2: Simulate skewed ages for top-coded obs
*-------------------------------------------------------
gen u = runiform() if topcoded78==1
gen dag_sim = exp(meanlog + sdlog*invnormal(u)) if topcoded78==1

*-------------------------------------------------------
* STEP 3: Replace top-coded ages
*-------------------------------------------------------
replace dag = dag_sim if topcoded78==1 & dag_sim>=78


*----------------------------------------------------------------------
* STEP 4: Simulate partner age using bivariate normal difference
*----------------------------------------------------------------------
*			0. male		1. female		
*  16. Italy			
*    Mean	5.2331234	-2.058018	
*    SD		4.6438638	3.8363997	
*	Corr	0.53

* - dcpst==1 individuals who are partnered
* Manual example scalars obtained from SHARE
*-------------------------------------------------------
scalar mean_diff_male   = 5.2
scalar sd_diff_male     = 4.6
scalar mean_diff_female = -2.06
scalar sd_diff_female   = 3.8
scalar rho_diff         = 0.53

*-------------------------------------------------------
* STEP 5: Simulate male/female age differences jointly (bivariate normal)
*-------------------------------------------------------
gen z1 = rnormal() if dcpst==1 & topcoded78==1
gen z2 = rnormal() if dcpst==1 & topcoded78==1

gen diff_male_sim   = mean_diff_male + sd_diff_male * z1 if dcpst==1 & topcoded78==1
gen diff_female_sim = mean_diff_female + sd_diff_female * (rho_diff*z1 + sqrt(1 - rho_diff^2)*z2) if dcpst==1 & topcoded78==1

* Compute partner ages
replace dagsp   = dag - diff_male_sim if dcpst==1 & dgn==1 & topcoded78==1
replace dagsp = dag - diff_female_sim if dcpst==1 & dgn==0 & topcoded78==1

*----------------------------------------------------------------------
*deleate variables used for the estimation
*----------------------------------------------------------------------
drop topcoded78 meanlog sdlog u z1 z2 diff_male_sim diff_female_sim
*----------------------------------------------------------------------
*save the dataset that will be used later for next steps
*----------------------------------------------------------------------
save "$dir_data/${country}-SILC_pooled_all_obs_02.dta", replace 
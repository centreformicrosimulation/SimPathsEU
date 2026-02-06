/*******************************************************************************
* PROJECT:  		SimPaths EU 
* SECTION:			Regression estimates
* OBJECT: 			Diagnostics 
* AUTHORS:			Ashley Burdett
* LAST UPDATE:		Jan 2026
* COUNTRY: 			Poland 
********************************************************************************
* NOTES: 			
*******************************************************************************/

* Test when fail eigenvalue tests in any of the regression models

/*
Faiture of any of the processes is due to a multicollinearity issue, which can 
prevent SimPaths from being able to invert the var-cov matrix. 

To investigate which variable is creating the issue you need to run 
collinearity diagnostic tests as the conditions that break the do-files does not 
provide any diagnostic information. This is most strighfroeardly done using 
"collin". 

This command should be run after the regression model and does not permit index 
or time series operators. 

Example below: 

VIF >10 suggests problematic. 

*/

gen l_Dnc = l.Dnc 
gen l_Dnc02 = l.Dnc02
gen l_Ydses_c5_Q2 = l.Ydses_c5_Q2
gen l_Ydses_c5_Q3 = l.Ydses_c5_Q3
gen l_Ydses_c5_Q4 = l.Ydses_c5_Q4
gen l_Ydses_c5_Q5 = l.Ydses_c5_Q5
gen l_Les_c4_Student = l.Les_c4_Student
gen l_Les_c4_NotEmployed = l.Les_c4_NotEmployed
gen l_Les_c4_Retired = l.Les_c4_Retired
gen l_Les_c4_Student_Dgn = l.Les_c4_Student_Dgn
gen l_Les_c4_NotEmployed_Dgn = l.Les_c4_NotEmployed_Dgn
gen l_Les_c4_Retired_Dgn = l.Les_c4_Retired_Dgn


collin Dag Dag_sq Dgn l_Dnc l_Dnc02 l_Ydses_c5_Q2 l_Ydses_c5_Q3 ///
	l_Ydses_c5_Q4 l_Ydses_c5_Q5 Ded_Dag Ded_Dag_sq Ded_Dgn Ded_Dnc_L1 ///
	Ded_Dnc02_L1 Ded_Ydses_c5_Q2_L1  Ded_Ydses_c5_Q3_L1 Ded_Ydses_c5_Q4_L1 ///
	Ded_Ydses_c5_Q5_L1 Deh_c4_Na Deh_c4_High ///
	 Deh_c4_Low l_Les_c4_Student l_Les_c4_NotEmployed ///
	l_Les_c4_Retired l_Les_c4_Student_Dgn l_Les_c4_NotEmployed_Dgn ///
	l_Les_c4_Retired_Dgn Dhe_Fair Dhe_Good Dhe_VeryGood ///
	Dhe_Excellent PL4 PL5 PL6 PL10 Year_transformed Y2020 Y2021 Y2022 if ///
	${u1_if_condition}

	
	
gen l_Dhe_Fair = l.Dhe_Fair	
gen l_Dhe_Good = l.Dhe_Good	
gen l_Dhe_VeryGood = l.Dhe_VeryGood	
gen l_Dhe_Excellent = l.Dhe_Excellent
gen l_Ln_Ypncp = l.Ln_Ypncp
gen l_Yplgrs_dv = l.Yplgrs_dv
gen l2_Yplgrs_dv = l2.Yplgrs_dv
gen l2_Ln_Ypncp = l2.Ln_Ypncp
gen l_Les_c4_Student = l.Les_c4_Student
gen l_Les_c4_NotEmployed = l.Les_c4_NotEmployed
gen l_Les_c4_Retired = l.Les_c4_Retired
gen l_Dhhtp_c4_CoupleChildren = l.Dhhtp_c4_CoupleChildren
gen l_Dhhtp_c4_SingleNoChildren = l.Dhhtp_c4_SingleNoChildren
gen l_Dhhtp_c4_SingleChildren = l.Dhhtp_c4_SingleChildren

collin Dgn Dag Dag_sq l_Dhe_Fair l_Dhe_Good l_Dhe_VeryGood ///
	l_Dhe_Excellent l_Ln_Ypncp l_Yplgrs_dv ///
	l2_Yplgrs_dv l2_Ln_Ypncp Ded_Dgn Ded_Dag Ded_Dag_sq ///
	Ded_Ln_Ypncp_L1 Ded_Yplgrs_dv_L1 Ded_Yplgrs_dv_L2 Ded_Ln_Ypncp_L2 ///
    Deh_c4_Low Deh_c4_Medium Deh_c4_High l_Les_c4_Student ///
	l_Les_c4_NotEmployed l_Les_c4_Retired l_Dhhtp_c4_CoupleChildren ///
	l_Dhhtp_c4_SingleNoChildren l_Dhhtp_c4_SingleChildren PL4 PL5 PL6 PL10 ///
	Year_transformed ///
    if ${i1b_if_condition}		

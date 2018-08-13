cap program drop crime_hs_near 
program define crime_hs_near 
syntax, OPERATION(name)
clear
clear mata
set maxvar 20000

*********************************
* Import the dataset ************
*********************************
// 226k observations, 6000 variables
// id means all streets
// objectid just means hotspots
use tmp/ready_sim_loop, clear

*********************************
* Set maximum repetitions *******
*********************************
local maxrep = 1000


***********************************
* The for loop ********************
***********************************

display "****** Repetitions in the for loop ***********"
quietly drop if id == objectid
forvalues i = 1/`maxrep' {
/* The goal here is to make a variable 
for baseline crime only for hotspots. 
We will use this as the total exposure 
of crime near you. 
*/
	qui gen sp250_crime_hsp_`i' = bl_crime_non_std if assign_hsp_`i' == 1 & ///
		all_assign_hsp_`i' == 2
	
	qui gen sp250_crime_bw_`i' = bl_crime_non_std if assign_bw_`i' == 1 & ///
		all_assign_bw_`i' == 2
	
	qui gen sp250_crime_hsp_bw_`i' = bl_crime_non_std if assign_hsp_`i' == 1 & /// 
		assign_bw_`i' == 1 & all_assign_hsp_`i' == 2 & all_assign_bw_`i' == 2

	qui gen n_sp250_hsp_`i' = (assign_hsp_`i' == 1) if ///
		all_assign_hsp_`i' == 2
	
	qui gen n_sp250_bw_`i' = (assign_hsp_`i' == 1) if ///
		all_assign_bw_`i' == 2
	
	qui gen n_sp250_hsp_bw_`i' = (assign_hsp_`i' == 1 & assign_hsp_`i' == 1) if ///
		all_assign_hsp_`i' == 2 & all_assign_bw_`i' == 2
}

****************************************** 
* Perform the collapse *******************
******************************************
// keep just the variables we want
keep id sp250_crime* n_sp250*

// rename id to objectid 
// so we can merge data from other datasets in
rename id objectid


dis "************* Collapsing ************"
fcollapse (`operation') sp250* (sum) n_sp250*, by(objectid)


*********************************************
* Merge in with other observations that are not spillovers 
*********************************************
quietly merge 1:1 objectid using in_data/treat_status, keepusing(objectid) nogen

****************************************************
* Replase observations with missing ***************
****************************************************
forvalues i = 1/`maxrep' {
	qui replace sp250_crime_hsp_`i' = 0 if missing(sp250_crime_hsp_`i')
	qui replace sp250_crime_bw_`i' = 0 if missing(sp250_crime_bw_`i')
	qui replace sp250_crime_hsp_bw_`i' = 0 if missing(sp250_crime_hsp_bw_`i')
	qui replace n_sp250_hsp_`i' = 0 if missing(n_sp250_hsp_`i')
	qui replace n_sp250_bw_`i' = 0 if missing(n_sp250_bw_`i')
	qui replace n_sp250_hsp_bw_`i' = 0 if missing(n_sp250_hsp_bw_`i')
}


**********************************************************
* Find expected values ***********************************
***********************************************************
// get locals for rowmeans 
local hsp_vars
local bw_vars
local hsp_bw_vars
local n_hsp_vars
local n_bw_vars
local n_hsp_bw_vars
forvalues i = 1/`maxrep' {
	local hsp_vars `hsp_vars' sp250_crime_hsp_`i'
	local bw_vars `bw_vars' sp250_crime_bw_`i'
	local hsp_bw_vars `hsp_bw_vars' sp250_crime_hsp_bw_`i'
	local n_hsp_vars `n_hsp_vars' n_sp250_hsp_`i'
	local n_bw_vars `n_bw_vars' n_sp250_bw_`i'
	local n_hsp_bw_vars `n_hsp_bw_vars' n_sp250_hsp_bw_`i'
}

egen e_sp250_crime_hsp = rowmean(`hsp_vars')
egen e_sp250_crime_bw = rowmean(`bw_vars')
egen e_sp250_crime_hsp_bw = rowmean(`hsp_bw_vars')
egen e_n_sp250_hsp = rowmean(`n_hsp_vars')
egen e_n_sp250_bw = rowmean(`n_bw_vars')
egen e_n_sp250_hsp_bw = rowmean(`n_hsp_bw_vars')



save out_data/crime_near_hs_sims_`operation', replace

************************************************************
* Save a temp file of just the expected value **************
***********************************************************
keep objectid e_*
tempfile expected_values
save `expected_values'


use tmp/ready_real_data, clear
quietly drop if id == objectid 

qui gen sp250_crime_hsp = bl_crime_non_std if treat_hsp == 1 & all_sp250_hsp  == 1
qui gen sp250_crime_bw = bl_crime_non_std if treat_bw == 1 & all_sp250_bw  == 1
qui gen sp250_crime_hsp_bw = bl_crime_non_std if treat_bw == 1 & treat_hsp == 1 & ///
	all_sp250_hsp == 1 & all_sp250_bw == 1
qui gen n_sp250_hsp = (treat_hsp == 1) if all_sp250_hsp == 1 
qui gen n_sp250_bw = (treat_bw == 1) if all_sp250_bw == 1
qui gen n_sp250_hsp_bw = (treat_hsp == 1 & treat_bw == 1) if ///
	all_sp250_hsp == 1 & all_sp250_bw == 1

*********************************************************
* Keep just the spillover variables we just created *****
*********************************************************
keep id ///
sp250_crime_hsp ///
sp250_crime_bw ///
sp250_crime_hsp_bw ///
n_sp250_hsp ///
n_sp250_bw ///
n_sp250_hsp_bw ///

* Rename the id variable
rename id objectid 


***********************************************************
* Perform the collapse *************************************
***********************************************************
fcollapse (`operation') sp250* (sum) n_* , by(objectid)




*************************************************************
* Merge in the rest of the street segments ******************
*************************************************************
quietly merge 1:1 objectid using in_data/treat_status, keepusing(objectid) nogen

*************************************************************
* Replace observations with missing *************************
*************************************************************
foreach var of varlist sp250* n_* {
	quietly replace `var' = 0 if missing(`var')
}

******************************************************************
* Merge in the expected values ***********************************
****************************************************************
merge 1:1 objectid using `expected_values', nogen 

save out_data/crime_near_hs_real_`operation', replace

end


***

clear
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
local maxrep = 1


***********************************
* The for loop ********************
***********************************

display "****** Repetitions in the for loop ***********"

forvalues i = 1/`maxrep' {
/* The goal here is to make a variable 
for baseline crime only for hotspots. 
We will use this as the total exposure 
of crime near you. 
*/
	gen sp250_crime_hsp_`i' = log_crime_all_u if assign_hsp_`i' == 1 & ///
		all_assign_hsp_`i' == 2
	
	gen sp250_crime_bw_`i' = log_crime_all_u if assign_bw_`i' == 1 & ///
		all_assign_bw_`i' == 2
	
}

****************************************** 
* Perform the collapse *******************
******************************************
// keep just the variables we want
keep id sp250_crime*

// rename id to objectid 
// so we can merge data from other datasets in
rename id objectid


dis "************* Collapsing ************"
fcollapse (sum) sp250*, by(objectid)


*********************************************
* Merge in with other observations that are not spillovers 
*********************************************
quietly merge 1:1 objectid using in_data/treat_status, keepusing(objectid) nogen

****************************************************
* Replase observations with missing ***************
****************************************************








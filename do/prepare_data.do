********************************************************************************
* Prepare the datasets for the randomization ***********************************
********************************************************************************

********************************************************************************
* Get a dataset connecting the arcGIS ID to our IDs for hotstpots **************
********************************************************************************
// import delimited "hs_segments.txt", delimiter(";") encoding(utf8) clear 
use in_data/hs_segments
keep fid objectid // the id for our dataset
rename fid in_fid // the id that arcGIS used (1,2,3...)
save tmp/hs, replace // N = 1919 

********************************************************************************
* Get a dataset connecting the arcGIS ID to our IDs for all segments ***********
********************************************************************************
use in_data/all_segments
keep fid objectid 
rename fid near_fid // the arcGIS ID
rename objectid id // our ID, but for all segments. 
save tmp/net, replace // N = 137,117

********************************************************************************
* Import the table of distances between all streets (137k) hotstpots (1919) ****
********************************************************************************
use in_data/near_table // N = 263,000,000
local radius = 250 // define the radius size
// generate a dummy or if the distance between the pair is less than the radius 
gen byte _within = dis <= `radius'  

* Merge identifiers for hotspots ***********************************************
// Here, we connect in_fid to objectid. 
merge m:1 in_fid using tmp/hs, keep(3) nogen

* Merge identifiers for all streets ********************************************
//Here, we connect near_fid to id (which is like objectid)
// this is the expensive operation!! 
merge m:1 near_fid using tmp/net, keep(3) nogen


* Get rid of the arcGIS IDs ****************************************************
keep id objectid _within

* Keep only the pairs of streets that are near an experimental street **********
keep if _within==1 // makes N go to 225,181
*/
* Save the dataset *************************************************************
save tmp/partialdata, replace



* Make a simulations dataset where objectid is called id ***********************
use in_data/simulations.dta, clear
rename objectid id 
rename assign* all_assign*
save tmp/simulations_id, replace

* Make a real treatment dataset where objectid is called id *******************
use in_data/treat_status.dta, clear
rename objectid id
rename treat* all_treat*
rename sp250* all_sp250*
rename non* all_non*
save tmp/treat_status_id, replace




********************************************************************************
* Merge in the simulation treatments for Hotspots ******************************
********************************************************************************
/*  The dataset of pairs of (all streets) and (experimental streets) where the
    distance between the two is less than 250m.
*/
use tmp/partialdata, clear 

// remember that objectid refers to experimental streets right now. 
merge m:1 objectid using in_data/simulations.dta,  keep(3) nogen

********************************************************************************
* Merge in simulation data for all streets *************************************
********************************************************************************
// remmeber that id refers to all streets 
// and that all_assign refers to the assgnmend for the id variable
merge m:1 id using tmp/simulations_id, keep(3) nogen


********************************************************************************
* Merge in the baseline data ***************************************************
********************************************************************************
merge m:1 objectid using in_data/baseline_crime_all_segments, keep(3) nogen

save tmp/ready_sim_loop, replace


*********************************************************************************
* Merge in real treatments for Hotspots ****************************************
*********************************************************************************
use tmp/partialdata, clear
merge m:1 objectid using in_data/treat_status, keep(3) nogen

*********************************************************************************
* Merge in real data for all streets ********************************************
*********************************************************************************
merge m:1 id using tmp/treat_status_id, keep(3) nogen 

*********************************************************************************
* merge in the baseline data ****************************************************
*********************************************************************************
merge m:1 objectid using in_data/baseline_crime_all_segments, keep(3) nogen 
save tmp/ready_real_data, replace
















*********************************************

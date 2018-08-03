
do do/test
// make the count stuff
// do do/hotspots_near_count
// 
// define the program for high and low crime spillovers
//do do/new_program

// prepare the dataset 
//do do/prepare_data

// 
// make a dataset for every percentile
//forvalues i = 5(5)100 {
//     crime_hetero_u_pct, belowcrimepct(`i') maxrep(1000) 
// }

do do/crime_hs_near
crime_hs_near, operation(sum)
crime_hs_near, operation(mean)
***




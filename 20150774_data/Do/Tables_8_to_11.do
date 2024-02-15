*---------------------------------------------------------------------------------------------------------------------------------------------------*
* This program performs the estimations shown in the appendixof "This mine is mine: how minerals fuel conflicts in Africa", Tables 8 to 11, Figure 3 
* This version: October 2016
*---------------------------------------------------------------------------------------------------------------------------------------------------*

* ------------------------------------------------------------------------------------ *
					*  Table 8 - Definition of a mining area *
* ------------------------------------------------------------------------------------ *

cap log close
log using "$Results\Table_8.log", replace

use "$Output_data\BCRT_baseline", clear

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

/* mining areas: from the first time a mine was observed onwards */
sort cell year
bys  cell: gen cum_mines=sum(mines)
g mining_area = cum_mines>0 
replace mining_area = . if cum_mines ==0 & max_mine>0

/* mining areas: mine is observed in 1997 */
g temp1 = (year == 1997 & mines == 1)
bys gid: egen mining_area2 = max(temp1)
drop temp1

/* interactions */
g main_lprice_hist1 = main_lprice*mining_area
g main_lprice_hist2 = main_lprice*mining_area2
g main_lprice_hist3 = main_lprice*mining_area_prior5
g main_lprice_hist4 = main_lprice*mining_area_priorall

keep if main_lprice_mines != .

/*baseline*/
eststo: my_reg2hdfespatial acled  main_lprice_mines if sd_mines == 0							 , timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*mine at some point over the period*/
eststo: my_reg2hdfespatial acled    main_lprice_hist0 											, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*lagged mine dummy*/
eststo: my_reg2hdfespatial acled  mines_l1 main_lprice main_lprice_mines_l1 m_lprice_mines_l1	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*coded as mining area after opening of first mine ownwards (drop years before)*/
eststo: my_reg2hdfespatial acled    main_lprice_hist1 											, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*coded as mining area if existing mine in 1997*/
eststo: my_reg2hdfespatial acled    main_lprice_hist2											, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*coded as mining area if existing mine in 1992-1996 */
eststo: my_reg2hdfespatial acled    main_lprice_hist3 											, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*coded as mining area if existing mine before 1997 */
eststo: my_reg2hdfespatial acled    main_lprice_hist4 											, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table 8) 
eststo clear

log close 

* ------------------------------------------------------------------------------------ *
						*  Table 9 - 1*1 degree cells *
* ------------------------------------------------------------------------------------ *

cap log close
log using "$Results\Table_9.log", replace

use "$Output_data\BCRT_baseline_1_1", clear

/* mining areas: mine observed at some point */
bys cell: egen max_mine = max(mines)

g main_lprice_hist0 = main_lprice*max_mine

label var max_mine 			"mine $>0$ (ever)"
label var mines 			"mine $>0$"
label var main_lprice_hist0 "$\ln$ price $\times$ mines $>0$ (ever)"
label var main_lprice_mines "$\ln$ price $\times$ mines $>0$"

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

/*condition for estimation with spatial lags of mines*/
global condition_around "(mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")"

/*column 1: time varying mining area dummy*/
eststo: my_reg2hdfespatial acled  mines main_lprice main_lprice_mines m_lprice_mines                     , timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 2: mine open the entire period*/
eststo: my_reg2hdfespatial acled  main_lprice_mines 									if sd_mines == 0 , timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 4: mine at some point over the period */
eststo: my_reg2hdfespatial acled   main_lprice_hist0                                                     , timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 5: year dummies only */
eststo: my_reg2hdfespatial acled  main_lprice_mines 									if sd_mines == 0 , timevar(year) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

preserve
/*column 6: neighbour-pair FE */
use "$Output_data\BCRT_neighbour_1_1", clear
eststo: my_reg2hdfespatial acled   mines main_lprice main_lprice_mines m_lprice_mines 	if sd_mines == 0 , timevar(year) panelvar(couple) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

restore

set linesize 250
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table 9) 
eststo clear

log close


* ------------------------------------------------------------------------------------ *
						*  Table 10 - Main mineral price *
* ------------------------------------------------------------------------------------ *


cap log close
log using "$Results\Table_10.log", replace

use "$Output_data\BCRT_baseline", clear

*-------------------------*
* STATISTICS MAIN MINERAL *
*-------------------------*

/* drop diamonds for baseline */
drop if mainmineral == "diamond"

/* What is the number of mines with a single mainmineral? */
d sd_metal_group
sum sd_metal_group, d
qui distinct gid if sd_metal_group == 0 & mainmineral  != ""
qui g  no1 = r(ndistinct)
qui distinct gid if sd_metal_group  > 0 & mainmineral  != ""
qui g  no2 = r(ndistinct)
qui 
*share 
di no1/(no1+no2)
drop no1 no2

/*what is the share of cells where main mineral never changes over time */
d 	sd_main_mineral
sum sd_main_mineral, d
qui distinct gid if sd_main_mineral == 0 & mainmineral  != ""
qui g  no1 = r(ndistinct)
qui distinct gid if sd_main_mineral >  0 & mainmineral  != ""
qui g  no2 = r(ndistinct)
*share 
di no1/(no1+no2)
drop no1 no2

/* What is the average share of main mineral ? */
d 	share_prod_main
*all cells
sum share_prod_main if mainmineral != "", d 
*excluding diamond producing cells
sum share_prod_main if mainmineral != "" & some_diamond != 1 , d  
* all cells except single mineral 
sum share_prod_main if mainmineral != "" & share_prod_main < 1, d 

*------------------------------------*
* Table 10, cols 1-2: single mineral *
*------------------------------------*

use "$Output_data\BCRT_baseline", clear

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

keep if (sd_metal_group == 0 & max_mine == 1) | max_mine == 0

/*column 1: mine open the entire period*/
eststo: my_reg2hdfespatial acled  main_lprice_mines if sd_mines == 0							, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 2: mine at some point over the period*/
eststo: my_reg2hdfespatial acled   main_lprice_hist0 			   								, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

/*neigborood FE (unreported)*/
use "$Output_data\BCRT_neighbour", clear
keep if (sd_metal_group == 0 & max_mine == 1) | max_mine == 0
my_reg2hdfespatial acled   mines main_lprice main_lprice_mines m_lprice_mines if sd_mines == 0	, timevar(year) panelvar(couple) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

*------------------------------------*
* Table 10, cols 3-4: stable mineral *
*------------------------------------*

use "$Output_data\BCRT_baseline", clear

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

keep if (sd_main_mineral == 0 & max_mine == 1) | max_mine == 0

/*column 3: mine open the entire period*/
eststo: my_reg2hdfespatial acled  main_lprice_mines if sd_mines == 0							, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 4: mine at some point over the period*/
eststo: my_reg2hdfespatial acled   main_lprice_hist0 			   								, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

/*neigborood FE (unreported)*/
use "$Output_data\BCRT_neighbour", clear
keep if (sd_main_mineral == 0 & max_mine == 1) | max_mine == 0
my_reg2hdfespatial acled   mines main_lprice main_lprice_mines m_lprice_mines if sd_mines == 0	, timevar(year) panelvar(couple) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

*---------------------------------*
* Table 10, cols 5-6: price index *
*---------------------------------*

use "$Output_data\BCRT_baseline", clear

cor lprice_index main_lprice
replace lprice_index = 0 if main_lprice == 0
cor lprice_index main_lprice

drop main_lprice_mines m_main_lprice m_lprice_mines main_lprice 

rename lprice_index main_lprice

bys gid: egen m_main_lprice    	= mean(main_lprice)
g main_lprice_mines 			= main_lprice*mines
g m_lprice_mines    			= mines*m_main_lprice

/*condition for estimation with spatial lags of mines*/
global condition_around "(mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")"

/*column 5: mine open the entire period*/
eststo: my_reg2hdfespatial acled  main_lprice_mines if sd_mines == 0							  , timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 6: mine at some point over the period*/
eststo: my_reg2hdfespatial acled   main_lprice_hist0 			   								  , timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

/*neigborood FE (unreported)*/
use "$Output_data\BCRT_baseline", clear
keep gid year lprice_index
sort gid year
save "$Output_data\temp0", replace

use "$Output_data\BCRT_neighbour", clear
sort  gid year
merge gid year using "$Output_data\temp0", nokeep
tab _merge 
drop _merge

replace lprice_index = . if lprice_index == 0
bys couple year: egen max_main_lprice	= max(lprice_index)
*
tab mines
drop main_lprice main_lprice_mines m_lprice_mines main_lprice_nbmines m_main_lprice
rename max_main_lprice  main_lprice

g main_lprice_mines   = main_lprice*mines

bys couple: egen m_main_lprice  = mean(main_lprice)
g m_lprice_mines                = mines*m_main_lprice

tab  mainmineral 
sort couple year

my_reg2hdfespatial acled   mines main_lprice main_lprice_mines m_lprice_mines if sd_mines == 0		, timevar(year) panelvar(couple) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

erase "$Output_data\temp0.dta"

set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table 10) 
eststo clear

log close


* ------------------------------------------------------------------------------------ *
						*  Table 11 - Number of conflict events *
* ------------------------------------------------------------------------------------ *


cap log close
log using "$Results\Table_11.log", replace


***********
// SAMPLE A
***********

use "$Output_data\BCRT_baseline", clear

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

g nb_acled_pos = nb_acled if nb_acled>0
tab nb_acled_pos
egen p99_nb_acled  = pctile(nb_acled_pos), p(99)
egen p95_nb_acled  = pctile(nb_acled_pos), p(95)
egen p90_nb_acled  = pctile(nb_acled_pos), p(90)
egen mean_nb_acled = mean(nb_acled_pos)
egen sd_nb_acled   = sd(nb_acled_pos)
g cutoff_nb_acled  = mean_nb_acled+2*sd_nb_acled

/*condition for estimation with spatial lags of mines*/
global condition_around "(mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")"

g lnb_acled 	= log(nb_acled+1)
g nb_acled_sine = log(nb_acled+(nb_acled^2+1)^(0.5))

g condition_around = (mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")

/*column 1: untransformed number of events - baseline */
eststo: my_reg2hdfespatial nb_acled  main_lprice_mines 					if sd_mines == 0							   	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 2: untransformed number of events - dropping top 5%*/
eststo: my_reg2hdfespatial nb_acled  main_lprice_mines					if sd_mines == 0	& nb_acled<p95_nb_acled 	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 3: nb events with mine open the entire period - dropping above mean + 2 sd */
eststo: my_reg2hdfespatial nb_acled  main_lprice_mines 					if sd_mines == 0	& nb_acled<cutoff_nb_acled 	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 4: PPML, no cleaning */
eststo: xtpqml nb_acled  main_lprice_mines yeard* 						if sd_mines == 0							   	, i(cell) cluster(country_nb) 
/*column 5: PPML - dropping top 5%*/
eststo: xtpqml nb_acled  main_lprice_mines yeard* 						if sd_mines == 0	& nb_acled<p95_nb_acled 	, i(cell) cluster(country_nb) 
/*column 6: PPML - dropping above mean + 2 sd */
eststo: xtpqml nb_acled  main_lprice_mines yeard* 						if sd_mines == 0	& nb_acled<cutoff_nb_acled 	, i(cell) cluster(country_nb) 
/*column 7: log(x+1) - no cleaning */
eststo: my_reg2hdfespatial lnb_acled  main_lprice_mines 				if sd_mines == 0							   	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 8: inverse hyperbolic sine - no cleaning */
eststo: my_reg2hdfespatial nb_acled_sine  main_lprice_mines 			if sd_mines == 0							   	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table 11a) 
eststo clear

***********
// SAMPLE B
***********

use "$Output_data\BCRT_baseline", clear

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

g nb_acled_pos = nb_acled if nb_acled>0
tab nb_acled_pos
egen p99_nb_acled  = pctile(nb_acled_pos), p(99)
egen p95_nb_acled  = pctile(nb_acled_pos), p(95)
egen p90_nb_acled  = pctile(nb_acled_pos), p(90)
egen mean_nb_acled = mean(nb_acled_pos)
egen sd_nb_acled   = sd(nb_acled_pos)
g cutoff_nb_acled  = mean_nb_acled+2*sd_nb_acled

/*condition for estimation with spatial lags of mines*/
global condition_around "(mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")"

g lnb_acled 	= log(nb_acled+1)
g nb_acled_sine = log(nb_acled+(nb_acled^2+1)^(0.5))

g condition_around = (mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")

/*column 1: untransformed number of events - baseline */
eststo: my_reg2hdfespatial nb_acled  main_lprice_hist0	   								  						, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 2: untransformed number of events - dropping top 5%*/
eststo: my_reg2hdfespatial nb_acled  main_lprice_hist0 		if  nb_acled<p95_nb_acled &  main_lprice_mines !=. 	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 3: nb events with mine open the entire period - dropping above mean + 2 sd */
eststo: my_reg2hdfespatial nb_acled  main_lprice_hist0 		if  nb_acled<cutoff_nb_acled & main_lprice_mines !=., timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 4: PPML, no cleaning */
eststo: xtpqml nb_acled  main_lprice_hist0 yeard*		  										  				, i(cell) cluster(country_nb) 
/*column 5: PPML - dropping top 5%*/
eststo: xtpqml nb_acled  main_lprice_hist0 yeard* 			if nb_acled<p95_nb_acled & main_lprice_mines !=. 	, i(cell) cluster(country_nb) 
/*column 6: PPML - dropping above mean + 2 sd */
eststo: xtpqml nb_acled  main_lprice_hist0 yeard* 			if nb_acled<cutoff_nb_acled  & main_lprice_mines !=., i(cell) cluster(country_nb) 
/*column 7: log(x+1) - no cleaning */
eststo: my_reg2hdfespatial lnb_acled  main_lprice_hist0  			   					  						, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 8: inverse hyperbolic sine - no cleaning */
eststo: my_reg2hdfespatial nb_acled_sine  main_lprice_hist0  							  						, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table 11b) 
eststo clear

****************************************
/* WITH 1*1 degree cells (unreported) */
****************************************

use "$Output_data\BCRT_baseline_1_1", clear

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

g nb_acled_pos = nb_acled if nb_acled>0
tab nb_acled_pos
egen p99_nb_acled  = pctile(nb_acled_pos), p(99)
egen p95_nb_acled  = pctile(nb_acled_pos), p(95)
egen p90_nb_acled  = pctile(nb_acled_pos), p(90)
egen mean_nb_acled = mean(nb_acled_pos)
egen sd_nb_acled   = sd(nb_acled_pos)
g cutoff_nb_acled  = mean_nb_acled+2*sd_nb_acled

tab year, gen(yeard)

/*condition for estimation with spatial lags of mines*/

g lnb_acled 	= log(nb_acled+1)
g nb_acled_sine = log(nb_acled+(nb_acled^2+1)^(0.5))

/*column 1: untransformed number of events - baseline */
eststo: my_reg2hdfespatial nb_acled  main_lprice_mines 					if sd_mines == 0							   	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 2: untransformed number of events - dropping top 5%*/
eststo: my_reg2hdfespatial nb_acled  main_lprice_mines 					if sd_mines == 0	& nb_acled<p95_nb_acled 	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 3: nb events with mine open the entire period - dropping above mean + 2 sd */
eststo: my_reg2hdfespatial nb_acled  main_lprice_mines 					if sd_mines == 0	& nb_acled<cutoff_nb_acled 	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 4: PPML, no cleaning */
eststo: xtpqml nb_acled  main_lprice_mines yeard* 						if sd_mines == 0							   	, i(cell) cluster(country_nb) 
/*column 5: PPML - dropping top 5%*/
eststo: xtpqml nb_acled  main_lprice_mines yeard* 						if sd_mines == 0	& nb_acled<p95_nb_acled 	, i(cell) cluster(country_nb) 
/*column 6: PPML - dropping above mean + 2 sd */
eststo: xtpqml nb_acled  main_lprice_mines yeard* 						if sd_mines == 0	& nb_acled<cutoff_nb_acled 	, i(cell) cluster(country_nb) 
/*column 7: log(x+1) - no cleaning */
eststo: my_reg2hdfespatial lnb_acled  main_lprice_mines 				if sd_mines == 0							   	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 8: inverse hyperbolic sine - no cleaning */
eststo: my_reg2hdfespatial nb_acled_sine  main_lprice_mines 			if sd_mines == 0							   	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table 11c) 
eststo clear

*****************************************************
/* WITH COLUMN 3 BASELINE (used in quantifications) */
*****************************************************

use "$Output_data\BCRT_baseline", clear

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

g nb_acled_pos = nb_acled if nb_acled>0
tab nb_acled_pos
egen p99_nb_acled  = pctile(nb_acled_pos), p(99)
egen p95_nb_acled  = pctile(nb_acled_pos), p(95)
egen p90_nb_acled  = pctile(nb_acled_pos), p(90)
egen mean_nb_acled = mean(nb_acled_pos)
egen sd_nb_acled   = sd(nb_acled_pos)
g cutoff_nb_acled  = mean_nb_acled+2*sd_nb_acled

/*condition for estimation with spatial lags of mines*/
global condition_around "(mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")"

g lnb_acled	 	= log(nb_acled+1)
g nb_acled_sine = log(nb_acled+(nb_acled^2+1)^(0.5))

g condition_around = (mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")

/*column 1: untransformed number of events - baseline */
eststo: my_reg2hdfespatial nb_acled  main_lprice_mines main_lprice_a 		if sd_mines == 0  & sd_mines_a ==0  & $condition_around							   		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 2: untransformed number of events - dropping top 5%*/
eststo: my_reg2hdfespatial nb_acled   main_lprice_mines main_lprice_a 		if sd_mines == 0  & sd_mines_a ==0  & $condition_around	& nb_acled<p95_nb_acled 		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 3: nb events with mine open the entire period - dropping above mean + 2 sd */
eststo: my_reg2hdfespatial nb_acled   main_lprice_mines main_lprice_a 		if sd_mines == 0  & sd_mines_a ==0  & $condition_around	&  nb_acled<cutoff_nb_acled 	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 4: PPML, no cleaning */
eststo: xtpqml nb_acled   main_lprice_mines main_lprice_a yeard* 			if sd_mines == 0  & sd_mines_a ==0  & $condition_around						   			, i(cell) cluster(country_nb) 
/*column 5: PPML - dropping top 5%*/
eststo: xtpqml nb_acled   main_lprice_mines main_lprice_a yeard* 			if sd_mines == 0  & sd_mines_a ==0  & $condition_around	& nb_acled<p95_nb_acled 		, i(cell) cluster(country_nb) 
/*column 6: PPML - dropping above mean + 2 sd */
eststo: xtpqml nb_acled   main_lprice_mines main_lprice_a yeard*		 	if sd_mines == 0  & sd_mines_a ==0  & $condition_around	& nb_acled<cutoff_nb_acled 		, i(cell) cluster(country_nb) 
/*column 7: log(x+1) - no cleaning */
eststo: my_reg2hdfespatial lnb_acled   main_lprice_mines main_lprice_a 		if sd_mines == 0  & sd_mines_a ==0  & $condition_around								   	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 8: inverse hyperbolic sine - no cleaning */
eststo: my_reg2hdfespatial nb_acled_sine   main_lprice_mines main_lprice_a 	if sd_mines == 0  & sd_mines_a ==0  & $condition_around							   		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table 11d) 
eststo clear

log close

* ------------------------------------------------------------------------------------ *
							*  Figure 3 - Placebo exercise *
* ------------------------------------------------------------------------------------ *


*************************
* WITH COL 2: Figure 3a *
*************************

clear
gen mines_c =.
gen mines_p =.
gen mines_se =.

save "$Output_data\random_all_aleatoire", replace
		
forvalues i=1(1)1000{
use "$Output_data\BCRT_baseline", clear

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

/*condition for estimation with spatial lags of mines*/
global condition_around "(mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")"

drop main_lprice_mines

global metals      "aluminum coal copper gold iron lead nickel phosphate platinum silver tin zinc "
egen g_main_mineral = group(mainmineral)

gen x = 1+int(12*runiform()) if mines == 1 & sd_mines == 0

gen m1 = ""

replace m1  = "aluminium"  			if x == 1
replace m1  = "coal"				if x == 2
replace m1  = "copper"				if x == 3
replace m1  = "gold"		 		if x == 4
replace m1  = "iron"				if x == 5
replace m1  = "lead"			  	if x == 6
replace m1  = "nickel"				if x == 7
replace m1  = "phosphate"		  	if x == 8
replace m1  = "platinum"		  	if x == 9
replace m1  = "silver"				if x == 10
replace m1  = "tin"  				if x == 11
replace m1  = "zinc"  				if x == 12

replace m1  = "" if x == .

replace main_lprice  = .
replace main_lprice  = lprice_aluminum  		if m1 == "aluminium"
replace main_lprice  = lprice_coal		 		if m1 == "coal"
replace main_lprice  = lprice_copper			if m1 == "copper"
replace main_lprice  = lprice_gold		 		if m1 == "gold"
replace main_lprice  = lprice_iron			  	if m1 == "iron"
replace main_lprice  = lprice_lead			  	if m1 == "lead"
replace main_lprice  = lprice_nickel			if m1 == "nickel"
replace main_lprice  = lprice_phosphate			if m1 == "phosphate"
replace main_lprice  = lprice_platinum		  	if m1 == "platinum"
replace main_lprice  = lprice_silver			if m1 == "silver"
replace main_lprice  = lprice_tin  				if m1 == "tin"
replace main_lprice  = lprice_zinc  			if m1 == "zinc"
replace main_lprice  = 0 if m1 == ""
*
g main_lprice_mines    = main_lprice*mines

qui : reghdfe acled main_lprice_mines if sd_mines == 0 , a(cell it) cluster(country_nb)
	global mines_c = _b[main_lprice_mines]
	global mines_se = _se[main_lprice_mines]
	global mines_p = 2*ttail(e(df_r),abs(_b[main_lprice_mines]/_se[main_lprice_mines]))
*
use "$Output_data\random_all_aleatoire", clear
set obs `i'

replace mines_c = $mines_c if _n == `i'
replace mines_p = $mines_p if _n == `i'
replace mines_se = $mines_se if _n == `i'
di "done `i' times"
save "$Output_data\random_all_aleatoire", replace
}


kdensity  mines_c,  xline(0.072) xline(0, lstyle(grey) lpattern(dash)) title("") note("") xtitle("Coefficient of {it:ln prices*mines > 0}") saving(temp.gph, replace) xlabel(-0.05(0.01)0.1) graphregion(color(white))
graph save "$Results\Figure_4a.gph", replace

erase "$Output_data\random_all_aleatoire.dta"


*************************
* WITH COL 4: Figure 3b *
*************************

clear
gen mines_c =.
gen mines_p =.
gen mines_se =.

save "$Output_data\random_all_aleatoire", replace
		
forvalues i=1(1)1000{
use "$Output_data\BCRT_baseline", clear

/* drop diamonds and tantalum for baseline */
drop if mainmineral == "diamond" | mainmineral == "tantalum"

drop main_lprice_mines

global metals      "aluminum coal copper gold iron lead nickel phosphate platinum silver tin zinc "
egen g_main_mineral = group(mainmineral)

gen x = 1+int(12*runiform()) if max_mine == 1

gen m1 = ""

replace m1  = "aluminium"  			if x == 1
replace m1  = "coal"				if x == 2
replace m1  = "copper"				if x == 3
replace m1  = "gold"		 		if x == 4
replace m1  = "iron"				if x == 5
replace m1  = "lead"			  	if x == 6
replace m1  = "nickel"				if x == 7
replace m1  = "phosphate"		  	if x == 8
replace m1  = "platinum"		  	if x == 9
replace m1  = "silver"				if x == 10
replace m1  = "tin"  				if x == 11
replace m1  = "zinc"  				if x == 12

replace m1  = "" if x == .

replace main_lprice  = .
replace main_lprice  = lprice_aluminum  		if m1 == "aluminium"
replace main_lprice  = lprice_coal		 		if m1 == "coal"
replace main_lprice  = lprice_copper			if m1 == "copper"
replace main_lprice  = lprice_gold		 		if m1 == "gold"
replace main_lprice  = lprice_iron			  	if m1 == "iron"
replace main_lprice  = lprice_lead			  	if m1 == "lead"
replace main_lprice  = lprice_nickel			if m1 == "nickel"
replace main_lprice  = lprice_phosphate			if m1 == "phosphate"
replace main_lprice  = lprice_platinum		  	if m1 == "platinum"
replace main_lprice  = lprice_silver			if m1 == "silver"
replace main_lprice  = lprice_tin  				if m1 == "tin"
replace main_lprice  = lprice_zinc  			if m1 == "zinc"
replace main_lprice  = 0 if m1 == ""
*
g main_lprice_mines    = main_lprice*max_mine

qui :  reghdfe acled main_lprice_mines, a(cell it) cluster(country_nb)
	global mines_c = _b[main_lprice_mines]
	global mines_se = _se[main_lprice_mines]
	global mines_p = 2*ttail(e(df_r),abs(_b[main_lprice_mines]/_se[main_lprice_mines]))
*
use "$Output_data\random_all_aleatoire", clear
set obs `i'

replace mines_c = $mines_c if _n == `i'
replace mines_p = $mines_p if _n == `i'
replace mines_se = $mines_se if _n == `i'

save "$Output_data\random_all_aleatoire", replace
di "done `i' times"
}

kdensity  mines_c,  xline(0.054) xline(0, lstyle(grey) lpattern(dash)) title("") note("") xtitle("Coefficient of {it:ln prices*mines > 0}") saving(temp.gph, replace) xlabel(-0.05(0.01)0.1) graphregion(color(white))
graph save "$Results\Figure_4b.gph", replace

erase "$Output_data\random_all_aleatoire.dta"





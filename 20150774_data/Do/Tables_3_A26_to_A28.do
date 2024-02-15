*---------------------------------------------------------------------------------------------------------------------------------------------------*
* This program performs the estimations of Tables 3 and A.26 to A_28 (online appendix) of "This mine is mine: how minerals fuel conflicts in Africa"
* This version: October 2016
*---------------------------------------------------------------------------------------------------------------------------------------------------*


* ------------------------------------------------------------------------------------ *
					*  Table 3 - Minerals and types of conflict events *
* ------------------------------------------------------------------------------------ *

cap log close
log using "$Results\Table_3.log", replace

use "$Output_data\BCRT_baseline", clear
*
g nb_acled_violent = nb_event8
g acled_violent    = (nb_acled_violent>0)
*
g nb_acled_battle  = nb_event1+nb_event2+nb_event3
g acled_battle     = (nb_acled_battle>0)
*
g nb_acled_riot    = nb_event7
g acled_riot       = (nb_acled_riot>0)

* descriptive stats by type of event (for Table 1) *
sum acled_violent acled_battle acled_riot, d

/*drop diamonds and tantalum*/
drop if mainmineral == "diamond" | mainmineral == "tantalum"

/*condition for estimation with spatial lags of mines*/
global condition_around "(mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")"

foreach type in  battle violent riot{
eststo: my_reg2hdfespatial acled_`type' main_lprice_mines if sd_mines == 0  , timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
eststo: my_reg2hdfespatial acled_`type'   main_lprice_hist0 			   	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
}
set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table 3) 
eststo clear

log close

* ------------------------------------------------------------------------------------ *
 *  Table A26 to A28 - Mineral and types of conflict events: Full sets of regressions *
* ------------------------------------------------------------------------------------ *

cap log close
log using "$Results\Tables_A26_to_A28.log", replace

**********************
// Table A26 : battles
**********************

use "$Output_data\BCRT_baseline", clear

/*drop diamonds and tantalum*/
drop if mainmineral == "diamond" | mainmineral == "tantalum"

/*condition for estimation with spatial lags of mines*/
global condition_around "(mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")"

*
g nb_acled_battle = nb_event1+nb_event2+nb_event3
g acled_battle    = (nb_acled_battle>0)
*
/*column 1: time varying mining area dummy*/
eststo: my_reg2hdfespatial acled_battle  mines main_lprice main_lprice_mines m_lprice_mines     								   							, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 2: mine open the entire period*/
eststo: my_reg2hdfespatial acled_battle  main_lprice_mines 										if sd_mines == 0							    			, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 3: mine open the entire period, with surrounding mines*/
eststo: my_reg2hdfespatial acled_battle  main_lprice_mines main_lprice_a 						if sd_mines == 0  & sd_mines_a ==0  & $condition_around		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000)
/*column 4: mine at some point over the period*/
eststo: my_reg2hdfespatial acled_battle   main_lprice_hist0 									   															, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 5: year dummies only*/
eststo: my_reg2hdfespatial acled_battle  main_lprice_mines 										if sd_mines == 0											, timevar(year) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

preserve
/*column 6: neighbourhood FE */
use "$Output_data\BCRT_neighbour", clear

g nb_acled_battle = nb_event1+nb_event2+nb_event3
g acled_battle    = (nb_acled_battle>0)
*

eststo: my_reg2hdfespatial acled_battle   mines main_lprice main_lprice_mines m_lprice_mines 	if sd_mines == 0	    									, timevar(year) panelvar(couple) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

restore

set linesize 250
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table A26) 
eststo clear

******************************************
// Table A27 : violence against civilians
******************************************

use "$Output_data\BCRT_baseline", clear

/*drop diamonds and tantalum*/
drop if mainmineral == "diamond" | mainmineral == "tantalum"

/*condition for estimation with spatial lags of mines*/
global condition_around "(mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")"

g nb_acled_violent = nb_event8
g acled_violent    = (nb_acled_violent>0)
*
/*column 1: time varying mining area dummy*/
eststo: my_reg2hdfespatial acled_violent  mines main_lprice main_lprice_mines m_lprice_mines     								   							, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 2: mine open the entire period*/
eststo: my_reg2hdfespatial acled_violent  main_lprice_mines 									if sd_mines == 0							    			, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 3: mine open the entire period, with surrounding mines*/
eststo: my_reg2hdfespatial acled_violent  main_lprice_mines main_lprice_a 						if sd_mines == 0  & sd_mines_a ==0  & $condition_around		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000)
/*column 4: mine at some point over the period*/
eststo: my_reg2hdfespatial acled_violent   main_lprice_hist0 									   															, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 5: year dummies only */
eststo: my_reg2hdfespatial acled_violent  main_lprice_mines 									if sd_mines == 0											, timevar(year) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

preserve
/*column 6: neighbourhood FE*/
use "$Output_data\BCRT_neighbour", clear

g nb_acled_violent = nb_event8
g acled_violent    = (nb_acled_violent>0)
*
eststo: my_reg2hdfespatial acled_violent   mines main_lprice main_lprice_mines m_lprice_mines 	if sd_mines == 0	    									, timevar(year) panelvar(couple) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

restore

set linesize 250
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table A27) 
eststo clear


**********************
// Table A28 : riots
**********************

use "$Output_data\BCRT_baseline", clear

/*drop diamonds and tantalum*/
drop if mainmineral == "diamond" | mainmineral == "tantalum"

/*condition for estimation with spatial lags of mines*/
global condition_around "(mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")"
*
g nb_acled_riot     = nb_event7
g acled_riot        = (nb_acled_riot>0)

/*column 1: time varying mining area dummy*/
eststo: my_reg2hdfespatial acled_riot  mines main_lprice main_lprice_mines m_lprice_mines     								   							, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 2: mine open the entire period*/
eststo: my_reg2hdfespatial acled_riot  main_lprice_mines 									if sd_mines == 0							    			, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 3: mine open the entire period, with surrounding mines*/
eststo: my_reg2hdfespatial acled_riot  main_lprice_mines main_lprice_a						if sd_mines == 0  & sd_mines_a ==0  & $condition_around		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000)
/*column 4: mine at some point over the period*/
eststo: my_reg2hdfespatial acled_riot   main_lprice_hist0 									   															, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 5: year dummies only */
eststo: my_reg2hdfespatial acled_riot  main_lprice_mines 									if sd_mines == 0											, timevar(year) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

preserve
/*column 6: neighbourhood FE */
use "$Output_data\BCRT_neighbour", clear

g nb_acled_riot     = nb_event7
g acled_riot        = (nb_acled_riot>0)

eststo: my_reg2hdfespatial acled_riot   mines main_lprice main_lprice_mines m_lprice_mines 	if sd_mines == 0	    									, timevar(year) panelvar(couple) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

restore

set linesize 250
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop(m_lprice_mines) b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table A28) 
eststo clear

log close

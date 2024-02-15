*-----------------------------------------------------------------------------------------------------------------------------------------------*
* This program performs the various quantification exercises discussed in "This mine is mine: how minerals fuel conflicts in Africa" 			*
* This version: October 2016	
*-----------------------------------------------------------------------------------------------------------------------------------------------*

		// OUTLINE //

// A 	Naive Quantification: effect of a SD increase in prices on conflict incidence (cell-level) 
// B 	Figures 1a and A7: baseline country-level quantification, PPML estimator 
// C 	Figures 1b and A8: baseline country-level quantification, LPM estimator  
// D 	Figures A5 and A6: cell-level quantifications (web appendix)



cap log close
log using "$Results\Results_quantifications.log", replace

* ----------------------------------------------------------------------------------------------- *
*  A - Naive Quantification: effect of a SD increase in prices on conflict incidence (cell-level) *
* ----------------------------------------------------------------------------------------------- *


// With col 2 of baseline

use "$Output_data\BCRT_baseline", clear
drop if mainmineral == "diamond" | mainmineral == "tantalum"

/*column 2: mine open the entire period*/
reghdfe acled  main_lprice_mines if sd_mines == 0, vce(cluster country_nb) absorb(cell it) /*spatial HAC correction does not matter for prediction*/

keep if e(sample)  

scalar coeff=_b[main_lprice_mines]
keep if mines==1
sum acled if mines==1, d
scalar baseline_acled = r(mean)
tsset cell year
sum main_lprice if mines==1, d
sum D.main_lprice if mines==1, d
gen demean_main_lprice=main_lprice-m_main_lprice
sum demean_main_lprice, d
scalar quant_naive=r(sd) * coeff
di "a one SD increase in prices translates into an increase in probability of conflict of " quant_naive ///
" percentage point from a baseline probability of conflict of " baseline_acled ""

// With col 3 of baseline

use "$Output_data\BCRT_baseline", clear

/*condition for estimation with spatial lags of mines*/
g condition_around = (mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")

reghdfe acled  main_lprice_mines main_lprice_a if sd_mines == 0  & sd_mines_a ==0  & condition_around==1, vce(cluster country_nb) absorb(cell it) /*spatial HAC correction does not matter for predictions*/

keep if e(sample) 

scalar coeff1=_b[main_lprice_mines]
scalar coeff2=_b[main_lprice_a]
keep if mines==1
sum acled if mines==1, d
scalar baseline_acled = r(mean)
tsset cell year
sum main_lprice if mines==1, d
sum D.main_lprice if mines==1, d
gen demean_main_lprice=main_lprice-m_main_lprice
sum demean_main_lprice, d
scalar quant_naive1=r(sd) * coeff1
gen demean_main_lprice_a=main_lprice_a-m_main_lprice_a
sum demean_main_lprice_a, d
scalar quant_naive2=r(sd) * coeff2
di "a one SD increase in prices translates into an increase in probability of conflict of " quant_naive1 + quant_naive2 ///
" percentage point from a baseline probability of conflict of " baseline_acled ""

// With col 4 of baseline

use "$Output_data\BCRT_baseline", clear
drop if mainmineral == "diamond" | mainmineral == "tantalum"

/*column 4: mine at some point over the period*/
reghdfe acled   main_lprice_hist0 , vce(cluster country_nb) absorb(cell it) /*spatial HAC correction does not matter for predictions*/

keep if e(sample) 

scalar coeff=_b[main_lprice_hist0]
keep if max_mine==1
sum acled if max_mine==1, d
scalar baseline_acled = r(mean)
tsset cell year
sum main_lprice if max_mine==1, d
sum D.main_lprice if max_mine==1, d
gen demean_main_lprice=main_lprice_hist0-m_main_lprice
sum demean_main_lprice, d
scalar quant_naive=r(sd) * coeff
di "a one SD increase in prices translates into an increase in probability of conflict of " quant_naive ///
" percentage point from a baseline probability of conflict of " baseline_acled ""


* ------------------------------------------------------------------------------------------------- *
		*  B - Figures 1a and A7: baseline country-level quantification, PPML estimator  *
* ------------------------------------------------------------------------------------------------- *

// Specification used similar to column 5 of Panel B, Table 11, augmented with surrounding cells
// PPML estimator


/*get 97 mineral prices of the cell */
use "$Output_data\BCRT_baseline", clear
drop if main_lprice == . | main_lprice == 0
keep if mines == 1
collapse (mean) main_lprice, by(mainmineral year)
keep if year == 1997
rename main_lprice main_lprice97
keep mainmineral main_lprice
sort mainmineral
save "$Output_data\tempzz", replace

/*get 97 mineral prices of the surrounding cells */
use "$Output_data\BCRT_baseline", clear
drop if main_lprice == . | main_lprice == 0
keep if mines == 1
collapse (mean) main_lprice, by(mainmineral year)
keep if year == 1997
rename main_lprice main_lprice_a97
rename mainmineral mainmineral_a 
keep mainmineral_a main_lprice_a97
sort mainmineral_a
save "$Output_data\tempyy", replace

/*start with baseline dataset*/
use "$Output_data\BCRT_baseline", clear

/* trim top 5% of nb events */
g nb_acled_pos 		= nb_acled if nb_acled>0
egen p95_nb_acled  	= pctile(nb_acled_pos), p(95)
keep if  nb_acled<p95_nb_acled

drop   main_lprice 
rename main_lprice_hist0 main_lprice

g condition_around = (mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")

/*estimation*/
xtpqml nb_acled  main_lprice main_lprice_a yeard* if condition_around == 1, i(cell) cluster(country_nb) 

keep if condition_around == 1 /* prediction only on minerals with reliable prices */
*
cap drop benchLPM_nb
predict  benchLPM_nb 
sum benchLPM_nb, d
*
tsset cell year

/* counterfactual: put all prices to their 97 level */
sort  mainmineral 
merge mainmineral using  "$Output_data\tempzz", nokeep
tab  _merge
drop _merge
*
rename mainmineral_around mainmineral_a
sort  mainmineral_a
merge mainmineral_a using "$Output_data\tempyy", nokeep
tab  _merge
drop _merge
*
replace main_lprice         = main_lprice97   if main_lprice   != 0
replace main_lprice_a       = main_lprice_a97 if main_lprice_a != 0
*
cap drop counterLPM_nb
predict counterLPM_nb
sum counterLPM_nb, d

/* how many events did not happen? */
g diff = benchLPM_nb-counterLPM_nb
/* drop 1997 (no change by definition) */
drop if year == 1997
/* keep if comparison can be made */
replace counterLPM_nb = . if benchLPM_nb   ==.
replace benchLPM_nb   = . if counterLPM_nb ==.
replace nb_acled      = . if counterLPM_nb ==.
drop if counterLPM_nb == . | benchLPM_nb  == . | nb_acled == .
save "$Output_data\tempzz", replace

********************************************
* country level effect for map (Figure A7) *
********************************************

use "$Output_data\tempzz", clear
/* sum events by year and country */
collapse (sum) nb_acled diff counterLPM_nb benchLPM_nb, by(iso_1 year)
/* sum events by country over the period */ 
collapse (sum) nb_acled diff counterLPM_nb benchLPM_nb, by(iso_1)
g share1 = diff/nb_acled 
g share2 = diff/benchLPM_nb 

sum, d 

rename iso_1 ISO3
sort ISO3
keep ISO3 diff nb_acled share1
save "$Output_data\Figure_A7", replace

use "$Output_data\BCRT_baseline", replace
replace main_lprice = . if main_lprice == 0
collapse (mean) main_lprice mines, by(iso_1)
g noprice = (mines>0 & main_lprice == .)
*
rename iso_1 ISO3
sort ISO3
merge ISO3 using "$Output_data\Figure_A7", nokeep
tab _merge
drop _merge
*
rename share1 share
replace share = -1 if share == 0 & noprice == 1
drop noprice

g share_bin = . 
replace share_bin = 1 if share >= 0.000 & share < 0.01 & share != .
replace share_bin = 2 if share >= 0.010 & share < 0.050 & share != .
replace share_bin = 3 if share >= 0.050 & share < 0.200 & share != .
replace share_bin = 4 if share >= 0.200 & share < 0.500 & share != .
replace share_bin = 5 if share >= 0.500 & share != . 
replace share_bin = 0 if mines == 0 | nb_acled == . | nb_acled == 0 /* no observation in estimation */

sort ISO3
save "$Output_data\Figure_A7", replace
outsheet using "$Results\Figure_A7.csv", comma replace

*************************
* Bar chart (Figure 1A) *
*************************

rename share increase
drop if increase == 0 | increase == . | increase == -1
replace increase = 1 if increase > 1
graph hbar (sum) increase, over(ISO3, sort(increase) label(labsize(small))) bar(1, color(black)) legend(off) bgcolor(white) graphregion(color(white)) intensity(40)   lintensity(100) ytitle(Share of events explained by increase in mineral prices)  
graph export $Results\Figure_1A.eps, as(eps) replace

*****************************
* Aggregate quantifications *
*****************************

/*get total number of observed events */
/*(to be able to drop countries with less than 50 events in total sample)*/

use "$Output_data\BCRT_baseline", replace
drop if year == 1997
collapse (sum) nb_acled, by(iso_1)
sort iso_1
save "$Output_data\tempzz.dta", replace

use "$Output_data\Figure_A7", clear
drop if share == -1 | nb_acled == .
g nomines = (diff == 0)
collapse (sum) nb_acled diff, by(nomines)
egen nb_acled_tot = sum(nb_acled)

* share of events across all Africa in countries with mines 
g share_events1 = diff/nb_acled if nomines == 0

///// AGGREGATE QUANTIFICATIONS /////

/* how many events saved in Africa? */ 
sum share_events1 if nomines == 0, d

/* how many on average across countries?*/
use "$Output_data\Figure_A7", clear
drop nb_acled
rename ISO3 iso_1
sort  iso_1
merge iso_1 using "$Output_data\tempzz.dta", nokeep
tab  _merge
drop _merge

drop if share == 0 | share == . | share == -1 
replace share = 1 if share > 1

/* how many on average across countries with mines? */
egen mean = mean(share)
di mean 
/* how many on average across countries with mines, excluding countries with <50 events ?*/
drop mean 
egen mean = mean(share) if nb_acled>=50
di mean 
*
/*clean*/
erase  "$Output_data\tempzz.dta"
erase  "$Output_data\tempyy.dta"
erase  "$Output_data\Figure_A7.dta"


* ------------------------------------------------------------------------------------------------- *
		*  C - Figures 1b and A8: baseline country-level quantification, LPM estimator  *
* ------------------------------------------------------------------------------------------------- *

// Specification used similar to column 2 of Panel B, Table 11, augmented with surrounding cells
// LPM estimator

/*get 97 mineral prices of the cell */
use "$Output_data\BCRT_baseline", clear
drop if main_lprice == . | main_lprice == 0
keep if mines == 1
collapse (mean) main_lprice, by(mainmineral year)
keep if year == 1997
rename main_lprice main_lprice97
keep mainmineral main_lprice
sort mainmineral
save "$Output_data\tempzz", replace

/*get 97 mineral prices of the surrounding cells */
use "$Output_data\BCRT_baseline", clear
drop if main_lprice == . | main_lprice == 0
keep if mines == 1
collapse (mean) main_lprice, by(mainmineral year)
keep if year == 1997
rename main_lprice main_lprice_a97
rename mainmineral mainmineral_a 
keep mainmineral_a main_lprice_a97
sort mainmineral_a
save "$Output_data\tempyy", replace

/*start with baseline dataset*/
use "$Output_data\BCRT_baseline", clear

/* trim top 5% of nb events */
g nb_acled_pos 		= nb_acled if nb_acled>0
egen p95_nb_acled  	= pctile(nb_acled_pos), p(95)
keep if  nb_acled<p95_nb_acled

qui tab it, gen(itd)

drop 	main_lprice 
rename 	main_lprice_hist0 main_lprice

g condition_around = (mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")

/*estimation*/
xtreg nb_acled  main_lprice main_lprice_a itd*  if condition_around == 1, fe cluster(country_nb)

keep if  condition_around == 1 /* prediction only on minerals with reliable prices */
*
cap drop benchLPM_nb
predict  benchLPM_nb 
sum benchLPM_nb, d
*
tsset cell year

/* counterfactual: put all prices to their 97 level */
sort  mainmineral 
merge mainmineral using  "$Output_data\tempzz", nokeep
tab  _merge
drop _merge
*
rename mainmineral_around mainmineral_a
sort  mainmineral_a
merge mainmineral_a using "$Output_data\tempyy", nokeep
tab  _merge
drop _merge
*
replace main_lprice         = main_lprice97   if main_lprice   != 0
replace main_lprice_a       = main_lprice_a97 if main_lprice_a != 0
*
cap drop counterLPM_nb
predict counterLPM_nb
sum counterLPM_nb, d

/* how many events did not happen? */
g diff = benchLPM_nb-counterLPM_nb
sum diff, d
/* drop 1997 (no change by definition) */
drop if year == 1997
/* keep if comparison can be made */
replace counterLPM_nb = . if benchLPM_nb   ==.
replace benchLPM_nb   = . if counterLPM_nb ==.
replace nb_acled      = . if counterLPM_nb ==.
drop if counterLPM_nb == . | benchLPM_nb  == . | nb_acled == .

save "$Output_data\tempzz", replace

********************************************
* country level effect for map (Figure A8) *
********************************************

use "$Output_data\tempzz", clear
/* sum events by year and country */
collapse (sum) nb_acled diff counterLPM_nb benchLPM_nb, by(iso_1 year)
/* sum events by country over the period */ 
collapse (sum) nb_acled diff counterLPM_nb benchLPM_nb, by(iso_1)
g share1 = diff/nb_acled 
g share2 = diff/benchLPM_nb 

sum, d 

rename iso_1 ISO3
sort ISO3
keep ISO3 diff nb_acled share1
save "$Output_data\Figure_A8", replace

use "$Output_data\BCRT_baseline", replace
replace main_lprice = . if main_lprice == 0
collapse (mean) main_lprice mines, by(iso_1)
g noprice = (mines>0 & main_lprice == .)
*
rename iso_1 ISO3
sort ISO3
merge ISO3 using "$Output_data\Figure_A8", nokeep
tab _merge
drop _merge
*
rename share1 share
replace share = -1 if share == 0 & noprice == 1
drop noprice

g share_bin = .
replace share_bin = 1 if share >= 0.000 & share < 0.01 & share != .
replace share_bin = 2 if share >= 0.010 & share < 0.050 & share != .
replace share_bin = 3 if share >= 0.050 & share < 0.200 & share != .
replace share_bin = 4 if share >= 0.200 & share < 0.500 & share != .
replace share_bin = 5 if share >= 0.500 & share != . 
replace share_bin = 0 if mines == 0 | nb_acled == . | nb_acled == 0/* no observation in estimation */

sort ISO3
save "$Output_data\Figure_A8", replace
outsheet using "$Results\Figure_A8.csv", comma replace

*************************
* Bar chart (Figure 1B) *
*************************

rename share increase
drop if increase == 0 | increase == . | increase == -1
replace increase = 1 if increase > 1

graph hbar (sum) increase, over(ISO3, sort(increase) label(labsize(small))) bar(1, color(black)) legend(off) bgcolor(white) graphregion(color(white)) intensity(40)   lintensity(100) ytitle(Share of events explained by increase in mineral prices)  
graph export $Results\Figure_1B.eps, as(eps) replace

save "$Output_data\tempzz", replace

*****************************
* aggregate quantifications *
*****************************

/*get total number of observed events */
/*(to be able to drop countries with less than 50 events in total sample)*/

use "$Output_data\BCRT_baseline", replace
drop if year == 1997
collapse (sum) nb_acled, by(iso_1)
sort iso_1
save "$Output_data\tempyy.dta", replace

use "$Output_data\tempzz", clear
rename increase share
drop if share == -1 | nb_acled == .
g nomines = (diff == 0)
collapse (sum) nb_acled diff, by(nomines)
egen nb_acled_tot = sum(nb_acled)

* share of events in countries with mines 
g share_events1 = diff/nb_acled if nomines == 0

///// AGGREGATE QUANTIFICATIONS /////

/* how many events saved in Africa? */ 
sum share_events1 if nomines == 0, d

/* how many on average across countries with mines ?*/
use "$Output_data\tempzz", clear
drop nb_acled
rename ISO3 iso_1
sort  iso_1
merge iso_1 using "$Output_data\tempyy.dta", nokeep
tab  _merge
drop _merge

rename increase share
drop if share == 0 | share == . | share == -1 
replace share = 1 if share > 1

/* how many on average across countries with mines? */
egen mean = mean(share)
di mean 
/* how many on average across countries with mines, excluding countries with <50 events ?*/
drop mean 
egen mean = mean(share) if nb_acled>=50
di mean 
*
erase  "$Output_data\tempzz.dta"
erase  "$Output_data\tempyy.dta"
erase  "$Output_data\Figure_A8.dta"


* ------------------------------------------------------------------------------------------------- *
					* D - Figures A5 and A6: cell-level quantifications *
* ------------------------------------------------------------------------------------------------- *

*----------------------------*
/* FIGURE A5 (Web appendix)*/
*----------------------------*

// Specification used similar to column 4 of baseline Table 2, augmented with surrounding cells

/*get 97 mineral prices of the cell */
use "$Output_data\BCRT_baseline", clear
drop if main_lprice == . | main_lprice == 0
keep if mines == 1
collapse (mean) main_lprice, by(mainmineral year)
keep if year == 1997
rename main_lprice main_lprice97
keep mainmineral main_lprice
sort mainmineral
save "$Output_data\tempzz", replace

/*get 97 mineral prices of the surrounding cells */
use "$Output_data\BCRT_baseline", clear
drop if main_lprice == . | main_lprice == 0
keep if mines == 1
collapse (mean) main_lprice, by(mainmineral year)
keep if year == 1997
rename main_lprice main_lprice_a97
rename mainmineral mainmineral_a 
keep mainmineral_a main_lprice_a97
sort mainmineral_a
save "$Output_data\tempyy", replace
*
use "$Output_data\BCRT_baseline", clear
cap drop FEcell FEit
qui tab it, gen(itd)

drop   main_lprice 
rename main_lprice_hist0 main_lprice

g condition_around = (mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")

/*estimation*/
xtreg acled  main_lprice main_lprice_a itd* if  condition_around == 1, fe cluster(country_nb)
*
keep if  condition_around == 1 /* prediction only on minerals with reliable prices */
*
cap drop benchLPM_nb
predict  benchLPM_nb 
sum benchLPM_nb, d
*
tsset cell year
/* counterfactual: put all prices to their 97 level */
sort  mainmineral 
merge mainmineral using  "$Output_data\tempzz", nokeep
tab  _merge
drop _merge
*
rename mainmineral_around mainmineral_a
sort  mainmineral_a
merge mainmineral_a using "$Output_data\tempyy", nokeep
tab  _merge
drop _merge
*
replace main_lprice         = main_lprice97   if main_lprice   != 0
replace main_lprice_a       = main_lprice_a97 if main_lprice_a != 0
*
cap drop counterLPM_nb
predict counterLPM_nb
sum counterLPM_nb, d

/* how many events did not happen? */
g diff = benchLPM_nb-counterLPM_nb
sum diff, d
/* drop 1997 (no change by definition) */
drop if year == 1997
/* keep if comparison can be made */
replace counterLPM_nb = . if benchLPM_nb   ==.
replace benchLPM_nb   = . if counterLPM_nb ==.
drop if counterLPM_nb == . | benchLPM_nb  == . | nb_acled == .
save "$Output_data\tempzz", replace

*****************************************
* cell level effect for map (Figure A5) *
*****************************************

use "$Output_data\tempzz", clear
keep if year == 2010
collapse (mean) benchLPM_nb counterLPM_nb, by(gid)
g share = abs((counterLPM_nb-benchLPM_nb)/benchLPM_nb)
keep gid share
sum share if share>0, d
drop if share == .
g share_bin = . 
replace share_bin = 0 if share == 0
replace share_bin = 1 if share > 0.000 & share <= 0.050
replace share_bin = 2 if share > 0.050 & share <= 0.075
replace share_bin = 3 if share > 0.075 & share <= 0.100
replace share_bin = 4 if share > 0.100
drop share
sort gid
save "$Output_data\Figure_A5", replace
outsheet using "$Results\Figure_A5.csv", comma replace
*
erase  "$Output_data\tempzz.dta"
erase  "$Output_data\tempyy.dta"
erase  "$Output_data\Figure_A5.dta"

*----------------------------*
/* FIGURE A6 (Web appendix)*/
*----------------------------*

// Specification used is column 3 of baseline Table 2

/*get 97 mineral prices of the cell */
use "$Output_data\BCRT_baseline", clear
drop if main_lprice == . | main_lprice == 0
keep if mines == 1
collapse (mean) main_lprice, by(mainmineral year)
keep if year == 1997
rename main_lprice main_lprice97
keep mainmineral main_lprice
sort mainmineral
save "$Output_data\tempzz", replace

/*get 97 mineral prices of the surrounding cells */
use "$Output_data\BCRT_baseline", clear
drop if main_lprice == . | main_lprice == 0
keep if mines == 1
collapse (mean) main_lprice, by(mainmineral year)
keep if year == 1997
rename main_lprice main_lprice_a97
rename mainmineral mainmineral_a 
keep mainmineral_a main_lprice_a97
sort mainmineral_a
save "$Output_data\tempyy", replace
*
use "$Output_data\BCRT_baseline", clear

qui tab it, gen(itd)
drop 	main_lprice 
rename  main_lprice_mines main_lprice

g condition_around = (mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")

/*estimation*/
xtreg acled  main_lprice main_lprice_a itd* if  sd_mines == 0  & sd_mines_a ==0 & condition_around == 1, fe cluster(country_nb)
*
keep if  condition_around == 1 /* prediction only on minerals with reliable prices */
*
cap drop benchLPM_nb
predict  benchLPM_nb 
sum benchLPM_nb, d
*
tsset cell year
/* counterfactual: put all prices to their 97 level */
sort  mainmineral 
merge mainmineral using  "$Output_data\tempzz", nokeep
tab  _merge
drop _merge
*
rename mainmineral_around mainmineral_a
sort  mainmineral_a
merge mainmineral_a using "$Output_data\tempyy", nokeep
tab  _merge
drop _merge
*
replace main_lprice         = main_lprice97   if main_lprice   != 0
replace main_lprice_a       = main_lprice_a97 if main_lprice_a != 0
*
cap drop counterLPM_nb
predict counterLPM_nb
sum counterLPM_nb, d

/* how many events did not happen? */
g diff = benchLPM_nb-counterLPM_nb
sum diff, d
/* drop 1997 (no change by definition) */
drop if year == 1997
/* keep if comparison can be made */
replace counterLPM_nb = . if benchLPM_nb   ==.
replace benchLPM_nb   = . if counterLPM_nb ==.
drop if counterLPM_nb == . | benchLPM_nb  == . | nb_acled == .
save "$Output_data\tempzz", replace

*****************************
* cell level effect for map *
*****************************

use "$Output_data\tempzz", clear
keep if year == 2010
collapse (mean) benchLPM_nb counterLPM_nb, by(gid)
g share = abs((counterLPM_nb-benchLPM_nb)/benchLPM_nb)
keep gid share
sum share if share>0, d
drop if share == .
g share_bin = . 
replace share_bin = 0 if share == 0
replace share_bin = 1 if share > 0.000 & share <= 0.050
replace share_bin = 2 if share > 0.050 & share <= 0.075
replace share_bin = 3 if share > 0.075 & share <= 0.100
replace share_bin = 4 if share > 0.100
drop share
sort gid
save "$Output_data\Figure_A6", replace
outsheet using "$Results\Figure_A6.csv", comma replace
*
erase  "$Output_data\tempzz.dta"
erase  "$Output_data\tempyy.dta"
erase  "$Output_data\Figure_A6.dta"

* ------------------------------------------------------------------------------------------------- *
	*  E - Figure A9.a: country-level quantification, permanent mining areas, PPML estimator  *
* ------------------------------------------------------------------------------------------------- *

// Specification used similar to column 5 of Panel A, Table 11, augmented with surrounding cells
// PPML estimator

/*get 97 mineral prices of the cell */
use "$Output_data\BCRT_baseline", clear
drop if main_lprice == . | main_lprice == 0
keep if mines == 1
collapse (mean) main_lprice, by(mainmineral year)
keep if year == 1997
rename main_lprice main_lprice97
keep mainmineral main_lprice
sort mainmineral
save "$Output_data\tempzz", replace

/*get 97 mineral prices of the surrounding cells */
use "$Output_data\BCRT_baseline", clear
drop if main_lprice == . | main_lprice == 0
keep if mines == 1
collapse (mean) main_lprice, by(mainmineral year)
keep if year == 1997
rename main_lprice main_lprice_a97
rename mainmineral mainmineral_a 
keep mainmineral_a main_lprice_a97
sort mainmineral_a
save "$Output_data\tempyy", replace

/*start with baseline dataset*/
use "$Output_data\BCRT_baseline", clear

/* trim top 5% of nb events */
g nb_acled_pos 		= nb_acled if nb_acled>0
egen p95_nb_acled  	= pctile(nb_acled_pos), p(95)
keep if  nb_acled<p95_nb_acled

drop 	main_lprice 
rename  main_lprice_mines main_lprice

g condition_around = (mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")

/*estimation*/
xtpoisson nb_acled   main_lprice main_lprice_a yeard* if sd_mines == 0  & sd_mines_a ==0  & condition_around == 1, fe
*
keep if  condition_around == 1 /* prediction only on minerals with reliable prices */
*
cap drop benchLPM_nb
predict  benchLPM_nb
sum benchLPM_nb, d
*
tsset cell year
/* counterfactual: put all prices to their 97 level */
sort  mainmineral 
merge mainmineral using  "$Output_data\tempzz", nokeep
tab  _merge
drop _merge
*
rename mainmineral_around mainmineral_a
sort  mainmineral_a
merge mainmineral_a using "$Output_data\tempyy", nokeep
tab  _merge
drop _merge
*
replace main_lprice         = main_lprice97   if main_lprice   != 0
replace main_lprice_a       = main_lprice_a97 if main_lprice_a != 0
*
cap drop counterLPM_nb
predict counterLPM_nb
sum counterLPM_nb, d

/* how many events did not happen? */
g diff = benchLPM_nb-counterLPM_nb
sum diff, d
/* drop 1997 (no change by definition) */
drop if year == 1997
/* keep if comparison can be made */
replace counterLPM_nb = . if benchLPM_nb   ==.
replace benchLPM_nb   = . if counterLPM_nb ==.
replace nb_acled      = . if counterLPM_nb ==.
drop if counterLPM_nb == . | benchLPM_nb  == . | nb_acled == .
save "$Output_data\tempzz", replace

**********************************************
* country level effect for map (not reported *
**********************************************

use "$Output_data\tempzz", clear
/* sum events by year and country */
collapse (sum) nb_acled diff counterLPM_nb benchLPM_nb, by(iso_1 year)
/* sum events by country over the period */ 
collapse (sum) nb_acled diff counterLPM_nb benchLPM_nb, by(iso_1)
g share1 = diff/nb_acled 
g share2 = diff/benchLPM_nb 

sum, d 
*
rename iso_1 ISO3
sort ISO3
keep ISO3 diff nb_acled share1
save "$Output_data\Figure_A9a", replace
*
use "$Output_data\BCRT_baseline", replace
replace main_lprice = . if main_lprice == 0
collapse (mean) main_lprice mines, by(iso_1)
g noprice = (mines>0 & main_lprice == .)
*drop main_lprice mines
rename iso_1 ISO3
sort ISO3
merge ISO3 using "$Output_data\Figure_A9a", nokeep
tab _merge
drop _merge
*
rename share1 share
replace share = -1 if share == 0 & noprice == 1
drop noprice

g share_bin = . 
replace share_bin = 1 if share >= 0.000 & share < 0.01 & share != .
replace share_bin = 2 if share >= 0.010 & share < 0.050 & share != .
replace share_bin = 3 if share >= 0.050 & share < 0.200 & share != .
replace share_bin = 4 if share >= 0.200 & share < 0.500 & share != .
replace share_bin = 5 if share >= 0.500 & share != . 
replace share_bin = 0 if mines == 0 | nb_acled == . | nb_acled == 0/* no observation in estimation */

sort ISO3
save "$Output_data\Figure_A9a", replace
outsheet using "$Results\Figure_A9a.csv", comma replace

**************************
* Bar chart (Figure A9a) *
**************************

rename share increase
drop if increase == 0 | increase == . | increase == -1
replace increase = 1 if increase > 1
graph hbar (sum) increase, over(ISO3, sort(increase) label(labsize(small))) bar(1, color(black)) legend(off) bgcolor(white) graphregion(color(white)) intensity(40)   lintensity(100) ytitle(Share of events explained by increase in mineral prices)  
graph export $Results\Figure_A9a.eps, as(eps) replace

*****************************
* Aggregate quantifications *
*****************************

/*get total number of observed events */
/*(to be able to drop countries with less than 50 events in total sample)*/

use "$Output_data\BCRT_baseline", replace
drop if year == 1997
collapse (sum) nb_acled, by(iso_1)
sort iso_1
save "$Output_data\tempzz.dta", replace

///// AGGREGATE QUANTIFICATIONS /////

use "$Output_data\Figure_A9a", clear
drop nb_acled
rename ISO3 iso_1
sort  iso_1
merge iso_1 using "$Output_data\tempzz.dta", nokeep
tab  _merge
drop _merge

drop if share == 0 | share == . | share == -1 
replace share = 1 if share > 1

/* how many on average across countries with mines*/
egen mean = mean(share)
di mean 
/* how many on average across countries with mines, excluding countries with <50 events ?*/
drop mean 
egen mean = mean(share) if nb_acled>=50
di mean 
*
erase  "$Output_data\tempzz.dta"
erase  "$Output_data\tempyy.dta"
erase  "$Output_data\Figure_A9a.dta"


* ------------------------------------------------------------------------------------------------- *
	*  F - Figure A9.b: country-level quantification, permanent mining areas, LPM estimator  *
* ------------------------------------------------------------------------------------------------- *

// Specification used similar to column 2 of Panel A, Table 11, augmented with surrounding cells
// LPM estimator

/*get 97 mineral prices of the cell */
use "$Output_data\BCRT_baseline", clear
drop if main_lprice == . | main_lprice == 0
keep if mines == 1
collapse (mean) main_lprice, by(mainmineral year)
keep if year == 1997
rename main_lprice main_lprice97
keep mainmineral main_lprice
sort mainmineral
save "$Output_data\tempzz", replace

/*get 97 mineral prices of the surrounding cells */
use "$Output_data\BCRT_baseline", clear
drop if main_lprice == . | main_lprice == 0
keep if mines == 1
collapse (mean) main_lprice, by(mainmineral year)
keep if year == 1997
rename main_lprice main_lprice_a97
rename mainmineral mainmineral_a 
keep mainmineral_a main_lprice_a97
sort mainmineral_a
save "$Output_data\tempyy", replace

/*start with baseline dataset*/
use "$Output_data\BCRT_baseline", clear

/* trim top 5% of nb events */
g nb_acled_pos 		= nb_acled if nb_acled>0
egen p95_nb_acled  	= pctile(nb_acled_pos), p(95)
keep if  nb_acled<p95_nb_acled

qui tab it, gen(itd)
drop main_lprice 
rename main_lprice_mines main_lprice

g condition_around = (mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")
/*estimation*/
xtreg nb_acled  main_lprice main_lprice_a itd* if  sd_mines == 0  & sd_mines_a ==0 & condition_around == 1, fe cluster(country_nb)
*
keep if  condition_around == 1  /* prediction only on minerals with reliable prices */
*
cap drop benchLPM_nb
predict  benchLPM_nb 
sum benchLPM_nb, d
*
tsset cell year
/* counterfactual: put all prices to their 97 level */
sort  mainmineral 
merge mainmineral using  "$Output_data\tempzz", nokeep
tab  _merge
drop _merge
*
rename mainmineral_around mainmineral_a
sort  mainmineral_a
merge mainmineral_a using "$Output_data\tempyy", nokeep
tab  _merge
drop _merge
*
replace main_lprice         = main_lprice97   if main_lprice   != 0
replace main_lprice_a       = main_lprice_a97 if main_lprice_a != 0
*
cap drop counterLPM_nb
predict counterLPM_nb
sum counterLPM_nb, d

/* how many events did not happen? */
g diff = benchLPM_nb-counterLPM_nb
sum diff, d
/* drop 1997 (no change by definition) */
drop if year == 1997
/* keep if comparison can be made */
replace counterLPM_nb = . if benchLPM_nb   ==.
replace benchLPM_nb   = . if counterLPM_nb ==.
replace nb_acled      = . if counterLPM_nb ==.
drop if counterLPM_nb == . | benchLPM_nb  == . | nb_acled == .
save "$Output_data\tempzz", replace

***********************************************
* country level effect for map (not reported) *
***********************************************

use "$Output_data\tempzz", clear
/* sum events by year and country */
collapse (sum) nb_acled diff counterLPM_nb benchLPM_nb, by(iso_1 year)
/* sum events by country over the period */ 
collapse (sum) nb_acled diff counterLPM_nb benchLPM_nb, by(iso_1)
g share1 = diff/nb_acled 
g share2 = diff/benchLPM_nb 

sum, d 
*
rename iso_1 ISO3
sort ISO3
keep ISO3 diff nb_acled share1
save "$Output_data\Figure_A9b", replace
*
use "$Output_data\BCRT_baseline", replace
g condition_around = (mainmineral != "diamond" & mainmineral_around != "diamond" & mainmineral != "tantalum" & mainmineral_around != "tantalum")
keep if  condition_around == 1 /* only predictions on minerals with reliable prices */
*
replace main_lprice = . if main_lprice == 0
collapse (mean) main_lprice mines, by(iso_1)
g noprice = (mines>0 & main_lprice == .)

rename iso_1 ISO3
sort ISO3
merge ISO3 using "$Output_data\Figure_A9b", nokeep
tab _merge
drop _merge
*
rename share1 share
replace share = -1 if share == 0 & noprice == 1
drop noprice

g share_bin = . 
replace share_bin = 1 if share >= 0.000 & share < 0.01 & share != .
replace share_bin = 2 if share >= 0.010 & share < 0.050 & share != .
replace share_bin = 3 if share >= 0.050 & share < 0.200 & share != .
replace share_bin = 4 if share >= 0.200 & share < 0.500 & share != .
replace share_bin = 5 if share >= 0.500 & share != . 
replace share_bin = 0 if mines == 0 | nb_acled == . | nb_acled == 0/* no observation in estimation */

sort ISO3

save "$Output_data\Figure_A9b", replace
outsheet using "$Results\Figure_A9b.csv", comma replace

*************************
* Bar chart (Figure A9b) *
*************************

rename share increase
drop if increase == 0 | increase == . | increase == -1
replace increase = 1 if increase > 1
graph hbar (sum) increase, over(ISO3, sort(increase) label(labsize(small))) bar(1, color(black)) legend(off) bgcolor(white) graphregion(color(white)) intensity(40)   lintensity(100) ytitle(Share of events explained by increase in mineral prices)  
graph export $Results\Figure_A9b.eps, as(eps) replace

*****************************
* aggregate quantifications *
*****************************

/*get total number of observed events */
/*(to be able to drop countries with less than 50 events in total sample)*/

use "$Output_data\BCRT_baseline", replace
drop if year == 1997
collapse (sum) nb_acled, by(iso_1)
sort iso_1
save "$Output_data\tempzz.dta", replace

///// AGGREGATE QUANTIFICATIONS /////

use "$Output_data\Figure_A9b", clear
drop nb_acled
rename ISO3 iso_1
sort  iso_1
merge iso_1 using "$Output_data\tempzz.dta", nokeep
tab  _merge
drop _merge

drop if share == 0 | share == . | share == -1 
replace share = 1 if share > 1

/* how many on average across countries with mines */
egen mean = mean(share)
di mean 
/* how many on average across countries with mines, excluding countries with <50 events ? */
drop mean 
egen mean = mean(share) if nb_acled>=50
di mean 
*
erase  "$Output_data\tempzz.dta"
erase  "$Output_data\tempyy.dta"
erase "$Output_data\Figure_A9b.dta"


log close


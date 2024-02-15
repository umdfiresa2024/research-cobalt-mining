*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------*
* This program performs the estimations of Tables 6 and 7, 16 and 17(appendix) and A36 to A38 (online appendix) of "This mine is mine: how minerals fuel conflicts in Africa"
* This version: Ocotber 2016
*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------*

cd "$base"

* ------------------------------------------------------------------------------------ *
					*  Table 6 - Firm ownership and conflicts *
* ------------------------------------------------------------------------------------ *

cap log close
log using "$Results\Table_6.log", replace

use "$Output_data\BCRT_baseline", clear

g nb_acled_battle = log(nb_event1+nb_event2+nb_event3+1)
g acled_battle    = (nb_acled_battle>0)

drop if mainmineral == "diamond" | mainmineral == "tantalum" 

drop for_company col_company gov_company other_company major_company

foreach var in for_company col_company gov_company other_company major_company{
	rename `var'_s `var'
}
sum for_company col_company gov_company other_company major_company, d

g for_company2 		= for_company-col_company /*foreign and colonizer*/
g tot_share 		= gov_company + for_company+other_company

keep if tot_share 	== .  | tot_share == 1

tab for_company

foreach var in for_company other_company gov_company major_company{
	replace `var' = 0 if mines == 0 
	g triple_`var'   = main_lprice_mines*`var'
}
qui reg acled     main_lprice_mines   for_company other_company gov_company  if sd_mines == 0 
keep if e(sample)

/*columns 1-2: foreign/domestic private/domestic public*/
eststo: my_reg2hdfespatial acled      		triple_for_company triple_other_company triple_gov_company 	if sd_mines == 0 , timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
eststo: my_reg2hdfespatial acled_battle   	triple_for_company triple_other_company triple_gov_company  if sd_mines == 0 , timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
	
drop triple*

foreach var in gov_company col_company for_company2 other_company{
	replace `var' = 0 if mines == 0
	g triple_`var'   = main_lprice_mines*`var'
}

/*columns 3-4: splitting foreign companies in colonizers vs non colonizers*/		
eststo: my_reg2hdfespatial acled      	     triple_* 													if sd_mines == 0, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
lincom triple_for_company2-triple_gov_company
lincom triple_for_company2-triple_col_company
lincom triple_for_company2-triple_other_company
eststo: my_reg2hdfespatial acled_battle      triple_* 													if sd_mines == 0, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
lincom triple_for_company2-triple_gov_company
lincom triple_for_company2-triple_col_company
lincom triple_for_company2-triple_other_company
	
foreach var in major_company{
	replace `var' = 0 if mines == 0
	g triple_`var'   = main_lprice_mines*`var'
}
/*columns 5-6: controlling for company size*/		
eststo: my_reg2hdfespatial acled		     triple_* if sd_mines == 0, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
eststo: my_reg2hdfespatial acled_battle      triple_* if sd_mines == 0, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

foreach var in for_company{
	replace `var' = 0 if mines == 0
	g triple_`var'   = main_lprice_mines*`var'
}
label var triple_col_company 		"$\ln$ price $\times$ mines $>0$ $\times$ Fgn Firms (col.)"
label var triple_for_company2 		"$\ln$ price $\times$ mines $>0$ $\times$ Fgn Firms (non col.)"
label var triple_for_company 		"$\ln$ price $\times$ mines $>0$ $\times$ Foreign Firms"
label var triple_major_company		"$\ln$ price $\times$ mines $>0$ $\times$ Large Firms"
label var triple_other_company		"$\ln$ price $\times$ mines $>0$ $\times$ Other Firms"
label var triple_gov_company		"$\ln$ price $\times$ mines $>0$ $\times$ Public Firms"

set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table 6) 
eststo clear			
				
log close

* ------------------------------------------------------------------------------------ *
					*  Table 7 - The role of transparency *
* ------------------------------------------------------------------------------------ *
				
cap log close
log using "$Results\Table_7.log", replace

use "$Output_data\BCRT_baseline", clear

** Corruption: country level **

foreach var in    major_company{ 
	replace `var' = 0 if mines == 0 
	g triple_`var'   = main_lprice_mines*`var'
}

foreach var in    wbgi_cce_init { 
		g triple_`var'   = main_lprice_mines*`var'
}

*** ICMM: firm level ***

bys gid: egen max_icmm = max(share_icmm)
replace icmm 			 = max_icmm

foreach var in  icmm{
 replace `var' = 0 if mines == 0
 g triple_`var'   = main_lprice_mines*`var'
}
 
sum acled if icmm == 1 & mines_a == 1 & year <2001
sum acled if icmm == 0 & mines_a == 1 & year <2001
 
sum production_main if icmm == 1 & mines_a == 1 & year <2001
sum production_main if icmm == 0 & mines_a == 1 & year <2001
 
** Tracability: GLR initiative + Kimberley ** 

cap drop diams
g diams 	= (mainmineral == "diamond")

g kimberley = (mainmineral  == "diamond" & year>2000) 
g glr_init  = ((mainmineral == "diamond" | mainmineral == "gold" | mainmineral == "tin" | mainmineral == "tungsten" | mainmineral == "manganese") & (year>=2006) & (iso_1 =="AGO" | iso_1 =="BDI" | iso_1 =="CAF" | iso_1 =="COD" | iso_1 =="COG" | iso_1 =="KEN" | iso_1 =="UGA" | iso_1 =="RWA" | iso_1 =="SDN" | iso_1 =="TZA" | iso_1 =="ZMB"))

g   traceability = (kimberley == 1 | glr_init == 1)
tab traceability

foreach var in   glr_init{ 
	g triple_`var'   = main_lprice_mines*`var'
}

drop for_company col_company gov_company other_company major_company

foreach var in for_company col_company gov_company other_company major_company{
	rename `var'_s `var'
}
sum for_company col_company gov_company other_company major_company, d

g noncol_company 		= for_company - col_company /* non colonizer countries' foreign companies share*/

* create mutually exclusive dummies *
replace for_company 	= 1 if for_company > gov_company & for_company > other_company & for_company!=. & gov_company!=. & other_company!=.
replace gov_company 	= 1 if gov_company > for_company & gov_company > other_company & for_company!=. & gov_company!=. & other_company!=.

replace for_company 	= 0 if for_company > 0 & for_company < 1 
replace other_company 	= 0 if other_company > 0 & other_company < 1 
replace gov_company 	= 0 if gov_company > 0 & gov_company < 1 

tab gov_company 
tab other_company 

g tot_share 			= gov_company + for_company+other_company
keep if tot_share == .  | tot_share == 1

* create mutually exclusive dummies for foreign firms*
replace col_company 	= 1  if noncol_company < col_company &  for_company == 1 & for_company!=. & col_company!=. & noncol_company!=.
replace col_company 	= 0 if  col_company > 0 &  col_company< 1

g for_company2 = .
replace for_company2 	= 1 if noncol_company > col_company &  for_company == 1 & for_company!=. & col_company!=. & noncol_company!=.
replace for_company2 	= 0 if (noncol_company < col_company &  for_company == 1 & for_company!=. & col_company!=. & noncol_company!=.) | for_company == 0

g tot_foreign_company 	= for_company2 + col_company
tab tot_foreign if for_company == 1 /*check mutually exclusive*/
drop tot_*

** EITI ** 

foreach letter in a p c c_bis{
	g triple_EITI`letter'   = main_lprice_mines*EITI`letter'
}
label var EITIa 					"EITI commitment (1st stage)"
label var EITIp 					"EITI candidature (2nd stage)"
label var EITIc_bis					"EITI submission compliance (3st stage)"
label var EITIc 					"EITI compliance (3st stage)"
label var icmm 						"International Council on Mining and Metals" 
label var triple_icmm 				"$\ln$ price $\times$ mines $>0$ $\times$ ICMM"
label var triple_wbgi_cce_init		"$\ln$ price $\times$ mines $>0$ $\times$ Corruption (TI)"
label var triple_major_company		"$\ln$ price $\times$ mines $>0$ $\times$ Major Company"
label var triple_glr_init 			"$\ln$ price $\times$ mines $>0$ $\times$ GLR initiative"
label var triple_EITIa		 		"$\ln$ price $\times$ mines $>0$ $\times$ EITIa"
label var triple_EITIp		 		"$\ln$ price $\times$ mines $>0$ $\times$ EITIp"
label var triple_EITIc		 		"$\ln$ price $\times$ mines $>0$ $\times$ EITIc"
label var triple_EITIc_bis	 		"$\ln$ price $\times$ mines $>0$ $\times$ EITIc_bis"

** Keep foreign owned firms only ** 
keep if for_company==1  | mines == 0

g nb_acled_battle = nb_event1+nb_event2+nb_event3
g acled_battle    = (nb_acled_battle>0)

drop if mainmineral == "diamond" | mainmineral == "tantalum"

/* Corruption */
eststo: reghdfe acled          				main_lprice_mines triple_major_company  triple_wbgi_cce_init 	if sd_mines == 0, vce(cluster country_nb) absorb(cell it) 
eststo: reghdfe acled_battle   				main_lprice_mines triple_major_company  triple_wbgi_cce_init 	if sd_mines == 0, vce(cluster country_nb) absorb(cell it) 

/* ICMM */
eststo: my_reg2hdfespatial acled          	main_lprice_mines triple_major_company  triple_icmm 			if sd_mines == 0, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
eststo: my_reg2hdfespatial acled_battle   	main_lprice_mines triple_major_company  triple_icmm 			if sd_mines == 0, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

/* EITI */
eststo: reghdfe acled          				main_lprice_mines triple_major_company  triple_EITIp 			if sd_mines == 0, vce(cluster country_nb) absorb(cell it) 
eststo: reghdfe acled_battle   				main_lprice_mines triple_major_company  triple_EITIp 			if sd_mines == 0, vce(cluster country_nb) absorb(cell it) 

eststo: reghdfe acled          				main_lprice_mines triple_major_company  triple_EITIc_bis 		if sd_mines == 0, vce(cluster country_nb) absorb(cell it) 
eststo: reghdfe acled_battle   				main_lprice_mines triple_major_company  triple_EITIc_bis 		if sd_mines == 0, vce(cluster country_nb) absorb(cell it) 

/* GLR  */
eststo: reghdfe acled         				main_lprice_mines triple_major_company  triple_glr_init 		if sd_mines == 0, vce(cluster country_nb) absorb(cell it) 
eststo: reghdfe acled_battle   				main_lprice_mines triple_major_company  triple_glr_init 		if sd_mines == 0, vce(cluster country_nb) absorb(cell it) 

drop triple*
	
set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table 7) 
eststo clear

log close

* ------------------------------------------------------------------------------------ *
				*  Table 16 - Ownership and conflicts: robustness *
* ------------------------------------------------------------------------------------ *

cap log close
log using "$Results\Table_16.log", replace

use "$Output_data\BCRT_baseline", clear

g nb_acled_battle = log(nb_event1+nb_event2+nb_event3+1)
g acled_battle    = (nb_acled_battle>0)

drop if mainmineral == "diamond" | mainmineral == "tantalum" 

drop for_company col_company gov_company other_company major_company
foreach var in for_company col_company gov_company other_company major_company{
	rename `var'_s `var'
}
sum for_company col_company gov_company other_company major_company, d

gen for_company2	= for_company-col_company /*foreign and colonizer*/

g tot_share 		= gov_company + for_company+other_company
keep if tot_share == .  | tot_share == 1

foreach var in for_company other_company gov_company major_company{
	replace `var' 	= 0 if max_mine == 0 
	g triple_`var'  = main_lprice_hist0*`var'
}
qui reg acled  main_lprice_hist0  for_company other_company gov_company
keep if e(sample)

/*columns 1-2: foreign/domestic private/domestic public*/
eststo: my_reg2hdfespatial acled      		triple_for_company triple_other_company triple_gov_company, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
eststo: my_reg2hdfespatial acled_battle   	triple_for_company triple_other_company triple_gov_company, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
	
drop triple*

foreach var in gov_company col_company for_company2 other_company{
	replace `var' = 0 if max_mine == 0
	g triple_`var'   = main_lprice_hist0*`var'
}
/*columns 3-4: splitting foreign companies in colonizers vs non colonizers*/		
eststo: my_reg2hdfespatial acled      	     triple_*, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
eststo: my_reg2hdfespatial acled_battle      triple_*, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
	
foreach var in major_company{
	replace `var' = 0 if max_mine == 0
	g triple_`var'   = main_lprice_hist0*`var'
}
/*columns 5-6: controlling for company size*/		
eststo: my_reg2hdfespatial acled		     triple_*, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
eststo: my_reg2hdfespatial acled_battle      triple_*, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
*
foreach var in for_company{
	replace `var' = 0 if max_mine == 0
	g triple_`var'   = main_lprice_hist0*`var'
}
label var triple_col_company 		"$\ln$ price $\times$ mines $>0$ $\times$ Fgn Firms (col.)"
label var triple_for_company2 		"$\ln$ price $\times$ mines $>0$ $\times$ Fgn Firms (non col.)"
label var triple_for_company 		"$\ln$ price $\times$ mines $>0$ $\times$ Foreign Firms"
label var triple_major_company		"$\ln$ price $\times$ mines $>0$ $\times$ Large Firms"
label var triple_other_company		"$\ln$ price $\times$ mines $>0$ $\times$ Other Firms"
label var triple_gov_company		"$\ln$ price $\times$ mines $>0$ $\times$ Public Firms"

set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table 16) 
eststo clear			

log close

* ------------------------------------------------------------------------------------ *
				*  Table 17 - The role of transparency: robustness *
* ------------------------------------------------------------------------------------ *

cap log close
log using "$Results\Table_17.log", replace

use "$Output_data\BCRT_baseline", clear

** Corruption: country level **

foreach var in major_company{ 
	replace `var' = 0 if max_mine == 0 
	g triple_`var'   = main_lprice_hist0*`var'
}

foreach var in wbgi_cce_init{ 
	g triple_`var'   = main_lprice_hist0*`var'
}

*** ICMM: firm level ***

bys gid: egen max_icmm  = max(share_icmm)
replace icmm 			= max_icmm


foreach var in  icmm{
 replace `var' 		= 0 if max_mine == 0
 g triple_`var'   	= main_lprice_hist0*`var'
}
 
 ** Tracability: GLR initiative + Kimberley ** 
g diams 			= (mainmineral == "diamond")
g kimberley 		= (mainmineral  == "diamond" & year>2000) 
g glr_init  		= ((mainmineral == "diamond" | mainmineral == "gold" | mainmineral == "tin" | mainmineral == "tungsten" | mainmineral == "manganese") & (year>=2006) & (iso_1 =="AGO" | iso_1 =="BDI" | iso_1 =="CAF" | iso_1 =="COD" | iso_1 =="COG" | iso_1 =="KEN" | iso_1 =="UGA" | iso_1 =="RWA" | iso_1 =="SDN" | iso_1 =="TZA" | iso_1 =="ZMB"))

g   traceability = (kimberley == 1 | glr_init == 1)
tab traceability
*
foreach var in   glr_init{ 
	g triple_`var'   = main_lprice_hist0*`var'
}

drop for_company col_company gov_company other_company major_company

foreach var in for_company col_company gov_company other_company major_company{
	rename `var'_s `var'
}
sum for_company col_company gov_company other_company major_company, d

g noncol_company = for_company - col_company /* non colonizer countries' foreign companies share*/

* create mutually exclusive dummies *
replace for_company 	= 1 if for_company > gov_company & for_company > other_company & for_company!=. & gov_company!=. & other_company!=.
replace gov_company 	= 1 if gov_company > for_company & gov_company > other_company & for_company!=. & gov_company!=. & other_company!=.

replace for_company 	= 0 if for_company > 0 & for_company < 1 
replace other_company 	= 0 if other_company > 0 & other_company < 1 
replace gov_company 	= 0 if gov_company > 0 & gov_company < 1 

tab gov_company 
tab other_company 

g tot_share 			= gov_company + for_company+other_company
keep if tot_share == .  | tot_share == 1

* create mutually exclusive dummies for foreign firms*
replace col_company 	= 1  if noncol_company < col_company &  for_company == 1 & for_company!=. & col_company!=. & noncol_company!=.
replace col_company 	= 0 if  col_company > 0 &  col_company< 1

g for_company2 			= .
replace for_company2 	= 1 if noncol_company > col_company &  for_company == 1 & for_company!=. & col_company!=. & noncol_company!=.
replace for_company2 	= 0 if (noncol_company < col_company &  for_company == 1 & for_company!=. & col_company!=. & noncol_company!=.) | for_company == 0

g tot_foreign_company 	= for_company2 + col_company
tab tot_foreign if for_company == 1 /*check mutually exclusive*/
drop tot_*

 ** EITI (UPDATED DATA - MAY 2016) ** 

 foreach letter in a p c c_bis{
	g triple_EITI`letter'   = main_lprice_hist0*EITI`letter'
}

label var EITIa 					"EITI commitment (1st stage)"
label var EITIp 					"EITI candidature (2nd stage)"
label var EITIc_bis					"EITI submission compliance (3st stage)"
label var EITIc 					"EITI compliance (3st stage)"
label var icmm 						"International Council on Mining and Metals" 
label var triple_icmm 				"$\ln$ price $\times$ mines $>0$ $\times$ ICMM"
label var triple_wbgi_cce_init		"$\ln$ price $\times$ mines $>0$ $\times$ Corruption (TI)"
label var triple_major_company		"$\ln$ price $\times$ mines $>0$ $\times$ Major Company"
label var triple_glr_init 			"$\ln$ price $\times$ mines $>0$ $\times$ GLR initiative"
label var triple_EITIa		 		"$\ln$ price $\times$ mines $>0$ $\times$ EITIa"
label var triple_EITIp		 		"$\ln$ price $\times$ mines $>0$ $\times$ EITIp"
label var triple_EITIc		 		"$\ln$ price $\times$ mines $>0$ $\times$ EITIc"
label var triple_EITIc_bis	 		"$\ln$ price $\times$ mines $>0$ $\times$ EITIc_bis"

** prelims estimations **

g nb_acled_battle 	= nb_event1+nb_event2+nb_event3
g acled_battle    	= (nb_acled_battle>0)

** Keep foreign owned firms only ** 
keep if for_company ==1 | max_mine == 0

drop if mainmineral == "diamond" | mainmineral == "tantalum"

** ESTIMATIONS **

/* Corruption */
eststo: reghdfe acled          				main_lprice_hist0 triple_major_company  triple_wbgi_cce_init , vce(cluster country_nb) absorb(cell it) 
eststo: reghdfe acled_battle   				main_lprice_hist0 triple_major_company  triple_wbgi_cce_init , vce(cluster country_nb) absorb(cell it) 

/* ICMM */
eststo: my_reg2hdfespatial acled          	main_lprice_hist0 triple_major_company  triple_icmm 		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
eststo: my_reg2hdfespatial acled_battle   	main_lprice_hist0 triple_major_company  triple_icmm 		, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

/* EITI */
eststo: reghdfe acled         				main_lprice_hist0 triple_major_company  triple_EITIp		, vce(cluster country_nb) absorb(cell it) 
eststo: reghdfe acled_battle   				main_lprice_hist0 triple_major_company  triple_EITIp		, vce(cluster country_nb) absorb(cell it) 

eststo: reghdfe acled         			 	main_lprice_hist0 triple_major_company  triple_EITIc_bis	, vce(cluster country_nb) absorb(cell it) 
eststo: reghdfe acled_battle   				main_lprice_hist0 triple_major_company  triple_EITIc_bis	, vce(cluster country_nb) absorb(cell it) 

/* GLR  */
eststo: reghdfe acled          				main_lprice_hist0 triple_major_company  triple_glr_init		, vce(cluster country_nb) absorb(cell it) 
eststo: reghdfe acled_battle  				main_lprice_hist0 triple_major_company  triple_glr_init		, vce(cluster country_nb) absorb(cell it) 

drop triple*
	
set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table 17) 
eststo clear

log close		


* ------------------------------------------------------------------------------------ *
			*  Table A36 to A38: robustness ownership and transparency *
* ------------------------------------------------------------------------------------ *

cap log close
log using "$Results\Table_A36_to_A38.log", replace

***********************
//Table A36: statistics
***********************

foreach var in gov_company for_company other_company major_company col_company for_company2 full_gov full_for full_other full_for2 full_col{

	use "$Output_data\BCRT_baseline", clear

	drop if mainmineral == "diamond" | mainmineral == "tantalum" 

	drop for_company col_company gov_company other_company major_company
		foreach var2 in for_company col_company gov_company other_company major_company{
		rename `var2'_s `var2'
	}
	sum for_company col_company gov_company other_company major_company, d
	
	gen for_company2=for_company-col_company /*foreign and colonizer*/
	
	g tot_share = gov_company + for_company+other_company
	keep if tot_share == 1

	g full_gov   = (gov_company==1)
	g full_for   = (for_company==1)
	g full_other = (other_company==1)
	g full_for2   = (for_company2==1)
	g full_col = (col_company==1)
	*
	collapse (count) N = `var' (mean) mean = `var' (median) median = `var' (sd) sd = `var'
	g name = "`var'" 
	save "$Results\stats_`var'", replace
}

use "$Results\stats_gov_company", clear
foreach var in for_company other_company major_company col_company for_company2 full_gov full_for full_other full_for2 full_col{
append using "$Results\stats_`var'"
}
*
order name N mean sd median
save "$Results\Table_A36", replace
*
foreach var in gov_company for_company other_company major_company col_company for_company2 full_gov full_for full_other full_for2 full_col{
erase "$Results\stats_`var'.dta"
}


*************************************
//Table A37: other types of companies
*************************************

use "$Output_data\BCRT_baseline", clear

** Corruption: country level **

foreach var in    major_company{ 
	replace `var' = 0 if mines == 0 
	g triple_`var'   = main_lprice_mines*`var'
}

foreach var in    wbgi_cce_init { 
	g triple_`var'   = main_lprice_mines*`var'
}

*** ICMM: firm level ***

bys gid: egen max_icmm 	 = max(share_icmm)
replace icmm 			 = max_icmm

foreach var in  icmm{
 replace `var' 		= 0 if mines == 0
 g triple_`var'   	= main_lprice_mines*`var'
 }
 
 ** Tracability: GLR initiative + Kimberley ** 
cap drop diams
g diams 		= (mainmineral == "diamond")

g kimberley 	= (mainmineral  == "diamond" & year>2000) 
g glr_init  	= ((mainmineral == "diamond" | mainmineral == "gold" | mainmineral == "tin" | mainmineral == "tungsten" | mainmineral == "manganese") & (year>=2006) & (iso_1 =="AGO" | iso_1 =="BDI" | iso_1 =="CAF" | iso_1 =="COD" | iso_1 =="COG" | iso_1 =="KEN" | iso_1 =="UGA" | iso_1 =="RWA" | iso_1 =="SDN" | iso_1 =="TZA" | iso_1 =="ZMB"))

g   traceability = (kimberley == 1 | glr_init == 1)
tab traceability
*
foreach var in   glr_init{ 
	g triple_`var' = main_lprice_mines*`var'
}

drop for_company col_company gov_company other_company major_company

foreach var in for_company col_company gov_company other_company major_company{
	rename `var'_s `var'
}
sum for_company col_company gov_company other_company major_company, d

g noncol_company = for_company - col_company /* non colonizer countries' foreign companies share*/

* create mutually exclusive dummies *
replace for_company 	= 1 if for_company > gov_company & for_company > other_company & for_company!=. & gov_company!=. & other_company!=.
replace gov_company 	= 1 if gov_company > for_company & gov_company > other_company & for_company!=. & gov_company!=. & other_company!=.

replace for_company 	= 0 if for_company > 0 & for_company < 1 
replace other_company 	= 0 if other_company > 0 & other_company < 1 
replace gov_company 	= 0 if gov_company > 0 & gov_company < 1 

tab gov_company 
tab other_company 

g tot_share 			= gov_company + for_company+other_company
keep if tot_share == .  | tot_share == 1

* create mutually exclusive dummies for foreign firms*
replace col_company	 	= 1  if noncol_company < col_company &  for_company == 1 & for_company!=. & col_company!=. & noncol_company!=.
replace col_company 	= 0 if  col_company > 0 &  col_company< 1

g for_company2 = .
replace for_company2 	= 1 if noncol_company > col_company &  for_company == 1 & for_company!=. & col_company!=. & noncol_company!=.
replace for_company2 	= 0 if (noncol_company < col_company &  for_company == 1 & for_company!=. & col_company!=. & noncol_company!=.) | for_company == 0

g tot_foreign_company 	= for_company2 + col_company
tab tot_foreign if for_company == 1 /*check mutually exclusive*/
drop tot_*

** EITI (UPDATED DATA - MAY 2016) ** 

foreach letter in a p c c_bis{
	g triple_EITI`letter'   = main_lprice_mines*EITI`letter'
}
label var EITIa 					"EITI commitment (1st stage)"
label var EITIp 					"EITI candidature (2nd stage)"
label var EITIc_bis					"EITI submission compliance (3st stage)"
label var EITIc 					"EITI compliance (3st stage)"
label var icmm 						"International Council on Mining and Metals" 
label var triple_icmm 				"$\ln$ price $\times$ mines $>0$ $\times$ ICMM"
label var triple_wbgi_cce_init		"$\ln$ price $\times$ mines $>0$ $\times$ Corruption (TI)"
label var triple_major_company		"$\ln$ price $\times$ mines $>0$ $\times$ Major Company"
label var triple_glr_init 			"$\ln$ price $\times$ mines $>0$ $\times$ GLR initiative"
label var triple_EITIa		 		"$\ln$ price $\times$ mines $>0$ $\times$ EITIa"
label var triple_EITIp		 		"$\ln$ price $\times$ mines $>0$ $\times$ EITIp"
label var triple_EITIc		 		"$\ln$ price $\times$ mines $>0$ $\times$ EITIc"
label var triple_EITIc_bis	 		"$\ln$ price $\times$ mines $>0$ $\times$ EITIc_bis"

** Keep foreign owned firms only ** 
keep if other_company ==1  | gov_company == 1 | mines == 0

g nb_acled_battle 	= nb_event1+nb_event2+nb_event3
g acled_battle    	= (nb_acled_battle>0)

drop if mainmineral == "diamond" | mainmineral == "tantalum"

/* Corruption */
eststo: reghdfe acled          				main_lprice_mines triple_major_company  triple_wbgi_cce_init 	if sd_mines == 0, vce(cluster country_nb) absorb(cell it) 
eststo: reghdfe acled_battle   				main_lprice_mines triple_major_company  triple_wbgi_cce_init 	if sd_mines == 0, vce(cluster country_nb) absorb(cell it) 

/* ICMM */
eststo: my_reg2hdfespatial acled          	main_lprice_mines triple_major_company  triple_icmm 			if sd_mines == 0, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
eststo: my_reg2hdfespatial acled_battle   	main_lprice_mines triple_major_company  triple_icmm 			if sd_mines == 0, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

/* EITI */
eststo: reghdfe acled          				main_lprice_mines triple_major_company  triple_EITIp 			if sd_mines == 0, vce(cluster country_nb) absorb(cell it) 
eststo: reghdfe acled_battle   				main_lprice_mines triple_major_company  triple_EITIp 			if sd_mines == 0, vce(cluster country_nb) absorb(cell it) 

eststo: reghdfe acled          				main_lprice_mines triple_major_company  triple_EITIc_bis 		if sd_mines == 0, vce(cluster country_nb) absorb(cell it) 
eststo: reghdfe acled_battle   				main_lprice_mines triple_major_company  triple_EITIc_bis 		if sd_mines == 0, vce(cluster country_nb) absorb(cell it) 

/* GLR  */
eststo: reghdfe acled          				main_lprice_mines triple_major_company  triple_glr_init 		if sd_mines == 0, vce(cluster country_nb) absorb(cell it) 
eststo: reghdfe acled_battle   				main_lprice_mines triple_major_company  triple_glr_init 		if sd_mines == 0, vce(cluster country_nb) absorb(cell it) 

drop triple*
	
set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table A37) 
eststo clear

******************************
//Table A38: kimberley process
******************************

use "$Output_data\BCRT_baseline", clear

 ** Tracability: GLR initiative + Kimberley ** 
cap drop diams
*
g diams = (mainmineral == "diamond")
*
g kimberley = (mainmineral  == "diamond" & year>2002) 
*
g post2002 = (year>2002) 

foreach var in  kimberley diams post2002{ 
	g triple_`var'   = main_lprice_mines*`var'
}
foreach var in  kimberley diams post2002{ 
	g triple_`var'_0   = main_lprice_hist0*`var'
}

g nb_acled_battle = nb_event1+nb_event2+nb_event3
g acled_battle    = (nb_acled_battle>0)

/* drop tantalum for baseline */
drop if mainmineral == "tantalum" 

/*column 1: mine open the entire period*/
eststo: my_reg2hdfespatial acled  main_lprice_mines triple_kimberley triple_diams triple_post2002 			if sd_mines == 0			, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 2: mine at some point over the period*/
eststo: my_reg2hdfespatial acled   main_lprice_hist0 triple_kimberley_0	triple_diams_0	triple_post2002_0							   	, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

/*column 3: mine open the entire period*/
eststo: my_reg2hdfespatial acled_battle  main_lprice_mines triple_kimberley triple_diams triple_post2002  	if sd_mines == 0			, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 
/*column 4: mine at some point over the period*/
eststo: my_reg2hdfespatial acled_battle   main_lprice_hist0 triple_kimberley_0	triple_diams_0 triple_post2002_0 						, timevar(it) panelvar(cell) lat(latitude) lon(longitude) distcutoff(500) lagcutoff(100000) 

set linesize 250
esttab, mtitles drop() b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles drop() b(%5.3f) se(%5.3f) r2  starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) se tex label  title(Table A38) 
eststo clear


cap log close

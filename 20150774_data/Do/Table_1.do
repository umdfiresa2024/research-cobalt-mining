*---------------------------------------------------------------------------------------------------------------------------*
* This program performs the descriptive statistics (Table 1) of "This mine is mine: how minerals fuel conflicts in Africa"
* This version: October 2016
*---------------------------------------------------------------------------------------------------------------------------*

cap log close
log using "$Results\Table_1.log", replace

* ------------------------------------------------------------------------------------ *
						*  Table 1 - Descriptive statistics *
* ------------------------------------------------------------------------------------ *

/* GID level */
foreach var in acled acled_mine1 acled_mine0 acled_battle acled_violent acled_riot nb_acled nb_acled_pos mines_a mine_with_around_d1 mine_with_around nb_mines_a nb_mines_pos two_more two_more_cond{
use "$Output_data\BCRT_baseline", clear
*
g mine_with_around    = max(mines_a,mines_around)
g mine_with_around_d1 = max(mines_a,mines_around_d1)
*
g nb_acled_violent 		= nb_event8
g acled_violent    		= (nb_acled_violent>0)
*
g nb_acled_battle 		= nb_event1+nb_event2+nb_event3
g acled_battle    		= (nb_acled_battle>0)
*
g nb_acled_riot     	= nb_event7
g acled_riot        	= (nb_acled_riot>0)

g acled_mine1 			= acled if mines_a>0
g acled_mine0 			= acled if mines_a==0
g nb_acled_pos 			= nb_acled if acled>0
g nb_mines_pos 			= nb_mines_a if mines_a>0
g two_more      		= (nb_mines_a>1 & nb_mines_a!=.)
g two_more_cond 		= (nb_mines_a>1 & nb_mines_a!=.)
replace two_more_cond = . if mines_a == 0

collapse (count) N = `var' (mean) mean = `var' (median) median = `var' (sd) sd = `var' (p25) p25 = `var' (p75) p75 = `var'

g name = "`var'" 
save "$Results\stats_`var'", replace
}

use "$Results\stats_acled", clear
foreach var in acled_mine1 acled_mine0 acled_battle acled_violent acled_riot nb_acled nb_acled_pos mines_a mine_with_around_d1 mine_with_around nb_mines_a nb_mines_pos two_more two_more_cond{
append using "$Results\stats_`var'"
}
*
order name N mean sd p25 median p75
save "$Results\Table_1", replace
*
foreach var in acled acled_mine1 acled_mine0 acled_battle acled_violent acled_riot nb_acled nb_acled_pos mines_a mine_with_around_d1 mine_with_around nb_mines_a nb_mines_pos two_more two_more_cond{
erase "$Results\stats_`var'.dta"
}

log close

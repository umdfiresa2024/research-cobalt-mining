capt program drop my_spatial_2sls
program my_spatial_2sls, eclass
	version 12
	syntax varlist [if] [in] [, end(varlist) iv(varlist) latitude(varname) longitude(varname) id(varname) time(varname) LAGcutoff(integer 0) DISTcutoff(real 1) LAGDISTcutoff(integer 0)]
	local depvar: word 1 of `varlist'
	local regs: list varlist - depvar
	marksample touse
	tempname b V
	

preserve	
	
qui ivreg2 `depvar' (`end' = `iv') `regs'
qui keep if e(sample)==1
qui sort `id' `time'
qui save temp_2sls_conley.dta, replace


*** Generate adjacency matrix 
*** We should turn adjency matrix into an input of the programs nw2ols and nw2sls
qui {
keep `id' `time'  `latitude' `longitude'

* sort group year
scalar define nsize = _N
gen numID=[_n]
save key.dta, replace


gen id_d= `id'
gen time_d= `time' 
gen numID_d= numID 
gen latitude_d= `latitude'
gen longitude_d= `longitude'
keep id_d time_d numID_d latitude_d longitude_d
save key_d.dta, replace

use key.dta, clear

cross using key_d
geodist `latitude' `longitude' latitude_d longitude_d , gen(distance) sphere

**** DEFINE CLUSTERING
** Panel clustering (time-series auto-correlation)
gen weight= max(0, 1 - (abs(`time' - time_d))/(`lagcutoff' +1)) if `id' == id_d
** Spatial clustering
replace weight=  max(0, 1 - (abs(`time' - time_d))/(`lagdistcutoff' +1)) if (`id'!=id_d) & (distance<= `distcutoff')
** Technical stuff: only zeros on the diagonal
replace weight=. if numID==numID_d 
**** END OF CLUSTERING

keep numID numID_d weight
replace weight=0 if weight==.
sort numID numID_d
}

capture mata mata drop adjacency



mata: st_view(W=.,.,.,.)
mata: adjacency = J(st_numscalar("nsize"),st_numscalar("nsize"), 0) 
mata for(i = 1; i <= rows(adjacency); i++) {
    for(j = 1; j<=cols(adjacency); j++) {
                   adjacency[i,j]=W[(i-1)* rows(adjacency)+j,3]
     }
 }
 

 
qui use temp_2sls_conley.dta, clear

qui do  "$Do_files\nw2sls"
nw2sls `depvar'  `regs', end(`end') iv(`iv')

qui cap erase  temp_2sls_conley.dta
qui cap erase key.dta
qui cap erase key_d.dta

end

 
 
/*
 
******
** Alternative: we patch the new2sls programm

use temp_2sls_conley.dta, clear


mata: st_view(Y=., ., "`depvar'")
mata: st_view(X=., ., "`end' `regs'")
mata: X=(X, J(rows(Y),1,1))
mata: st_view(Z=., ., "`iv' `regs'")
mata: Z=(Z, J(rows(Y),1,1))

mata: st_view(Xe=., ., "`end'")
mata: Nend = cols(Xe)

mata: st_view(Ze=., ., "`iv'")
mata: Niv = cols(Ze)


* 2SLS: parameters
mata: W=invsym(Z'Z)
mata: P=invsym(X'Z * W * Z'X)* X'Z * W *Z'
mata: b=P*Y
mata: res = Y-X*b
mata: resmat = res * res'
mata: N=rows(res)

* clustering
*diagnoal (i.e. robust)
*mata: cluster = I(rows(u))
* network
mata: cluster= I(rows(Y))+adjacency

* VCV of errors
mata: omega = resmat :* cluster

/*
* First stage
mata: PZ=Z*invsym(Z'Z)*Z'
mata: MZ=I(rows(PZ))-PZ


mata: X1=Xe[.,1]
mata: X2=Xe[.,2]

mata: gamma1=PZ * X1
*mata: rows(gamma1)
mata: resX1 = MZ * X1

mata: VCV1 = PZ * (resX1 * resX1' :* cluster) * PZ'
mata: VCV1 = VCV1[|1,1\16,16|]

mata: F1 = (gamma1[.,1..Niv]'*invsym(VCV1)*gamma1[.,1..Niv])/Niv
*/

* 2SLS: VCV
mata: V=P*omega*P'
mata: _makesymmetric(V)


* export
mata: b=b'
mata: st_matrix("r(V)", V)
mata: st_matrix("r(b)", b)
mata: st_numscalar("r(N)", N)
*mata: st_numscalar("r(F1)", F1)


	mat `b'=r(b)
	mat `V'=r(V)
	matname `V' "`end' `regs' _cons"
	mat colnames `b' = `end' `regs' _cons

    ereturn post `b' `V'
	ereturn local depvar "`depvar'"
	ereturn scalar N=r(N)
    ereturn local cmd "nw2sls"
    
    ereturn display
	

end


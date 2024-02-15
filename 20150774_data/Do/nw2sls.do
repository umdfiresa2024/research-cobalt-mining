capt program drop nw2sls
program nw2sls, eclass
	version 12
	syntax varlist [if] [in] [, end(varlist) iv(varlist) ]
	local depvar: word 1 of `varlist'
	local regs: list varlist - depvar
	marksample touse
	tempname b V
	


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

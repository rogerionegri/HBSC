PRO STOCH_DISTANCES_SET
   ;caller...
END


;###########################################
FUNCTION BHATTACHARYYA, MuX, MuY, SigmaX, SigmaY

  ;Distancia de Bhattacharyya, simplificada para distribuição gaussiana multivariada
  P = (SigmaX + SigmaY)/2.0
  D = (1/8.0)*TRANSPOSE(MuX - MuY)#INVERT(P)#(MuX - MuY) + $
    0.5*ALOG(DETERM(P, /check, /double)/SQRT(DETERM(SigmaX, /check, /double)*DETERM(SigmaY, /check, /double)))

  Return, D
END



;###########################################
FUNCTION JM, MuX, MuY, SigmaX, SigmaY

  B = BHATTACHARYYA(MuX, MuY, SigmaX, SigmaY)
  D = 2*(1-exp(-1*B))
  
  Return, D
END



;###########################################
FUNCTION HELLINGER, MuX, MuY, SigmaX, SigmaY

  ;Distancia de Hellinger, simplificada para distribuição gaussiana multivariada

  P = 0.5*(SigmaX + SigmaY)
  A = DETERM(SigmaX, /check, /double)^0.25 * DETERM(SigmaY, /check, /double)^0.25
  B = DETERM( P , /check, /double)^0.5
  D = -0.125 * TRANSPOSE(MuX - MuY)#INVERT(P)#(MuX - MuY)

  ;H = 1.0 - ( (A/B) * EXP(D) )
  H = SQRT(1.0 - ( (A/B) * EXP(D) ))

  Return, H
END



;###########################################
FUNCTION KULLBACK_LEIBLER, Mu0, Mu1, Sigma0, Sigma1

  ;Distancia de Kullback-Leibler para distribuição gaussiana multivariada

  invSigma0 = INVERT(Sigma0)
  invSigma1 = INVERT(Sigma1)
  k = N_ELEMENTS(Mu0)
  detSigma0 = DETERM(Sigma0, /check, /double)
  detSigma1 = DETERM(Sigma1, /check, /double)

  D01 = 0.5 * ( TRACE(invSigma1 # Sigma0) + TRANSPOSE(Mu1 - Mu0) # invSigma1 # (Mu1 - Mu0) - k + ALOG(detSigma1/detSigma0) )
  D10 = 0.5 * ( TRACE(invSigma0 # Sigma1) + TRANSPOSE(Mu0 - Mu1) # invSigma0 # (Mu0 - Mu1) - k + ALOG(detSigma0/detSigma1) )

  ;cabrito tosco....
  if ~finite(d01) then d01 = randomu(seed,1)
  if ~finite(d10) then d10 = randomu(seed,1)

  D = 0.5*(D01 + D10)

  Return, D
END
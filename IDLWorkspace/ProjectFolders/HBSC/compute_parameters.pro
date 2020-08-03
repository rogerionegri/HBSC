FUNCTION COMPUTE_PARAMETERS, Image, TReg, PntROIs

   Dim = SIZE(Image,/DIMENSION)
   NB = Dim[0]   &   NC = Dim[1]   &   NL = Dim[2]

   ParRegs = PTRARR(N_ELEMENTS(PntROIs))

   FOR i = 0, N_ELEMENTS(TReg)-1 DO BEGIN
   
      Regs = *TReg[i]
      Pars = PTRARR(N_ELEMENTS(Regs)) 
   
      FOR j = 0, N_ELEMENTS(Regs)-1 DO BEGIN
         Lex = *Regs[j] ;Pixel positions inside the region
      
         Samples = FLTARR(NB)
         FOR k = 0, N_ELEMENTS(Lex)-1 DO BEGIN
            lin = FIX(Lex[k]/NC)
            col = FIX(Lex[k] MOD NC)
            Samples = [ [Samples] , [Image[*,col,lin]] ]
         ENDFOR
         Samples = Samples[*,1:N_ELEMENTS(Samples[0,*])-1]
      
         ;Compute parameters....
         MeanVec = MEAN_VECTOR(Samples)
         SigMatrix = COVARIANCE_MATRIX(Samples)
         InvSigma = INVERT(SigMatrix, Status, /DOUBLE)
      
         IF Status THEN BEGIN
            WHILE Status DO BEGIN
               print, 'Singular matrix found... try small changes for conditioning', i
               SigMatrix += RANDOMU(SYSTIME(/SECONDS),N_ELEMENTS(SigMatrix[*,0]), N_ELEMENTS(SigMatrix[0,*]))
               InvSigma = INVERT(SigMatrix, Status, /DOUBLE)
            ENDWHILE             
         ENDIF
      
         Pars[j] = PTR_NEW({Mu: MeanVec, Sigma: SigMatrix, InvSigma: InvSigma})
      
         PTR_FREE, Regs[j] ;flushing vector 
      ENDFOR
   
      ParRegs[i] = PTR_NEW(Pars)
      PTR_FREE, TReg[i] ;flushing position
   ENDFOR

   Return, ParRegs
END


;#################################
FUNCTION MEAN_VECTOR, Samples
   MeanVec = Samples[*,0]
   FOR i = 0, N_ELEMENTS(Samples[*,0])-1 DO $
      MeanVec[i] = TOTAL(Samples[i,*])/FLOAT(N_ELEMENTS(Samples[0,*]))

   Return, MeanVec
END



;#################################
FUNCTION COVARIANCE_MATRIX, Samples
   MeanVec = Samples[*,0]
   FOR i = 0L, N_ELEMENTS(Samples[*,0])-1 DO $
      MeanVec[i] = TOTAL(Samples[i,*])/FLOAT(N_ELEMENTS(Samples[0,*]))
   
   SigMatrix = FLTARR(N_ELEMENTS(Samples[*,0]),N_ELEMENTS(Samples[*,0]))

   SampleMu = Samples
   FOR i = 0L, N_ELEMENTS(Samples[0,*])-1 DO SampleMu[*,i] = Samples[*,i] - MeanVec[*]
   FOR i = 0L, N_ELEMENTS(Samples[0,*])-1 DO SigMatrix += SampleMu[*,i]##(SampleMu[*,i])

   SigMatrix = SigMatrix/FLOAT(N_ELEMENTS(Samples[0,*]))

   Return, SigMatrix
END


FUNCTION COMPUTE_PARAMETERS_ROI, Image, PntROIs

   Dim = SIZE(Image,/DIMENSION)
   NB = Dim[0]   &   NC = Dim[1]   &   NL = Dim[2]

   ParRegs = PTRARR(N_ELEMENTS(PntROIs))

   FOR i = 0, N_ELEMENTS(PntROIs)-1 DO BEGIN
   
      Roi = *PntROIs[i]
      Lex = Roi.RoiLex
      Samples = FLTARR(NB)
      FOR k = 0L, N_ELEMENTS(Lex)-1 DO BEGIN
         lin = FIX(Lex[k]/NC)
         col = FIX(Lex[k] MOD NC)
         Samples = [ [Samples] , [Image[*,col,lin]] ]
      ENDFOR
      Samples = Samples[*,1:N_ELEMENTS(Samples[0,*])-1]
      
      ;Compute parameters...
      MeanVec = MEAN_VECTOR(Samples)
      SigMatrix = COVARIANCE_MATRIX(Samples)
      InvSigma = INVERT(SigMatrix, Status, /DOUBLE)
      
      IF Status THEN print, 'Singular matrix found...', i
      
      ;Store computed parametes...
      Pars = {Mu: MeanVec, Sigma: SigMatrix, InvSigma: InvSigma}      
      ParRegs[i] = PTR_NEW(Pars)
   
   ENDFOR

   Return, ParRegs
END
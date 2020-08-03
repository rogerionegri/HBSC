;TODO: Incluir a documentação desta função
FUNCTION kmeans_2clusterChanDetect, Image, Centroids

  Epsilon = 0.0000001

  Dims = GET_DIMENSIONS(Image)
  NB = Dims[0]
  NC = Dims[1]
  NL = Dims[2]

  ClaImage = BYTARR(3,NC,NL)
  ClaIndex = BYTARR(NC,NL)
  RuleImage = FLTARR(Centroids,NC,NL)

  ;Maximun value observed in each band
  maxBand = FLTARR(NB)
  FOR i = 0, NB-1 DO maxBand[i] = MAX(Image[i,*,*])

  ;Compute the mean vector of each class (from randomic seeds)
  C = FLTARR(Centroids,NB)
  Seed = RANDOMU(SYSTIME(/SECOND), Centroids)*100000
  FOR i = 0, Centroids-1 DO BEGIN
    C[i,*] = RANDOMU(Seed[i], NB) * maxBand
  ENDFOR

  Qnt = LONARR(Centroids)
  Sum = DBLARR(Centroids,NB)
  Diff = FLTARR(Centroids)

  REPEAT BEGIN
    oldC = C
    Qnt[*] = 0
    Sum[*] = 0
    FOR i = 0, NC-1 DO BEGIN
      FOR j = 0, NL-1 DO BEGIN
        Val = 10e10
        FOR k = 0, Centroids-1 DO BEGIN
          Dist = NORM(C[k,*] - Image[*,i,j])
          IF(Dist LT Val) THEN BEGIN
            Val = Dist
            Index = k
          ENDIF
        ENDFOR
        Sum[Index,*] += Image[*,i,j]
        Qnt[Index]++
      ENDFOR
    ENDFOR

    ;Centroid updating
    FOR i = 0, Centroids-1 DO C[i,*] = FLOAT(Sum[i,*])/FLOAT(Qnt[i] + 1)

    ;Convergence?
    ;print, MAX(NORM(C[*,*] - oldC[*,*])) ;temporario...
    Diff[*] = 0
    FOR i = 0, Centroids-1 DO Diff[i] = NORM(C[i,*] - oldC[i,*])

    print, MAX(Diff)

    ;ENDREP UNTIL(MAX(NORM(C[*,*] - oldC[*,*])) LT Epsilon)
  ENDREP UNTIL(MAX(Diff) LT Epsilon)

 ;Regra do Celik para Mudanca-NaoMudanca!
 cdIndex = INTARR(2)
 IF NORM(C[0,*]) LT NORM(C[1,*]) THEN cdIndex = [0,1] ELSE cdIndex = [1,0]
 
 FOR i = 0, NC-1 DO BEGIN
   FOR j = 0, NL-1 DO BEGIN
     Val = 10e10

     FOR k = 0, Centroids-1 DO BEGIN
       Dist = NORM(C[k,*] - Image[*,i,j])
       RuleImage[k,i,j] = Dist
       IF(Dist LT Val) THEN BEGIN
         Val = Dist
         Index = k
       ENDIF
     ENDFOR
     ClaIndex[i,j] = cdIndex[Index]
     ClaImage[*,i,j] = TEKTRONIX(cdIndex[Index])
   ENDFOR
 ENDFOR  

  Return, {Index: ClaIndex, Classification: ClaImage, RuleImage: RuleImage}
END
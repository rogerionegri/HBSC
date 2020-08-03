FUNCTION FUNC_CVA, I1, I2

   dims = GET_DIMENSIONS(I1)

   ;magnitude and direction-----------------------
   imgMag = DBLARR(dims[1],dims[2])
   imgDir = DBLARR(dims[1],dims[2])
   FOR i  = 0L, dims[1]-1 DO BEGIN
      FOR j  = 0L, dims[2]-1 DO BEGIN
         imgMag[i,j] = NORM(I1[*,i,j] - I2[*,i,j], /DOUBLE)
         imgDir[i,j] = ATAN( TOTAL(I1[*,i,j] * I2[*,i,j])/(NORM(I1[*,i,j], /DOUBLE) * NORM(I2[*,i,j], /DOUBLE)) )
      ENDFOR
   ENDFOR

   Return, {magnitude: imgMag, direction: imgDir}
END
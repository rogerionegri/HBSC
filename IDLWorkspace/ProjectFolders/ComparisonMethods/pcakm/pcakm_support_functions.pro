;Caller
;
FUNCTION PCAKM_SUPPORT_FUNCTIONS
 print, 'caller...'
END


;-----------------------------------------
FUNCTION GET_SAMPLE_BLOCKS, difImage, h

dims = GET_DIMENSIONS(difImage)

colBlocks = CEIL(dims[1]/FLOAT(h))
linBlocks = CEIL(dims[2]/FLOAT(h))

totalBlocks = LONG(colBlocks)*LONG(linBlocks)
vec_samples = MAKE_ARRAY(totalBlocks, h^2 , TYPE = SIZE(difImage, /TYPE))

count = 0L
FOR i = 0, dims[1], h DO BEGIN
  FOR j = 0, dims[2], h DO BEGIN
    
    IF ((i - h/2) GE 0) AND ((i + h/2) LT dims[1]) AND ((j - h/2) GE 0) AND ((j + h/2) LT dims[2]) THEN BEGIN
      vec_samples[count, *] = GET_VECTOR_NEIGH(difImage, i, j, h)
      count++
    ENDIF
    
  ENDFOR
ENDFOR


Return, vec_samples[0:count-1, *]
END



;----------------------------------------
FUNCTION GET_VECTOR_NEIGH, Img, i, j, h

  posNeigh = 0L
  neigh = MAKE_ARRAY(h^2 , TYPE = SIZE(Img, /TYPE))
  FOR k = (i - h/2), (i + h/2) DO BEGIN
    FOR l = (j - h/2), (j + h/2) DO BEGIN
      neigh[posNeigh] = Img[k,l]
      posNeigh++
    ENDFOR
  ENDFOR

  Return, neigh
END


;----------------------------------------
FUNCTION COMPUTE_MEAN_VECTOR_FROM_BLOCKS, Samples
   dims = SIZE(Samples, /DIMENSIONS)
   
   avgVec = DBLARR(dims[1])
   FOR i = 0, dims[1]-1 DO avgVec[i] = MEAN(Samples[*,i])

   Return, avgVec
END


;----------------------------------------
FUNCTION COMPUTE_COV_MATRIX_FROM_BLOCKS, Samples

   dims = SIZE(Samples, /DIMENSIONS)
   Psi = COMPUTE_MEAN_VECTOR_FROM_BLOCKS(Samples)

   C = DBLARR(dims[1], dims[1])
   FOR i = 0, dims[0]-1 DO C[*,*] +=  TRANSPOSE(Samples[i,*] - Psi[*]) # (Samples[i,*] - Psi[*])
   
   C =  (1.0/dims[0])*C
    
   Return, C
END


;-----------------------------------------
FUNCTION PROJECTION_PCA_SPACE, Img, Psi, sortC, h


dims = GET_DIMENSIONS(Img)

projImg = DBLARR(N_ELEMENTS(Psi), dims[1], dims[2]) 

   FOR i = 0, dims[1]-1 DO BEGIN
    FOR j = 0, dims[2]-1 DO BEGIN
      
      IF ((i - h/2) GE 0) AND ((i + h/2) LT dims[1]) AND ((j - h/2) GE 0) AND ((j + h/2) LT dims[2]) THEN BEGIN
        x = GET_VECTOR_NEIGH(Img, i, j, h)
        Vs = transpose(sortC)#(x - Psi)
        
        projImg[*,i,j] = Vs
      ENDIF
            
    ENDFOR 
   ENDFOR

Return, projImg
END
FUNCTION PCAKM_MODULE, PATH_T1, PATH_T2, Atts1, Atts2, h, s

   ;-------------------------------------------------------
   ;  PATH_T1 = 'time 1'
   ;  PATH_T2 = 'time 2';
   ;
   ;  Atts = attributes...
   ;
   ;  h = context size
   ;  S = extended space size
   ;-------------------------------------------------------

   img1 = OPEN_IMAGE(PATH_T1, Atts1)
   img2 = OPEN_IMAGE(PATH_T2, Atts2)
   difImage = FUNC_CVA(img1,img2)
   difImage = difImage.Magnitude
   
   sampleBlocks = GET_SAMPLE_BLOCKS(difImage, h)

   Psi = COMPUTE_MEAN_VECTOR_FROM_BLOCKS(sampleBlocks)
   covBlocks = COMPUTE_COV_MATRIX_FROM_BLOCKS(sampleBlocks)

   eval = EIGENQL(covBlocks, EIGENVECTORS = evec, RESIDUAL = residual)

   sortEVal = REVERSE(SORT(eval))
   pcaEigVecMatrix = covBlocks*0D

   ;ordenar a matriz de confusao de acordo com o autovalor mais relevante
   FOR i = 0, N_ELEMENTS(sortEVal)-1 DO pcaEigVecMatrix[*,i] = evec[*,sortEVal[i]]

   ;fazer a projecao da informaçao para o espaço pca
   projPCA = PROJECTION_PCA_SPACE(difImage, Psi, pcaEigVecMatrix, h)

   Res = kmeans_2clusterChanDetect(projPCA[0:(S-1),*,*], 2)

   Return, Res
END
@BocaLib.pro
@kmeans_2clusterChanDetect.pro
@assess_chandet_report.pro


PRO USFA_MAIN

   ;Path to LibSVM solver (set for your local path)
   PATH_OP_SOLVERS = './SVM_functions/LibSVM_solver/'

   ;PATH_T1 and _T2 are the images paths (tif files)
   PATH_T1 = './dataset/Images/Area1/20150925.tif'
   PATH_T2 = './dataset/Images/Area1/20160911.tif'
  
   ;PATH_ROI is the path for txt-like file containing references samples to assess the change detection results
   ;Such file must the ENVI's ASCII Roi format only with "ROI Location - 1dAddress" option   
   PATH_ROI = './dataset/Images/Area1/ChangeNonChange_RefSamples.txt'

   ;Atts1 allows select a band/attribute from images at PATH_T1 and PATH_T2
   ;The first band is indexed by 0 
   Atts1 = [0,1,2] ;The first three bands of PATH_T1 (and indirectly PATH_T2) will be considered in the following steps 
   Atts2 = Atts1

   ;Output text file with several assessment measures (Accuracy ; Precision ; Recall ; F1-Score ; Kappa ; VarianceKappa ; TP ; TN ; FP ; FN ; MCC; time(sec.))
   PATH_REPORT = './outputPath/Report.txt'
  
   ;Output path which contains the resullting change detection maps
   PATH_RESULT = './outputPath/'

   PREFIX = 'USFA__' ;Just a filename prefix (usefull for organization purposes)

   ;Atts1 allows select a band/attribute from images at PATH_T1 and PATH_T2
   ;The first band is indexed by 0
   Atts1 = [0,1,2] ;The first three bands of PATH_T1 (and indirectly PATH_T2) will be considered in the following steps
   Atts2 = Atts1

   ;Thresholding type: 1 - Otsu; 2 - Kittler-Illingworth; 3 - K-Means based approach
   tresType = 3
   ;Rule for histogram binsize choice: 0 - Freedman-Diaconis' rule; 1- Scott's rule [used for tresType 0 or 1]
   rule = 1
  
   parNames = ['tresType', 'rule']
   ;----------------------------------------------

   
   ;Dados originais-----------------------------
   img1 = OPEN_IMAGE(PATH_T1, Atts1)
   img2 = OPEN_IMAGE(PATH_T2, Atts2)
   
   ;Ajusta/inicia o Report
   PUT_HEADER, PATH_REPORT, parNames
   
   ;Número de pixels nas imagens
   N = FLOAT(N_ELEMENTS(img1[0,*,*]))

   ;Inicio cálculo do tempo
   t1 = SYSTIME(/seconds)

   ;Padronização da imagem-----------------------
   img1Pad = img1*0.0
   img2Pad = img2*0.0
   FOR i = 0, N_ELEMENTS(Atts1)-1 DO BEGIN
      mu = MEAN(img1[i,*,*])
      sig = MEAN(img1[i,*,*])
      img1Pad[i,*,*] = (img1[i,*,*] - mu)/sig
      
      mu = MEAN(img2[i,*,*])
      sig = MEAN(img2[i,*,*])
      img2Pad[i,*,*] = (img2[i,*,*] - mu)/sig
   ENDFOR
   
   ;Cálculo da matriz A--------------------------
   A = DBLARR(N_ELEMENTS(img1[*,0,0]) , N_ELEMENTS(img1[*,0,0])) * 0.0
   difImg = img1Pad - img2Pad
   FOR i = 0, N_ELEMENTS(img1[0,*,0])-1 DO BEGIN
      FOR j = 0, N_ELEMENTS(img1[0,0,*])-1 DO BEGIN
         vec = difImg[*,i,j]
         A[*,*] += vec#TRANSPOSE(vec)
      ENDFOR
   ENDFOR
   A[*,*] /= N
   
   ;Cálculo da matriz B--------------------------
   B  = DBLARR(N_ELEMENTS(img1[*,0,0]) , N_ELEMENTS(img1[*,0,0])) * 0.0
   sX = DBLARR(N_ELEMENTS(img1[*,0,0]) , N_ELEMENTS(img1[*,0,0])) * 0.0
   sY = DBLARR(N_ELEMENTS(img1[*,0,0]) , N_ELEMENTS(img1[*,0,0])) * 0.0
   FOR i = 0, N_ELEMENTS(img1[0,*,0])-1 DO BEGIN
      FOR j = 0, N_ELEMENTS(img1[0,0,*])-1 DO BEGIN
         vecX = img1Pad[*,i,j]
         vecY = img2Pad[*,i,j]
         
         sX[*,*] += vecX#TRANSPOSE(vecX)
         sY[*,*] += vecY#TRANSPOSE(vecY)
      ENDFOR
   ENDFOR
   sX[*,*] /= N
   sY[*,*] /= N
   B[*,*] = 0.5*( sX[*,*] + sY[*,*] )
   
   ;Resolução do probema de autovalor generalizados :: AW = BWL    (removido -- RANGE=vector, SEARCH_RANGE=vector, TOLERANCE=value)
   eval = LA_EIGENQL(A,B,/DOUBLE,EIGENVECTORS=evec,FAILED=fail,GENERALIZED=0,METHOD=0, STATUS=status)
   
   ;Geração da imagem SFA
   imgSFA = difImg*0.0
   FOR i = 0, N_ELEMENTS(img1[0,*,0])-1 DO BEGIN
      FOR j = 0, N_ELEMENTS(img1[0,0,*])-1 DO BEGIN
         FOR k = 0, N_ELEMENTS(img1[*,0,0])-1 DO BEGIN
            imgSFA[k,i,j] = (TRANSPOSE(evec[*,k]) # img1Pad[*,i,j]) - (TRANSPOSE(evec[*,k]) # img2Pad[*,i,j])
         ENDFOR
      ENDFOR
   ENDFOR
   
   ;Geração da imagem IDW
   ;imgIDW = imgSFA*0.0
   imgIDW  = FLTARR(1,N_ELEMENTS(img1[0,*,0]) , N_ELEMENTS(img1[0,0,*]))
   FOR i = 0, N_ELEMENTS(img1[0,*,0])-1 DO BEGIN
      FOR j = 0, N_ELEMENTS(img1[0,0,*])-1 DO BEGIN
         val = 0.0
         FOR k = 0, N_ELEMENTS(img1[*,0,0])-1 DO BEGIN
            val += (imgSFA[k,i,j]^2)/eval[k]     ;>>>esta em ordem crescente?
         ENDFOR
         imgIDW[0,i,j] = val
      ENDFOR
   ENDFOR
   
   
   ;-------------------------------------------
   ;Thresholding or K-Means based approach
   imgIDW_  = FLTARR(N_ELEMENTS(imgIDW[0,*,0]) , N_ELEMENTS(imgIDW[0,0,*]))
   imgIDW_[*,*] = imgIDW[0,*,*] & imgIDW = imgIDW_ *0 & imgIDW = imgIDW_ 
   CASE tresType OF
     1: BEGIN
       otsu = OTSU_THRESHOLD(imgIDW, rule)
       IndexMap = INTARR(N_ELEMENTS(imgIDW[*,0]) , N_ELEMENTS(imgIDW[0,*]))
       IndexMap[*,*] = otsu[*,*]

       cdmap = INTARR(3, N_ELEMENTS(imgIDW[*,0]) , N_ELEMENTS(imgIDW[0,*]))
       FOR i = 0, N_ELEMENTS(imgIDW[*,0])-1 DO BEGIN
         FOR j = 0, N_ELEMENTS(imgIDW[0,*])-1 DO BEGIN
           cdmap[*,i,j] = TEKTRONIX(IndexMap[i,j])
         ENDFOR
       ENDFOR
       Res = {Index: IndexMap, Classification: cdmap, RuleImage: imgIDW}
     END

     2: BEGIN
       kiw = KIW_THRESHOLD(imgIDW,rule)
       IndexMap = FLTARR(N_ELEMENTS(imgIDW[*,0]) , N_ELEMENTS(imgIDW[0,*]))
       IndexMap[*,*] = kiw

       cdmap = INTARR(3, N_ELEMENTS(imgIDW[*,0]) , N_ELEMENTS(imgIDW[0,*]))
       FOR i = 0, N_ELEMENTS(imgIDW[*,0])-1 DO BEGIN
         FOR j = 0, N_ELEMENTS(imgIDW[0,*])-1 DO BEGIN
           cdmap[*,i,j] = TEKTRONIX(IndexMap[i,j])
         ENDFOR
       ENDFOR
       Res = {Index: IndexMap, Classification: cdmap, RuleImage: imgIDW}
     END
     
     3: BEGIN
        temp  = FLTARR(1,N_ELEMENTS(imgIDW[*,0]) , N_ELEMENTS(imgIDW[0,*]))
        temp[0,*,*] = imgIDW[*,*]
        Res = kmeans_2clusterChanDetect(temp, 2)
     END
   ENDCASE
   time = SYSTIME(/seconds) - t1   
   
   ASSESS_CHANDET_REPORT, PATH_REPORT, Res.Index, PATH_ROI, [STRTRIM(STRING(tresType),1),STRTRIM(STRING(rule),1)], time
   WRITE_TIFF, PATH_RESULT + PREFIX + 'tresType-rule = ' + STRTRIM(STRING(tresType),1) +' - '+ STRTRIM(STRING(rule),1) + '_binMap.tif', Res.Index
   WRITE_TIFF, PATH_RESULT + PREFIX + 'tresType-rule = ' + STRTRIM(STRING(tresType),1) +' - '+ STRTRIM(STRING(rule),1) + '_classMap.tif', Res.Classification

   Print, 'End of process...'
END
@BocaLib.pro
@func_cva.pro
@pcakm_support_functions.pro
@kmeans_2clusterChanDetect.pro
@pcakm_module.pro
@assess_chandet_report.pro


PRO PCAKM_MAIN

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
   

   PREFIX = 'PCAKM__' ;Just a filename prefix (usefull for organization purposes)

   ;Atts1 allows select a band/attribute from images at PATH_T1 and PATH_T2
   ;The first band is indexed by 0
   Atts1 = [0,1,2] ;The first three bands of PATH_T1 (and indirectly PATH_T2) will be considered in the following steps
   Atts2 = Atts1

   ;PCAKM Parameters:
   h = 3 ;block size
   s = 3 ;number of selected princpal componentes (the first 's' components) :: s < h^2

   parNames = ['blockSize', 'numberComponents']
   ;----------------------------------------------
   
   PUT_HEADER, PATH_REPORT, parNames
   
   t1 = SYSTIME(/seconds)
   Res = PCAKM_MODULE(PATH_T1, PATH_T2, Atts1, Atts2, h, s)
   time = SYSTIME(/seconds) - t1

   ASSESS_CHANDET_REPORT, PATH_REPORT, Res.Index, PATH_ROI, [STRTRIM(STRING(h),1),STRTRIM(STRING(s),1)], time
   WRITE_TIFF, PATH_RESULT + PREFIX + 'blockSize-numberComponents = ' + STRTRIM(STRING(h),1) +' - '+ STRTRIM(STRING(s),1) + '_binMap.tif', Res.Index
   WRITE_TIFF, PATH_RESULT + PREFIX + 'blockSize-numberComponents = ' + STRTRIM(STRING(h),1) +' - '+ STRTRIM(STRING(s),1) + '_classMap.tif', Res.Classification
   
   Print, 'End of process...'
END
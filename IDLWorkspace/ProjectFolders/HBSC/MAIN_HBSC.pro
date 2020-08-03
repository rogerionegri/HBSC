@BocaLib.pro

@assess_chandet_report.pro
@build_component_diference_image.pro
@check_homogenety_all_sizes.pro
@find_homogeneous_blocks_if_possible.pro
@stoch_distances_set.pro
@check_homogenety.pro
@compute_parameters.pro

@svm__oneclass.pro
@image2text_libsvm_predict_format.pro
@build_training_data__one_class.pro
@text2image_libsvm_predict_format__oneclass.pro


PRO MAIN_HBSC
   COMMON PkgOpSolvers, PATH_OP_SOLVERS

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
   
    PREFIX = 'HBSC__' ;Just a filename prefix (usefull for organization purposes)

   ;Parameters
   alpha = 0.7   ;Significance for homogeneous block hypothesis testing 
   nu = 0.001    ;OC-SVM parameter
   gamm = 0.01  ;RBF kernel parameter
   ;-----------------------------------------------


   PUT_HEADER, PATH_REPORT, 'alpha ; nu ; gamma'
   
   t0 = systime(/seconds)

   ;Determinacao dos blocos de comparacao----------
   dims = GET_IMAGE_DIMS_WITHOUT_OPEN(PATH_T1)
   t0 = systime(/seconds)

   ;Obter a imagem de diferença por componentes
   cdImage = BUILD_COMPONENT_DIFERENCE_IMAGE(PATH_T1,PATH_T2, Atts1, Atts2)

   ;Investigacao dos blocos homogeneos...
   structHomogeneous = CHECK_HOMOGENETY_ALL_SIZES(cdImage, alpha)

   ;One-Class SVM classification stage
   lex = WHERE(structHomogeneous.homoImageRefined EQ 1)
   IF N_ELEMENTS(lex) LT 100000L then $ ;...if not too large, use the complete information from homogeneous blocks   
      OneClassRoi = PTR_NEW( {RoiName: 'Pseudo-OneClass', RoiColor: [255,0,0], RoiLex: lex} ) $
   ELSE OneClassRoi = PTR_NEW( {RoiName: 'Pseudo-OneClass', RoiColor: [255,0,0], RoiLex: lex[SORT(RANDOMU(seed, 50000))]} )

   cdMap = SVM__OneClass(cdImage, OneClassRoi, {nu: nu, gamma: gamm}) ;Output structure from change detection process

   runTime = systime(/seconds) - t0

   ;Result assessment
   ASSESS_CHANDET_REPORT, PATH_REPORT, cdMap.Classification, PATH_ROI, [alpha,cdMap.pars], runTime
  
   WRITE_TIFF, PATH_RESULT + PREFIX + STRTRIM(STRING(alpha),2) + '_binMap.tif', cdMap.Index
   WRITE_TIFF, PATH_RESULT+ PREFIX + STRTRIM(STRING(alpha),2) + '_classMap.tif', TEKTRONIX_V2(cdMap.Index)

   Print, 'End of process...'
   Stop
END
FUNCTION SVM__OneClass, Image, ROIs, ParamStruct
COMMON PkgOpSolvers, PATH_OP_SOLVERS 
 
   IMAGE2TEXT_LIBSVM_PREDICT_FORMAT, Image ;Imagem a ser usada no LibSVM (entrada em texto)
  
   temp = *ROIs[0]
   PtrTRAINING = BUILD_TRAINING_DATA__ONE_CLASS(temp.RoiLex, Image)

   ;---------------------------------------------------------------------------------------------
   ;DiImage = INTERFACE_LIBSVM_TRAIN_PREDICT__COMPLETE__ONECLASS(PtrTRAINING, ParamSTRUCT)
   
   ;transforma no formato de entrada adequado
   OpenW, File, PATH_OP_SOLVERS+'TrainingLibSVM', /GET_LUN
   X = *PtrTRAINING[0]
   Y = *PtrTRAINING[1]
   n = N_ELEMENTS(Y)-1
   d = N_ELEMENTS(X[*,0])-1

   FOR i = 0L, n DO BEGIN
     Line = STRTRIM(STRING(FIX(Y[i])),1)
     FOR j = 0L, d DO BEGIN
       Att = ' '+STRTRIM(STRING(j+1),1) + ':'+STRTRIM(STRING(X[j,i], FORMAT='(F30.20)'),1)
       Line += Att
     ENDFOR
     PrintF, File, Line
   ENDFOR
   Close, File   &   FREE_LUN, File


   CD, PATH_OP_SOLVERS

   ;On Windows OS, change ./svm-train_LINUX and ./svm-predict_LINUX to svm-train and svm-predict_LINUX, respectively 
   command_train = './svm-train_LINUX -s 2 -n ' + STRTRIM(STRING(ParamStruct.nu),1) + ' -t 2 -g ' + STRTRIM(STRING(ParamStruct.gamma),1) + ' -e 0.0001 -h 0' + ' TrainingLibSVM' + ' FileSV' 
   SPAWN, command_train;, /HIDE
   command_pred = './svm-predict_LINUX  predictFile  FileSV  outPrediction'
   SPAWN, command_pred;, /HIDE

   dims = GET_DIMENSIONS(*PtrTRAINING[2])
   Index = TEXT2Image_LIBSVM_PREDICT_FORMAT__ONECLASS(PATH_OP_SOLVERS+'outPrediction', dims[1], dims[2])
;---------------------------------------------------------------------------------------------   
   
END
   Return, {Index: Index, pars: [ParamStruct.nu, ParamStruct.gamma]} 
FUNCTION TEXT2Image_LIBSVM_PREDICT_FORMAT__ONECLASS, Path_Prediction, numCol, numLines

  OpenR, Arq, Path_Prediction, /GET_LUN

  imgPred = INTARR(numCol, numLines)

;  Head = ''
;  ReadF, Arq, Head
  FOR i = 0, numCol-1 DO BEGIN
    FOR j = 0, numLines-1 DO BEGIN
      ReadF, Arq, lab
      IF lab EQ 1 THEN imgPred[i,j] = 0 ELSE imgPred[i,j] = 1
    ENDFOR
  ENDFOR

  Close, Arq
  FREE_LUN, Arq

  Return, imgPred
END
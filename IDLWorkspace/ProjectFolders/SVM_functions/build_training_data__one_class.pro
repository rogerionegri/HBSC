;#######################
FUNCTION BUILD_TRAINING_DATA__ONE_CLASS, Roi, Image
  ;#INPUT
  ;R1: Lexicographic pixel positions of ROI
  ;Image: Image

  ;#OUTPUT
  ;Vector containing with pointers to X and Y vectors
  ;[X,Y]: X = Pointer to Data Training matrix / Y = Pointer to Class Label vector

  Dims = size(Image,/dimension)
  NL = Dims[2]
  NC = Dims[1]

  ;Build a image just with interest attributes
  ;TEMP = Image  &
  ImageAux = Image

  X = FLTARR(Dims[0],N_ELEMENTS(Roi))
  Y = FLTARR(N_ELEMENTS(Roi))
  pos = 0L

  ;Reading values on ROI and building the training vector (X,Y)
  FOR i=0L, N_ELEMENTS(Roi)-1 DO BEGIN
    lin = FIX(Roi[i]/NC)
    col = (Roi[i] MOD NC)
    X[*,pos] = ImageAux[*,col,lin]
    Y[pos] = +1
    pos++
  ENDFOR

  Return, [PTR_NEW(X),PTR_NEW(Y),PTR_NEW(ImageAux)]
END
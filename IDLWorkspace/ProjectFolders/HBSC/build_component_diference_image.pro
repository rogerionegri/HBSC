FUNCTION BUILD_COMPONENT_DIFERENCE_IMAGE, PATH_T1, PATH_T2, Atts1, Atts2

;Opening---------------------------------
img1 = OPEN_IMAGE(PATH_T1, Atts1)
img2 = OPEN_IMAGE(PATH_T2, Atts2)

;Normalizing-----------------------------
img1 = IMAGE_NORMALIZATION(img1)
img2 = IMAGE_NORMALIZATION(img2)

dims = GET_DIMENSIONS(img1)

cdImage = img1*0.0
FOR i = 0, dims[0] -1 DO cdImage[i,*,*] = FLOAT(img1[i,*,*]) - FLOAT(img2[i,*,*]) 
  
Return, cdImage
END
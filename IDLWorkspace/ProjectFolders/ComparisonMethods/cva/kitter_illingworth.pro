FUNCTION KITTER_ILLINGWORTH, h, x

  n = N_ELEMENTS(x)
  h *= 1.0   &   x *= 1.0

  A = GRADATIVE_CUMSUM(h)
  B = GRADATIVE_CUMSUM(h[*]*x[*])
  C = GRADATIVE_CUMSUM(h[*]*(x[*]^2))

  p = A[*]/A[n-1]
  q = (A[n-1] - A[*])/A[n-1]

  u = B[*]/A[*]
  v = (B[n-1] - B[*])/(A[n-1] - A[*])

  s2 = (C[*]/A[*]) - u[*]^2
  t2 = (C[n-1] - C[*])/(A[n-1] - A[*]) - v[*]^2

  s = (p[*] * alog(s2[*] / p[*])) + (q[*] * alog(t2[*] / q[*]))

  f = WHERE(FINITE(s) EQ 1)
  idx = WHERE(s[f[*]] EQ MIN(s[f[*]]))

  t = x[f[idx[0]]]

  Return, t ;[t,s]
END



;#####################################################
FUNCTION GRADATIVE_CUMSUM, vec

  n = N_ELEMENTS(vec)

  acc = vec[*]*0
  FOR i = 0, (n-1) DO acc[i] = TOTAL(vec[0:i])

  Return, acc
END



;#####################################################
FUNCTION KIW_THRESHOLD, Img, rule

  if rule eq 0 then BS = 0.5*IQR(Img)*(N_ELEMENTS(Img)^(-1.0/3.0)) $ ;freedman-diaconis rule
  else BS = 3.49*STDDEV(Img)*(N_ELEMENTS(Img)^(-1.0/3)) ;scott rule

  ;h = HISTOGRAM( image - minimumDC, OMIN=minDC, OMAX=maxDC, BINSIZE=BS, locations=x )

  ;h = HISTOGRAM(Img, BINSIZE=(MAX(Img) - MIN(Img))*0.1, LOCATIONS = x)
  ;FreedmanDiaconis = 2*IQR(Img)*(N_ELEMENTS(Img)^(-1.0/3.0))
  ;Scott = 3.49*STDDEV(Img)*(N_ELEMENTS(Img)^(-1.0/3))
  
  h = HISTOGRAM(Img, BINSIZE=BS, LOCATIONS = x)
  Res = KITTER_ILLINGWORTH(h,x)

  pos = WHERE(Img GE Res)
  treshImg = FLOOR(Img[*,*]*0)
  treshImg[pos] = 1

  Return, treshImg
END




;#####################################################
FUNCTION IQR, Img

  sortData = Img[SORT(Img)]
  ind = N_ELEMENTS(Img)/2

  IF N_ELEMENTS(sortData) MOD 2 EQ 0 THEN BEGIN
    lower = sortData[0:ind-1]
    higher = sortData[ind:N_ELEMENTS(Img)-1]
  ENDIF ELSE BEGIN
    lower = sortData[0:ind]
    higher = sortData[ind:N_ELEMENTS(Img)-1]
  ENDELSE

  q25 = MEDIAN(lower, /EVEN)
  q75 = MEDIAN(higher, /EVEN)

  Return, q75-q25
END
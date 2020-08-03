;+
; Compilation procedure.
;
PRO RoiFunctions
END

;+
; Function developed to parse samples colected from images and stored in
; ENVI ASCII format, just using the lexicographic pixel adress (1d-adress).
;
; @returns a pointer to structures that contains informations like name, 
;          color representations and lexicographic pixel adress that compose 
;          the samples of each class
; 
; @param PathROI {in}{required}{type=string} sample file path.
;-
FUNCTION ASCII_READ_ROI,PathROI
COMMON PkgROIs, NumROIs, FileDIM
COMMON PkgARQs, ArqROI
COMMON PkgStruct, RoiStruct, CountStruct
COMMON PkgPointer, PointerROIs
close,/all
OpenR,ArqROI,PathROI,/GET_LUN
Line = ''
CountStruct = 0
WHILE ~EOF(ArqROI) DO BEGIN
   ReadF,ArqROI,Line
   Split = STRSPLIT(Line,' ',/EXTRACT)
   VERIFY_INFO, Split
ENDWHILE
Return, PointerROIs
END

;+
; Procedure used to read ASCII file and store the lexicographic pixel information, for each sample.
; The set variables used into this procedure are global, and defined in ASCII_READ_ROI procedure
;-
PRO FILL_ROI
COMMON PkgROIs, NumROIs, FileDIM
COMMON PkgARQs, ArqROI
COMMON PkgStruct, RoiStruct, CountStruct
COMMON PkgPointer, PointerROIs
pos = 0L
TEMP = *PointerROIs[CountStruct]
WHILE ~EOF(ArqROI) DO BEGIN
   ReadF,ArqROI,Line
  
   IF pos EQ N_ELEMENTS(TEMP.RoiLex) THEN BEGIN
      pos = 0L
      CountStruct++
   ENDIF
  
   TEMP = *PointerROIs[CountStruct]
   TEMP.RoiLex[pos] = ULONG(Line)
   *PointerROIs[CountStruct]=TEMP
   pos++
ENDWHILE
END

;+
; Procedure responsable to parse keywords into ENVI's ASCII sample file format. 
; 
; @param Split {in}{required}{type=string} string line read from ASCII file
;-
PRO VERIFY_INFO, Split
COMMON PkgROIs, NumROIs, FileDIM
COMMON PkgARQs, ArqROI
COMMON PkgStruct, RoiStruct, CountStruct
COMMON PkgPointer, PointerROIs
IF N_ELEMENTS(Split) GT 1 THEN BEGIN
   IF Split[0]+Split[1] EQ ';Number' THEN  PointerROIs = PTRARR(FIX(Split[4]))
 
   IF Split[0]+Split[1] EQ ';File' THEN  FileDIM = [Split[3],Split[5]]
   IF Split[0]+Split[1] EQ ';ROI' THEN  BEGIN
      BUILD_ROI_STRUCT, Split
      PointerROIs[CountStruct] = PTR_NEW(RoiStruct)
      CountStruct++
   ENDIF
   IF Split[0]+Split[1] EQ ';Addr' THEN  BEGIN
      CountStruct = 0
      FILL_ROI
   ENDIF
ENDIF
END

;+
; Function used to parse and recognize the color defined to each class into ENVI's ASCII sample file. 
;
; @returns a 3d integer array with the RGB color class representation
; 
; @param Colour {in}{required}{type=string} string segment read from ASCII file
;-
FUNCTION ExtractColor,Colour
Colour = STRSPLIT(Colour,'{',/EXTRACT)
Colour = STRSPLIT(Colour,'}',/EXTRACT)
Vector = STRSPLIT(Colour,',',/EXTRACT)
Red = FIX(Vector[0])
Green = FIX(Vector[1])
Blue = FIX(Vector[2])
Return,[Red,Green,Blue]
END

;+
; Procedure used to join all parsed information and build a structure with informations about the sample. 
; 
; @param Split {in}{required}{type=string} string line read from ASCII file
;-
PRO BUILD_ROI_STRUCT, Split
COMMON PkgROIs, NumROIs, FileDIM
COMMON PkgARQs, ArqROI
COMMON PkgStruct, RoiStruct, CountStruct
COMMON PkgPointer, PointerROIs
Name = Split[3]
Line = ''
ReadF,ArqROI,Line
Split = STRSPLIT(Line,' ',/EXTRACT)
Colour = Split[4]+Split[5]+Split[6]
VecCOLOR = ExtractColor(Colour)
ReadF,ArqROI,Line
Split = STRSPLIT(Line,' ',/EXTRACT)
Points = LONG(Split[3])
RoiStruct = { RoiName: Name, RoiColor: VecCOLOR, RoiLex: LONARR(Points)}
END

;+
; Verify if a ROI/ASCII file is consistent.  
;
; @returns a index value, where -1 indicates total consistence. 
; Values from 0 to 11 are codes that informs diferent problems 
; found into the ROI file. Meaning for these codes are given in
; 'ROI_ERROR_CODE' function.
; 
; @param PATH_ROI {in}{required}{type=string} file path of and ASCII/ROI file
; 
; @param Dims {in}{required}{type=numeric vector} Image dimension releted to the
; ROIS represented on ASCII/ROI file
;-
FUNCTION CHECK_ROI_CONSISTENCY, PATH_ROI, Dims
COMMON PkgUnit, Unit

;GET_LUN,Unit
OpenR, Unit, PATH_ROI, /GET_LUN

;Check reader consistency
Line = ''

ReadF, Unit, Line ;First line (file description and data/time)
Str = STRSPLIT(Line,' ',/EXTRACT)
IF Str[0] NE ';' THEN  Return, ROI_ERROR_CODE(0)

IF EOF(Unit) THEN Return, ROI_ERROR_CODE(11)
ReadF, Unit, Line ;Second line (number of regions)
Str = STRSPLIT(Line,' ',/EXTRACT)
IF Str[0] EQ ';' AND STRUPCASE(Str[1]+Str[2]+Str[3]) EQ 'NUMBEROFROIS:' AND FIX(Str[4]) GT 0 $
   THEN nROIs = FIX(Str[4]) ELSE Return, ROI_ERROR_CODE(1)

;verify the image dimensions...
IF EOF(Unit) THEN Return, ROI_ERROR_CODE(11)
ReadF, Unit, Line ;Third line (image dimensions)
Str = STRSPLIT(Line,' ',/EXTRACT)   
IF Str[0] EQ ';' AND STRUPCASE(Str[1]+Str[2]+Str[4]) EQ 'FILEDIMENSION:X' AND $
   FIX(Str[3]) GT 0 AND FIX(Str[5]) GT 0 THEN Dim = [FIX(Str[3]),FIX(Str[5])] ELSE Return, ROI_ERROR_CODE(2)
      

;check samples information consistency
RoiInfo = REPLICATE({RoiStruct, RoiName: '', RoiColor: [0,0,0], RoiNPTS: LONG(0)}, nROIs)
 
FOR i = 0, nROIs-1 DO BEGIN
   
   IF EOF(Unit) THEN Return, ROI_ERROR_CODE(11)
   ReadF, Unit, Line  ;blank line
   IF STRSPLIT(Line,';',/EXTRACT) NE '' THEN Return, ROI_ERROR_CODE(3)
   
   IF EOF(Unit) THEN Return, ROI_ERROR_CODE(11)
   ReadF, Unit, Line ;roi name
   Str = STRSPLIT(Line,' ',/EXTRACT)
   IF STRUPCASE(Str[1]+Str[2]) EQ 'ROINAME:' THEN RoiInfo[i].RoiName = Str[3] ELSE Return, ROI_ERROR_CODE(4)
   
   IF EOF(Unit) THEN Return, ROI_ERROR_CODE(11)
   ReadF, Unit, Line ;roi rgb value
   Str = STRSPLIT(Line,' ',/EXTRACT)
   IF STRUPCASE(Str[1]+Str[2]+Str[3]) EQ 'ROIRGBVALUE:' THEN BEGIN
      Str = STRSPLIT(Str[4]+Str[5]+Str[6],'{,}',COUNT = match, /EXTRACT)
      IF match EQ 3 THEN RoiInfo[i].RoiColor = FIX(Str) ELSE Return, ROI_ERROR_CODE(5)
   ENDIF
   
   IF EOF(Unit) THEN Return, ROI_ERROR_CODE(11)
   ReadF, Unit, Line ;# of points
   Str = STRSPLIT(Line,' ',/EXTRACT)
   IF STRUPCASE(Str[1]+Str[2]) EQ 'ROINPTS:' AND FIX(Str[3]) GT 0 $
      THEN RoiInfo[i].RoiNPTS = FIX(Str[3]) ELSE Return, ROI_ERROR_CODE(6)
   
ENDFOR

ReadF, Unit, Line ;start of sample list
Str = STRSPLIT(Line,' ',/EXTRACT)
IF N_ELEMENTS(Str) EQ 2 and STRUPCASE(Str[0]+Str[1]) EQ ';ADDR' THEN BEGIN
   
   FOR i = 0L, nROIs-1 DO BEGIN
      
      FOR j = 1L, RoiInfo[i].RoiNPTS DO BEGIN
      
         ;cheking pixels location
         IF EOF(Unit) THEN Return, ROI_ERROR_CODE(11)
         ReadF, Unit, Line
         IF Line EQ '' THEN Return, ROI_ERROR_CODE(10) ELSE BEGIN
            pos = LONG(Line)
         
            ;Quoc = pos/Dim[0]
            ;Rest = pos MOD Dim[0]
         
            ;??? não esta errado???
            ;col = pos/Dim[0]
            ;lin = pos MOD Dim[0]
           
            col = pos MOD Dim[0] 
            lin = pos/Dim[0]
           
         
            ;IF Rest EQ 0 THEN lin = Quoc - 1 ELSE lin = Quoc
            ;IF Rest EQ 0 THEN col = Dim[0] ELSE col = Rest - 1
         
            IF (col LT 0) OR (col GE Dim[0]) THEN BEGIN
               ;stop
               Return, ROI_ERROR_CODE(8)
            ENDIF
            
            IF (lin LT 0) OR (lin GE Dim[1]) THEN BEGIN
               ;stop
               Return, ROI_ERROR_CODE(8)
            ENDIF
         ENDELSE
      ENDFOR
      
      
      IF ~EOF(Unit) THEN BEGIN
         ReadF, Unit, Line
         IF (Line NE '') THEN Return, ROI_ERROR_CODE(9)
      ENDIF
   
   ENDFOR

ENDIF ELSE Return, ROI_ERROR_CODE(7)

Close, Unit
FREE_LUN, Unit

Return, -1 ;when everthing is alright!
END


;+
; Error code dialog for the 'CHECK_ROI_CONSISTENCY' function
;
; @returns a dialog window showing possible erros found along the ASCII/ROI
; file consistence checking.
; 
; @param Arg {in}{required}{type=numeric} index to distinguishes kins of erros.
;-
FUNCTION ROI_ERROR_CODE, Arg
COMMON PkgUnit, Unit

;0 - Invalid file header. ';' not found.
;1 - Invalid number of rois.
;2 - Invalid image dimensions.
;3 - Blank line not found.
;4 - Invalid roi name definition.
;5 - Invalid color definition.
;6 - Invalid definition of number of points.
;7 - Invalid sample list beginig.
;8 - Invalid sample location - lexicographic location is out the image bounds.
;9 - Invalid information. Unexpected read information.
;10 - Invalid information. Unexpected null information.
;11 - Unexpected end of file.

CASE Arg OF 
   0 : Message = 'Invalid file header. ";" not found.'
   1 : Message = 'Invalid number of rois.'
   2 : Message = 'Invalid image dimensions.'
   3 : Message = 'Blank line not found.'
   4 : Message = 'Invalid roi name definition.'
   5 : Message = 'Invalid color definition.'
   6 : Message = 'Invalid definition of number of points.'
   7 : Message = 'Invalid sample list beginig.'
   8 : Message = 'Invalid sample location - lexicographic location is out the image bounds.'
   9 : Message = 'Invalid information. Unexpected read information.'
   10 : Message = 'Invalid information. Unexpected null information.'
   11 : Message = 'Unexpected end of file.'
ENDCASE

Result = DIALOG_MESSAGE( Message, /CENTER, /ERROR, TITLE = 'B.O.C.A' )

Close, Unit
FREE_LUN, Unit

Return, Arg
END




;+
; Write a ASCII/ROI file from a given Pointer ROI struct, the dimensions of the 
; related image and a file path to save the new ASCII/ROI file. 
; 
; @param PtrROI {in}{required}{type=pointer} Pointer ROI Struct.
; 
; @param PATH {in}{required}{type=pointer} file path to write the new ASCII/ROI file.
; 
; @param Dims {in}{required}{type=vector} dimensions of the image related to the Pointer ROI Struct.
;-
PRO ASCII_SAVE_ROI, PtrROI, PATH, Dims

GET_LUN, Unit
OpenW, Unit, PATH

PrintF, Unit, '; BOCA ROI file [' + SYSTIME() + ']'
PrintF, Unit, '; Number of ROIs: ' + STRTRIM(STRING(N_ELEMENTS(PtrROI)),1)
PrintF, Unit, '; File Dimension: ' + STRTRIM(STRING(Dims[1]),1) + ' x ' + STRTRIM(STRING(Dims[2]),1)

FOR i = 0, N_ELEMENTS(PtrROI)-1 DO BEGIN
   ROI = *PtrROI[i]
   PrintF, Unit, ';'
   PrintF, Unit, '; ROI name: ' + ROI.RoiName
   PrintF, Unit, '; ROI rgb value: {' + $
      STRTRIM(STRING(ROI.RoiColor[0]),1) + ', ' + $
      STRTRIM(STRING(ROI.RoiColor[1]),1) + ', ' + $
      STRTRIM(STRING(ROI.RoiColor[2]),1) + '}'      
   PrintF, Unit, '; ROI npts: ' + STRTRIM(STRING(N_ELEMENTS(ROI.RoiLex)),1)
ENDFOR

PrintF, Unit, '; Addr'
FOR i = 0L, N_ELEMENTS(PtrROI)-1 DO BEGIN
   ROI = *PtrROI[i]   
   FOR j = 0L, N_ELEMENTS(ROI.RoiLex)-1 DO PrintF, Unit, STRTRIM(STRING(ROI.RoiLex[j]),1) 
   IF (i NE N_ELEMENTS(PtrROI)-1) THEN PrintF, Unit, ''
ENDFOR

Close, Unit
END


;;;##################################################
;;Suposing that path_roi gives a valid roi file...
;;TODO: documentar
;FUNCTION GET_ASCII_ROI_SUPPORT, PATH_ROI
;   OpenR, Arq, PATH_ROI, /GET_LUN
;   FOR i = 0, 2 DO ReadF, Arq, Line
;   info = STRSPLIT(Line,' ',/EXTRACT)
;   Return, FIX([info[3],info[5]])
;END



;;##################################################
FUNCTION DECORRELATE_ROI_ASCII, PATH_ROI, Dims, Lags

MASK = INTARR(Dims[1],Dims[2])
FOR i = 0L, Dims[1]-1, Lags[0] DO BEGIN
   FOR j = 0L, Dims[2]-1, Lags[1] DO MASK[i,j] = 1
ENDFOR 

PtrROIs = ASCII_READ_ROI(PATH_ROI)
DecPtrROIs = PTRARR(N_ELEMENTS(PtrROIs))

FOR i = 0L, N_ELEMENTS(PtrROIs)-1 DO BEGIN
   Roi = *PtrROIs[i]
   DecLex = [-1]
   pos = 0L
   
   FOR j = 0L, N_ELEMENTS(Roi.RoiLex)-1 DO BEGIN
      pos = Roi.RoiLex[j]
      col = pos MOD Dims[1]
      lin = pos/Dims[1]
      IF MASK[col,lin] EQ 1 THEN DecLex = [DecLex,pos]
   ENDFOR
   
   RoiStruct = { RoiName: Roi.RoiName, RoiColor: Roi.RoiColor, RoiLex: DecLex[1:*]}
   DecPtrROIs[i] = PTR_NEW(RoiStruct)
ENDFOR

Return, DecPtrROIs
END




;;##################################################
;TODO: Incluir documentação desta função...
FUNCTION DECORRELATE_SINGLE_ROI, Roi, Dims, Lags

MASK = INTARR(Dims[0],Dims[1])
FOR i = 0, Dims[0]-1, Lags[0] DO $
   FOR j = 0, Dims[1]-1, Lags[1] DO MASK[i,j] = 1

DecLex = Roi.RoiLex*0L
pos = 0L
count = 0L
FOR j = 0L, N_ELEMENTS(Roi.RoiLex)-1 DO BEGIN
   pos = Roi.RoiLex[j]
   col = pos MOD Dims[0]
   lin = pos/Dims[0]
   IF MASK[col,lin] EQ 1 THEN BEGIN
      DecLex[count] = pos
      count++
   ENDIF
ENDFOR

IF ~count THEN Return, { RoiName: Roi.RoiName, RoiColor: Roi.RoiColor, RoiLex: -1} $
          ELSE Return, { RoiName: Roi.RoiName, RoiColor: Roi.RoiColor, RoiLex: DecLex[0:count-1]}
END


;##################################################
;TODO: incluir documentação...
FUNCTION CLONE_ROIS, PtrROIs
   clone = PTRARR(N_ELEMENTS(PtrROis))
   FOR i = 0L, N_ELEMENTS(PtrROIs)-1 DO clone[i] = PTR_NEW(*PtrROIs[i])
Return, clone
END

;##################################################
;TODO: incluir documentação...
FUNCTION CLONE_SINGLE_ROI, ROI
   temp = *ROI[0]
   Return, PTR_NEW({RoiName: temp.RoiName, RoiColor: temp.RoiColor, RoiLex: temp.RoiLex})
END
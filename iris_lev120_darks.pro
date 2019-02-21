function IRIS_LEV120_darks, image_lev1, header
;gfunction IRIS_LEV120, image_lev1, header

;+
;
; Given a lev1 image and header, returns a lev0 image (no lev0 header, because
; for most things the lev1 header is sufficient)
;
;-

imsize = SIZE(image_lev1)

; If called on a 3D input, just call itself recursively 
if imsize[0] eq 3 then begin
	result = image_lev1
	for i = 0, imsize[3] - 1 do begin
		result[*,*,i] = IRIS_LEV120(image_lev1[*,*,i], header[i])
	endfor
	RETURN, result
endif

case header.img_path of
	'FUV'		:	def_flip = 1
	'NUV'		:	def_flip = 2
	'SJI_1330'	:	def_flip = 2
	'SJI_1400'	:	def_flip = 2
	'SJI_1600'	:	def_flip = 2
	'SJI_2796'	:	def_flip = 0
	'SJI_2832'	:	def_flip = 0
	'SJI_5000W'	:	def_flip = 0
	'NUV-SJI'	:	def_flip = 1 ; 0
	else		:	STOP, 'Bad img_path...'
endcase

flip_rotate_dir = [0, 7, 5, 2]	;	map win_flip keyword to IDL's ROTATE function
flipper = flip_rotate_dir[def_flip]
image_lev0 = ROTATE(image_lev1, flipper)

RETURN, image_lev0

end
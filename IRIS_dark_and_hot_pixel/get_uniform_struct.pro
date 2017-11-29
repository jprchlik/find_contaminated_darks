function get_uniform_struct, struct_in

;Some of the old level1 data has different keywords that don't play nice with the new data.
;To compensate, I just make a smaller structure with all of the relevant keywords that exist in both the old and new indexes. 
small_struct = create_struct('NAXIS1',0,'NAXIS2',0,'TELESCOP','','DATE_OBS','','INSTRUME','','IMG_PATH','','IMG_TYPE','','SUMSPTRL',0,'SUMSPAT',0,'INT_TIME',0L)
copy_struct, struct_in, small_struct
return, small_struct
end
pro string_to_time,timest,timejd,normal=normal


;timest is the input time string
;timejd is the output JULDAY time
;normal is the day normalization of the output JULDAY

if keyword_set(normal) then normal=normal else normal=JULDAY(1,1,2012,0,0,0)


timejd = dblarr(n_elements(timest))

for i=0,n_elements(timest)-1 do begin
    year  = fix(strmid(timest[i],0,4))
    month = fix(strmid(timest[i],5,2))
    day   = fix(strmid(timest[i],8,2))
    hour  = fix(strmid(timest[i],11,2))
    min   = fix(strmid(timest[i],14,2))
    sec   = fix(strmid(timest[i],17,2))
    if year gt 0 then $
        timejd[i] = JULDAY(month,day,year,hour,min,sec)-normal
        
endfor

end

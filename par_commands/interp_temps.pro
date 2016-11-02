pro interp_temps,time_obs,temp_obs,time_tab,temp_tab,phase_lag=phase_lag
;interp_temps 
;time obs anytim formated string
;temp_obs output interpolated temperature
;time_tab times of observed temperature values
;temp_tab observed temperature values
;phase_lag empirically derived phase lag in minutes

if keyword_set(phase_lag) then phase_lag=phase_lag*60. else phase_lag = 8.*60.

atime_obs = anytim(time_obs)
atime_tab = anytim(time_tab)


temp_obs = interpol(temp_tab,atime_tab+phase_lag,atime_obs)




end 

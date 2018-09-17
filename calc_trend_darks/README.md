calc_dark_trend directory contains idl programs for comparing the current long term dark trend in the pedestal level with the predicted long term dark trend.

The main program in this directory is dark_trend.pro.
dark_trend.pro calculates the average value in a given month for all SAA free darks (it reads files in ../txtout/*txt). 
*Therefore, before you run dark_trend.pro for a given month you must run find_con_darks.pro in the parent directory.
You must also download the temperature data for day of and prior to the observation
(only really need the day before if observations is near midnight, which seems to happen a lot).
The temperature day can be automatically downloaded by running the python script get_list_of_days (located in ../temps).
The official documentation for the programs is in the README up one directory.


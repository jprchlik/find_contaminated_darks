fit_ports_gui.py
================
A python GUI for fitting the long term pedestal trend of the IRIS CCDs. 
The program uses the sav file created by the main IDL program, 
so no additional file formatting required. 

The python GUI imports the following modules. I also included the version my code works with the modules
in case any future issues arise.

    a. matplotlib 2.0.0
    b. numpy 1.11.3
    c. Tkinter Revision: 81008
    d. scipy 1.0.0


To run the program type the following command in a terminal window:  
> python fit_ports_gui.py  


After typing the command you will be greeted with a GUI containing two plots.
The left and right plots contain the FUV and NUV, respectively, difference between the model pedestal and the measured dark
pedestal as a function of time. Both the FUV and NUV CCDs contain four ports for rapid read out of the CCD
 (port 1 = red circle, port 2 = blue square, port 3 = teal diamond, and port 4 = black triangle).
The plot also contains a model for the pedestal's evolution with the color corresponding to the port number. 
The model pedestal parameters' for CCD type and port are below their respective plots in the med row. Above and below 
the med row for each parameter is the maximum and minimum range to search for new parameters. 
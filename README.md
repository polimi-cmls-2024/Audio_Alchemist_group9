# Audio_Alchemist_group9

Music Instrument Interface for guitarist : 

With this application you can play the sound you want with your guitar by connecting it to your computer and downloading all the files. 
It uses the Fast Fourier Transform to find the fundamental frequency and a GUI interface to use the differents effects for a guitar.
To use our app the steps are explained below. The sound of the "audio alchemist" is provided in the files, but feel free to change the parameters or the synthDef to find your own sound !


How to make our project work ?

- Step 1 : Connect the guitar to the computer and make sure the sound is coming from the audio interface
- Step 2 : Compile the JUCE files (available in the \Source folder) and see if the FFT is working and receiving the sound from the guitar
- Step 3 : Launch the processing file "bouncing_sqares.pde"
- Step 4 : Launch the SuperCollider final file, compile everything from the top to the bottom.

Now you can either choose the parameters of the effects with the GUI or let them change randomly with the interaction of the bouncing squares.
If it's easier for you to choose the parameters close the window of processing. Otherwise if you want to challenge yourself and your creativity you can let it on !

Project by : Djavan Borius, Dario Sorce, Salvatore Pantusa, Gianmarco Parente and Julien Boidevaix

P.S : The video is composed of 2 parts. The first part is related to show the effects developped. The second is to show the all music instrument interface.
Some issues occured during the second part's recording. The Video recorder software has a high CPU usage so has the FFT program in JUCE. It resulted in the FFT couldn't send notes anymore. We recorded the sound after and superposed it to the video to get a better sounding result for the viewers.



#pragma once

//==========================Initialization====================================================

class AnalyserComponent   : public juce::AudioAppComponent,
                            private juce::Timer
{
public:
    AnalyserComponent()
        : forwardFFT (fftOrder),        //Here we initialize our FFT object and the windowing function (with a Hanning window)
          window (fftSize, juce::dsp::WindowingFunction<float>::hann)
    {
        setOpaque (true);
        setAudioChannels (2, 0);        // we want a couple of input channels but no outputs
        startTimerHz (40);
        setSize (700, 500);             // Size of the Window to display the spectrum 
    }

    ~AnalyserComponent() override
    {
        shutdownAudio();
    }

    //==========================Collect the samples from the audio buffer====================================================
    void prepareToPlay (int, double) override {}
    void releaseResources() override          {}

//! [getNextAudioBlock] This function collects the samples in the current audio Buffer and sends it to the FIFO block
// and waits to be analysed later
    void getNextAudioBlock (const juce::AudioSourceChannelInfo& bufferToFill) override
    {
        if (bufferToFill.buffer->getNumChannels() > 0)
        {
            auto* channelData = bufferToFill.buffer->getReadPointer (0, bufferToFill.startSample);

            for (auto i = 0; i < bufferToFill.numSamples; ++i)
                pushNextSampleIntoFifo (channelData[i]);
        }
    }


    //==========================Play and send the DATA collected to the FFT====================================================
    
//! [pushNextSampleIntoFifo]
    void pushNextSampleIntoFifo (float sample) noexcept
    {
        if (fifoIndex == fftSize)               //We look in the FIFO, if it contains all the necessary data fft,
                                                // then the next frame can be now rendered
        
        {
            if (! nextFFTBlockReady)            //If the block is not ready we increment the sample number and... 
            {
                juce::zeromem (fftData, sizeof (fftData));
                memcpy (fftData, fifo, sizeof (fifo));
                nextFFTBlockReady = true;
            }

            fifoIndex = 0;
        }

        fifo[fifoIndex++] = sample;             // ... We put information in the FIFO here
    }
    
    //=============================FFT and Drawing Process================================================

//! [drawNextFrameOfSpectrum]
    void drawNextFrameOfSpectrum()
    {
        window.multiplyWithWindowingTable (fftData, fftSize);       // Windowing of our signal data

        forwardFFT.performFrequencyOnlyForwardTransform (fftData);  // Perform the FFT
        
        for (int i =0; i< fftSize/2; ++i)
        {
            magnitude[i] = std::abs(fftData[i]);                    // Spectrum is an imaginary number so we convert the fftData with std::abs
        }
        
        auto mindB = -100.0f;
        auto maxdB =    0.0f;

        for (int i = 0; i < N; ++i)                                 // We loop over the scope to draw it 
                                                                    // In order for it to be understandable we need to do a log scale and
                                                                    // transform it in decibels
        {
            auto skewedProportionX = 1.0f - std::exp (std::log (1.0f - (float) i / (float) N) * 0.2f);
            auto fftDataIndex = juce::jlimit (0, fftSize / 2, (int) (skewedProportionX * (float) fftSize * 0.5f));
            auto level = juce::jmap (juce::jlimit (mindB, maxdB, juce::Decibels::gainToDecibels (fftData[fftDataIndex])
                                                               - juce::Decibels::gainToDecibels ((float) fftSize)),
                                     mindB, maxdB, 0.0f, 1.0f);

            scopeData[i] = level;                                   // the data with the correct amplitude is collected here
        }
    }

//! [drawFrame]  This function is called by the paint over and over and it allows to refresh and draw the spectrum from scopeData
    void drawFrame (juce::Graphics& g)
    {
        
        for (int i = 1; i < N; ++i)
        {
            auto width  = getLocalBounds().getWidth();
            auto height = getLocalBounds().getHeight();

            g.drawLine ({ (float) juce::jmap (i - 1, 0, N - 1, 0, width),
                                  juce::jmap (scopeData[i - 1], 0.0f, 1.0f, (float) height, 0.0f),
                          (float) juce::jmap (i,     0, N - 1, 0, width),
                                  juce::jmap (scopeData[i],     0.0f, 1.0f, (float) height, 0.0f) });
        }
    }

    //========================Finding the fundamental frequency and the Velocity===================================

    //! [findfundamental] This function goes over the frequencies to find the fundamental one
    void findfundamental()
    {   
        float maxValue = juce::findMaximum(magnitude,4096);
        int maxIndex = 0;
        
        for (int i = 0; i < N; ++i)
        {   
            if (magnitude[i] == maxValue)
                {
                    maxIndex = i;
                    break;
                }
        }
        f_0 = maxIndex;
    }
    
    //================================Paint function============================================
    
    void paint (juce::Graphics& g) override
    {
        g.fillAll (juce::Colours::black);

        g.setOpacity (1.0f);
        g.setColour (juce::Colours::white);
        drawFrame (g);
        
      
                                                    
        findfundamental();                                      //find the fundamental frequency
        float maxValue = juce::findMaximum(fftData,2*4096);     //find the amplitude
            
        juce::String intAsString = juce::String(f_0*df);
        
        g.drawText ("freq is : " +intAsString, getLocalBounds(), juce::Justification::centred, true); //print the fundamental frequency in the windaw
        
    
        ds.bindToPort(57120);
        sender.connectToSocket(ds,"127.0.0.1", 57120);        
        sender.send("/JUCE/receiver", f_0*df, maxValue); //send the fundamental frequency and the amplitude to SC
        
        }

//! [timerCallback]
    void timerCallback() override
    {
        
        if (nextFFTBlockReady)
        {
            drawNextFrameOfSpectrum();
            nextFFTBlockReady = false;
            repaint();
        }
    }


    enum
    {
        fftOrder  = 12,              
        fftSize   = 1 << fftOrder,                  // Size of the fft Window calculated as 2^12
        N = 4096,                                   // Number of point in Magnitude vector after the fft is calculated
    };

private:
    juce::dsp::FFT forwardFFT;                      //Declaration of the object to perform the forward FFT
    juce::dsp::WindowingFunction<float> window;     //Same but to apply a window on the signal we receive

    float fifo [fftSize];                           // Contains the incoming audio DATA
    float fftData [2 * fftSize];                    // Results of the FFT calculations
    int fifoIndex = 0;                              // Temporary index that keeps count of the amount of samples in the fifo
    bool nextFFTBlockReady = false;                 // Temporary boolean in order to know if we can perform the next FFT or not
    float magnitude [N];                            // Contains the Magnitude of our data (Can be interpreted as the velocity of the guitar)
    float scopeData [N];                            // Contains the information to display the spectrum in real Time
    
    float df = 48000/fftSize;                       // Frequency resolution = Sampling_Frequency / fftSize 
    float f_0;                                      // We collect the fundamental frequency
    
    juce::OSCSender sender;                         //Declaration of the OSC sender
    juce::DatagramSocket ds;
   
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (AnalyserComponent)
};


/*
  ==============================================================================

    This file contains the startup code for a PIP.

  ==============================================================================
*/

#include <JuceHeader.h>
#include "MainComponent.h"

class Application  : public juce::JUCEApplication
{
public:
    //==============================================================================
    Application() = default;

    const juce::String getApplicationName() override       { return "Spectrum"; }
    const juce::String getApplicationVersion() override    { return "2.0.0"; }

    void initialise (const juce::String&) override
    {
        mainWindow.reset (new MainWindow ("Spectrum", new AnalyserComponent, *this));
    }
    
    
    void shutdown() override                         { mainWindow = nullptr; }

private:
   

    class MainWindow    : public juce::DocumentWindow
    {
    public:
        MainWindow (const juce::String& name, juce::Component* c, JUCEApplication& a)
            : DocumentWindow (name, juce::Desktop::getInstance().getDefaultLookAndFeel()
                                                                .findColour (ResizableWindow::backgroundColourId),
                              juce::DocumentWindow::allButtons),
              app (a)
              
        {
            
           
            setUsingNativeTitleBar (true);
            setContentOwned (c, true);

           #if JUCE_ANDROID || JUCE_IOS
            setFullScreen (true);
           #else
            setResizable (true, false);
            setResizeLimits (300, 250, 10000, 10000);
            centreWithSize (getWidth(), getHeight());
           #endif           
            ds.bindToPort(57120);
            sender.connectToSocket(ds,"127.0.0.1", 57120);        
 
            setVisible (true);
        }

        void closeButtonPressed() override
        {
            app.systemRequestedQuit();
        }

    private:
        JUCEApplication& app;
        juce::OSCSender sender;
        juce::DatagramSocket ds;
   
        
        //==============================================================================
        JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (MainWindow)
    };

    std::unique_ptr<MainWindow> mainWindow;
};

//==============================================================================
START_JUCE_APPLICATION (Application)

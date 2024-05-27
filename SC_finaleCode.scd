(
s.options.numOutputBusChannels = 2;
s.options.numInputBusChannels = 1;

s.options.inDevice_("Scarlett 2i2 USB");
s.options.outDevice_("Scarlett 2i2 USB");
s.boot;

s.meter;
)

s.scope;
s.plotTree;
Server.killAll;

//Create groups
(
~g0 = Group.new(s);
~g1 = Group.after(~g0);
~g2 = Group.after(~g1);
~g3 = Group.after(~g2);
~g4 = Group.after(~g3);
~g5 = Group.after(~g4);
)
//Audio busses
(
~b0 = Bus.audio(s, 2);
~b1 = Bus.audio(s, 2);
~b2 = Bus.audio(s, 2);
~b3 = Bus.audio(s, 2);
~b4 = Bus.audio(s, 2);
~bscope = Bus.audio(s, 2);
)


(
///////////////////////////////////

SynthDef (\source, {
	arg micguitar=0, obs;
	var sound;
	sound = In. ar (micguitar);
	//Poll.kr(Impulse.kr(1), sound, "source: ");
	Out. ar (obs, sound) ;
}).add;
~sourceSynth = Synth(\source, [\obs, ~b0], ~g0);



///////////////////////////////////

/////////////////-----REVERB-----/////////////////


SynthDef(\Reverb, {
    arg ibs=0, obs=0, amp=0, atk=0.02, rel=0.1, crv= -2, gate=1, predelay=0.08, decay=0, damp=0;
	var source, sig, env, comb1, comb2, allpass1, allpass2, allpass3, allpass4;

	env = EnvGen.ar(Env.asr(atk, 1, rel, crv), gate);
	source = In.ar(ibs);
	//Poll.kr(Impulse.kr(1), source, "reverb in: ");

    // Comb Filters
	comb1 = CombC.ar(source, 0.35, predelay, 0 - (decay));
    comb2 = CombC.ar(source, 0.41, predelay, decay);

    // Allpass Filters
    allpass1 = AllpassC.ar(comb1, 0.05, 0.05, 2);
    allpass2 = AllpassC.ar(comb2, 0.047, 0.047, 2);
    allpass3 = AllpassC.ar(allpass1, 0.029, 0.029, 2);
    allpass4 = AllpassC.ar(allpass2, 0.031, 0.031, 2);

    // Mix
    sig = (allpass3 + allpass4) * damp;
    sig = sig*amp*env;
	//Poll.kr(Impulse.kr(1), sig, "reverb out: ");
    Out.ar(obs, sig);
}).add;
~fx1Synth = Synth(\Reverb, [\ibs, ~b0, \obs, ~b1], ~g1);



////////////////-----CHORUS-----/////////////////


SynthDef(\Chorus, {
    arg ibs=0, obs=0, amp=0, rate=0, depth=0.001, blend=0, mode=1, atk=0.02, rel=0.1, crv= -2, gate=1;
	var source, lfo, delay1, delay2, mixed, sig, env;

	env = EnvGen.ar(Env.asr(atk, 1, rel, crv), gate);
    source= In.ar(ibs);
	//Poll.kr(Impulse.kr(1), source, "chorus in: ");
    lfo = SinOsc.ar(rate.reciprocal, 0, depth);

    // Left and right delay with interpolation
    delay1 = DelayC.ar(source, 0.0065, 0.0065 + (lfo * 0.0025).clip(0, 0.005));
    delay2 = DelayC.ar(source, 0.0085, 0.0085 + (lfo * 0.0025).clip(0, 0.005));

    // Mixing the original signal with the delayed and modulated signal
    mixed = (source * (1 - blend)) + ((delay1 + delay2) * blend);

    // vintage oR modern modulation
    mixed = Select.ar(mode, [BPF.ar(mixed, 600, 0.1), AllpassC.ar(mixed, 0.02, 0.02, 2)]);

    sig = mixed * amp * env;
	//Poll.kr(Impulse.kr(1), sig, "chorus out: ");
    Out.ar(obs, sig);
}).add;
~fx2Synth = Synth(\Chorus, [\ibs, ~b0, \obs, ~b1], ~g2);



/////////////////-----SPACE_ECHO-----/////////////////


SynthDef(\SpaceEcho, {
    arg ibs=0, obs=0, amp=0, atk=0.02, rel=0.1, crv= -2, gate=1, echo=0, repeatRate=0;
    var source, echosig, sig, env;

	env = EnvGen.ar(Env.asr(atk, 1, rel, crv), gate);
    source = In.ar(ibs);
	//Poll.kr(Impulse.kr(1), source, "echo in: ");
    // echo effect
    echosig = CombN.ar(source, 0.1, 0.1, echo.linlin(0, 1, 0.1, 2), repeatRate.linlin(0, 1, 0.1, 2));

    //mix
    sig = source + echosig;
	sig = sig * amp * env;
	//Poll.kr(Impulse.kr(1), sig, "echo out: ");
	Out.ar(obs, sig);
}).add;
~fx3Synth = Synth(\SpaceEcho, [\ibs, ~b0, \obs, ~b1], ~g3);


/////////////////-----DISTORSION-----/////////////////


SynthDef(\Distortion, {
    arg ibs=0, obs=0, drive=0, tone=0, amp=0 , atk=0.02, rel=0.1, crv= -2, gate=1;
    var source, distorted, filtered, sig, env;

	env = EnvGen.ar(Env.asr(atk, 1, rel, crv), gate);
	source = In.ar(ibs);
	//Poll.kr(Impulse.kr(1), source, "distortion in: ");
    source = HPF.ar(source, 720);

    // waveshaping
    distorted = source * drive;
    distorted = distorted.clip(-1.0, 1.0);
    distorted = (3 * distorted) / (1 + distorted.abs);

    // controlling tone
    filtered = LPF.ar(distorted, tone.linexp(0, 1, 500, 5000));

    // output lovel
    sig = filtered * amp* env;
	//Poll.kr(Impulse.kr(1), sig, "distortion out: ");
    Out.ar(obs, sig);
}).add;
~fx4Synth = Synth(\Distortion, [\ibs, ~b0, \obs, ~b1], ~g4);



///////////////////////////////////


SynthDef(\out, {
	arg ibs, thresh=0.8;
    var sound;
    sound = In.ar(ibs);
	//Poll.kr(Impulse.kr(1), sound, "output: ");
	sound = Compander.ar(sound, sound, thresh, 1.0, 1.0, 0.01, 0.1, 1.0, 0.0);
	Out.ar([0, 1], sound);
	Out.ar(~bscope, sound);
}).add;
~outputSynth = Synth(\out, [\ibs, ~b1], ~g5);

///////////////////////////////////
)

/////////////////////////////////////////--GUI--/////////////////////////////////////////


(
w = Window("EFFECTS", Rect(650, 250, 560, 500))
.background_(Color(0.8, 0.8, 0.8))
.front
.alwaysOnTop_(true);

// Helper function to center controls
~centerText = { |parent, rect, text|
    StaticText(parent, rect)
    .string_(text)
    .align_(\center);
};

// Helper function to create section titles
~sectionTitle = { |parent, rect, text, backgroundColor|
    StaticText(parent, rect)
    .string_(text)
    .font_(Font("Arial", 12).bold_(true))
    .align_(\center)
    .background_(backgroundColor);
};


// Reverb Section
~reverbColor = Color(204/255, 255/255, 0/255);
~sectionTitle.(w, Rect(20, 10, 100, 20), "Reverb", ~reverbColor);

// Reverb Predelay Knob
~reverbPredelayTime = Knob(w, Rect(45, 50, 50, 50))
.background_(~reverbColor)
.action_({ arg obj;
    var cf;
    cf = obj.value.linlin(0, 1, 0.08, 0.3); // Convert knob value to desired range
    ("Reverb Predelay Time: " + cf).postln;
    if(~fx1Synth.notNil) { ~fx1Synth.set(\predelay, cf) };
});

~centerText.(w, Rect(40, 100, 60, 20), "predelay");

// Reverb Decay Time Knob
~reverbDecayTime = Knob(w, Rect(45, 130, 50, 50))
.background_(~reverbColor)
.action_({ arg obj;
    var cf;
    cf = obj.value.linlin(0, 1, 0.3, 10); // Convert knob value to desired range
    ("Reverb DecayTime: " + cf).postln;
    if(~fx1Synth.notNil) { ~fx1Synth.set(\decay, cf) };
});

~centerText.(w, Rect(40, 180, 60, 20), "decay");

// Reverb Damp Knob
~reverbDamp = Knob(w, Rect(45, 210, 50, 50))
.background_(~reverbColor)
.action_({ arg obj;
    var cf;
    cf = obj.value.linlin(0, 1, 0, 1); // Convert knob value to desired range
    ("Reverb Damp: " + cf).postln;
    if(~fx1Synth.notNil) { ~fx1Synth.set(\damp, cf) };
});

~centerText.(w, Rect(40, 260, 60, 20), "damp");

// Reverb Amp Slider
~reverbLevel = Slider(w, Rect(55, 290, 30, 150))
.background_(~reverbColor)
.action_({ arg obj;
    var cf;
    cf = obj.value.linlin(0, 1, 0.0001, 1); // Convert slider value to desired range
    ("Reverb Level: " + cf).postln;
    if(~fx1Synth.notNil) { ~fx1Synth.set(\amp, cf) };
});

~centerText.(w, Rect(50, 440, 40, 20), "mix");



// Divider Line
UserView(w, Rect(140, 20, 1, 460))
.drawFunc_({ |view|
    Pen.use {
        Pen.width = 1;
        Pen.strokeColor = Color.black;
        Pen.line(0 @ 0, 0 @ view.bounds.height);
        Pen.stroke;
    };
});

// Chorus Section
~chorusColor = Color(172/255, 229/255, 238/255);
~sectionTitle.(w, Rect(300, 10, 100, 20), "Chorus", ~chorusColor);

~chorusDepth = Knob(w, Rect(325, 50, 50, 50))
.background_(~chorusColor)
.action_({ arg obj;
    var cf;
    cf = obj.value.linlin(0, 1, 0, 0.02); // Convert knob value to desired range
    ("Chorus Depth: " + cf).postln;
    if(~fx2Synth.notNil) { ~fx2Synth.set(\depth, cf) };
});

~centerText.(w, Rect(320, 100, 60, 20), "depth");

~chorusBlend = Knob(w, Rect(325, 130, 50, 50))
.background_(~chorusColor)
.action_({ arg obj;
    var cf;
    cf = obj.value.linlin(0, 1, 0, 1); // Convert knob value to desired range
    ("Chorus Blend: " + cf).postln;
    if(~fx2Synth.notNil) { ~fx2Synth.set(\blend, cf) };
});

~centerText.(w, Rect(320, 180, 60, 20), "blend");

~chorusRate = Knob(w, Rect(325, 210, 50, 50))
.background_(~chorusColor)
.action_({ arg obj;
    var cf;
    cf = obj.value.linlin(0, 1, 0.05, 10); // Convert knob value to desired range
    ("Chorus Rate: " + cf).postln;
    if(~fx2Synth.notNil) { ~fx2Synth.set(\rate, cf) };
});

~centerText.(w, Rect(320, 260, 60, 20), "rate");

~chorusLevel = Slider(w, Rect(335, 290, 30, 150))
.background_(~chorusColor)
.action_({ arg obj;
    var cf;
    cf = obj.value.linlin(0, 1, 0.0001, 1); // Convert slider value to desired range
    ("Chorus Level: " + cf).postln;
    if(~fx2Synth.notNil) { ~fx2Synth.set(\amp, cf) };
});

~centerText.(w, Rect(330, 440, 40, 20), "mix");



// Divider Line
UserView(w, Rect(420, 20, 1, 460))
.drawFunc_({ |view|
    Pen.use {
        Pen.width = 1;
        Pen.strokeColor = Color.black;
        Pen.line(0 @ 0, 0 @ view.bounds.height);
        Pen.stroke;
    };
});

// SpaceEcho Section
~spaceechoColor = Color(255/255, 153/255, 102/255);
~sectionTitle.(w, Rect(160, 10, 100, 20), "SpaceEcho", ~spaceechoColor);

~echo = Knob(w, Rect(185, 80, 50, 50))
.background_(~spaceechoColor)
.action_({ arg obj;
    var cf;
    cf = obj.value.linlin(0, 1, 0.1, 2); // Convert knob value to desired range
    ("Echo: " + cf).postln;
    if(~fx3Synth.notNil) { ~fx3Synth.set(\echo, cf) };
});

~centerText.(w, Rect(180, 130, 60, 20), "echo");

~rate = Knob(w, Rect(185, 180, 50, 50))
.background_(~spaceechoColor)
.action_({ arg obj;
    var cf;
    cf = obj.value.linlin(0, 1, 0.1, 5); // Convert knob value to desired range
    ("Rate: " + cf).postln;
    if(~fx3Synth.notNil) { ~fx3Synth.set(\repeatRate, cf) };
});

~centerText.(w, Rect(180, 230, 60, 20), "rate");

~echoLevel = Slider(w, Rect(195, 290, 30, 150))
.background_(~spaceechoColor)
.action_({ arg obj;
    var cf;
    cf = obj.value.linlin(0, 1, 0.0001, 1); // Convert slider value to desired range
    ("Echo Level: " + cf).postln;
    if(~fx3Synth.notNil) { ~fx3Synth.set(\amp, cf) };
});
~centerText.(w, Rect(190, 440, 40, 20), "mix");


// Divider Line
UserView(w, Rect(280, 20, 1, 460))
.drawFunc_({ |view|
    Pen.use {
        Pen.width = 1;
        Pen.strokeColor = Color.black;
        Pen.line(0 @ 0, 0 @ view.bounds.height);
        Pen.stroke;
    };
});



// Distorsion Section
~distortionColor = Color(204/255, 102/255, 102/255);
~sectionTitle.(w, Rect(440, 10, 100, 20), "Distorsion", ~distortionColor);

~distorsionDrive = Knob(w, Rect(465, 80, 50, 50))
.background_(~distortionColor)
.action_({ arg obj;
    var cf;
    cf = obj.value.linlin(0, 1, 0, 5); // Convert knob value to desired range
    ("Distorsion PreDelay: " + cf).postln;
    if(~fx4Synth.notNil) { ~fx4Synth.set(\drive, cf) };
});

~centerText.(w, Rect(460, 130, 60, 20), "drive");

~distorsionTone = Knob(w, Rect(465, 180, 50, 50))
.background_(~distortionColor)
.action_({ arg obj;
    var cf;
    cf = obj.value.linlin(0, 1, 0, 5); // Convert knob value to desired range
    ("Distorsion Damp: " + cf).postln;
    if(~fx4Synth.notNil) { ~fx4Synth.set(\tone, cf) };
});

~centerText.(w, Rect(460, 230, 60, 20), "tone");

~distorsionLevel = Slider(w, Rect(475, 290, 30, 150))
.background_(~distortionColor)
.action_({ arg obj;
    var cf;
    cf = obj.value.linlin(0, 1, 0.0001, 0.80); // Convert slider value to desired range
    ("Distorsion Level: " + cf).postln;
    if(~fx4Synth.notNil) { ~fx4Synth.set(\amp, cf) };
});
~centerText.(w, Rect(470, 440, 40, 20), "mix");


w.onClose = {
    if(~fx1Synth.notNil) { ~fx1Synth.free };
	if(~fx2Synth.notNil) { ~fx2Synth.free };
	if(~fx3Synth.notNil) { ~fx3Synth.free };
	if(~fx4Synth.notNil) { ~fx4Synth.free };
    if(~outputSynth.notNil) { ~outputSynth.free };
	if(~scope.notNil) { ~scope.free };

    w = nil;
};

w.front;
)
(
OSCdef(\receiveEffectChanges, { |msg|
  var effectIndex, param, value;

  effectIndex = msg[1].asInteger;
  param = msg[2].asSymbol;
  value = msg[3].asFloat;

  // Log the received message
  ("Received OSC message: " + msg).postln;

  // Seleziona il Synth corrispondente all'indice dell'effetto
  case
  { effectIndex == 0 } { ~fx1Synth.set(param, value) }
  { effectIndex == 1 } { ~fx2Synth.set(param, value) }
  { effectIndex == 2 } { ~fx3Synth.set(param, value) }
  { effectIndex == 3 } { ~fx4Synth.set(param, value) }
  { true } { "Unknown effect index".postln }
}, '/effectChange').add;
)



//////////////////////// The sound of Audio Alchemist
(
SynthDef("alchemist", {
	arg
	// Standard Values
	out = 0, pan = 0, amp = 1.0, freq = 440, vel = 0.5,
	// Others
	freqDev = 2+freq/25, op1mul = 0.1, op2mul = 0.1, sprd = 0.5, subAmp = 0.2;

	var env, osc1, osc2, osc3, osc4, osclow, snd1, snd2, snd, sub, knock;

	// percussiv envelop for the main sound
	env = Env.perc(Rand(0,0.1),vel).ar;

	// Overtones we can add more if we want
	osc1 = SinOsc.ar(freq: freq * 4, mul: vel/2 + op1mul);
	osc2 = SinOsc.ar(freq: freq * 2, phase: osc1, mul: vel/2 + op2mul);

	// Fundamental Frequency
	osc3 = SinOsc.ar(freq: freq, phase: osc1, mul: vel);
	osc4 = SinOsc.ar(freq: freq + Rand(-1 * freqDev, freqDev), phase: osc2, mul: vel);

	snd = osc3 + osc4;

	// High Pass Filter
	snd = LeakDC.ar(snd);

	// knock in the beginning for a tapping sound
	knock = PinkNoise.ar;
	knock = BPF.ar(knock, freq, 0.3) *30.dbamp;
	knock = knock * Env.perc(0.001, 0.05).ar;

	// Add a sub
	sub = SinOsc.ar(freq: freq/2, mul: env * subAmp);
	sub = Pan2.ar(sub, pan);
	sub = sub * (1+Env.perc(0.01,0.1).ar);
	sub = sub* -6.dbamp;
	snd = snd + sub + knock;

	//Ouput
	snd = snd * env;
	snd = snd* -9.dbamp;
	snd = snd * amp;
	snd = snd + CombC.ar(LPF.ar(snd* -10.dbamp, 2500), 0.2, 1/95, 0.4);
	snd = snd + CombC.ar(LPF.ar(snd* -10.dbamp, 2500), 0.2, 1/35, 0.4);
	Out.ar(out, snd);
},
).add;
)

x = Synth(\alchemist,[\freq,200,\vel,2]);
x.free
/////////////////-----Initialization of parameters-----/////////////////

// Receiver of the JUCE notes and amplitude
(
OSCdef('OSCreceiver',
	{
		arg msg;

		var freq = msg[1]; // frequency to play
		var play = msg[2]; // amplitude

		if(play>5, //check if the amplitude is enough
			{postln("freq: "+freq+" - volume: "+play);
				x.free;                                        // Stop the previous synth to free some buffer memory
				x = Synth(\alchemist,[\freq,freq, \vel, 0.5 + play/200, \amp,2]);    // play the new note
			},
			{postln("not played")});
	},
	'/JUCE/receiver');
)

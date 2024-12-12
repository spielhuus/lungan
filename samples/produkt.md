---
author: "spielhuus"
categories:
- module
date: 2021-07-28
excerpt: "Amplitude Modulation has its origin in electronic communication technology. It is used in radio transmission where an audio signal is modulated on a carrier signal. Amplitude Modulation is also used in synthesizers. When both signals in a VCA are in the audio range, the resulting audio signal has added timbre. Amplitude Modulation is also used in a Ring Modulator. Ring modulation adds frequencies to the audio signal which gives it a different characteristic. The resulting audio signal has some ‘metallic’ sound. The popular usage of Ring Modulation is the Dalek voice from the BBC series Doctor Who. Produkt is a voltage controlled amplifier (VCA). There are various designs to implement a VCA. rod elliott (ESP) has an article on VCA techniques [[1][1]]. diy synthesizer modules are usualy designed with an integrated VCA chip [[2][2]] or with a differential amplifier [[3][3]]. The integrated VCA chips are either obsolete or rather expensive. The differential amplifier can be built with transistors only. the design has some downsides. Even in the simulation the result is not symetryc and has a dc offset from the control voltage. This needs a lot of trimming to get an accurate result. but the biggest downside is, that this design can not do proper amplitude modulation (am). when the carrier signal goes below zero the base signal is completely muted."
subtitle: "produkt is a vca and ringmodulator"
tags:
- grundlage
title: produkt
version: 2
draft: False
history:
  - date: "2021-11-12"
    description: "Bipolar LED and redesign of PCB"
    revision: "2"
  - date: "2021-04-01"
    description: "initial commit of project"
    revision: "1"
references:
  - description: "VCA Techniques Investigated"
    title: "ESP"
    url: "https://sound-au.com/articles/vca-techniques.html"
  - description: "Keyiing and VCA citcuits for electronic music instruments."
    title: "Popular Electronics"
    url: "https://tinaja.com/glib/pop_elec/mus_keying_vca_1+2_75.pdf"
  - description: "Basics of the Gilbert Cell | Analog Multiplier | Mixer | Modulator"
    title: "w2aew"
    url: "https://www.youtube.com/watch?v=7nmmb0pqTU0&t=2s"
  - description: "AM & DSB-SC Modulation with the Gilbert Cell"
    title: "w2aew"
    url: "https://www.youtube.com/watch?v=38OQub2Vi2Q"
  - description: "Analog multiplier application guide "
    title: "Analog Devices"
    url: "https://www.analog.com/media/en/training-seminars/design-handbooks/ADI_Multiplier_Applications_Guide.pdf"
  - description: "Datasheet"
    title: "AD633"
    url: "https://www.analog.com/media/en/technical-documentation/data-sheets/AD633.pdf"
---

# amplitude modulation

"Amplitude Modulation (AM) is a fundamental technique used in both analog
and digital signal processing. It's characterized by a simple yet effective
method of encoding a message signal onto a carrier wave.

There are two primary applications of AM:

1. **Radio and Television Broadcasting**: AM is used to encode audio and video
signals onto high-frequency carrier waves, which are then transmitted to
receivers. This is how AM radio stations broadcast music and talk shows, and
how television signals are transmitted over the airwaves.
2. **Synthesizers**: AM is used in synthesizers to create dynamic and
interesting sounds. In this context, AM is employed for applications like
VCA (Voltage-Controlled Amplifier) modulation and ring modulation.

At its core, AM involves changing the **amplitude** (signal strength) of the
carrier wave in **proportion to the message signal**. This basic principle
makes AM a versatile and widely-used technique in many areas of
electronics."

$$
\begin{array}{c}
c(t) = A \sin(2 \pi f_c t)\,
\end{array}
$$

Where A is the amplitude of the carrier singal and the function of the
modulation signal. Amplitude Modulation is a multiplication of the two signals.

```{py echo=FALSE}
import numpy as np
import matplotlib.pyplot as plt
import scipy.fftpack
from scipy.fft import fft, fftfreq

f1 = 200
f2 = 40

N = 10000
# sample spacing
T = 1.0 / 20000.0
x = np.linspace(0.0, N*T, N, endpoint=False) #[:200]

y1 = np.sin(f1 * 2.0 * np.pi * x)
y2 = np.sin(f2 * 2.0 * np.pi * x)
y3 = np.sin(f1 * 2.0 * np.pi * x) * np.sin(f2 * 2.0 * np.pi * x)
y4 = np.sin(f1 * 2.0 * np.pi * x) * np.sin(f2 * 2.0 * np.pi * x) + np.sin(f1 * 2.0 * np.pi * x)

am = {}
am['x'] = x[0:600] * 1000
am['INPUT'] = y2[0:600]
am['DSBSC'] = y3[0:600]

y = y3
yf = fft(y)
yam = fft(y4)
xf = fftfreq(N, T)[:N//2]

am_bode = {}
am_bode['bx'] = xf[40:160]
am_bode['DSBSC'] = 2.0/N * np.abs(yf[40:160])
am_bode['AM'] = 2.0/N * np.abs(yam[40:160])
```

```{d3 element="am" x="x" y="INPUT,DSBSC" data="py$am" width="600" height="400" fig.align='center' fig.cap="Figure 1: Amplitude modulation"}```

```py
import matplotlib.pyplot as plt 
import matplotlib
matplotlib.use('module://lungan')
 
# Ensure your lists have the same length 
assert len(am['x']) == len(am['INPUT']) == len(am['DSBSC']) 
 
# Create the plot 
plt.plot(am['x'], am['INPUT'], label='INPUT') 
plt.plot(am['x'], am['DSBSC'], label='DSBSC') 
 
# Set title and labels 
plt.title('DSBSC vs INPUT') 
plt.xlabel('Time (ms)') 
plt.ylabel('Amplitude') 
 
# Add legend 
plt.legend() 
 
# Show the plot 
plt.show() 

```


Here the carrier frequency is 200Hz and the modulation frequency is 40Hz. The carrier frequency is modulated by the modulation frequency. When the modulation signal is negative the resulting signal has a phase shift of 180°. The frequency analysis shows that the two sidebands are created at 160Hz and 240Hz. The modulation frequency is added and subtracted from the base frequency. This is called a double-sideband with suppressed carrier (DSBSC).

```{d3 element="am_bode" x="bx" y="AM,DSBSC" data="py$am_bode" width="600" height="400" fig.align='center' fig.cap="Figure 2: Frequency analysis" xType="scaleLinear"}```

When the carrier frequency is added to the result, we see two things. First, the final signal is not phase-shifted when the base signal is negative. Second, the carrier signal is part of the final signal. This is basic amplitude modulation. but notice that the output amplitude is twice the input.

# Long tailed pair

The long-tailed pair or differential amplifier is probably the most widely used circuit building block. For example, the long-tailed pair is the base for op-amps. Also in synthesizer circuits, we see the long-tailed pair a lot for converting CV signals into current. This circuit can be implemented with BJTs or MOSFETs. The differential pair multiplies the voltage difference between the two inputs with the differential gain. The differential gain can be configured with the current in the long tail. The output can be taken either from one side or the difference from both sides.


```{python echo=FALSE output="hide" fig.align="center" fig.cap="Figure 3: Long tailed pair"}
from IPython.display import SVG, display
import recad
import lungan
lungan.set_plot(0, 0, [])
import matplotlib
matplotlib.use('module://lungan')

hema = recad.Schema("")
schema.move_to((50.8, 50.8))
schema = (schema
    + recad.LocalLabel("X").rotate(180) 
)
schema.plot(scale=10)
print(plot)
```



# draw = (Draw(["/usr/share/kicad/symbols"])
#   + Label("X").rotate(180)
#   + Element("Q1", "Transistor_BJT:BC547", unit=1, value="BC547",
#                  Spice_Netlist_Enabled="Y",
#                  Spice_Primitive="Q",
#                  Spice_Model="BC547B").anchor(2)
#
#   + Line().at("Q1", "1").up().length(5.08)
#   + (dot_out_a := Dot())
#   + Line().up().length(5.08)
#   + Element("R1", "Device:R", unit=1, value="15k").rotate(180)
#   + Line().up().length(5.08)
#   + Element("+15V", "power:+15V", value="+15V")
#
#   + Line().at("Q1", "3").down().length(5.08)
#   + Line().right().length(10.16)
#   + (dot1 := Dot())
#   + Line().right().length(10.16)
#   + Line().up().length(5.08)
#   + Element("Q2", "Transistor_BJT:BC547", unit=1, value="BC547",
#                  Spice_Netlist_Enabled="Y",
#                  Spice_Primitive="Q",
#                  Spice_Model="BC547B").anchor(3).mirror('x').rotate(180)
#
#   + Line().at("Q2", "1").up().length(5.08)
#   + (dot_out_b := Dot())
#   + Line().up().length(5.08)
#   + Element("R2", "Device:R", unit=1, value="15k").rotate(180)
#   + Line().up().length(5.08)
#   + Element("+15V", "power:+15V", value="+15V")
#
#   + Element("GND", "power:GND", value="GND").at("Q2", "2")
#
#   + Element("R3", "Device:R", unit=1, value="33k").at(dot1)
#   + Line().down().length(2.54)
#   + (dot2 := Dot())
#   + Line().down().length(2.54)
#   + Element("R4", "Device:R", unit=1, value="15k")
#   + Element("-15V", "power:-15V", value="-15V").rotate(180)
#
#   + Line().at(dot2).left().length(10.16)
#   + Line().down().length(2.54)
#   + Element("Q3", "Transistor_BJT:BC547", unit=1, value="BC547",
#                  Spice_Netlist_Enabled="Y",
#                  Spice_Primitive="Q",
#                  Spice_Model="BC547B").anchor(3).mirror('x')
#
#   + Element("GND", "power:GND", value="GND").at("Q3", "1")
#   + Line().at("Q3", "2")
#   + Label("Y").rotate(180)
#
#   + Line().at(dot_out_a).left().length(5.08)
#   + Label("OUTa").rotate(180)
#
#   + Line().at(dot_out_b).right().length(5.08)
#   + Label("OUTb"))
#
# circuit = draw.circuit(["../../lib/spice"])
# circuit.voltage("1", "+15V", "GND", "DC 15V")
# circuit.voltage("2", "-15V", "GND", "DC -15V")
# circuit.voltage("3", "X", "GND", "5V SIN(0, 25m, 1k)")
# circuit.voltage("4", "Y", "GND", "5V SIN(0, 5V, 100)")
#
# simulation = Simulation(circuit)
# ltp = simulation.tran("40us", "10ms", "0")
# ltp_data = {}
# ltp_data['time'] = [x * 1000 for x in ltp['time']]
# ltp_data['y'] = [x for x in ltp['y']]
# ltp_data['out'] = [5 * (a - b) for (a, b) in zip(ltp['outa'], ltp['outb'])]
#
# draw.plot(scale=2, theme='BlackWhite')
```

In this typical vca configuration, the audio signal is applied to the transistor Q1 where Q2 is grounded. The multiplication factor, or current, is set with the transistor Q3. The output is the difference of OUTa and OUTb (OUTb - OUTa).

```{d3 element="ltp" x="time" y="y,out" data="py$ltp_data" width="600" height="400" fig.align='center' fig.cap="Figure 4: long tailed pair simulation."}```

The output (red) is the signal multiplied by the input at the long tail. But we see that only the negative signal creates amplification. When the signal is positive the output is silent. This circuit can be useful for a VCA where a DC envelope is applied.

# gilbert cell

Another circuit for the multiplication of two signals is the Gilbert Cell. Although everybody calls it the Gilbert Cell, it is not invented by [Barrie Gilbert](https://en.wikipedia.org/wiki/Barrie_Gilbert). The circuit was first used by Howard Jones in 1963. But Barrie Gilbert invented and augmented it independently and made it a common building block in analog electronics. The Gilbert Cell essentially comprises two differential transistor pairs whose bias current is controlled by one of the input signals.

```{python echo=FALSE output="hide" fig.align="center" fig.cap="Figure 5: Gilbert cell."}
from elektron import Circuit, Draw, Element, Label, Line, Dot, Simulation

draw = (Draw(["/usr/share/kicad/symbols"])
  + Label("X").rotate(180)
  + Line().right().length(2.54)
  + (dot_in_x := Dot())
  + Line().right().length(2.54)
  + Element("Q1", "Transistor_BJT:BC547", value="BC547", unit=1,
                 Spice_Netlist_Enabled="Y",
                 Spice_Primitive="Q",
                 Spice_Model="BC547B").anchor(2)

  + Line().at("Q1", "3").down().length(2 * 2.54)
  + Line().right().length(10.8)
  + (dot_tail_1 := Dot())
  + Line().right().length(10.8)
  + Line().up().length(2 * 2.54)
  + Element("Q2", "Transistor_BJT:BC547", value="BC547", unit=1,
                 Spice_Netlist_Enabled="Y",
                 Spice_Primitive="Q",
                 Spice_Model="BC547B").anchor(3).mirror('x').rotate(180)
#the pair
  + Line().at("Q2", "2").right().length(2.54)
  + (dot_pair_gnd := Dot())
  + Element("GND", "power:GND", value="GND")

  + Line().at(dot_pair_gnd)
  + Line().right().length(2.54)
  + Element("Q3", "Transistor_BJT:BC547", value="BC547", unit=1,
                 Spice_Netlist_Enabled="Y",
                 Spice_Primitive="Q",
                 Spice_Model="BC547B").anchor(2)

  + Line().at("Q3", "3").down().length(2 * 2.54)
  + Line().right().length(10.16)
  + (dot_tail_2 := Dot())
  + Line().right().length(10.16)
  + Line().up().length(2 * 2.54)
  + Element("Q4", "Transistor_BJT:BC547", value="BC547", unit=1,
                 Spice_Netlist_Enabled="Y",
                 Spice_Primitive="Q",
                 Spice_Model="BC547B").anchor(3).mirror('x').rotate(180)

  + Element("Q5", "Transistor_BJT:BC547", value="BC547", unit=1,
                 Spice_Netlist_Enabled="Y",
                 Spice_Primitive="Q",
                 Spice_Model="BC547B").anchor(1).at(dot_tail_1)

  + Line().at("Q5", "3").down().length(2.54)
  + Line().left().tox(dot_pair_gnd)
  + (dot_tail := Dot())
  + Element("R4", "Device:R", value="720")
  + Element("-15V", "power:-15V", value="-15V").rotate(180)

  + Element("Q6", "Transistor_BJT:BC547", value="BC547", unit=1,
                 Spice_Netlist_Enabled="Y",
                 Spice_Primitive="Q",
                 Spice_Model="BC547B").at(dot_tail_2).anchor(1).mirror('y')

  + Line().at("Q6", "3").down().length(2.54)
  + Line().tox(dot_pair_gnd)

  + Element("R5", "Device:R", value="2.2k").at("Q6", "2")
  + Element("+7.5V", "power:+7.5V", value="vBias").rotate(180)

  + Line().at("Q5", "2").left().length(2.54)
  + (y_bias := Dot())
  + Element("C", "Device:C", value="220n").rotate(270)
  + Line().left().length(5 * 1.27)
  + Label("Y").rotate(180)


  + Element("R3", "Device:R", value="2.2k").at(y_bias)
  + Element("+7.5V", "power:+7.5V", value="vBias").rotate(180)
  + Line().at("Q1", "1").up().length(2.54)
  + (dot_con_a := Dot())
  + Line().up().length(5.08)
  + (dot_out_a := Dot())
  + Line().up().length(2.54)
  + Element("R1", "Device:R", value="720").rotate(180)
  + Line().tox(dot_pair_gnd)
  + Dot()
  + Element("+15V", "power:+15V", value="+15V")

  + Line().at("Q4", "1").up().length(5.08)
  + (dot_con_b := Dot())
  + Line().up().length(2.54)
  + (dot_out_b := Dot())
  + Line().up().length(2.54)
  + Element("R2", "Device:R", value="720").rotate(180)
  + Line().tox(dot_pair_gnd)

  + Line().at(dot_con_a).tox("Q3", "1")
  + Line().toy("Q3", "1")

  + Line().at(dot_con_b).tox("Q2", "1")
  + Line().toy("Q2", "1")

  + Line().at(dot_out_a).right().length(2.54)
  + Label("OUTa")

  + Line().at(dot_out_b).left().length(2.54)
  + Label("OUTb").rotate(180)

  + Line().at("Q4", "2").down().length(3 * 2.54)
  + Line().tox(dot_in_x)
  + Line().toy(dot_in_x))

circuit = draw.circuit(["../../lib/spice"])
circuit.voltage("1", "+15V", "GND", "DC 15V")
circuit.voltage("2", "-15V", "GND", "DC -15V")
circuit.voltage("3", "X", "GND", "5V SIN(0, 20m, 100)")
circuit.voltage("4", "Y", "GND", "5V SIN(0, 10m, 1k)")
circuit.voltage("5", "Vbias", "GND", "DC -7.5V")

simulation = Simulation(circuit)
gilbert = simulation.tran("30us", "10ms", "0")

gc_data = {}
gc_data['time'] = [x * 1000 for x in gilbert['time']]
gc_data['x'] = [x * 8 for x in gilbert['x']]

gc_data['out'] = [(a - b) for (a, b) in zip(gilbert['outa'], gilbert['outb'])]

draw.plot(scale=2, theme='BlackWhite')
```

It is not so easy to create a discrete Gilbert Cell. All the transistors have to be matched. The most tricky part is the biasing of the input signals. Here the audio signal is biased with a voltage of -7.5V (Vbias). The carrier is biased by the -15V in the long tail. This allows, that the carrier signal can also be a DC signal, like an envelope. This is a very crude implementation of a Gilbert Cell, which most likely is not precise and would add a lot of noise to the output.

```{d3 element="gilbert_cell" x="time" y="x,out" data="py$gc_data" width="600" height="400" fig.align='center' fig.cap="Figure 6: Gilbert cell simulation."}```

The plot shows, that the Gilbert Cell does work as excpected and creates real amplitude modulation with double sideband and supressed carrier.

# Analog Multiplier

We saw that multiple types of multiplier circuits behave differently. Of course, this is a well-defined behaviour. The multipliers are classified in three types. The types are called quadrants. In the following table the different quadrants are listed and for which signal type they can be used.


|Type|X [V]| Y  [V]| Out [V]|
|--- |---  |---    |---     |
|1-Quadrant|Unipolar|Unipolar|Unipolar|
|2-Quadrant|Bipolar|Unipolar|Bipolar|
|4-Quadrant|Bipolar|Bipolar|Bipolar|


The simulation showed that the long-tailed pair is a 2-quadrant multiplier. The X signal can be an audio signal but the Y signal has to be unipolar, for example, an envelope. In contrast, the Gilbert Cell is a four-quadrant multiplier and allows both signals to be bipolar. The Gilbert Cell can be used as a Ring Modulator. of course, a 4-quadrant multiplier also works correctly when one signal is unipolar. But the output signal would be the same as with a 2-quadrant multiplier.


# construction

There are different circuits for multiplication of signals. The choice of the circuit depends on the nature of the signal and the required functions we want to apply to them. Here only circuits using BJT's are shown. The downside of these circuits is that all the transistors have to be properly matched. In my experience, they are also very sensitive to noise. My take on a discrete Gilbert Cell produced to much noise to be useful. There are also integrated circuits which implement a VCA or multiplier available. For a simple VCA the [LM13700](https://www.ti.com/lit/ds/symlink/lm13700.pdf) is a good choice. There are also integrated circuits available which implement the Gilbert Cell. One example is the [AD633](https://www.analog.com/media/en/technical-documentation/data-sheets/AD633.pdf) from Analog Devices. This chip is very handy, it offers the right input and output impedances. No buffering or biasing of the signals is necessary. It is a very precise multiplier, which of course has some price.

```{latex echo=FALSE fig.align='center' fig.cap='Figure 1: produkt block diagram'}
\documentclass[border=2mm]{standalone}
\usepackage{tikz}
\usepackage{circuitikz}

\begin{document}
\ctikzset{blocks/thickness=2,switches/thickness=1.5}
\begin{circuitikz}[line width=2pt,scale=1.5,font=\sffamily,every node/.style={scale=1.5}]

  \draw (0,0) node[twoportshape,t=mul](tp1){};
  \draw (tp1.north) to ++(0,1) to ++(-1,0)
    node[spdt,xscale=-1,yscale=-1,anchor=in](Sw1){} ++(1,0)
    (Sw1.out 1) to[short, -o] ++(-0.3,0) node[left] {X};
  \draw (tp1.south) to ++(0,-1) to[short,-o] ++(-2.5,0) node[left] {Y};
  \draw (tp1.east) to[short,-o] ++(1.9,0) node[right] {OUT};

  \draw (0,4) node[twoportshape,t=mul](tp1){};
  \draw (tp1.north) to ++(0,1) to[short,-o] ++(-2.5,0) node[left] {X};
  \draw (tp1.south) to ++(0,-1) to[short,-o] ++(-2.5,0) node[left] {Y};
  \draw (tp1.east) to[short] ++(0.2,0)
    node[spdt,anchor=in](Sw2){}
    (Sw2.out 1) to[short, -o] ++(0.5,0) node[right] {OUT};

  \draw (Sw1.out 2) to ++(0,0.4) to ++(4.05,0) to ++(0, 1.5);

\end{circuitikz}
\end{document}
```

First we design the input stage. the input voltage for the X signal should be 10mV and 20mV for the control voltage.

{{< bom >}}

For mounting the LED's the long lead has to go to the round pad.

{{< image "/produkt-side.jpg" "Figure 5: Side View" >}}

{{< callout >}}

{{< report produkt main mount>}}

# calibration

there is no calibration needed. but the potentiomenter knobs have to be aliged to center position.

# usage

the input jacks are wired to 5 volts when nothing is connected.

all channels are mixed to the out jack. when something is connected to the channel out, this channel is removed from the overall mix.

_mixer_
* connect the different channels from audio or cv sources to the in jacks.
* connect the out jack to something
* turn the pots clockwise to adjust the volume.

_attenuverter_
* connect all or a single channel.
* when you turn the pot knob counter clockwise the signal is inverted.
=1,p=1;ENOENT:Put command refers to image with id: 1 that could not load its data=1;EBADPNG:bad adaptive filter value\

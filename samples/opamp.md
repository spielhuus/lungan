---
author: "spielhuus"
categories:
- module
date: 2021-07-28
title: opamp
draft: False
---

# Opamp inverting amplifier

```py
import recad

schema = recad.Schema("")
schema.move_to((5.08, 2*5.08))
schema = (schema
    + recad.LocalLabel("Vin").rotate(180) 
    + recad.Wire().right()
    + recad.Symbol("R1", "100k", "Device:R").rotate(90)
    + recad.Junction()
    + recad.Symbol("U1", "TL072", "Amplifier_Operational:LM2904").anchor("2").mirror("x")
    + recad.Junction()
    + recad.Wire().up().length(4)
    + recad.Symbol("R2", "100k", "Device:R").rotate(270).tox("U1", "2")
    + recad.Wire().toy("U1", "2")
    + recad.Symbol("GND", "GND", "power:GND").at("U1", "3")
    + recad.LocalLabel("Vout").at("U1", "1")
)
schema.plot(scale=0.8)
```



























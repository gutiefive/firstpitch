"""Generate original prototype effects with Python's standard library.
Run from the repository root. No recordings, dependencies, or downloaded assets.
"""
from pathlib import Path
import math
import random
import struct
import wave
RATE = 22050
OUT = Path(__file__).resolve().parents[1] / 'assets/audio'
OUT.mkdir(parents=True, exist_ok=True)

def render(name, seconds, sample, loop=False):
    rng = random.Random(9137)
    low = 0.0
    values = []
    for i in range(round(seconds * RATE)):
        t = i / RATE
        noise = rng.uniform(-1, 1)
        low = 0.92 * low + 0.08 * noise
        value = sample(t, noise, low)
        # Quiet joins and a bounded peak keep generated loops free of hard clicks.
        edge = min(1, t / .025, (seconds - t - 1 / RATE) / .025)
        value *= max(0, edge) if loop else 1
        values.append(max(-.85, min(.85, value)))
    with wave.open(str(OUT / (name + '.wav')), 'wb') as f:
        f.setparams((1, 2, RATE, len(values), 'NONE', 'not compressed'))
        f.writeframes(b''.join(struct.pack('<h', round(v * 32767)) for v in values))

render('engine', 2, lambda t,n,l: .22*math.sin(math.tau*55*t)*(1+.25*math.sin(math.tau*5*t))+.09*math.sin(math.tau*110*t)+.08*l, True)
render('hose', 3, lambda t,n,l: .24*(n-l)+.17*l, True)
render('drag', 3, lambda t,n,l: .48*l*(.7+.3*math.sin(math.tau*7*t))+.07*n, True)
render('chalk', 3, lambda t,n,l: .22*l+.045*n*(.5+.5*math.sin(math.tau*13*t)), True)
render('wind', 8, lambda t,n,l: .38*l*(.65+.2*math.sin(math.tau*t/8)), True)
def birds(t,n,l):
    value = 0
    for start, pitch in [(1,2100),(1.3,2600),(4.6,1800),(7.2,2400),(7.5,2100),(10.1,1900)]:
        age = t-start
        if 0 <= age < .18:
            value += .12*math.sin(math.pi*age/.18)**2*math.sin(math.tau*(pitch*age+1300*age*age))
    return value
render('birds', 12, birds, True)
render('step', .16, lambda t,n,l: (.3*l+.08*n+.12*math.sin(math.tau*105*t))*math.exp(-35*t)*min(1,t/.004))
render('tamp', .3, lambda t,n,l: (.4*math.sin(math.tau*(95*t-60*t*t))+.2*l+.08*n)*math.exp(-19*t)*min(1,t/.003))
def bell(t,n,l):
    value = 0
    for start, pitch in [(0,523.25),(.13,659.25),(.26,783.99)]:
        age = t-start
        if age >= 0:
            value += .18*math.sin(math.tau*pitch*age)*math.exp(-9*age)*min(1,age/.008)
    return value
render('shift', .9, bell)

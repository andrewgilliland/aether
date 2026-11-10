"""Generates the game's placeholder sounds into assets/sounds/.

    python tools/make_sounds.py

Everything here is synthesised from simple waves and noise: serviceable
stand-ins, not finished audio. To replace a sound, drop a WAV of the same
name into assets/sounds/ (and do not run this again, or it is overwritten).
Uses only the Python standard library.
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sounds")
random.seed(7)


def save(name, samples, peak=0.8, soften=True):
    """Write a sound. `soften` eases the first and last few milliseconds so an
    effect does not click; the music loop must not be softened."""
    samples = list(samples)
    if soften:
        ramp = int(0.003 * RATE)
        for i in range(ramp):
            samples[i] *= i / ramp
            samples[-1 - i] *= i / ramp
    top = max(1e-9, max(abs(s) for s in samples))
    scale = peak / top
    frames = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s * scale)) * 32767)) for s in samples)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(frames)
    print("%-18s %.2fs" % (name, len(samples) / RATE))


def square(phase, duty=0.5):
    return 1.0 if (phase % 1.0) < duty else -1.0


def triangle(phase):
    return 4.0 * abs((phase % 1.0) - 0.5) - 1.0


def sine(phase):
    return math.sin(2.0 * math.pi * phase)


def tone(seconds, freq_at, wave_fn, volume_at):
    """A tone whose pitch and loudness are functions of progress 0..1."""
    count = int(seconds * RATE)
    out, phase = [], 0.0
    for i in range(count):
        t = i / count
        phase += freq_at(t) / RATE
        out.append(wave_fn(phase) * volume_at(t))
    return out


def noise(seconds, cutoff_at, volume_at, floor_at=None):
    """Noise through a sweeping low-pass; with floor_at, a band between the two."""
    count = int(seconds * RATE)
    out, low, lower = [], 0.0, 0.0
    for i in range(count):
        t = i / count
        white = random.uniform(-1.0, 1.0)
        a = min(1.0, 2.0 * math.pi * cutoff_at(t) / RATE)
        low += a * (white - low)
        value = low
        if floor_at:
            b = min(1.0, 2.0 * math.pi * floor_at(t) / RATE)
            lower += b * (white - lower)
            value = low - lower
        out.append(value * volume_at(t))
    return out


def mix(*parts):
    out = [0.0] * max(len(p) for p in parts)
    for part in parts:
        for i, s in enumerate(part):
            out[i] += s
    return out


def join(*parts):
    out = []
    for part in parts:
        out.extend(part)
    return out


def lerp(a, b, t):
    return a + (b - a) * t


def decay(power=3.0):
    return lambda t: (1.0 - t) ** power


def swell(t):
    return math.sin(math.pi * t) ** 0.8


# ------------------------------------------------------------- effects

def make_effects():
    # The blade through the air: a band of noise sliding downward.
    save("swing", noise(0.20, lambda t: lerp(7000, 1200, t), swell, lambda t: lerp(1800, 300, t)), 0.7)

    # A Swing landing: a click of noise over a falling thud.
    save("struck", mix(
        tone(0.14, lambda t: lerp(240, 80, t), lambda p: square(p, 0.5), decay(2.5)),
        [s * 0.9 for s in noise(0.05, lambda t: 5000, decay(2.0))],
    ), 0.8)

    # A Puffhop's hop: a small rising chirp.
    save("hop", tone(0.11, lambda t: lerp(300, 560, t), triangle, decay(1.5)), 0.5)

    # A Puffhop defeated: four falling notes and a puff.
    notes = [tone(0.06, lambda t, f=f: f, lambda p: square(p, 0.25), decay(1.0)) for f in (660, 520, 390, 260)]
    save("defeated", mix(join(*notes), [0.0] * int(0.1 * RATE) + [s * 0.6 for s in noise(0.25, lambda t: lerp(3000, 400, t), decay(2.0))]), 0.7)

    # The Hero hurt: a harsh buzz dropping in pitch.
    save("hurt", tone(0.24, lambda t: lerp(190, 105, t) * (1.0 + 0.06 * math.sin(2 * math.pi * 30 * t * 0.24)),
                      lambda p: square(p, 0.2), decay(1.5)), 0.7)

    # The Hero Fallen: four slow notes stepping down.
    steps = [tone(0.22, lambda t, f=f: f, triangle, decay(1.2)) for f in (392.0, 329.6, 261.6, 196.0)]
    save("fallen", join(*steps), 0.7)

    # The Recharge Gauge filling: two rising bell notes.
    bell = lambda f: tone(0.16, lambda t: f, sine, decay(3.0))
    save("gauge_full", mix(bell(880.0), [0.0] * int(0.07 * RATE) + bell(1318.5)), 0.45)

    # A Transition: a soft low rush.
    save("transition", noise(0.45, lambda t: lerp(300, 900, math.sin(math.pi * t)), swell), 0.5)


# --------------------------------------------------------------- music

A4 = 440.0
NOTE = {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}


def hz(name):
    """'A4' -> 440.0"""
    return A4 * 2.0 ** ((NOTE[name[0]] + 12 * (int(name[1]) - 4)) / 12.0)


def make_music():
    """An eight-bar loop in A minor, 96 beats a minute: melody, bass and a
    quiet broken chord. It is mixed around the end so the loop has no seam."""
    eighth = 60.0 / 96.0 / 2.0
    bars = 8
    total = int(bars * 8 * eighth * RATE)
    track = [0.0] * total

    def play(start_eighth, eighths, freq, wave_fn, volume, attack=0.015, release=0.08, vibrato=0.0):
        start = int(start_eighth * eighth * RATE)
        count = int(eighths * eighth * RATE)
        tail = int(release * RATE)
        phase = 0.0
        for i in range(count + tail):
            seconds = i / RATE
            rise = min(1.0, seconds / attack)
            if i < count:
                level = rise * (0.65 + 0.35 * math.exp(-4.0 * seconds))
            else:
                level = 0.65 * (1.0 - (i - count) / tail)
            wobble = 1.0 + vibrato * math.sin(2 * math.pi * 5.0 * seconds)
            phase += freq * wobble / RATE
            track[(start + i) % total] += wave_fn(phase) * level * volume

    chords = ["Am", "F", "C", "G"] * 2
    tones = {
        "Am": ("A2", ["A3", "C4", "E4", "C4"]),
        "F": ("F2", ["A3", "C4", "F4", "C4"]),
        "C": ("C3", ["G3", "C4", "E4", "C4"]),
        "G": ("G2", ["G3", "B3", "D4", "B3"]),
    }
    # Each bar: (note, length in eighths) pairs; "-" is a rest.
    melody = [
        [("E5", 2), ("A5", 2), ("G5", 1), ("E5", 3)],
        [("F5", 2), ("E5", 2), ("C5", 4)],
        [("E5", 2), ("G5", 2), ("C6", 2), ("B5", 1), ("G5", 1)],
        [("D5", 4), ("B4", 2), ("D5", 2)],
        [("E5", 2), ("A5", 2), ("C6", 2), ("A5", 2)],
        [("A5", 2), ("G5", 1), ("F5", 1), ("E5", 2), ("C5", 2)],
        [("D5", 2), ("E5", 2), ("G5", 2), ("E5", 2)],
        [("D5", 6), ("-", 2)],
    ]
    soft_lead = lambda p: 0.7 * triangle(p) + 0.3 * sine(2 * p)
    for bar in range(bars):
        at = bar * 8
        root, arp = tones[chords[bar]]
        play(at, 3, hz(root), triangle, 0.5)
        play(at + 4, 2, hz(root) * 1.5, triangle, 0.4)
        play(at + 6, 2, hz(root), triangle, 0.4)
        for step in range(8):
            play(at + step, 1, hz(arp[step % 4]), sine, 0.16)
        cursor = at
        for name, length in melody[bar]:
            if name != "-":
                play(cursor, length, hz(name), soft_lead, 0.42, vibrato=0.004)
            cursor += length

    # One soft echo, wrapped around the loop.
    delay = int(3 * eighth * RATE)
    dry = list(track)
    for i in range(total):
        track[i] += 0.28 * dry[(i - delay) % total]
    save("forest_music", track, 0.6, soften=False)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    make_effects()
    make_music()

#!/usr/bin/env python3
"""Original, deterministic additive/noise synthesis. No samples or external audio.
Writes an 80-second stereo loop and optional MP3 listening copy with ffmpeg.
The rendered recording/composition is dedicated under CC0; see assets/music.
"""
from pathlib import Path
import json, math, shutil, subprocess, wave
import numpy as np
from scipy.signal import butter, sosfilt
ROOT=Path(__file__).resolve().parents[1]
RATE=44100;BPM=96;BEAT=60/BPM;BARS=32;SECONDS=BARS*4*BEAT
N=round(RATE*SECONDS);rng=np.random.default_rng(271029)
mix=np.zeros((N,2),dtype=np.float64)
def hz(note):return 440*2**((note-69)/12)
def add(sound,beat,pan=0,gain=1):
    start=round(beat*BEAT*RATE)
    a=np.asarray(sound,dtype=np.float64)
    if a.ndim==1:a=np.column_stack((a*math.sqrt((1-pan)/2),a*math.sqrt((1+pan)/2)))
    # Wrapped reverb/voice tails make the rendered source loop periodic.
    i=start%N;first=min(len(a),N-i);mix[i:i+first]+=a[:first]*gain
    if first<len(a):mix[:len(a)-first]+=a[first:]*gain
def envelope(t,attack,release):return (1-np.exp(-t/max(attack,.001)))*np.exp(-t/release)*np.clip((t[-1]-t)/min(.02,t[-1]/4),0,1)
def pad(notes,beats):
    duration=beats*BEAT+2;t=np.arange(round(duration*RATE))/RATE
    fade=np.minimum(1,t/.7)*np.minimum(1,np.maximum(0,(duration-t)/1.6))
    out=np.zeros((len(t),2))
    for j,note in enumerate(notes):
        phase=rng.uniform(0,2*np.pi)
        for side,cents in enumerate((-3.2,3.2)):
            f=hz(note)*2**(cents/1200)
            voice=np.sin(2*np.pi*f*t+phase)+.2*np.sin(2*np.pi*f*2*t+phase*.7)+.055*np.sin(2*np.pi*f*3*t)
            out[:,side]+=voice*(1+.045*np.sin(2*np.pi*.18*t+j))
    return out*fade[:,None]*(.018/len(notes))
def bass(note):
    t=np.arange(round(.52*RATE))/RATE;f=hz(note)
    return (np.sin(2*np.pi*f*t)+.22*np.sin(2*np.pi*f*2*t))*envelope(t,.012,.2)*.105
def mallet(note):
    t=np.arange(round(1.9*RATE))/RATE;f=hz(note)
    return (np.sin(2*np.pi*f*t)+.15*np.sin(2*np.pi*f*2.005*t)*np.exp(-t*5)+.045*np.sin(2*np.pi*f*3.97*t)*np.exp(-t*8))*envelope(t,.008,.44)*.038
chords=[(40,[52,55,59,66]),(36,[48,52,55,59]),(43,[55,59,62,64]),(38,[50,54,57,64])]
melody=[[(.5,64),(2.25,67)],[(1.5,66),(3,59)],[(.75,64),(2.5,62)],[(1.5,59)],[(.5,62),(2.75,67)],[(1,64),(3.25,62)],[(.75,66),(2,64)],[(1.5,62),(3.25,59)]]
for bar in range(BARS):
    root,notes=chords[(bar//2)%4]
    if bar%2==0:add(pad(notes,8),bar*4)
    for beat in [0,1.5,2.75]:add(bass(root+(12 if beat==2.75 and bar%4==3 else 0)),bar*4+beat,pan=-.03,gain=.9 if beat==0 else .72)
    # Quiet synthetic kick, brushed backbeat, and sparse metallic ticks.
    for beat in [0,2]:
        t=np.arange(round(.34*RATE))/RATE;frequency=48+75*np.exp(-t*33);phase=np.cumsum(frequency)*2*np.pi/RATE
        kick=np.sin(phase)*envelope(t,.003,.075)*.08
        add(kick,bar*4+beat,gain=.72 if bar//8==0 else 1)
    for beat in [1,3]:
        t=np.arange(round(.19*RATE))/RATE;noise=rng.normal(0,1,len(t));filtered=sosfilt(butter(2,[650,4200],btype='bandpass',fs=RATE,output='sos'),noise)
        snap=(filtered*.012+np.sin(2*np.pi*185*t)*.009)*envelope(t,.004,.035)
        add(snap,bar*4+beat,pan=.1)
    for half in [1,3,5,7]:
        t=np.arange(round(.085*RATE))/RATE;noise=rng.normal(0,1,len(t));brush=sosfilt(butter(2,[3200,7400],btype='bandpass',fs=RATE,output='sos'),noise)
        add(brush*envelope(t,.002,.016)*.005,bar*4+half/2,pan=(-.4 if half%4==1 else .4))
    if bar%4==3:
        t=np.arange(round(.23*RATE))/RATE;tick=(np.sin(2*np.pi*680*t)+.35*np.sin(2*np.pi*961*t)+.12*np.sin(2*np.pi*1836*t))*envelope(t,.002,.035)*.009
        add(tick,bar*4+3.5,pan=-.5 if bar%8==3 else .5)
    # Sparse original motif; a variation lowers the final eight bars by an octave.
    for beat,note in melody[bar%8]:
        if 8<=bar<16 and bar%2:continue
        voice=mallet(note-(12 if bar>=24 and bar%2 else 0));pan=.25*math.sin(bar*1.7)
        add(voice,bar*4+beat,pan=pan)
        add(voice,bar*4+beat+.75,pan=-pan,gain=.19)
        add(voice,bar*4+beat+1.5,pan=pan,gain=.08)
# Original low-level room texture, filtered with wrapped pre-roll for continuity.
noise=rng.normal(0,1,N);low=sosfilt(butter(2,180,fs=RATE,output='sos'),np.concatenate((noise[-RATE:],noise)))[RATE:]
t=np.arange(N)/RATE
room=(low*.0012+np.sin(2*np.pi*50*t)*.0004)*(1+.12*np.sin(2*np.pi*t/20))
mix+=room[:,None]
mix-=mix.mean(axis=0)
# Symmetric soft limiting; leave 2dB headroom. Scale to a measured, modest RMS.
mix=np.tanh(mix*2)/2
rms=float(np.sqrt(np.mean(mix**2)));mix*=10**(-20/20)/rms
peak=float(np.max(np.abs(mix)))
if peak>10**(-2/20):mix*=10**(-2/20)/peak
pcm=np.round(np.clip(mix,-1,1)*32767).astype('<i2')
folder=ROOT/'assets/music';folder.mkdir(parents=True,exist_ok=True);wav=folder/'scrapyard-afterglow.wav'
with wave.open(str(wav),'wb') as w:w.setnchannels(2);w.setsampwidth(2);w.setframerate(RATE);w.writeframes(pcm.tobytes())
metrics={'title':'Scrapyard Afterglow','duration_seconds':SECONDS,'bpm':BPM,'sample_rate':RATE,'channels':2,'peak_dbfs':float(20*np.log10(np.max(np.abs(pcm.astype(float)))/32768)),'rms_dbfs':float(20*np.log10(np.sqrt(np.mean((pcm.astype(float)/32768)**2)))),'loop_boundary_step':int(np.max(np.abs(pcm[0].astype(int)-pcm[-1].astype(int)))),'source':'Original additive/noise synthesis; no third-party samples','license':'CC0-1.0'}
(folder/'track-info.json').write_text(json.dumps(metrics,indent=2)+'\n')
ffmpeg=shutil.which('ffmpeg')
if ffmpeg:subprocess.run([ffmpeg,'-hide_banner','-loglevel','error','-y','-i',str(wav),'-codec:a','libmp3lame','-b:a','192k',str(folder/'scrapyard-afterglow.mp3')],check=True)
print(json.dumps(metrics,indent=2))

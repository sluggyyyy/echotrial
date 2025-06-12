
import { NUIMessage, AudioState } from './types';

class MoneyCounterAudio {
  private audioState: AudioState;

  constructor() {
    this.audioState = {
      countingAudio: null,
      countingInterval: null,
      currentVolume: 0.1715,
      activeCountingAudios: []
    };

    this.setupEventListeners();
  }

  private setupEventListeners(): void {
    window.addEventListener('message', (event: MessageEvent<NUIMessage>) => {
      const data = event.data;
      
      switch (data.type) {
        case 'playSound':
          if (data.sound) {
            this.playSound(data.sound, data.counterCoords);
          }
          break;
          
        case 'stopSound':
          if (data.sound) {
            this.stopSound(data.sound);
          }
          break;
          
        case 'updateVolume':
          if (data.sound && data.distance !== undefined) {
            this.updateVolume(data.sound, data.distance);
          }
          break;
      }
    });
  }

  private calculateVolume(distance: number, maxDistance: number = 10.0, baseVolume: number = 1.0): number {
    if (distance >= maxDistance) return 0;
    
    const volumeMultiplier = Math.max(0, 1 - (distance / maxDistance));
    return baseVolume * volumeMultiplier;
  }

  private playSound(soundName: string, counterCoords?: [number, number, number]): void {
    try {
      
      if (soundName === 'beep') {
        const audio = new Audio('./beep.ogg');
        audio.volume = 0.1715;
        audio.play();
        
        
      } else if (soundName === 'counting_loop') {
        this.startCountingLoop();
      }
      
    } catch (e) {
    }
  }

  private startCountingLoop(): void {
    if (this.audioState.countingInterval) {
      clearInterval(this.audioState.countingInterval);
    }

    this.audioState.countingInterval = setInterval(() => {
      try {
        const audio = new Audio('./money_counter.ogg');
        audio.volume = this.audioState.currentVolume;
        audio.play();
        
        this.audioState.activeCountingAudios.push(audio);

        audio.addEventListener('ended', () => {
          const index = this.audioState.activeCountingAudios.indexOf(audio);
          if (index > -1) {
            this.audioState.activeCountingAudios.splice(index, 1);
          }
        });
        
      } catch (e) {
      }
    }, 2100);

    try {
      const audio = new Audio('./money_counter.ogg');
      audio.volume = this.audioState.currentVolume;
      audio.play();
      this.audioState.activeCountingAudios.push(audio);

      audio.addEventListener('ended', () => {
        const index = this.audioState.activeCountingAudios.indexOf(audio);
        if (index > -1) {
          this.audioState.activeCountingAudios.splice(index, 1);
        }
      });
    } catch (e) {
    }
  }

  private updateVolume(soundName: string, distance: number): void {
  }

  private stopSound(soundName: string): void {
    if (soundName === 'counting_loop') {
      if (this.audioState.countingInterval) {
        clearInterval(this.audioState.countingInterval);
        this.audioState.countingInterval = null;
      }

      this.audioState.activeCountingAudios.forEach(audio => {
        audio.pause();
        audio.currentTime = 0;
      });
      
      this.audioState.activeCountingAudios = [];
    }
  }
}

new MoneyCounterAudio();
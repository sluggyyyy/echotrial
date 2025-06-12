
export interface SoundData {
  sound: string;
  counterCoords?: [number, number, number];
}

export interface VolumeData {
  sound: string;
  distance: number;
}

export interface NUIMessage {
  type: 'playSound' | 'stopSound' | 'updateVolume';
  
  sound?: string;
  counterCoords?: [number, number, number];
  distance?: number;
}

export interface AudioState {
  countingAudio: HTMLAudioElement | null;
  countingInterval: NodeJS.Timeout | null;
  currentVolume: number;
  activeCountingAudios: HTMLAudioElement[];
}

declare global {
  function GetParentResourceName(): string;
}
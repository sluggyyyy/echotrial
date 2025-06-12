
export interface MinigameData {
  timeLimit: number;
  targetScore: number;
}

export interface MinigameResult {
  success: boolean;
}

export interface SoundData {
  sound: string;
  machineCoords?: [number, number, number];
}

export interface VolumeData {
  sound: string;
  distance: number;
}

export interface NUIMessage {
  type: 'startMinigame' | 'stopMinigame' | 'playSound' | 'stopSound' | 'updateVolume';
  
  timeLimit?: number;
  targetScore?: number;
  sound?: string;
  machineCoords?: [number, number, number];
  distance?: number;
}

export interface BubbleElement extends HTMLElement {
  animationDuration?: string;
}

export interface GameElements {
  container: HTMLElement;
  bubbleArea: HTMLElement;
}

export type BubbleSize = 'small' | 'medium' | 'large';

export interface GameState {
  isActive: boolean;
  bubblesPopped: number;
  bubblesMissed: number;
  timeLeft: number;
  targetBubbles: number;
  maxMisses: number;
  activeBubbles: HTMLElement[];
}

export interface AudioState {
  washingAudio: HTMLAudioElement | null;
  washingInterval: NodeJS.Timeout | null;
  currentWashingVolume: number;
  activeWashingAudios: HTMLAudioElement[];
}

declare global {
  function GetParentResourceName(): string;
}
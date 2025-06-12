interface MinigameData {
    timeLimit: number;
    targetScore: number;
}

interface MinigameResult {
    success: boolean;
}

interface NUIMessage {
    type: 'startMinigame' | 'playSound' | 'stopSound' | 'updateVolume' | 'stopMinigame';
    timeLimit?: number;
    targetScore?: number;
    sound?: string;
    distance?: number;
    machineCoords?: [number, number, number];
}

type BubbleSize = 'small' | 'medium' | 'large';

interface GameState {
    isActive: boolean;
    bubblesPopped: number;
    bubblesMissed: number;
    timeLeft: number;
    targetBubbles: number;
    maxMisses: number;
    activeBubbles: HTMLElement[];
}

interface AudioState {
    washingAudio: HTMLAudioElement | null;
    washingInterval: NodeJS.Timeout | null;
    currentWashingVolume: number;
    activeWashingAudios: HTMLAudioElement[];
}

interface GameElements {
    container: HTMLElement;
    bubbleArea: HTMLElement;
}

interface BubbleElement extends HTMLElement {
    style: CSSStyleDeclaration & {
        animationDuration: string;
    };
}


class BubbleMinigame {
    private gameState: GameState;
    private audioState: AudioState;
    private elements: GameElements;
    private bubbleSpawnInterval: NodeJS.Timeout | null = null;
    private gameTimer: NodeJS.Timeout | null = null;
    private bubbleTimeouts: Set<NodeJS.Timeout> = new Set();

    constructor() {
        this.gameState = {
            isActive: false,
            bubblesPopped: 0,
            bubblesMissed: 0,
            timeLeft: 0,
            targetBubbles: 0,
            maxMisses: 5,
            activeBubbles: []
        };

        this.audioState = {
            washingAudio: null,
            washingInterval: null,
            currentWashingVolume: 0.245,
            activeWashingAudios: []
        };

        this.elements = {
            container: document.getElementById('minigame')!,
            bubbleArea: document.getElementById('bubble-area')!
        };

        this.setupEventListeners();
    }

    private setupEventListeners(): void {
        window.addEventListener('message', (event: MessageEvent<NUIMessage>) => {
            const data = event.data;
            
            switch (data.type) {
                case 'startMinigame':
                    this.startGame({
                        timeLimit: data.timeLimit || 30,
                        targetScore: data.targetScore || 25
                    });
                    break;
                    
                case 'playSound':
                    if (data.sound) {
                        this.playSound(data.sound, data.machineCoords);
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
                case 'stopMinigame':
                    console.log('NUI: Received stopMinigame message. Force resetting game state.');
                    this.forceReset();
                    this.hideGame();
                    this.sendResult(false);
                    break;
            }
        });
    }

    private calculateVolume(distance: number, maxDistance: number = 10.0, baseVolume: number = 1.0): number {
        if (distance >= maxDistance) return 0;
        
        const volumeMultiplier = Math.max(0, 1 - (distance / maxDistance));
        return baseVolume * volumeMultiplier;
    }

    private playSound(soundName: string, machineCoords?: [number, number, number]): void {
        try {
            
            if (soundName === 'washing_start') {
                const audio = new Audio('./washing_start.ogg');
                audio.volume = 0.343;
                audio.play();
                
            } else if (soundName === 'washing_loop') {
                this.startWashingLoop();
            }
            
        } catch (e) {
            console.error("Error playing sound:", e);
        }
    }

    private startWashingLoop(): void {
        if (this.audioState.washingInterval) {
            clearInterval(this.audioState.washingInterval);
        }

        this.audioState.washingInterval = setInterval(() => {
            try {
                const audio = new Audio('./washing.ogg');
                audio.volume = this.audioState.currentWashingVolume;
                audio.play();
                
                this.audioState.activeWashingAudios.push(audio);

                audio.addEventListener('ended', () => {
                    const index = this.audioState.activeWashingAudios.indexOf(audio);
                    if (index > -1) {
                        this.audioState.activeWashingAudios.splice(index, 1);
                    }
                });
                
            } catch (e) {
                console.error("Error playing washing loop segment:", e);
            }
        }, 3000);

        try {
            const audio = new Audio('./washing.ogg');
            audio.volume = this.audioState.currentWashingVolume;
            audio.play();
            this.audioState.activeWashingAudios.push(audio);

            audio.addEventListener('ended', () => {
                const index = this.audioState.activeWashingAudios.indexOf(audio);
                if (index > -1) {
                    this.audioState.activeWashingAudios.splice(index, 1);
                }
            });
        } catch (e) {
            console.error("Error playing initial washing loop sound:", e);
        }
    }

    private updateVolume(soundName: string, distance: number): void {
    }

    private stopSound(soundName: string): void {
        if (soundName === 'washing_loop') {
            if (this.audioState.washingInterval) {
                clearInterval(this.audioState.washingInterval);
                this.audioState.washingInterval = null;
                console.log('Stopped washing loop interval.');
            }

            this.audioState.activeWashingAudios.forEach(audio => {
                audio.pause();
                audio.currentTime = 0;
                console.log('Paused and reset washing audio instance.');
            });
            
            this.audioState.activeWashingAudios = [];
        }
    }

    private startGame(data: MinigameData): void {
        console.log('Starting new game - timeLimit:', data.timeLimit, 'targetScore:', data.targetScore);
        
        console.log('Always force resetting to ensure clean state before starting.');
        this.forceReset();

        this.gameState = {
            isActive: true,
            bubblesPopped: 0,
            bubblesMissed: 0,
            timeLeft: data.timeLimit,
            targetBubbles: data.targetScore,
            maxMisses: 5,
            activeBubbles: []
        };
        
        console.log('Game state initialized:', this.gameState);

        this.elements.container.classList.remove('hidden');

        this.bubbleSpawnInterval = setInterval(() => {
            if (this.gameState.isActive) {
                this.spawnBubble();
            }
        }, 400);

        this.gameTimer = setInterval(() => {
            this.gameState.timeLeft--;
            
            if (this.gameState.timeLeft <= 0) {
                console.log('Game timer reached zero. Ending game as failure.');
                this.endGameInstant(false);
            }
        }, 1000);

        for (let i = 0; i < 3; i++) {
            setTimeout(() => {
                console.log('Creating initial bubble', i + 1, 'of 3');
                this.spawnBubble();
            }, i * 300);
        }
    }

    private spawnBubble(): void {
        console.log('spawnBubble called - isActive:', this.gameState.isActive, 'timeLeft:', this.gameState.timeLeft);
        if (!this.gameState.isActive) {
            console.log('Game is not active, cancelling bubble spawn.');
            return;
        }

        const maxBubbleFloatDuration = 3.0; 
        const reactionBuffer = 0.5; 
        
        if (this.gameState.timeLeft < (maxBubbleFloatDuration + reactionBuffer)) { 
            console.log("Not enough time left for bubble to fully appear and be interactable. Skipping spawn.");
            return; 
        }

        const bubble = document.createElement('div') as BubbleElement;
        bubble.className = 'bubble';

        const sizes: BubbleSize[] = ['small', 'medium', 'large'];
        const sizeClass = sizes[Math.floor(Math.random() * sizes.length)];
        bubble.classList.add(sizeClass);

        const areaRect = this.elements.bubbleArea.getBoundingClientRect();
        const bubbleSize = 60;
        const margin = 40;
        const availableWidth = areaRect.width - (2 * margin) - bubbleSize;
        const startX = margin + (Math.random() * availableWidth);

        bubble.style.left = startX + 'px';
        bubble.style.bottom = '-60px';

        const duration = 1.8 + Math.random() * 1.8; 
        console.log('Spawning bubble with duration:', duration, 'seconds, timeout in:', duration * 1000, 'ms');
        bubble.style.animationDuration = duration + 's';

        bubble.addEventListener('click', (event: MouseEvent) => {
            console.log('Bubble click detected!');
            this.popBubble(bubble);
        });
        bubble.addEventListener('mousedown', (event: MouseEvent) => {
            console.log('Bubble mousedown detected!');
            this.popBubble(bubble);
        });
        bubble.addEventListener('touchstart', (event: TouchEvent) => {
            console.log('Bubble touchstart detected!');
            this.popBubble(bubble);
        });
        bubble.onclick = () => {
            console.log('Bubble onclick detected!');
            this.popBubble(bubble);
        };

        const timeToReachTop = (420 / 440) * duration;
        
        const timeout = setTimeout(() => {
            console.log('Timeout firing for bubble - game active:', this.gameState.isActive, 'bubble in DOM:', !!bubble.parentNode, 'has popping class:', bubble.classList.contains('popping'));
            if (this.gameState.isActive && bubble.parentNode && !bubble.classList.contains('popping')) {
                this.missBubble(bubble);
            }
            this.bubbleTimeouts.delete(timeout);
            console.log('Timeout cleanup - remaining timeouts:', this.bubbleTimeouts.size);
        }, timeToReachTop * 1000);
        this.bubbleTimeouts.add(timeout);
        console.log('Created timeout - total timeouts:', this.bubbleTimeouts.size);

        this.elements.bubbleArea.appendChild(bubble);
        this.gameState.activeBubbles.push(bubble);
    }

    private popBubble(bubble: HTMLElement): void {
        console.log('popBubble called - isActive:', this.gameState.isActive, 'already popping:', bubble.classList.contains('popping'));
        if (!this.gameState.isActive || bubble.classList.contains('popping')) {
            console.log('Game not active or bubble already popping, ignoring pop.');
            return;
        }

        bubble.classList.add('popping');
        console.log('Bubble successfully popped! Total popped (before increment):', this.gameState.bubblesPopped);
        
        this.gameState.bubblesPopped++;

        this.showScorePopup(bubble);

        this.gameState.activeBubbles = this.gameState.activeBubbles.filter(b => b !== bubble);
        console.log('Removed bubble from active array. Remaining active bubbles:', this.gameState.activeBubbles.length);

        setTimeout(() => {
            if (bubble.parentNode) {
                bubble.remove();
                console.log('Bubble DOM element removed.');
            }
        }, 300);

        setTimeout(() => {
            this.gameState.activeBubbles.forEach(activeBubble => {
                activeBubble.style.pointerEvents = 'auto';
                activeBubble.style.zIndex = '999';
            });
        }, 100);

        this.checkWinCondition();
    }

    private missBubble(bubble: HTMLElement): void {
        console.log('missBubble called - isActive:', this.gameState.isActive, 'currentMisses:', this.gameState.bubblesMissed);
        
        if (!this.gameState.isActive) {
            console.log('Game not active, ignoring miss and preventing further actions.');
            return;
        }

        const bubbleIndex = this.gameState.activeBubbles.indexOf(bubble);
        if (bubbleIndex === -1) {
            console.log('Bubble not in active array, ignoring miss (already popped or removed).');
            return;
        }

        this.gameState.bubblesMissed++;
        console.log('Bubble missed! Total misses:', this.gameState.bubblesMissed, '/', this.gameState.maxMisses);

        this.gameState.activeBubbles = this.gameState.activeBubbles.filter(b => b !== bubble);
        
        if (bubble.parentNode) {
            bubble.remove();
            console.log('Missed bubble DOM element removed.');
        }

        if (this.gameState.bubblesMissed >= this.gameState.maxMisses) {
            console.log('TOO MANY MISSES! Game ending as failure due to', this.gameState.bubblesMissed, 'misses.');
            this.endGameInstant(false);
        }
    }

    private showScorePopup(bubble: HTMLElement): void {
        const popup = document.createElement('div');
        popup.className = 'score-popup';
        popup.textContent = '+1';
        
        popup.style.left = bubble.style.left;
        popup.style.bottom = bubble.style.bottom;

        this.elements.bubbleArea.appendChild(popup);

        setTimeout(() => {
            if (popup.parentNode) {
                popup.remove();
            }
        }, 1000);
    }

    private checkWinCondition(): void {
        if (this.gameState.bubblesPopped >= this.gameState.targetBubbles) {
            console.log('Win condition met! Bubbles popped:', this.gameState.bubblesPopped, 'Target:', this.gameState.targetBubbles);
            this.endGameInstant(true);
        } else {
            console.log('Win condition not yet met. Popped:', this.gameState.bubblesPopped, 'Target:', this.gameState.targetBubbles);
        }
    }

    private endGameInstant(success: boolean): void {
        console.log('Ending game instantly. Success:', success);
        this.gameState.isActive = false;

        if (this.bubbleSpawnInterval) {
            clearInterval(this.bubbleSpawnInterval);
            this.bubbleSpawnInterval = null;
            console.log('Cleared bubble spawn interval.');
        }
        if (this.gameTimer) {
            clearInterval(this.gameTimer);
            this.gameTimer = null;
            console.log('Cleared game timer interval.');
        }

        this.bubbleTimeouts.forEach(timeout => {
            clearTimeout(timeout);
            console.log('Cleared individual bubble timeout.');
        });
        this.bubbleTimeouts.clear();
        console.log('All bubble timeouts cleared.');


        this.gameState.activeBubbles.forEach(bubble => {
            if (bubble.parentNode) {
                bubble.remove();
                console.log('Removed active bubble on game end.');
            }
        });
        this.gameState.activeBubbles = [];
        console.log('Cleared active bubbles array.');

        this.hideGame();
        this.sendResult(success);
    }

    private hideGame(): void {
        this.elements.container.classList.add('hidden');
        console.log('Minigame container hidden.');
    }

    private sendResult(success: boolean): void {
        const result: MinigameResult = { success };
        console.log('Sending minigame result to NUI callback:', result);
        
        fetch(`https://${GetParentResourceName()}/minigameResult`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(result)
        });
    }

    private forceReset(): void {
        console.log('Force reset called. Current state - isActive:', this.gameState.isActive, 'timeouts:', this.bubbleTimeouts.size, 'bubbles:', this.gameState.activeBubbles.length);
        
        this.gameState.isActive = false;

        if (this.bubbleSpawnInterval) {
            clearInterval(this.bubbleSpawnInterval);
            this.bubbleSpawnInterval = null;
            console.log('Force reset: Cleared bubble spawn interval.');
        }
        if (this.gameTimer) {
            clearInterval(this.gameTimer);
            this.gameTimer = null;
            console.log('Force reset: Cleared game timer interval.');
        }

        this.bubbleTimeouts.forEach(timeout => {
            clearTimeout(timeout);
            console.log('Force reset: Cleared individual bubble timeout.');
        });
        this.bubbleTimeouts.clear();
        console.log('Force reset: All bubble timeouts cleared.');

        this.gameState.activeBubbles.forEach(bubble => {
            if (bubble.parentNode) {
                bubble.remove();
                console.log('Force reset: Removed active bubble from DOM.');
            }
        });
        this.gameState.activeBubbles = [];
        console.log('Force reset: Cleared active bubbles array.');

        const bubbleArea = this.elements.bubbleArea;
        while (bubbleArea.firstChild) {
            bubbleArea.removeChild(bubbleArea.firstChild);
        }
        console.log('Force reset: Cleared bubble area children.');

        const overlays = this.elements.container.querySelectorAll('.result-overlay');
        overlays.forEach(overlay => {
            overlay.remove();
            console.log('Force reset: Removed result overlay.');
        });

        const oldBubbleArea = this.elements.bubbleArea;
        const parent = oldBubbleArea.parentNode;
        const newBubbleArea = oldBubbleArea.cloneNode(false) as HTMLElement;
        newBubbleArea.id = 'bubble-area';
        newBubbleArea.className = 'bubble-area';
        
        if (parent) {
            parent.replaceChild(newBubbleArea, oldBubbleArea);
            this.elements.bubbleArea = newBubbleArea;
            console.log('Force reset: Completely recreated bubble area DOM element.');
        }
        
        this.gameState = {
            isActive: false,
            bubblesPopped: 0,
            bubblesMissed: 0,
            timeLeft: 0,
            targetBubbles: 0,
            maxMisses: 5,
            activeBubbles: []
        };
        
        console.log('Force reset complete. Game state reset:', this.gameState);
    }
}

new BubbleMinigame();

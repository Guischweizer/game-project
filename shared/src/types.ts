export interface User {
  id: string;
  username: string;
  email: string;
}

export interface GameScore {
  id: string;
  userId: string;
  username: string;
  score: number;
  playedAt: Date;
}

export interface Ticket {
  id: string;
  userId: string;
  used: boolean;
  acquiredAt: Date;
  usedAt?: Date;
}

export interface LeaderboardEntry {
  userId: string;
  username: string;
  highScore: number;
  gamesPlayed: number;
}

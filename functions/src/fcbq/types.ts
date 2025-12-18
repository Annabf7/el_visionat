// ============================================================================
// FCBQ Types - Definicions de tipus per a l'integració amb la FCBQ
// ============================================================================

/**
 * Representa un equip en un partit
 */
export interface TeamInfo {
  name: string;
  logo: string; // nom del fitxer .webp (slug generat)
  fcbqId?: string; // ID intern de la FCBQ (opcional, per futures extensions)
}

/**
 * Estat d'un partit
 */
export type MatchStatus = "scheduled" | "live" | "finished" | "postponed" | "suspended";

/**
 * Representa un partit individual
 * Mantenim compatibilitat amb l'estructura actual de MatchSeed
 */
export interface MatchData {
  jornada: number;
  home: TeamInfo;
  away: TeamInfo;
  dateTime: string; // ISO 8601 format: "YYYY-MM-DDTHH:mm:ss"
  timezone: string; // "Europe/Madrid"
  gender: "male" | "female";
  source: string; // "fcbq-scraper" o similar
  // Camps opcionals nous (no trencadors)
  status?: MatchStatus;
  homeScore?: number;
  awayScore?: number;
  venue?: string;
  matchId?: string; // ID del partit a la FCBQ
  streamingUrl?: string;
}

/**
 * Representa un equip a la classificació
 */
export interface StandingEntry {
  position: number;
  teamName: string;
  teamId?: string;
  played: number; // J (jugats)
  won: number; // G (guanyats)
  lost: number; // P (perduts)
  notPlayed: number; // NP (no presentats)
  pointsFor: number; // PF (punts a favor)
  pointsAgainst: number; // PC (punts en contra)
  points: number; // Punts classificació
  streak?: string; // Ratxa (opcional)
}

/**
 * Resposta completa d'una jornada
 */
export interface JornadaResponse {
  jornada: number;
  competitionId: string; // "19795" per Super Copa Masculina
  competitionName: string;
  partits: MatchData[];
  classificacio: StandingEntry[];
  // Metadades
  fetchedAt: string; // ISO timestamp
  source: "fcbq-live" | "fcbq-cache";
  cacheExpiresAt?: string; // ISO timestamp
}

/**
 * Paràmetres de la petició
 */
export interface FetchJornadaRequest {
  jornada: number; // 1-30
  competitionId?: string; // Per defecte "19795" (Super Copa Masculina)
  forceRefresh?: boolean; // Ignorar cache i fer scraping fresh
}

/**
 * Configuració del scraper
 */
export interface ScraperConfig {
  baseUrl: string;
  competitionId: string;
  cacheTtlMinutes: number;
  maxRetries: number;
  timeoutMs: number;
}

export const DEFAULT_SCRAPER_CONFIG: ScraperConfig = {
  baseUrl: "https://www.basquetcatala.cat/competicions/resultats",
  competitionId: "19795", // Super Copa Masculina
  cacheTtlMinutes: 60, // 1 hora de cache
  maxRetries: 3,
  timeoutMs: 15000,
};

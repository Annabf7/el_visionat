// ============================================================================
// FCBQ Module - Index d'exportació
// ============================================================================

// Cloud Functions existents per fetch de jornades
export {fetchJornada, fetchMultipleJornades, clearJornadaCache} from "./fetch_jornada";

// Cloud Functions per sincronització de votacions
export {
  syncWeeklyVoting,
  triggerSyncWeeklyVoting,
  getActiveVotingJornada,
  closeSuggestions,
} from "./sync_weekly_voting";

// Utilitats de scraping
export {scrapeJornada, parseMatches, parseStandings} from "./scraper";

// Utilitats de mapping d'equips
export {mapFcbqTeam, mapMultipleTeams, getAllTeams, getTeamsByGender} from "./team_mapper";

// Tipus
export * from "./types";

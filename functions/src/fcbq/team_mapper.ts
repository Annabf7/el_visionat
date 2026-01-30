// ============================================================================
// Team Mapper - Mapeja noms FCBQ als IDs locals
// ============================================================================
// Llegeix les dades d'equips des de supercopa_teams.json (font única de veritat)
// i proporciona funcions per mapejar noms de la FCBQ als IDs locals.
// ============================================================================

import * as fs from "fs";
import * as path from "path";

/**
 * Representació d'un equip del diccionari local
 */
export interface LocalTeam {
  id: string;
  name: string;
  acronym: string;
  gender: "Masculina" | "Femenina";
  colorHex: string;
  logoAssetPath: string | null;
  aliases: string[];
}

/**
 * Resultat del mapping d'un equip
 */
export interface TeamMappingResult {
  found: boolean;
  teamId: string | null;
  teamNameRaw: string; // Nom original de la FCBQ
  teamNameNormalized: string | null; // Nom del diccionari local
  logoSlug: string; // Generat automàticament per fallback
  colorHex: string | null; // Color de l'equip
  matchType?: "exact" | "normalized" | "alias" | "not-found";
}

// ============================================================================
// Càrrega del JSON d'equips
// ============================================================================

let SUPERCOPA_TEAMS: LocalTeam[] = [];
let teamsLoaded = false;

/**
 * Carrega les dades d'equips des del JSON
 * Això es fa una sola vegada (lazy loading)
 */
function loadTeamsData(): void {
  if (teamsLoaded) return;

  try {
    // Provem múltiples paths possibles:
    // 1. lib/data/ (quan es copia amb copyfiles)
    // 2. Relatiu a lib/fcbq/ (path antic)
    // 3. src/data/ (per desenvolupament local)
    const possiblePaths = [
      path.join(__dirname, "..", "data", "supercopa_teams.json"),
      path.join(__dirname, "data", "supercopa_teams.json"),
      path.join(__dirname, "..", "..", "src", "data", "supercopa_teams.json"),
    ];

    for (const jsonPath of possiblePaths) {
      if (fs.existsSync(jsonPath)) {
        const rawData = fs.readFileSync(jsonPath, "utf-8");
        SUPERCOPA_TEAMS = JSON.parse(rawData) as LocalTeam[];
        teamsLoaded = true;
        console.log(`[TeamMapper] Carregats ${SUPERCOPA_TEAMS.length} equips des de ${jsonPath}`);
        return;
      }
    }

    throw new Error(`JSON no trobat a cap dels paths: ${possiblePaths.join(", ")}`);
  } catch (error) {
    console.error("[TeamMapper] Error carregant supercopa_teams.json:", error);
    // Fallback: array buit (el mapping fallarà però no crashejarà)
    SUPERCOPA_TEAMS = [];
    teamsLoaded = true;
  }
}

// ============================================================================
// Utilitats
// ============================================================================

/**
 * Normalitza un nom d'equip per comparació
 * - Converteix a majúscules
 * - Elimina accents
 * - Elimina puntuació i espais extres
 */
function normalizeTeamName(name: string): string {
  return name
    .toUpperCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "") // Elimina accents
    .replace(/[^A-Z0-9\s]/g, " ") // Substitueix puntuació per espais
    .replace(/\s+/g, " ") // Normalitza espais múltiples
    .trim();
}

/**
 * Genera un slug per al logo de l'equip a partir del nom
 */
function generateLogoSlug(teamName: string): string {
  return (
    teamName
      .toLowerCase()
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/[^a-z0-9\s-]/g, "")
      .trim()
      .replace(/\s+/g, "-") + ".webp"
  );
}

// Cache de noms normalitzats per optimitzar cerques
const normalizedNameCache = new Map<string, LocalTeam>();
const aliasCache = new Map<string, LocalTeam>();
let cachesInitialized = false;

/**
 * Inicialitza els caches de cerca
 */
function initCaches(): void {
  if (cachesInitialized) return;

  loadTeamsData();

  for (const team of SUPERCOPA_TEAMS) {
    // Cache per nom exacte normalitzat
    normalizedNameCache.set(normalizeTeamName(team.name), team);

    // Cache per aliases normalitzats
    for (const alias of team.aliases) {
      aliasCache.set(normalizeTeamName(alias), team);
    }
  }

  cachesInitialized = true;
  console.log(
    `[TeamMapper] Caches inicialitzats: ${normalizedNameCache.size} noms, ${aliasCache.size} aliases`
  );
}

// ============================================================================
// Funcions públiques
// ============================================================================

/**
 * Busca un equip pel seu nom de la FCBQ
 * Prova en ordre:
 * 1. Match exacte (case-insensitive)
 * 2. Match normalitzat (sense accents/puntuació)
 * 3. Match per aliases
 * 4. Retorna fallback amb logoSlug generat
 */
export function mapFcbqTeam(fcbqName: string): TeamMappingResult {
  initCaches();

  const fcbqNameUpper = fcbqName.toUpperCase().trim();
  const fcbqNameNormalized = normalizeTeamName(fcbqName);

  // 1. Match exacte
  const exactMatch = SUPERCOPA_TEAMS.find(
    (t) => t.name.toUpperCase() === fcbqNameUpper
  );
  if (exactMatch) {
    return {
      found: true,
      teamId: exactMatch.id,
      teamNameRaw: fcbqName,
      teamNameNormalized: exactMatch.name,
      colorHex: exactMatch.colorHex,
      logoSlug: exactMatch.logoAssetPath ?
        exactMatch.logoAssetPath.split("/").pop()! :
        generateLogoSlug(fcbqName),
      matchType: "exact",
    };
  }

  // 2. Match normalitzat
  const normalizedMatch = normalizedNameCache.get(fcbqNameNormalized);
  if (normalizedMatch) {
    return {
      found: true,
      teamId: normalizedMatch.id,
      teamNameRaw: fcbqName,
      teamNameNormalized: normalizedMatch.name,
      colorHex: normalizedMatch.colorHex,
      logoSlug: normalizedMatch.logoAssetPath ?
        normalizedMatch.logoAssetPath.split("/").pop()! :
        generateLogoSlug(fcbqName),
      matchType: "normalized",
    };
  }

  // 3. Match per alias
  const aliasMatch = aliasCache.get(fcbqNameNormalized);
  if (aliasMatch) {
    return {
      found: true,
      teamId: aliasMatch.id,
      teamNameRaw: fcbqName,
      teamNameNormalized: aliasMatch.name,
      colorHex: aliasMatch.colorHex,
      logoSlug: aliasMatch.logoAssetPath ?
        aliasMatch.logoAssetPath.split("/").pop()! :
        generateLogoSlug(fcbqName),
      matchType: "alias",
    };
  }

  // 4. No trobat - retorna sense logoSlug (el frontend mostrarà inicials)
  console.warn(`[TeamMapper] ⚠️ Equip no trobat: "${fcbqName}" (normalitzat: "${fcbqNameNormalized}")`);
  return {
    found: false,
    teamId: null,
    teamNameRaw: fcbqName,
    teamNameNormalized: null,
    colorHex: null,
    logoSlug: "", // Buit - no generar slugs invàlids
    matchType: "not-found",
  };
}

/**
 * Busca múltiples equips i retorna estadístiques
 */
export function mapMultipleTeams(fcbqNames: string[]): {
  results: TeamMappingResult[];
  stats: {
    total: number;
    found: number;
    notFound: number;
    byMatchType: Record<string, number>;
  };
  notFoundNames: string[];
} {
  const results = fcbqNames.map(mapFcbqTeam);

  const notFoundNames = results
    .filter((r) => !r.found)
    .map((r) => r.teamNameRaw);

  const stats = {
    total: results.length,
    found: results.filter((r) => r.found).length,
    notFound: results.filter((r) => !r.found).length,
    byMatchType: {
      "exact": results.filter((r) => r.matchType === "exact").length,
      "normalized": results.filter((r) => r.matchType === "normalized").length,
      "alias": results.filter((r) => r.matchType === "alias").length,
      "not-found": results.filter((r) => r.matchType === "not-found").length,
    },
  };

  return {results, stats, notFoundNames};
}

/**
 * Obté tots els equips del diccionari
 */
export function getAllTeams(): LocalTeam[] {
  loadTeamsData();
  return [...SUPERCOPA_TEAMS];
}

/**
 * Obté equips per gènere
 */
export function getTeamsByGender(gender: "Masculina" | "Femenina"): LocalTeam[] {
  loadTeamsData();
  return SUPERCOPA_TEAMS.filter((t) => t.gender === gender);
}

/**
 * Reinicia els caches (útil per a testing)
 */
export function resetCaches(): void {
  normalizedNameCache.clear();
  aliasCache.clear();
  cachesInitialized = false;
  teamsLoaded = false;
  SUPERCOPA_TEAMS = [];
}

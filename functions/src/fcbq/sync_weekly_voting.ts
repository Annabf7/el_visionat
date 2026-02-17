// ============================================================================
// syncWeeklyVoting - Cloud Function programada per sincronitzar votacions
// ============================================================================
// Aquesta funció s'executa cada dilluns a les 8:00 AM (Europe/Madrid)
// i prepara les dades de votació per al cap de setmana següent.
//
// LÒGICA DE SELECCIÓ DE JORNADA (amb signatures):
// 1. Calcula el rang del proper cap de setmana (dissabte 00:00 - diumenge 23:59)
// 2. Escaneja un rang petit de jornades candidates (estimada ± 3)
// 3. Per cada partit del cap de setmana, genera una "signatura" (home|away|dateTime)
// 4. Si la mateixa signatura apareix en múltiples jornades → tria la més alta
// 5. Si hi ha signatures diferents → tria la jornada amb més partits
// 6. Només si no hi ha candidats en el rang petit, escanejem fins a 30
// ============================================================================

import {onSchedule} from "firebase-functions/v2/scheduler";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {scrapeJornada, fetchActaInfo, fetchFcbqPage} from "./scraper";
import * as cheerio from "cheerio";
import {mapFcbqTeam, TeamMappingResult} from "./team_mapper";
import {MatchData, StandingEntry, RefereeInfo, DEFAULT_SCRAPER_CONFIG} from "./types";

const db = admin.firestore();

// ============================================================================
// Tipus específics per a votació
// ============================================================================

export interface VotingTeamInfo {
  teamId: string | null;
  teamNameRaw: string;
  teamNameDisplay: string;
  logoSlug: string;
  colorHex: string | null;
}

export interface VotingMatch {
  matchId: string;
  jornada: number;
  home: VotingTeamInfo;
  away: VotingTeamInfo;
  dateTime: string;
  dateDisplay: string;
  status: "scheduled" | "live" | "finished" | "postponed" | "suspended";
  homeScore?: number;
  awayScore?: number;
}

export interface VotingJornadaDocument {
  jornada: number;
  competitionId: string;
  competitionName: string;
  matches: VotingMatch[];
  classification: StandingEntry[];
  weekendStart: string;
  weekendEnd: string;
  publishedAt: string;
  updatedAt: string;
  source: "fcbq-scraper";
  mappingStats: {
    totalTeams: number;
    foundTeams: number;
    notFoundTeams: number;
  };
}

export interface VotingMetaDocument {
  activeJornada: number;
  weekendStart: string;
  weekendEnd: string;
  publishedAt: string;
  matchCount: number;
}

/**
 * Document que representa el focus setmanal: partit guanyador + àrbitres
 * Es guarda a weekly_focus/current i weekly_focus/jornada_{n}
 */
export interface WeeklyFocusDocument {
  jornada: number;
  winningMatch: VotingMatch;
  totalVotes: number;
  refereeInfo: RefereeInfo | null;
  votingClosedAt: string;
  suggestionsOpen: boolean;
  suggestionsCloseAt: string; // Dimecres 15:00
  status: "minutatge" | "entrevista_pendent" | "completat";
}

// ============================================================================
// Tipus interns per a la selecció de jornada
// ============================================================================

interface MatchSignature {
  signature: string; // "homeNormalized|awayNormalized|dateTime"
  match: MatchData;
}

interface JornadaCandidate {
  jornada: number;
  signatures: Set<string>;
  matches: MatchData[];
  standings: StandingEntry[];
}

// ============================================================================
// Utilitats de dates
// ============================================================================

function getNextSaturday(from: Date): Date {
  const result = new Date(from);
  const dayOfWeek = result.getDay();
  const daysUntilSaturday = (6 - dayOfWeek + 7) % 7 || 7;
  result.setDate(result.getDate() + daysUntilSaturday);
  result.setHours(0, 0, 0, 0);
  return result;
}

function getSundayAfter(saturday: Date): Date {
  const result = new Date(saturday);
  result.setDate(result.getDate() + 1);
  result.setHours(23, 59, 59, 999);
  return result;
}

function isDateInRange(dateStr: string, start: Date, end: Date): boolean {
  const date = new Date(dateStr);
  return date >= start && date <= end;
}

function formatDateDisplay(isoDateStr: string): string {
  const date = new Date(isoDateStr);
  const days = ["Diumenge", "Dilluns", "Dimarts", "Dimecres", "Dijous", "Divendres", "Dissabte"];
  const months = ["Gener", "Febrer", "Març", "Abril", "Maig", "Juny", "Juliol", "Agost", "Setembre", "Octubre", "Novembre", "Desembre"];
  const dayName = days[date.getDay()];
  const dayNum = date.getDate();
  const monthName = months[date.getMonth()];
  const hours = date.getHours().toString().padStart(2, "0");
  const minutes = date.getMinutes().toString().padStart(2, "0");
  return `${dayName} ${dayNum} ${monthName}, ${hours}:${minutes}`;
}

// ============================================================================
// Utilitats de signatures
// ============================================================================

/**
 * Normalitza un nom d'equip per generar signatures consistents
 */
function normalizeForSignature(name: string): string {
  return name
    .toUpperCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^A-Z0-9]/g, "")
    .trim();
}

/**
 * Genera una signatura única per a un partit
 * Format: "HOME|AWAY|DATETIME"
 */
function generateMatchSignature(match: MatchData): string {
  const homeNorm = normalizeForSignature(match.home.name);
  const awayNorm = normalizeForSignature(match.away.name);
  return `${homeNorm}|${awayNorm}|${match.dateTime}`;
}

// ============================================================================
// Lògica de transformació
// ============================================================================

function transformToVotingMatch(match: MatchData): VotingMatch {
  const homeMapping = mapFcbqTeam(match.home.name);
  const awayMapping = mapFcbqTeam(match.away.name);
  const homeTeam = teamMappingToVotingTeam(homeMapping);
  const awayTeam = teamMappingToVotingTeam(awayMapping);

  // Generar matchId: usar logoSlug si existeix, sinó normalitzar el nom
  const homeSlug = homeTeam.logoSlug ?
    homeTeam.logoSlug.replace(".webp", "") :
    normalizeForSignature(match.home.name).toLowerCase();
  const awaySlug = awayTeam.logoSlug ?
    awayTeam.logoSlug.replace(".webp", "") :
    normalizeForSignature(match.away.name).toLowerCase();
  const matchId = `${match.jornada}-${homeSlug}-${awaySlug}`;

  const votingMatch: VotingMatch = {
    matchId,
    jornada: match.jornada,
    home: homeTeam,
    away: awayTeam,
    dateTime: match.dateTime,
    dateDisplay: formatDateDisplay(match.dateTime),
    status: match.status || "scheduled",
  };

  if (match.homeScore !== undefined) votingMatch.homeScore = match.homeScore;
  if (match.awayScore !== undefined) votingMatch.awayScore = match.awayScore;

  return votingMatch;
}

function teamMappingToVotingTeam(mapping: TeamMappingResult): VotingTeamInfo {
  return {
    teamId: mapping.teamId,
    teamNameRaw: mapping.teamNameRaw,
    teamNameDisplay: mapping.teamNameNormalized || mapping.teamNameRaw,
    logoSlug: mapping.logoSlug,
    colorHex: mapping.colorHex,
  };
}

// ============================================================================
// NOVA LÒGICA: Selecció de jornada amb signatures
// ============================================================================

/**
 * Escaneja jornades candidates i selecciona la millor pel cap de setmana.
 *
 * Estratègia amb signatures:
 * 1. Primer escanegem un rang petit (estimada ± 3)
 * 2. Si no trobem res, ampliem fins a 30
 * 3. Per cada partit del cap de setmana, generem signatura (home|away|dateTime)
 * 4. Si múltiples jornades tenen la mateixa signatura → triem la més alta
 * 5. Si tenen signatures diferents → triem la jornada amb més partits
 */
async function findWeekendJornada(
  saturdayStart: Date,
  sundayEnd: Date
): Promise<{
  jornada: number;
  matches: MatchData[];
  standings: StandingEntry[];
  reason: string;
} | null> {
  console.log("\n" + "=".repeat(60));
  console.log("[findWeekendJornada] Iniciant cerca de jornada");
  console.log(`[findWeekendJornada] Rang: ${saturdayStart.toISOString()} - ${sundayEnd.toISOString()}`);
  console.log("=".repeat(60));

  // Estimem la jornada actual basant-nos en la temporada
  const now = new Date();
  const seasonStart = new Date(now.getFullYear(), 9, 1); // 1 octubre
  const weeksFromStart = Math.floor((now.getTime() - seasonStart.getTime()) / (7 * 24 * 60 * 60 * 1000));
  const estimatedJornada = Math.max(1, Math.min(30, weeksFromStart + 1));

  console.log(`[findWeekendJornada] Jornada estimada: ${estimatedJornada} (${weeksFromStart} setmanes des d'octubre)`);

  // FASE 1: Escanejem rang petit (estimada +0 a +5, després -1 a -3)
  const smallRange = [
    ...Array.from({length: 6}, (_, i) => estimatedJornada + i).filter((j) => j <= 30),
    ...Array.from({length: 3}, (_, i) => estimatedJornada - i - 1).filter((j) => j >= 1),
  ];

  console.log(`[findWeekendJornada] Fase 1: escaneig rang petit [${smallRange.join(", ")}]`);

  let result = await scanJornadasWithSignatures(smallRange, saturdayStart, sundayEnd);

  // FASE 2: Si no hem trobat res, ampliem a totes les jornades
  if (!result) {
    console.log("[findWeekendJornada] Fase 2: no s'ha trobat res, ampliant a rang complet 1-30");
    const fullRange = Array.from({length: 30}, (_, i) => i + 1).filter((j) => !smallRange.includes(j));
    result = await scanJornadasWithSignatures(fullRange, saturdayStart, sundayEnd);
  }

  if (result) {
    console.log("\n" + "=".repeat(60));
    console.log(`[findWeekendJornada] ✅ RESULTAT FINAL: Jornada ${result.jornada}`);
    console.log(`[findWeekendJornada] Partits: ${result.matches.length}`);
    console.log(`[findWeekendJornada] Motiu: ${result.reason}`);
    console.log("=".repeat(60) + "\n");
  } else {
    console.log("\n[findWeekendJornada] ❌ No s'ha trobat cap jornada amb partits pel cap de setmana\n");
  }

  return result;
}

/**
 * Escaneja una llista de jornades i selecciona la millor segons signatures
 */
async function scanJornadasWithSignatures(
  jornadas: number[],
  saturdayStart: Date,
  sundayEnd: Date
): Promise<{
  jornada: number;
  matches: MatchData[];
  standings: StandingEntry[];
  reason: string;
} | null> {
  // Mapa de signatura → jornades on apareix
  const signatureToJornadas = new Map<string, number[]>();

  // Llista de candidats amb les seves dades
  const candidates: JornadaCandidate[] = [];

  // Escanejem cada jornada
  for (const jornada of jornadas) {
    try {
      console.log(`[scanJornadasWithSignatures] Escanejant jornada ${jornada}...`);

      const {matches, standings} = await scrapeJornada(jornada, DEFAULT_SCRAPER_CONFIG);

      // Filtrem partits del cap de setmana
      const weekendMatches = matches.filter((m) => isDateInRange(m.dateTime, saturdayStart, sundayEnd));

      if (weekendMatches.length === 0) {
        console.log(`  └─ Jornada ${jornada}: 0 partits del cap de setmana`);
        continue;
      }

      // Generem signatures
      const signatures = new Set<string>();
      for (const match of weekendMatches) {
        const sig = generateMatchSignature(match);
        signatures.add(sig);

        // Registrem a quin jornada apareix aquesta signatura
        if (!signatureToJornadas.has(sig)) {
          signatureToJornadas.set(sig, []);
        }
        signatureToJornadas.get(sig)!.push(jornada);
      }

      console.log(`  └─ Jornada ${jornada}: ${weekendMatches.length} partits, ${signatures.size} signatures úniques`);

      candidates.push({
        jornada,
        signatures,
        matches: weekendMatches,
        standings,
      });

      // Delay per no sobrecarregar la FCBQ
      await new Promise((resolve) => setTimeout(resolve, 200));
    } catch (error) {
      console.warn(`  └─ Jornada ${jornada}: ERROR - ${error}`);
    }
  }

  if (candidates.length === 0) {
    return null;
  }

  // Log de signatures compartides
  console.log("\n[scanJornadasWithSignatures] Anàlisi de signatures:");
  for (const [sig, jornades] of signatureToJornadas) {
    if (jornades.length > 1) {
      console.log(`  └─ Signatura duplicada en jornades [${jornades.join(", ")}]: ${sig.substring(0, 50)}...`);
    }
  }

  // DECISIÓ: Triem la millor jornada
  return selectBestJornada(candidates, signatureToJornadas);
}

/**
 * Selecciona la millor jornada basant-se en signatures
 *
 * Regles:
 * 1. Si hi ha signatures duplicades entre jornades → la jornada més alta guanya
 * 2. Si no hi ha duplicats → la jornada amb més partits únics guanya
 * 3. En cas d'empat → la jornada més alta guanya
 */
function selectBestJornada(
  candidates: JornadaCandidate[],
  signatureToJornadas: Map<string, number[]>
): {
  jornada: number;
  matches: MatchData[];
  standings: StandingEntry[];
  reason: string;
} {
  // Comptem signatures duplicades per jornada
  const jornadaScores = new Map<number, {unique: number; duplicated: number; total: number}>();

  for (const candidate of candidates) {
    let unique = 0;
    let duplicated = 0;

    for (const sig of candidate.signatures) {
      const jornadesAmbSig = signatureToJornadas.get(sig) || [];
      if (jornadesAmbSig.length === 1) {
        unique++;
      } else {
        // Signatura duplicada - només compta si som la jornada més alta
        const maxJornada = Math.max(...jornadesAmbSig);
        if (candidate.jornada === maxJornada) {
          duplicated++;
        }
      }
    }

    jornadaScores.set(candidate.jornada, {
      unique,
      duplicated,
      total: unique + duplicated,
    });

    console.log(
      `[selectBestJornada] Jornada ${candidate.jornada}: ` +
      `${unique} úniques, ${duplicated} duplicades (guanyades), total efectiu: ${unique + duplicated}`
    );
  }

  // Ordenem per: total efectiu (desc), després per jornada (desc)
  const sorted = [...candidates].sort((a, b) => {
    const scoreA = jornadaScores.get(a.jornada)!;
    const scoreB = jornadaScores.get(b.jornada)!;

    // Primer per total de partits efectius
    if (scoreB.total !== scoreA.total) {
      return scoreB.total - scoreA.total;
    }

    // En cas d'empat, la jornada més alta
    return b.jornada - a.jornada;
  });

  const winner = sorted[0];
  const winnerScore = jornadaScores.get(winner.jornada)!;

  let reason: string;
  if (candidates.length === 1) {
    reason = "Única jornada amb partits del cap de setmana";
  } else if (winnerScore.duplicated > 0) {
    reason = `Jornada més alta amb signatures duplicades (${winnerScore.duplicated} partits recuperats de jornades anteriors)`;
  } else {
    reason = `Jornada amb més partits únics (${winnerScore.unique} partits)`;
  }

  return {
    jornada: winner.jornada,
    matches: winner.matches,
    standings: winner.standings,
    reason,
  };
}

// ============================================================================
// Processar guanyador de votació
// ============================================================================

/**
 * Calcula el proper dimecres a les 15:00 des d'una data donada
 */
function getNextWednesday15h(from: Date): Date {
  const result = new Date(from);
  const dayOfWeek = result.getDay();
  // Dimecres és 3
  const daysUntilWednesday = (3 - dayOfWeek + 7) % 7 || 7;
  result.setDate(result.getDate() + daysUntilWednesday);
  result.setHours(15, 0, 0, 0);
  return result;
}

/**
 * Processa la jornada anterior quan es tanca:
 * 1. Calcula el partit més votat
 * 2. Extreu la info dels àrbitres de l'acta
 * 3. Guarda tot a weekly_focus/current
 */
async function processVotingWinner(previousJornada: number): Promise<void> {
  console.log(`[processVotingWinner] 🏆 Processant guanyador de jornada ${previousJornada}...`);

  // 1. Obtenir tots els vots de la jornada
  const votesSnapshot = await db.collection("vote_counts")
    .where("jornada", "==", previousJornada)
    .orderBy("count", "desc")
    .limit(10)
    .get();

  if (votesSnapshot.empty) {
    console.log(`[processVotingWinner] ⚠️ No hi ha vots per la jornada ${previousJornada}`);
    return;
  }

  // El primer és el guanyador
  const winnerDoc = votesSnapshot.docs[0];
  const winnerData = winnerDoc.data();
  const winningMatchId = winnerData.matchId;
  const totalVotes = winnerData.count;

  console.log(`[processVotingWinner] 🥇 Partit guanyador: ${winningMatchId} amb ${totalVotes} vots`);

  // 2. Obtenir les dades completes del partit guanyador
  const jornadaDoc = await db.collection("voting_jornades").doc(previousJornada.toString()).get();

  if (!jornadaDoc.exists) {
    console.log(`[processVotingWinner] ⚠️ No es troba voting_jornades/${previousJornada}`);
    return;
  }

  const jornadaData = jornadaDoc.data() as VotingJornadaDocument;
  const winningMatch = jornadaData.matches.find((m) => m.matchId === winningMatchId);

  if (!winningMatch) {
    console.log(`[processVotingWinner] ⚠️ No es troba el partit ${winningMatchId} a la jornada`);
    return;
  }

  // 3. Extreure info dels àrbitres si hi ha URL de l'acta
  let refereeInfo: RefereeInfo | null = null;

  // Busquem l'acta URL del partit original (necessitem l'MatchData original)
  // L'acta URL s'extreu durant el scraping, però no la guardem al VotingMatch
  // Fem un scraping ràpid per obtenir-la
  try {
    const scrapedData = await scrapeJornada(previousJornada);

    // Normalitzem els noms dels equips per fer una cerca més robusta
    const targetHomeNorm = normalizeForSignature(winningMatch.home.teamNameRaw);
    const targetAwayNorm = normalizeForSignature(winningMatch.away.teamNameRaw);

    console.log(`[processVotingWinner] 🔍 Buscant partit: ${targetHomeNorm} vs ${targetAwayNorm}`);
    console.log(`[processVotingWinner] Data esperada: ${winningMatch.dateTime}`);

    const originalMatch = scrapedData.matches.find((m) => {
      const homeNorm = normalizeForSignature(m.home.name);
      const awayNorm = normalizeForSignature(m.away.name);
      const dateMatch = m.dateTime === winningMatch.dateTime;

      console.log(`  └─ Comparant amb: ${homeNorm} vs ${awayNorm} (${m.dateTime})`);

      // Primer intentem match exacte amb data
      if (homeNorm === targetHomeNorm && awayNorm === targetAwayNorm && dateMatch) {
        console.log("  └─ ✅ Match exacte trobat!");
        return true;
      }

      // Si no, intentem match només per equips (pot haver-hi diferències mínimes de data)
      if (homeNorm === targetHomeNorm && awayNorm === targetAwayNorm) {
        console.log("  └─ ✅ Match per equips trobat (data diferent)");
        return true;
      }

      return false;
    });

    if (originalMatch?.actaUrl) {
      console.log(`[processVotingWinner] 📋 Partit trobat! Obtenint àrbitres de: ${originalMatch.actaUrl}`);
      refereeInfo = await fetchActaInfo(originalMatch.actaUrl);
      console.log(`[processVotingWinner] ✅ Àrbitre principal: ${refereeInfo.principal || "no trobat"}`);
      console.log(`[processVotingWinner] ✅ Àrbitre auxiliar: ${refereeInfo.auxiliar || "no trobat"}`);
      if (refereeInfo.anotador) console.log(`[processVotingWinner] 📝 Anotador: ${refereeInfo.anotador}`);
      if (refereeInfo.cronometrador) console.log(`[processVotingWinner] ⏱️ Cronometrador: ${refereeInfo.cronometrador}`);
    } else if (originalMatch) {
      // Partit trobat però sense actaUrl - busquem qualsevol altre partit amb els mateixos equips que tingui acta
      console.log("[processVotingWinner] ⚠️ Partit trobat però sense actaUrl. Buscant actes alternatives...");
      const alternativeMatch = scrapedData.matches.find((m) => {
        const homeNorm = normalizeForSignature(m.home.name);
        const awayNorm = normalizeForSignature(m.away.name);
        return (homeNorm === targetHomeNorm && awayNorm === targetAwayNorm && m.actaUrl) ||
               (awayNorm === targetHomeNorm && homeNorm === targetAwayNorm && m.actaUrl); // També invertit
      });

      if (alternativeMatch?.actaUrl) {
        console.log(`[processVotingWinner] 📋 Acta alternativa trobada: ${alternativeMatch.actaUrl}`);
        refereeInfo = await fetchActaInfo(alternativeMatch.actaUrl);
        console.log(`[processVotingWinner] ✅ Àrbitre principal: ${refereeInfo.principal || "no trobat"}`);
        console.log(`[processVotingWinner] ✅ Àrbitre auxiliar: ${refereeInfo.auxiliar || "no trobat"}`);
      } else {
        console.log("[processVotingWinner] ⚠️ No s'ha trobat cap acta disponible per aquest partit");
      }
    } else {
      console.log("[processVotingWinner] ⚠️ No s'ha trobat el partit a la jornada");
      console.log(`[processVotingWinner] 🔍 Partits disponibles a la jornada ${previousJornada}:`);
      scrapedData.matches.forEach((m) => {
        console.log(`  └─ ${m.home.name} vs ${m.away.name} (${m.dateTime}) - actaUrl: ${m.actaUrl || "no disponible"}`);
      });

      // FALLBACK: Cerca directa d'acta a la pàgina HTML per matching d'equips
      console.log("[processVotingWinner] 🔄 Intentant cerca directa d'acta a la pàgina HTML...");
      try {
        const html = await fetchFcbqPage(previousJornada);
        const $ = cheerio.load(html);

        // Busquem totes les actes i els seus equips propers
        $("a[href*='/acta/']").each((_, el) => {
          const href = $(el).attr("href");
          if (!href || refereeInfo) return; // Si ja hem trobat, sortim

          const container = $(el).closest(".row");
          const teamsInContainer: string[] = [];
          container.find("a.teamNameLink").each((__, teamEl) => {
            teamsInContainer.push(normalizeForSignature($(teamEl).text().trim()));
          });

          // Comprovem si els equips coincideixen
          if (teamsInContainer.includes(targetHomeNorm) || teamsInContainer.includes(targetAwayNorm)) {
            const actaUrl = href.startsWith("http") ? href : `https://www.basquetcatala.cat${href}`;
            console.log(`[processVotingWinner] 📋 Acta trobada per cerca directa: ${actaUrl}`);
            // Fem el fetch síncronament dins del callback no és ideal, ho fem fora
          }
        });

        // Cerca alternativa: busquem qualsevol acta que contingui els equips
        if (!refereeInfo) {
          const allActas: string[] = [];
          $("a[href*='/acta/']").each((_, el) => {
            const href = $(el).attr("href");
            if (href) {
              const container = $(el).closest(".row");
              const teamsInContainer: string[] = [];
              container.find("a.teamNameLink").each((__, teamEl) => {
                teamsInContainer.push(normalizeForSignature($(teamEl).text().trim()));
              });
              if (teamsInContainer.includes(targetHomeNorm) || teamsInContainer.includes(targetAwayNorm)) {
                const actaUrl = href.startsWith("http") ? href : `https://www.basquetcatala.cat${href}`;
                allActas.push(actaUrl);
              }
            }
          });

          if (allActas.length > 0) {
            console.log(`[processVotingWinner] 📋 Acta trobada per cerca directa: ${allActas[0]}`);
            refereeInfo = await fetchActaInfo(allActas[0]);
            console.log(`[processVotingWinner] ✅ Àrbitre principal: ${refereeInfo.principal || "no trobat"}`);
          }
        }
      } catch (fallbackError) {
        console.error("[processVotingWinner] ❌ Error en cerca directa:", fallbackError);
      }
    }
  } catch (error) {
    console.error("[processVotingWinner] ❌ Error obtenint àrbitres:", error);
  }

  // 4. Calcular quan es tanquen els suggeriments (dimecres 15:00)
  const now = new Date();
  const suggestionsCloseAt = getNextWednesday15h(now);

  // 5. Crear el document weekly_focus
  const focusDoc: WeeklyFocusDocument = {
    jornada: previousJornada,
    winningMatch,
    totalVotes,
    refereeInfo,
    votingClosedAt: now.toISOString(),
    suggestionsOpen: true,
    suggestionsCloseAt: suggestionsCloseAt.toISOString(),
    status: "minutatge",
  };

  // 6. Guardar a Firestore
  const batch = db.batch();

  // Guardar com a current
  batch.set(db.collection("weekly_focus").doc("current"), focusDoc);

  // Guardar còpia històrica
  batch.set(db.collection("weekly_focus").doc(`jornada_${previousJornada}`), focusDoc);

  await batch.commit();

  console.log(
    "[processVotingWinner] ✅ Guardat weekly_focus: " +
    `${winningMatch.home.teamNameDisplay} vs ${winningMatch.away.teamNameDisplay} ` +
    `(${totalVotes} vots). Suggeriments oberts fins ${suggestionsCloseAt.toLocaleString("ca-ES")}`
  );
}

// ============================================================================
// Guardar a Firestore
// ============================================================================

async function saveVotingData(
  jornada: number,
  matches: VotingMatch[],
  standings: StandingEntry[],
  saturdayStart: Date,
  sundayEnd: Date
): Promise<void> {
  const now = new Date().toISOString();

  // 1. Llegir la jornada anterior per tancar-la
  const metaRef = db.collection("voting_meta").doc("current");
  const currentMeta = await metaRef.get();
  const previousJornada = currentMeta.exists ? currentMeta.data()?.activeJornada : null;

  const allTeamIds = matches.flatMap((m) => [m.home.teamId, m.away.teamId]);
  const foundTeams = allTeamIds.filter((id) => id !== null).length;
  const notFoundTeams = allTeamIds.filter((id) => id === null).length;

  const jornadaDoc: VotingJornadaDocument = {
    jornada,
    competitionId: DEFAULT_SCRAPER_CONFIG.competitionId,
    competitionName: "Super Copa Masculina",
    matches,
    classification: standings,
    weekendStart: saturdayStart.toISOString(),
    weekendEnd: sundayEnd.toISOString(),
    publishedAt: now,
    updatedAt: now,
    source: "fcbq-scraper",
    mappingStats: {
      totalTeams: allTeamIds.length,
      foundTeams,
      notFoundTeams,
    },
  };

  const metaDoc: VotingMetaDocument = {
    activeJornada: jornada,
    weekendStart: saturdayStart.toISOString(),
    weekendEnd: sundayEnd.toISOString(),
    publishedAt: now,
    matchCount: matches.length,
  };

  const batch = db.batch();

  // 2. Tancar la votació de la jornada anterior (si n'hi ha) i processar guanyador
  if (previousJornada && previousJornada !== jornada) {
    const prevVotingMetaRef = db.collection("voting_meta").doc(`jornada_${previousJornada}`);
    batch.set(prevVotingMetaRef, {
      votingOpen: false,
      closedAt: now,
      closedReason: `Nova jornada ${jornada} publicada`,
    }, {merge: true});
    console.log(`[saveVotingData] 🔒 Tancant votació de jornada ${previousJornada}`);

    // Processar el guanyador de la jornada anterior (fora del batch)
    // Guard: comprovar si ja s'ha processat (p.ex. durant una setmana de descans)
    try {
      const focusDoc = await db.collection("weekly_focus").doc("current").get();
      if (!focusDoc.exists || focusDoc.data()?.jornada !== previousJornada) {
        await processVotingWinner(previousJornada);
      } else {
        console.log(`[saveVotingData] ℹ️ Guanyador de jornada ${previousJornada} ja processat, saltant`);
      }
    } catch (error) {
      console.error("[saveVotingData] ❌ Error processant guanyador:", error);
      // Continuem igualment amb la nova jornada
    }
  }

  // Netejar flags de setmana de descans (si n'hi havia)
  if (currentMeta.exists && currentMeta.data()?.restWeek) {
    console.log("[saveVotingData] 🧹 Netejant flags de setmana de descans");
  }

  // 3. Obrir la votació de la nova jornada
  const newVotingMetaRef = db.collection("voting_meta").doc(`jornada_${jornada}`);
  batch.set(newVotingMetaRef, {
    votingOpen: true,
    openedAt: now,
  }, {merge: true});

  batch.set(db.collection("voting_jornades").doc(jornada.toString()), jornadaDoc);
  batch.set(metaRef, metaDoc);
  await batch.commit();

  console.log(
    `[saveVotingData] ✅ Guardat: jornada ${jornada} amb ${matches.length} partits. ` +
    `Mapping: ${foundTeams}/${allTeamIds.length} equips trobats.`
  );
}

// ============================================================================
// Cloud Functions
// ============================================================================

export const syncWeeklyVoting = onSchedule(
  {
    schedule: "0 8 * * 1", // Cada dilluns a les 8:00
    timeZone: "Europe/Madrid",
    region: "europe-west1",
    memory: "512MiB",
    timeoutSeconds: 300,
    retryCount: 3,
  },
  async () => {
    console.log("[syncWeeklyVoting] 🏀 Iniciant sincronització setmanal...");

    try {
      const now = new Date();
      const saturdayStart = getNextSaturday(now);
      const sundayEnd = getSundayAfter(saturdayStart);

      console.log(`[syncWeeklyVoting] Cap de setmana: ${saturdayStart.toDateString()} - ${sundayEnd.toDateString()}`);

      const result = await findWeekendJornada(saturdayStart, sundayEnd);

      if (!result) {
        console.log("[syncWeeklyVoting] ℹ️ No hi ha partits pel cap de setmana (vacances/descans?)");

        // Igualment processar el guanyador de la jornada anterior
        const metaRef = db.collection("voting_meta").doc("current");
        const currentMeta = await metaRef.get();
        const previousJornada = currentMeta.exists ? currentMeta.data()?.activeJornada : null;

        if (previousJornada) {
          console.log(`[syncWeeklyVoting] 🏆 Processant guanyador de jornada ${previousJornada} (setmana de descans)...`);

          // Tancar votació de la jornada anterior
          const prevVotingMetaRef = db.collection("voting_meta").doc(`jornada_${previousJornada}`);
          await prevVotingMetaRef.set({
            votingOpen: false,
            closedAt: now.toISOString(),
            closedReason: "Setmana de descans",
          }, {merge: true});

          // Processar guanyador
          try {
            await processVotingWinner(previousJornada);
          } catch (error) {
            console.error(`[syncWeeklyVoting] ❌ Error processant guanyador de jornada ${previousJornada}:`, error);
          }

          // Calcular data de la propera votació (proper dilluns 8:00)
          const nextMonday = new Date(now);
          nextMonday.setDate(nextMonday.getDate() + 7);
          nextMonday.setHours(8, 0, 0, 0);

          // Marcar setmana de descans a voting_meta/current
          await metaRef.set({
            ...currentMeta.data(),
            restWeek: true,
            restWeekMessage: "La competició descansa aquest cap de setmana. Les noves votacions s'obriran el proper dilluns.",
            nextVotingDate: nextMonday.toISOString(),
          }, {merge: true});

          console.log(`[syncWeeklyVoting] ✅ Setmana de descans gestionada. Propera votació: ${nextMonday.toDateString()}`);
        }

        return;
      }

      const votingMatches = result.matches.map(transformToVotingMatch);
      await saveVotingData(result.jornada, votingMatches, result.standings, saturdayStart, sundayEnd);

      console.log("[syncWeeklyVoting] ✅ Sincronització completada!");
    } catch (error) {
      console.error("[syncWeeklyVoting] ❌ Error:", error);
      throw error;
    }
  }
);

export const triggerSyncWeeklyVoting = onCall(
  {
    region: "europe-west1",
    memory: "512MiB",
    timeoutSeconds: 300,
  },
  async (request): Promise<{success: boolean; message: string; jornada?: number; reason?: string}> => {
    console.log("[triggerSyncWeeklyVoting] 🔄 Execució manual sol·licitada");

    const data = request.data as {targetDate?: string};

    try {
      let now: Date;
      if (data.targetDate) {
        now = new Date(data.targetDate);
        if (isNaN(now.getTime())) {
          throw new HttpsError("invalid-argument", "targetDate ha de ser una data vàlida ISO");
        }
        console.log(`[triggerSyncWeeklyVoting] Usant data objectiu: ${now.toISOString()}`);
      } else {
        now = new Date();
      }

      const saturdayStart = getNextSaturday(now);
      const sundayEnd = getSundayAfter(saturdayStart);

      const result = await findWeekendJornada(saturdayStart, sundayEnd);

      if (!result) {
        return {
          success: false,
          message: `No s'han trobat partits pel cap de setmana ${saturdayStart.toDateString()} - ${sundayEnd.toDateString()}`,
        };
      }

      const votingMatches = result.matches.map(transformToVotingMatch);
      await saveVotingData(result.jornada, votingMatches, result.standings, saturdayStart, sundayEnd);

      return {
        success: true,
        message: `Sincronització completada: jornada ${result.jornada} amb ${votingMatches.length} partits`,
        jornada: result.jornada,
        reason: result.reason,
      };
    } catch (error) {
      console.error("[triggerSyncWeeklyVoting] Error:", error);
      throw new HttpsError(
        "internal",
        `Error durant la sincronització: ${error instanceof Error ? error.message : "desconegut"}`
      );
    }
  }
);

export const getActiveVotingJornada = onCall(
  {region: "europe-west1"},
  async (): Promise<VotingJornadaDocument | null> => {
    try {
      const metaDoc = await db.collection("voting_meta").doc("current").get();

      if (!metaDoc.exists) {
        console.log("[getActiveVotingJornada] No hi ha jornada activa");
        return null;
      }

      const meta = metaDoc.data() as VotingMetaDocument;
      const jornadaDoc = await db.collection("voting_jornades").doc(meta.activeJornada.toString()).get();

      if (!jornadaDoc.exists) {
        console.warn(`[getActiveVotingJornada] Jornada ${meta.activeJornada} no trobada`);
        return null;
      }

      return jornadaDoc.data() as VotingJornadaDocument;
    } catch (error) {
      console.error("[getActiveVotingJornada] Error:", error);
      throw new HttpsError("internal", `Error obtenint jornada: ${error instanceof Error ? error.message : "desconegut"}`);
    }
  }
);

// ============================================================================
// Tancar suggeriments - Dimecres 15:00
// ============================================================================

export const closeSuggestions = onSchedule(
  {
    schedule: "0 15 * * 3", // Cada dimecres a les 15:00
    timeZone: "Europe/Madrid",
    region: "europe-west1",
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async () => {
    console.log("[closeSuggestions] 🔒 Tancant suggeriments...");

    try {
      const focusRef = db.collection("weekly_focus").doc("current");
      const focusDoc = await focusRef.get();

      if (!focusDoc.exists) {
        console.log("[closeSuggestions] ℹ️ No hi ha weekly_focus/current");
        return;
      }

      const focusData = focusDoc.data() as WeeklyFocusDocument;

      if (!focusData.suggestionsOpen) {
        console.log("[closeSuggestions] ℹ️ Suggeriments ja tancats");
        return;
      }

      const now = new Date().toISOString();

      // Tancar suggeriments
      await focusRef.update({
        suggestionsOpen: false,
        suggestionsClosedAt: now,
        status: "entrevista_pendent",
      });

      // També actualitzem la còpia històrica
      const historicRef = db.collection("weekly_focus").doc(`jornada_${focusData.jornada}`);
      await historicRef.update({
        suggestionsOpen: false,
        suggestionsClosedAt: now,
        status: "entrevista_pendent",
      });

      console.log(
        `[closeSuggestions] ✅ Suggeriments tancats per jornada ${focusData.jornada}. ` +
        "Status: entrevista_pendent"
      );
    } catch (error) {
      console.error("[closeSuggestions] ❌ Error:", error);
      throw error;
    }
  }
);

// ============================================================================
// Forçar processament del guanyador - Per a testing
// ============================================================================

export const forceProcessWinner = onCall(
  {
    region: "europe-west1",
    memory: "512MiB",
    timeoutSeconds: 120,
  },
  async (request): Promise<{success: boolean; message: string; data?: unknown}> => {
    const data = request.data as {jornada: number};

    if (!data.jornada || typeof data.jornada !== "number") {
      throw new HttpsError("invalid-argument", "Cal especificar jornada (number)");
    }

    console.log(`[forceProcessWinner] 🏆 Forçant processament de jornada ${data.jornada}...`);

    try {
      await processVotingWinner(data.jornada);

      // Llegir el resultat
      const focusDoc = await db.collection("weekly_focus").doc("current").get();

      return {
        success: true,
        message: `Processament de jornada ${data.jornada} completat`,
        data: focusDoc.exists ? focusDoc.data() : null,
      };
    } catch (error) {
      console.error("[forceProcessWinner] ❌ Error:", error);
      throw new HttpsError("internal", `Error: ${error instanceof Error ? error.message : "desconegut"}`);
    }
  }
);

// ============================================================================
// Configurar weekly_focus manualment - Per a testing/setup inicial
// ============================================================================

interface SetupWeeklyFocusData {
  jornada: number;
  winningMatch: VotingMatch;
  totalVotes: number;
  refereeInfo: RefereeInfo | null;
  competitionName?: string;
}

export const setupWeeklyFocus = onCall(
  {
    region: "europe-west1",
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async (request): Promise<{success: boolean; message: string}> => {
    const data = request.data as SetupWeeklyFocusData;

    if (!data.jornada || !data.winningMatch) {
      throw new HttpsError("invalid-argument", "Cal especificar jornada i winningMatch");
    }

    console.log(`[setupWeeklyFocus] 📝 Configurant weekly_focus per jornada ${data.jornada}...`);

    const now = new Date();
    const suggestionsCloseAt = getNextWednesday15h(now);

    const focusDoc: WeeklyFocusDocument & {competitionName?: string} = {
      jornada: data.jornada,
      competitionName: data.competitionName || "Super Copa Masculina",
      winningMatch: data.winningMatch,
      totalVotes: data.totalVotes || 1,
      refereeInfo: data.refereeInfo,
      votingClosedAt: now.toISOString(),
      suggestionsOpen: true,
      suggestionsCloseAt: suggestionsCloseAt.toISOString(),
      status: data.refereeInfo ? "completat" : "minutatge",
    };

    // Guardar a Firestore
    const batch = db.batch();
    batch.set(db.collection("weekly_focus").doc("current"), focusDoc);
    batch.set(db.collection("weekly_focus").doc(`jornada_${data.jornada}`), focusDoc);
    await batch.commit();

    console.log(`[setupWeeklyFocus] ✅ weekly_focus configurat: jornada ${data.jornada}`);

    return {
      success: true,
      message: `Weekly focus configurat per jornada ${data.jornada}`,
    };
  }
);

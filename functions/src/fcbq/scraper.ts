// ============================================================================
// FCBQ Scraper - Extracció de dades de la web de la Federació
// ============================================================================
// Aquest mòdul s'encarrega de fer scraping de la web pública de la FCBQ
// i transformar les dades en el format normalitzat del projecte.
// ============================================================================

import * as cheerio from "cheerio";
import {
  MatchData,
  StandingEntry,
  TeamInfo,
  MatchStatus,
  ScraperConfig,
  DEFAULT_SCRAPER_CONFIG,
} from "./types";

/**
 * Genera un slug per al logo de l'equip a partir del nom
 * Exemple: "FC MARTINENC BÀSQUET A" -> "fc-martinenc-basquet-a.webp"
 */
function generateLogoSlug(teamName: string): string {
  return (
    teamName
      .toLowerCase()
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "") // elimina accents
      .replace(/[^a-z0-9\s-]/g, "") // elimina caràcters especials
      .trim()
      .replace(/\s+/g, "-") + ".webp"
  );
}

/**
 * Parseja una data en format "DD-MM-YYYY HH:mm" a ISO 8601
 */
function parseDateTime(dateStr: string): string {
  // Format esperat: "10-01-2026 17:30"
  const match = dateStr.match(/(\d{2})-(\d{2})-(\d{4})\s+(\d{2}):(\d{2})/);
  if (!match) {
    console.warn(`Format de data no reconegut: ${dateStr}`);
    return new Date().toISOString();
  }
  const [, day, month, year, hour, minute] = match;
  return `${year}-${month}-${day}T${hour}:${minute}:00`;
}

/**
 * Extreu l'ID de l'equip de l'URL de la FCBQ
 */
function extractTeamId(href: string | undefined): string | undefined {
  if (!href) return undefined;
  const match = href.match(/\/equip\/(\d+)/);
  return match ? match[1] : undefined;
}

/**
 * Parseja els partits de la pàgina HTML
 * La FCBQ utilitza una estructura Bootstrap amb divs, no taules tradicionals:
 * - .teamNameLink per als noms dels equips
 * - #time2 per a la data/hora
 * - .row per agrupar cada partit
 */
export function parseMatches(
  html: string,
  jornada: number
): MatchData[] {
  const $ = cheerio.load(html);
  const matches: MatchData[] = [];

  // Busquem tots els enllaços d'equips amb classe .teamNameLink
  const teamLinks = $("a.teamNameLink");

  // Els equips venen en parelles (local, visitant)
  // Cada parell correspon a un partit
  for (let i = 0; i < teamLinks.length; i += 2) {
    const homeLink = $(teamLinks[i]);
    const awayLink = $(teamLinks[i + 1]);

    if (!awayLink.length) break; // Imparell, sortim

    const homeName = homeLink.text().trim();
    const awayName = awayLink.text().trim();

    if (!homeName || !awayName) continue;

    // Busquem la data/hora - està en un div#time2 proper
    // Naveguem cap amunt per trobar el contenidor del partit
    const homeContainer = homeLink.closest(".row");
    const timeDiv = homeContainer.find("#time2, [id='time2']").first();
    let dateTimeStr = timeDiv.text().trim().replace(/\s+/g, " ");

    // Si no trobem la data al contenidor, busquem el següent #time2
    if (!dateTimeStr) {
      // Intentem buscar en el context proper
      const allTimeDivs = $("#time2, [id='time2']");
      const matchIndex = Math.floor(i / 2);
      if (allTimeDivs.length > matchIndex) {
        dateTimeStr = $(allTimeDivs[matchIndex]).text().trim().replace(/\s+/g, " ");
      }
    }

    const homeTeam: TeamInfo = {
      name: homeName,
      logo: generateLogoSlug(homeName),
      fcbqId: extractTeamId(homeLink.attr("href")),
    };

    const awayTeam: TeamInfo = {
      name: awayName,
      logo: generateLogoSlug(awayName),
      fcbqId: extractTeamId(awayLink.attr("href")),
    };

    // Determinem l'estat i resultat
    let status: MatchStatus = "scheduled";
    let homeScore: number | undefined;
    let awayScore: number | undefined;

    // Comprovem si hi ha resultat (format: "85 - 72" o similar)
    const scoreMatch = dateTimeStr.match(/^(\d+)\s*-\s*(\d+)$/);
    if (scoreMatch) {
      status = "finished";
      homeScore = parseInt(scoreMatch[1], 10);
      awayScore = parseInt(scoreMatch[2], 10);
    }

    // Busquem indicadors d'ajornat o suspès al contenidor
    const containerHtml = $.html(homeContainer);
    if (containerHtml.includes("ico_ajo") || containerHtml.includes("Ajornat")) {
      status = "postponed";
    } else if (containerHtml.includes("Suspes") || containerHtml.includes("ico_suspes")) {
      status = "suspended";
    }

    const dateTime = parseDateTime(dateTimeStr);

    const match: MatchData = {
      jornada,
      home: homeTeam,
      away: awayTeam,
      dateTime,
      timezone: "Europe/Madrid",
      gender: "male",
      source: "fcbq-scraper",
      status,
    };

    if (homeScore !== undefined) match.homeScore = homeScore;
    if (awayScore !== undefined) match.awayScore = awayScore;

    // Busquem URL de streaming
    const streamingLink = homeContainer.find("a[href*='youtube'], a[href*='twitch'], a[href*='streaming']").first();
    if (streamingLink.length) {
      match.streamingUrl = streamingLink.attr("href");
    }

    matches.push(match);
  }

  console.log(`[parseMatches] Trobats ${matches.length} partits a la jornada ${jornada}`);
  return matches;
}

/**
 * Parseja la classificació de la pàgina HTML
 *
 * La FCBQ utilitza una estructura Bootstrap amb divs en lloc de taules:
 * - Container: div.container.m-bottom que conté "Classificació a la jornada"
 * - Files: div#fila dins del container
 * - Posició: div.numRanking
 * - Equip: a[href*="/equip/"]
 * - Stats: div.textRanking (J, G, P, NP, PF, PC, Punts en ordre)
 */
export function parseStandings(html: string): StandingEntry[] {
  const $ = cheerio.load(html);
  const standings: StandingEntry[] = [];

  // Busquem el container de la classificació
  const classifContainer = $("div.container.m-bottom").filter((_, el) => {
    return $(el).text().includes("Classificació a la jornada");
  }).first();

  if (!classifContainer.length) {
    console.log("[parseStandings] No s'ha trobat el container de classificació");
    return standings;
  }

  // Busquem totes les files de classificació (div#fila)
  const rows = classifContainer.find("div#fila");
  console.log(`[parseStandings] Trobades ${rows.length} files de classificació`);

  rows.each((index, row) => {
    const $row = $(row);

    // Posició
    const positionText = $row.find("div.numRanking").first().text().trim();
    const position = parseInt(positionText, 10) || index + 1;

    // Nom de l'equip
    const teamLink = $row.find("a[href*='/equip/']").first();
    const teamName = teamLink.text().trim();

    if (!teamName || teamName.length < 2) return;

    // Stats: tots els div.textRanking en ordre (J, G, P, NP, PF, PC, Punts)
    const stats: number[] = [];
    $row.find("div.textRanking").each((_, stat) => {
      const value = parseInt($(stat).text().trim(), 10);
      stats.push(isNaN(value) ? 0 : value);
    });

    // Assegurem que tenim almenys 7 valors
    while (stats.length < 7) {
      stats.push(0);
    }

    const entry: StandingEntry = {
      position,
      teamName,
      teamId: extractTeamId(teamLink.attr("href")),
      played: stats[0],
      won: stats[1],
      lost: stats[2],
      notPlayed: stats[3],
      pointsFor: stats[4],
      pointsAgainst: stats[5],
      points: stats[6],
    };

    // Ratxa (si hi ha més stats, pot ser la ratxa en format "VVDVV")
    // De moment no l'extraiem perquè és complexa (imatges o caràcters especials)

    standings.push(entry);
  });

  console.log(`[parseStandings] Parseats ${standings.length} equips a la classificació`);
  return standings;
}

/**
 * Fa la petició HTTP a la web de la FCBQ
 */
export async function fetchFcbqPage(
  jornada: number,
  config: ScraperConfig = DEFAULT_SCRAPER_CONFIG
): Promise<string> {
  const url = `${config.baseUrl}/${config.competitionId}/${jornada}`;

  console.log(`[FCBQ Scraper] Fetching: ${url}`);

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), config.timeoutMs);

  try {
    const response = await fetch(url, {
      method: "GET",
      headers: {
        "User-Agent": "Mozilla/5.0 (compatible; ElVisionat/1.0)",
        "Accept": "text/html,application/xhtml+xml",
        "Accept-Language": "ca,es;q=0.9",
      },
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    return await response.text();
  } catch (error) {
    clearTimeout(timeoutId);
    if (error instanceof Error && error.name === "AbortError") {
      throw new Error(`Timeout després de ${config.timeoutMs}ms`);
    }
    throw error;
  }
}

/**
 * Funció principal que fa scraping complet d'una jornada
 */
export async function scrapeJornada(
  jornada: number,
  config: ScraperConfig = DEFAULT_SCRAPER_CONFIG
): Promise<{ matches: MatchData[]; standings: StandingEntry[] }> {
  // Validem el número de jornada
  if (jornada < 1 || jornada > 30) {
    throw new Error(`Jornada ${jornada} fora de rang (1-30)`);
  }

  const html = await fetchFcbqPage(jornada, config);

  const matches = parseMatches(html, jornada);
  const standings = parseStandings(html);

  console.log(`[FCBQ Scraper] Jornada ${jornada}: ${matches.length} partits, ${standings.length} equips a la classificació`);

  return {matches, standings};
}

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
  RefereeInfo,
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

  // Extraiem els enllaços d'acta amb informació de context (equips propers)
  // La FCBQ pot usar .row (Bootstrap) o tr (taula) com a contenidor
  interface ActaInfo {
    url: string;
    nearbyTeams: string[]; // Noms d'equips propers a l'enllaç d'acta
  }
  const actaInfos: ActaInfo[] = [];
  $("a[href*='/acta/']").each((_, el) => {
    const href = $(el).attr("href");
    if (href) {
      const fullUrl = href.startsWith("http") ? href : `https://www.basquetcatala.cat${href}`;
      const $el = $(el);
      const nearbyTeams: string[] = [];

      // Intentem trobar el contenidor del partit (pot ser .row, tr, o un div pare)
      let container = $el.closest(".row");
      if (!container.length || container.find("a.teamNameLink").length === 0) {
        container = $el.closest("tr");
      }
      if (!container.length || container.find("a.teamNameLink").length === 0) {
        // Fallback: busquem en els parents fins a trobar equips
        container = $el.parent();
        let maxIterations = 5;
        while (container.length && container.find("a.teamNameLink").length === 0 && maxIterations > 0) {
          container = container.parent();
          maxIterations--;
        }
      }

      container.find("a.teamNameLink").each((__, teamEl) => {
        const teamName = $(teamEl).text().trim();
        if (teamName) nearbyTeams.push(teamName.toUpperCase());
      });

      actaInfos.push({url: fullUrl, nearbyTeams});
      if (nearbyTeams.length > 0) {
        console.log(`[parseMatches] Acta ${fullUrl} → equips: ${nearbyTeams.join(", ")}`);
      }
    }
  });
  console.log(`[parseMatches] Trobats ${actaInfos.length} enllaços d'acta a la pàgina`);

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
    // Naveguem cap amunt per trobar el contenidor del partit (.row o tr)
    let homeContainer = homeLink.closest(".row");
    if (!homeContainer.length) {
      homeContainer = homeLink.closest("tr");
    }
    if (!homeContainer.length) {
      // Fallback: busquem el parent que contingui ambdós equips
      homeContainer = homeLink.parent();
      let maxIterations = 5;
      while (homeContainer.length && homeContainer.find("a.teamNameLink").length < 2 && maxIterations > 0) {
        homeContainer = homeContainer.parent();
        maxIterations--;
      }
    }
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

    // Busquem URL de l'acta oficial
    // Primer intentem dins del contenidor
    const actaLink = homeContainer.find("a[href*='/acta/']").first();
    if (actaLink.length) {
      const href = actaLink.attr("href");
      if (href) {
        match.actaUrl = href.startsWith("http") ? href : `https://www.basquetcatala.cat${href}`;
      }
    } else {
      // Si no trobem l'acta dins del contenidor, busquem per matching d'equips
      // (millora respecte a l'assignació per índex que era incorrecta)
      const homeUpper = homeName.toUpperCase();
      const awayUpper = awayName.toUpperCase();
      const matchingActa = actaInfos.find((acta) =>
        acta.nearbyTeams.includes(homeUpper) || acta.nearbyTeams.includes(awayUpper)
      );
      if (matchingActa) {
        match.actaUrl = matchingActa.url;
        console.log(`[parseMatches] Assignant acta per matching d'equips: ${match.actaUrl} al partit ${homeName} vs ${awayName}`);
      }
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
 * Parseja l'acta d'un partit per extreure la informació dels àrbitres
 *
 * L'acta conté una taula amb els oficials del partit:
 * - Àrbitre/a Principal
 * - Àrbitre/a Auxiliar
 * - Anotador/a
 * - Cronometrador/a
 * - Operador/a RLL
 */
export function parseActa(html: string, actaUrl?: string): RefereeInfo {
  const $ = cheerio.load(html);
  const info: RefereeInfo = {};

  if (actaUrl) {
    info.actaUrl = actaUrl;
  }

  // Busquem la informació del partit (equips i resultat)
  // Format típic: "CB ARTÉS 80 - 72 FC MARTINENC BÀSQUET A"
  const headerText = $("h1, h2, .title, .match-header").first().text().trim();
  const matchPattern = /(.+?)\s+(\d+)\s*-\s*(\d+)\s+(.+)/;
  const matchResult = headerText.match(matchPattern);

  if (matchResult) {
    info.homeTeam = matchResult[1].trim();
    info.homeScore = parseInt(matchResult[2], 10);
    info.awayScore = parseInt(matchResult[3], 10);
    info.awayTeam = matchResult[4].trim();
  }

  // Busquem la data del partit
  const datePattern = /(\d{2}-\d{2}-\d{4})/;
  const pageText = $("body").text();
  const dateMatch = pageText.match(datePattern);
  if (dateMatch) {
    info.matchDate = dateMatch[1];
  }

  // Busquem els oficials del partit
  // L'estructura típica és una llista o taula amb els rols i noms
  const officials: Record<string, string> = {
    "principal": "",
    "auxiliar": "",
    "anotador": "",
    "cronometrador": "",
    "operadorRll": "",
    "caller1": "",
  };

  // Primer intentem extreure de les cel·les de taula (més precís)
  $("td, th").each((_, cell) => {
    const cellText = $(cell).text().trim();
    const nextCell = $(cell).next("td, th").text().trim();

    if (cellText.includes("Àrbitre") && cellText.includes("Principal") && nextCell) {
      officials.principal = nextCell;
    } else if (cellText.includes("Àrbitre") && cellText.includes("Auxiliar") && nextCell) {
      officials.auxiliar = nextCell;
    } else if (cellText.includes("Anotador") && nextCell) {
      officials.anotador = nextCell;
    } else if (cellText.includes("Cronometrador") && nextCell) {
      officials.cronometrador = nextCell;
    } else if (cellText.includes("Operador") && cellText.includes("RLL") && nextCell) {
      officials.operadorRll = nextCell;
    } else if (cellText.includes("Caller") && cellText.includes("1") && nextCell) {
      officials.caller1 = nextCell;
    }
  });

  // L'estructura de l'acta FCBQ és: "Rol:\n\n NOM COMPLET \nSegüentRol:"
  // Usem regex que capturen el text entre el rol i el següent rol o final de secció
  // pageText ja declarat abans

  // Patrons per capturar cada oficial - busquem el text després dels dos punts fins al proper camp
  const extractName = (text: string, rolePattern: RegExp, stopPatterns: string[]): string => {
    const match = text.match(rolePattern);
    if (!match) return "";

    // Trobem on comença el nom (després del rol)
    const startIdx = match.index! + match[0].length;
    let endIdx = text.length;

    // Busquem el primer stopPattern que aparegui
    for (const stop of stopPatterns) {
      const stopIdx = text.indexOf(stop, startIdx);
      if (stopIdx !== -1 && stopIdx < endIdx) {
        endIdx = stopIdx;
      }
    }

    // Extraiem i netejem el nom
    const rawName = text.substring(startIdx, endIdx).trim();
    // Eliminem espais múltiples i netegem
    let cleanName = rawName.replace(/\s+/g, " ").trim();
    // Si el nom conté paraules típiques de codi JS, el tallem
    const jsIndicators = ["function", "var ", "const ", "document", "$(", "window"];
    for (const indicator of jsIndicators) {
      const idx = cleanName.indexOf(indicator);
      if (idx !== -1) {
        cleanName = cleanName.substring(0, idx).trim();
      }
    }
    return cleanName;
  };

  const stopMarkers = [
    "Àrbitre/a Principal",
    "Àrbitre/a Auxiliar",
    "Anotador/a",
    "Operador/a RLL",
    "Cronometrador/a",
    "Caller 1",
    "Caller 2", // Per si n'hi ha més d'un
    "Colors SAMARRETA", // Marca el final de la secció d'oficials
    "function ", // Indicador de codi JavaScript
    "document.", // Indicador de codi JavaScript
    "Rambla Guipúscoa", // Adreça de la FCBQ al footer
  ];

  if (!officials.principal) {
    officials.principal = extractName(pageText, /Àrbitre\/a Principal[:\s]*/i,
      stopMarkers.filter((s) => s !== "Àrbitre/a Principal"));
  }
  if (!officials.auxiliar) {
    officials.auxiliar = extractName(pageText, /Àrbitre\/a Auxiliar[:\s]*/i,
      stopMarkers.filter((s) => s !== "Àrbitre/a Auxiliar"));
  }
  if (!officials.anotador) {
    officials.anotador = extractName(pageText, /Anotador\/a[:\s]*/i,
      stopMarkers.filter((s) => s !== "Anotador/a"));
  }
  if (!officials.operadorRll) {
    officials.operadorRll = extractName(pageText, /Operador\/a RLL[:\s]*/i,
      stopMarkers.filter((s) => s !== "Operador/a RLL"));
  }
  if (!officials.cronometrador) {
    officials.cronometrador = extractName(pageText, /Cronometrador\/a[:\s]*/i,
      stopMarkers.filter((s) => s !== "Cronometrador/a"));
  }
  if (!officials.caller1) {
    officials.caller1 = extractName(pageText, /Caller 1[:\s]*/i,
      stopMarkers.filter((s) => s !== "Caller 1"));
  }

  // Assignem els valors trobats
  if (officials.principal) info.principal = officials.principal;
  if (officials.auxiliar) info.auxiliar = officials.auxiliar;
  if (officials.anotador) info.anotador = officials.anotador;
  if (officials.cronometrador) info.cronometrador = officials.cronometrador;
  if (officials.operadorRll) info.operadorRll = officials.operadorRll;
  if (officials.caller1) info.caller1 = officials.caller1;

  // Construïm l'array tableOfficials per compatibilitat amb Flutter
  const tableOfficials: Array<{role: string; name: string}> = [];
  if (officials.anotador) {
    tableOfficials.push({role: "Anotador", name: officials.anotador});
  }
  if (officials.cronometrador) {
    tableOfficials.push({role: "Cronometrador", name: officials.cronometrador});
  }
  if (officials.operadorRll) {
    tableOfficials.push({role: "Operador RLL", name: officials.operadorRll});
  }
  if (officials.caller1) {
    tableOfficials.push({role: "Caller", name: officials.caller1});
  }
  if (tableOfficials.length > 0) {
    info.tableOfficials = tableOfficials;
  }

  // Afegim source
  info.source = "fcbq-acta";

  // Extraiem la instal·lació (nom del pavelló i adreça)
  // Format típic a l'acta FCBQ:
  // Instal·lació:
  // PAVELLO ESPORTIU D'ARTES
  // BARCELONA, S/N, Artés (08271)
  const venuePattern = /Instal[\u00b7.]lació[:\s]*([^\n]+)\s*([^\n]*(?:\(\d{5}\)))?/i;
  const venueMatch = pageText.match(venuePattern);
  if (venueMatch) {
    const venueName = venueMatch[1]?.trim();
    const venueAddress = venueMatch[2]?.trim();
    if (venueName) {
      // Combinem nom i codi postal si hi ha
      const postalCodeMatch = venueAddress?.match(/([^,]+),?\s*([^,]+,)?\s*(\w+)\s*\((\d{5})\)/);
      if (postalCodeMatch) {
        const city = postalCodeMatch[3]?.trim();
        const postalCode = postalCodeMatch[4];
        info.venue = `${venueName} - ${city} (${postalCode})`;
        info.venueAddress = venueAddress;
      } else {
        info.venue = venueName;
        if (venueAddress) info.venueAddress = venueAddress;
      }
    }
  }

  // Si no hem trobat amb el patró anterior, intentem una cerca més simple
  if (!info.venue) {
    // Busquem després de "Instal·lació:" fins a dos salts de línia
    const simpleVenueMatch = pageText.match(/Instal[\u00b7.]lació[:\s]*\n?\s*([A-Z][A-Z\s'"\-.]+)\n?\s*([A-Z].*?\(\d{5}\))?/i);
    if (simpleVenueMatch) {
      let venueName = simpleVenueMatch[1]?.trim();
      const fullAddress = simpleVenueMatch[2]?.trim();

      // Netejar el nom (eliminar text extraño)
      venueName = venueName.replace(/\s+/g, " ").trim();
      // Tallem si trobem paraules que no haurien d'estar al nom
      const cutMarkers = ["BARCELONA", "GIRONA", "TARRAGONA", "LLEIDA", "Carrer", "Av.", "Plaça"];
      for (const marker of cutMarkers) {
        const idx = venueName.indexOf(marker);
        if (idx > 0) {
          venueName = venueName.substring(0, idx).trim();
        }
      }
      if (venueName && venueName.length > 3) {
        // Extraiem ciutat i codi postal de l'adreça completa
        if (fullAddress) {
          const addressMatch = fullAddress.match(/,?\s*(\w+)\s*\((\d{5})\)/);
          if (addressMatch) {
            info.venue = `${venueName} - ${addressMatch[1]} (${addressMatch[2]})`;
            info.venueAddress = fullAddress;
          } else {
            info.venue = venueName;
          }
        } else {
          info.venue = venueName;
        }
      }
    }
  }

  console.log(`[parseActa] Àrbitre principal: ${info.principal || "no trobat"}`);
  console.log(`[parseActa] Àrbitre auxiliar: ${info.auxiliar || "no trobat"}`);
  console.log(`[parseActa] Instal·lació: ${info.venue || "no trobada"}`);

  return info;
}

/**
 * Fa fetch de l'acta d'un partit i extreu la informació dels àrbitres
 */
export async function fetchActaInfo(actaUrl: string): Promise<RefereeInfo> {
  console.log(`[FCBQ Scraper] Fetching acta: ${actaUrl}`);

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 15000);

  try {
    const response = await fetch(actaUrl, {
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

    const html = await response.text();
    return parseActa(html, actaUrl);
  } catch (error) {
    clearTimeout(timeoutId);
    if (error instanceof Error && error.name === "AbortError") {
      throw new Error("Timeout després de 15000ms");
    }
    throw error;
  }
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

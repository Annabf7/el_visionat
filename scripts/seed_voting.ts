/**
 * Seed per omplir les dades de votació a l'emulador de Firestore
 * Executa amb: npm run seed:voting
 */

import admin from "firebase-admin";
import { getApps, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

// L'emulador s'especifica via variable d'entorn FIRESTORE_EMULATOR_HOST
if (getApps().length === 0) {
  initializeApp({
    projectId: "el-visionat",
  });
}

const db = getFirestore();

// Dades de la jornada 12 (20-21 desembre 2025)
const votingJornada12 = {
  jornada: 12,
  competitionId: "19795",
  competitionName: "Super Copa Masculina",
  matches: [
    {
      matchId: "12-cbu-lloret-samba-hotels-sd-espanyol",
      jornada: 12,
      home: {
        teamId: "ubulloret",
        teamNameRaw: "CBU LLORET SAMBA HOTELS",
        teamNameDisplay: "CBU LLORET SAMBA HOTELS",
        logoSlug: "cbu-lloret-samba-hotels.webp",
        colorHex: null,
      },
      away: {
        teamId: "sdespanyol",
        teamNameRaw: "SD ESPANYOL",
        teamNameDisplay: "SD ESPANYOL",
        logoSlug: "sd-espanyol.webp",
        colorHex: null,
      },
      dateTime: "2025-12-20T17:00:00",
      dateDisplay: "Dissabte 20 Desembre, 17:00",
      status: "scheduled",
    },
    {
      matchId: "12-cb-ipsi-a-ramon-soler-cb-salt",
      jornada: 12,
      home: {
        teamId: "cbipsi",
        teamNameRaw: "CB IPSI A",
        teamNameDisplay: "CB IPSI A",
        logoSlug: "cb-ipsi-a.webp",
        colorHex: null,
      },
      away: {
        teamId: "ramonsoler",
        teamNameRaw: "RAMON SOLER CB SALT",
        teamNameDisplay: "RAMON SOLER CB SALT",
        logoSlug: "ramon-soler-cb-salt.webp",
        colorHex: null,
      },
      dateTime: "2025-12-20T17:30:00",
      dateDisplay: "Dissabte 20 Desembre, 17:30",
      status: "scheduled",
    },
    {
      matchId: "12-fc-martinenc-basquet-a-maristes-ademar-a",
      jornada: 12,
      home: {
        teamId: "fcmartinenc",
        teamNameRaw: "FC MARTINENC BÀSQUET A",
        teamNameDisplay: "FC MARTINENC BÀSQUET A",
        logoSlug: "fc-martinenc-basquet-a.webp",
        colorHex: null,
      },
      away: {
        teamId: "maristes",
        teamNameRaw: "MARISTES ADEMAR A",
        teamNameDisplay: "MARISTES ADEMAR A",
        logoSlug: "maristes-ademar-a.webp",
        colorHex: null,
      },
      dateTime: "2025-12-20T17:30:00",
      dateDisplay: "Dissabte 20 Desembre, 17:30",
      status: "scheduled",
    },
    {
      matchId: "12-ae-minguella-a-pure-cuisine-club-basquet-santfeliuenc",
      jornada: 12,
      home: {
        teamId: "minguella",
        teamNameRaw: "AE MINGUELLA A - PURE CUISINE",
        teamNameDisplay: "AE MINGUELLA A - PURE CUISINE",
        logoSlug: "ae-minguella-a-pure-cuisine.webp",
        colorHex: null,
      },
      away: {
        teamId: "santfeliuenc",
        teamNameRaw: "CLUB BASQUET SANTFELIUENC",
        teamNameDisplay: "CLUB BASQUET SANTFELIUENC",
        logoSlug: "club-basquet-santfeliuenc.webp",
        colorHex: null,
      },
      dateTime: "2025-12-20T17:45:00",
      dateDisplay: "Dissabte 20 Desembre, 17:45",
      status: "scheduled",
    },
    {
      matchId: "12-cbvic-2-universitat-de-vic-cb-martorell-a",
      jornada: 12,
      home: {
        teamId: "cbvic2",
        teamNameRaw: "CBVIC 2 - UNIVERSITAT DE VIC",
        teamNameDisplay: "CBVIC 2 - UNIVERSITAT DE VIC",
        logoSlug: "cbvic-2-universitat-de-vic.webp",
        colorHex: null,
      },
      away: {
        teamId: "cbmartorell",
        teamNameRaw: "CB MARTORELL A",
        teamNameDisplay: "CB MARTORELL A",
        logoSlug: "cb-martorell-a.webp",
        colorHex: null,
      },
      dateTime: "2025-12-20T17:45:00",
      dateDisplay: "Dissabte 20 Desembre, 17:45",
      status: "scheduled",
    },
    {
      matchId: "12-ue-montgat-jac-sants-barcelona",
      jornada: 12,
      home: {
        teamId: "uemontgat",
        teamNameRaw: "UE.MONTGAT",
        teamNameDisplay: "UE.MONTGAT",
        logoSlug: "ue-montgat.webp",
        colorHex: null,
      },
      away: {
        teamId: "jacsants",
        teamNameRaw: "JAC SANTS BARCELONA",
        teamNameDisplay: "JAC SANTS BARCELONA",
        logoSlug: "jac-sants-barcelona.webp",
        colorHex: null,
      },
      dateTime: "2025-12-20T18:00:00",
      dateDisplay: "Dissabte 20 Desembre, 18:00",
      status: "scheduled",
    },
    {
      matchId: "12-cb-artes-intersport-olaria-sama-vilanova-sam",
      jornada: 12,
      home: {
        teamId: "cbartes",
        teamNameRaw: "CB ARTÉS",
        teamNameDisplay: "CB ARTÉS",
        logoSlug: "cb-artes.webp",
        colorHex: null,
      },
      away: {
        teamId: "intersport",
        teamNameRaw: "INTERSPORT OLARIA - SAMÀ VILANOVA SAM",
        teamNameDisplay: "INTERSPORT OLARIA - SAMÀ VILANOVA SAM",
        logoSlug: "intersport-olaria-sama-vilanova-sam.webp",
        colorHex: null,
      },
      dateTime: "2025-12-20T18:15:00",
      dateDisplay: "Dissabte 20 Desembre, 18:15",
      status: "scheduled",
    },
    {
      matchId: "12-cb-alpicat-a-salas-ce-sant-nicolau",
      jornada: 12,
      home: {
        teamId: "cbalpicat",
        teamNameRaw: "CB ALPICAT A",
        teamNameDisplay: "CB ALPICAT A",
        logoSlug: "cb-alpicat-a.webp",
        colorHex: null,
      },
      away: {
        teamId: "salassantnicolau",
        teamNameRaw: "SALAS CE SANT NICOLAU",
        teamNameDisplay: "SALAS CE SANT NICOLAU",
        logoSlug: "salas-ce-sant-nicolau.webp",
        colorHex: null,
      },
      dateTime: "2025-12-21T18:00:00",
      dateDisplay: "Diumenge 21 Desembre, 18:00",
      status: "scheduled",
    },
  ],
  classification: [],
  weekendStart: "2025-12-20T00:00:00.000Z",
  weekendEnd: "2025-12-21T23:59:59.999Z",
  publishedAt: new Date().toISOString(),
  updatedAt: new Date().toISOString(),
  source: "seed-emulator",
  mappingStats: {
    totalTeams: 16,
    foundTeams: 16,
    notFoundTeams: 0,
  },
};

const votingMeta = {
  activeJornada: 12,
  weekendStart: "2025-12-20T00:00:00.000Z",
  weekendEnd: "2025-12-21T23:59:59.999Z",
  publishedAt: new Date().toISOString(),
  matchCount: 8,
};

async function seedVoting() {
  console.log("🏀 Seeding voting data to emulator...\n");

  try {
    // Guardem la jornada
    await db.collection("voting_jornades").doc("12").set(votingJornada12);
    console.log("✅ voting_jornades/12 created");

    // Guardem el meta
    await db.collection("voting_meta").doc("current").set(votingMeta);
    console.log("✅ voting_meta/current created");

    console.log("\n🎉 Voting seed completed!");
    console.log("   - Jornada: 12");
    console.log("   - Partits: 8");
    console.log("   - Cap de setmana: 20-21 Desembre 2025");
  } catch (error) {
    console.error("❌ Error seeding voting data:", error);
  }

  process.exit(0);
}

seedVoting();

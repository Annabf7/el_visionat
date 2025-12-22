// functions/src/models/video_clip.ts

import {Timestamp, FieldValue} from "firebase-admin/firestore";

/**
 * Tipus d'acció arbitral capturada al clip
 */
export type ClipActionType =
  | "falta_personal"
  | "falta_antiesportiva"
  | "falta_tecnica"
  | "falta_descalificant"
  | "avantatge"
  | "for"
  | "violacio"
  | "altres";

/**
 * Resultat de la decisió arbitral
 */
export type ClipOutcome = "encert" | "errada" | "dubte";

/**
 * Model de dades per als clips de videoinformes
 * Col·lecció: /video_clips/{clipId}
 */
export interface VideoClip {
  /** ID del document (auto-generat) */
  id?: string;

  /** UID de l'usuari propietari del clip */
  userId: string;

  /** Informació del partit (text lliure) */
  matchInfo: string;

  /** Data del partit (opcional) */
  matchDate?: Timestamp | FieldValue;

  /** Categoria del partit (ex: "Primera Catalana", "Lliga EBA") */
  matchCategory?: string;

  /** URL del vídeo a Firebase Storage */
  videoUrl: string;

  /** URL del thumbnail (generat automàticament) */
  thumbnailUrl?: string;

  /** Durada del vídeo en segons */
  durationSeconds: number;

  /** Mida del fitxer en bytes */
  fileSizeBytes: number;

  /** Tipus d'acció arbitral */
  actionType: ClipActionType;

  /** Resultat de la decisió */
  outcome: ClipOutcome;

  /** Descripció personal: "Què vaig veure i per què vaig decidir..." */
  personalDescription: string;

  /** Feedback del tècnic: "El tècnic va dir que..." */
  technicalFeedback?: string;

  /** Reflexió/Aprenentatge: "El que n'he tret és..." */
  learningNotes?: string;

  /** Si el clip és públic (visible per altres usuaris) */
  isPublic: boolean;

  /** Comptador de visualitzacions */
  viewCount: number;

  /** Comptador de "útil" (likes) */
  helpfulCount: number;

  /** Data de creació */
  createdAt: Timestamp | FieldValue;

  /** Data d'última actualització */
  updatedAt?: Timestamp | FieldValue;
}

/**
 * Interfície per crear un nou clip (sense camps auto-generats)
 */
export interface CreateVideoClipData {
  matchInfo: string;
  matchDate?: Date;
  matchCategory?: string;
  videoUrl: string;
  thumbnailUrl?: string;
  durationSeconds: number;
  fileSizeBytes: number;
  actionType: ClipActionType;
  outcome: ClipOutcome;
  personalDescription: string;
  technicalFeedback?: string;
  learningNotes?: string;
  isPublic: boolean;
}

/**
 * Mapeig de tipus d'acció a etiqueta en català
 */
export const ACTION_TYPE_LABELS: Record<ClipActionType, string> = {
  falta_personal: "Falta Personal",
  falta_antiesportiva: "Falta Antiesportiva",
  falta_tecnica: "Falta Tècnica",
  falta_descalificant: "Falta Descalificant",
  avantatge: "Avantatge",
  for: "For",
  violacio: "Violació",
  altres: "Altres",
};

/**
 * Mapeig de resultat a etiqueta en català
 */
export const OUTCOME_LABELS: Record<ClipOutcome, string> = {
  encert: "Encert ✅",
  errada: "Errada ❌",
  dubte: "Dubte 🤔",
};

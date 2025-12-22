import {Timestamp, FieldValue} from "firebase-admin/firestore";

/**
 * Configuració de visibilitat del perfil públic
 * Cada camp indica si és visible per altres usuaris
 */
export interface ProfileVisibility {
    showYearsExperience: boolean;
    showAnalyzedMatches: boolean;
    showPersonalNotes: boolean;
    showSeasonGoals: boolean;
}

/**
 * Model d'usuari per a la col·lecció /users/{uid} a Firestore.
 * Utilitzat per emmagatzemar el rol i l'estat de subscripció.
 */
export interface AppUser {
    uid: string;
    email: string;
    displayName: string;
    role: "referee" | "admin" | "table_official";
    isSubscribed: boolean; // La variable crítica de negoci
    createdAt: Timestamp | FieldValue;

    // Dades de la llicència
    llissenciaId: string;
    categoriaRrtt: string;

    // Gènere per a l'avatar per defecte ('male' | 'female')
    gender: "male" | "female";

    // Estadístiques del perfil
    analyzedMatches?: number;
    personalNotesCount?: number;
    sharedClipsCount?: number; // Clips públics compartits (per calcular nivell d'accés)

    // Imatges personalitzades
    avatarUrl?: string; // Avatar personalitzat (override del default segons gender)
    headerUrl?: string; // Header personalitzat (override del default segons gender)

    // Any d'inici com a àrbitre (per calcular anys d'experiència)
    startYear?: number;

    // Configuració de visibilitat del perfil públic
    profileVisibility?: ProfileVisibility;
}

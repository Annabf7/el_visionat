import {Timestamp, FieldValue} from "firebase-admin/firestore";

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

    // Altres camps que pots afegir al futur
    analyzedMatches?: number;
    avatarUrl?: string; // Avatar personalitzat (override del default segons gender)
    headerUrl?: string; // Header personalitzat (override del default segons gender)
}

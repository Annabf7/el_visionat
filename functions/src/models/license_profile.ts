import {Timestamp} from "firebase-admin/firestore";

/**
 * Interface for the document stored in the /referees_registry/{licenseId} collection.
 * This data acts as the master list of authorized users.
 */
export interface LicenseProfile {
    // Clau de validació primària
    email: string;

    // Camps per a la validació estricta (Nom, Cognoms)
    nom: string;
    cognoms: string;
    telefon?: string;

    // Dades de perfil
    llissenciaId: string; // Utilitzat com a ID del document a la col·lecció
    categoriaRrtt: string; // Ex: C1, C2, TT, etc.

    // Estat del compte
    accountStatus: "pending" | "active" | "suspended";
    createdAt: Timestamp;
}

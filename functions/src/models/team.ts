// functions/src/models/team.ts

import { Timestamp } from 'firebase-admin/firestore';
import { TeamGender } from './team_gender';

/**
 * Model de dades per als documents a la col·lecció /teams.
 * Aquesta serà la nostra font de veritat (Backend) i la base per al nostre caché local (Isar).
 */
export interface Team {
    /** ID del document de Firestore (el mateix ID que s'utilitzarà a Isar). */
    id: string;

    /** Nom complet de l'equip (Ex: CB Artés). */
    name: string;

    /** Acrònim curt o nom simple (Ex: ARTE). */
    acronym: string;

    /** Categoria de gènere (Masculina o Femenina). */
    gender: TeamGender;

    /** URL pública del logotip emmagatzemat a Firebase Storage (Logotip). */
    logoUrl: string;

    /** Codi hexadecimal del color primari de l'equip (Ex: "#FF0000"). */
    colorHex: string;

    /** Marca de temps per saber quan es van actualitzar per última vegada les dades (per a la sincronització). */
    lastUpdated: Timestamp;
}

export { TeamGender };

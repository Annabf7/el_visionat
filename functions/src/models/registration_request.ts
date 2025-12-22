// functions/src/models/registration_request.ts

import {Timestamp, FieldValue} from "firebase-admin/firestore";

/**
 * Model de dades per als documents a la col·lecció /registration_requests.
 * Representa una sol·licitud de registre pendent d'aprovació manual.
 */
export interface RegistrationRequest {
  /** L'ID de llicència de l'àrbitre/auxiliar. */
  llissenciaId: string;

  /** El correu electrònic que l'usuari vol utilitzar per al seu compte. */
  email: string;

  /** Nom de l'àrbitre (copiat de /referees_registry per conveniència). */
  nom: string;

  /** Cognoms de l'àrbitre (copiat de /referees_registry per conveniència). */
  cognoms: string;

  /** Gènere per a l'avatar per defecte ('male' | 'female'). */
  gender: "male" | "female";

  /** Estat actual de la sol·licitud ('pending', 'approved', 'rejected', 'completed'). */
  status: "pending" | "approved" | "rejected" | "completed";

  /** Data i hora en què es va crear la sol·licitud.
   * Permet Timestamp (lectura) o FieldValue (escriptura de serverTimestamp).
   */
  createdAt: Timestamp | FieldValue; //

  /** Data i hora de l'última actualització (opcional).
   * Permet Timestamp (lectura) o FieldValue (escriptura de serverTimestamp).
   */
  updatedAt?: Timestamp | FieldValue; //

  /** Motiu del rebuig (opcional, si status és 'rejected'). */
  rejectionReason?: string;
}

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { LicenseProfile } from '../models/license_profile'; 
import { AppUser } from '../models/app_user'; // <-- AQUEST FITXER JA EXISTEIX

// Inicialitza l'SDK d'Admin
admin.initializeApp();
const db = admin.firestore();

/**
 * Interfície d'entrada per tipar els paràmetres que arriben des de Flutter.
 */
interface RegisterData {
    email: string;
    password: string;
    nom: string;
    cognoms: string;
    llissenciaId: string;
}


/**
 * Funció Callable que valida les dades de registre contra la llista mestra de llicències
 * i crea l'usuari si la validació és correcta.
 */
export const validateLicenseRegister = functions.https.onCall(async (request, context) => { // <-- CANVIAT A 'request'
    // 1. Validació dels Paràmetres d'Entrada
    // Aplicació de tipatge indirecte: declarem el tipus de 'data' que rebem a l'objecte request.
    const data = request.data as RegisterData; // <-- CAST A L'OBJECTE DATA
    
    const { email, password, nom, cognoms, llissenciaId } = data; 

    if (!email || !password || !nom || !cognoms || !llissenciaId) {
        throw new functions.https.HttpsError('invalid-argument', 'Tots els camps de registre són obligatoris.');
    }

    // --- SEGURETAT: PAS CLAU DE VALIDACIÓ CONTRA LA LLISTA MESTRA ---
    try {
        // 2. Cercar a la Llista de Llicències
        const registryDoc = await db.collection('referees_registry').doc(llissenciaId).get();

        if (!registryDoc.exists) {
            // Llicència no trobada
            throw new functions.https.HttpsError('unauthenticated', 'Llicència no trobada al registre. Accés denegat.');
        }

        const registryData = registryDoc.data() as LicenseProfile;

        // 3. Comprovació d'Extricta Coincidència de Dades (TFG Error #6)
        const emailMatch = registryData.email.toLowerCase() === email.toLowerCase();
        const nomMatch = registryData.nom.toLowerCase() === nom.toLowerCase();
        const cognomsMatch = registryData.cognoms.toLowerCase() === cognoms.toLowerCase();

        if (!emailMatch || !nomMatch || !cognomsMatch) {
            throw new functions.https.HttpsError('unauthenticated', 'Les dades proporcionades no coincideixen amb el registre oficial. Verifiqueu nom, cognoms i correu electrònic.');
        }
        
        // 4. Comprovar que l'email no estigui ja en ús abans de crear el document /users
        try {
            await admin.auth().getUserByEmail(email);
            throw new functions.https.HttpsError('already-exists', 'Aquest correu electrònic ja té un compte registrat.');
        } catch (e: any) {
            if (e.code !== 'auth/user-not-found') {
                throw new functions.https.HttpsError('internal', 'Error de verificació d\'usuari existent.');
            }
        }


        // 5. Crear l'usuari a Firebase Authentication
        const userRecord = await admin.auth().createUser({ email, password });
        const newUid = userRecord.uid;

        // 6. Crear el Document de Perfil de l'Usuari a /users/{uid}
        const newUserProfile: AppUser = {
            uid: newUid,
            email: email,
            displayName: `${nom} ${cognoms}`,
            role: 'referee', 
            isSubscribed: false,
            createdAt: admin.firestore.Timestamp.now(),
            llissenciaId: llissenciaId,
            categoriaRrtt: registryData.categoriaRrtt,
        };

        await db.collection('users').doc(newUid).set(newUserProfile);

        // 7. Actualitzar l'estat al registre oficial 
        await registryDoc.ref.update({ accountStatus: 'active' });

        return { success: true, uid: newUid, message: 'Registre completat amb èxit.' };

    } catch (error: any) {
        console.error('Error during license registration process:', error);

        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        if (error.code && error.code === 'auth/email-already-in-use') {
             throw new functions.https.HttpsError('already-exists', 'Aquest correu electrònic ja té un compte registrat.');
        }

        throw new functions.https.HttpsError('internal', `Error intern: ${error.message}`);
    }
});

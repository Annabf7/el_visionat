// Sintaxi ESM (moderna)
export interface RefereeLicenseProfile {
  llissenciaId: string;
  email?: string; // <-- AFEGIT EL '?' PER FER-LO OPCIONAL
  nom: string;
  cognoms: string;
  categoriaRrtt: string;
  accountStatus: 'pending' | 'active';
}


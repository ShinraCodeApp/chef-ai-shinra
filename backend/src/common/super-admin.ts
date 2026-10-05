/** Único administrador de Chef AI: ninguna otra cuenta puede serlo. */
export const SUPER_ADMIN_EMAIL = 'admin@chefai.com';

export function isSuperAdminEmail(email: string | null | undefined): boolean {
  return (email ?? '').trim().toLowerCase() === SUPER_ADMIN_EMAIL;
}

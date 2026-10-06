import {
  currentLanguage,
  parseLanguage,
  requestLanguageMiddleware,
  runWithLanguage,
} from './request-language';
import { languageNote } from '../modules/ai/providers/gemini.provider';

describe('idioma de la request', () => {
  it('lee Accept-Language (castellano por defecto)', () => {
    expect(parseLanguage('en')).toBe('en');
    expect(parseLanguage('en-US,en;q=0.9')).toBe('en');
    expect(parseLanguage('es')).toBe('es');
    expect(parseLanguage(undefined)).toBe('es');
    expect(parseLanguage('fr')).toBe('es');
  });

  it('el middleware deja el idioma disponible durante la request', (done) => {
    requestLanguageMiddleware(
      { headers: { 'accept-language': 'en' } } as any,
      {} as any,
      () => {
        expect(currentLanguage()).toBe('en');
        done();
      },
    );
  });

  it('fuera de una request es castellano', () => {
    expect(currentLanguage()).toBe('es');
  });

  it('la IA recibe la instrucción de inglés solo si el usuario usa inglés', () => {
    expect(runWithLanguage('es', () => languageNote())).toBe('');
    const note = runWithLanguage('en', () => languageNote());
    expect(note).toContain('English');
    expect(note).toContain('Spanish'); // nombres de ingredientes del catálogo
  });
});

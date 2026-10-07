import { localize } from './recipe-language.interceptor';

const recipe = () => ({
  id: 'r1',
  title: 'Katsudon',
  description: 'Bowl de arroz con milanesa',
  instructions: [{ order: 1, instruction: 'Cocinar el arroz.' }],
  tips: ['Usá panko'],
  translations: {
    en: {
      title: 'Katsudon',
      description: 'Rice bowl with pork cutlet',
      instructions: ['Cook the rice.'],
      tips: ['Use panko'],
      ingredientNotes: [null, 'panko is best'],
    },
  },
  recipeIngredients: [
    { order: 0, notes: null },
    { order: 1, notes: 'mejor si es panko' },
  ],
  createdAt: new Date('2026-10-07'),
});

describe('localize (recetas en inglés)', () => {
  it('en inglés reemplaza título, descripción, pasos, tips y notas', () => {
    const out = localize(recipe(), 'en', new WeakSet()) as any;
    expect(out.description).toBe('Rice bowl with pork cutlet');
    expect(out.instructions).toEqual([
      { order: 1, instruction: 'Cook the rice.' },
    ]);
    expect(out.tips).toEqual(['Use panko']);
    expect(out.recipeIngredients[1].notes).toBe('panko is best');
    expect(out.translations).toBeUndefined();
    expect(out.createdAt).toBeInstanceOf(Date);
  });

  it('en español deja todo igual y no manda las traducciones', () => {
    const out = localize(recipe(), 'es', new WeakSet()) as any;
    expect(out.description).toBe('Bowl de arroz con milanesa');
    expect(out.recipeIngredients[1].notes).toBe('mejor si es panko');
    expect(out.translations).toBeUndefined();
  });

  it('funciona dentro de listas y objetos anidados (favoritos, planes)', () => {
    const out = localize(
      { items: [{ recipe: recipe() }] },
      'en',
      new WeakSet(),
    ) as any;
    expect(out.items[0].recipe.description).toBe('Rice bowl with pork cutlet');
  });

  it('recetas sin traducción quedan en español', () => {
    const r: any = recipe();
    r.translations = null;
    const out = localize(r, 'en', new WeakSet()) as any;
    expect(out.description).toBe('Bowl de arroz con milanesa');
  });
});

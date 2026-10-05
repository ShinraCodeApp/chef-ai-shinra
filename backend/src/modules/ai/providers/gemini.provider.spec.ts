import { InternalServerErrorException } from '@nestjs/common';
import { GeminiProvider, isBusyError } from './gemini.provider';

const RECIPE_JSON = JSON.stringify({
  title: 'Fideos con tomate',
  description: 'Rápidos',
  instructions: [{ order: 1, instruction: 'Hervir' }],
  servings: 2,
  prepTimeMinutes: 20,
  difficulty: 'easy',
  estimatedCostTotal: 1000,
  dietTags: [],
  ingredients: [{ name: 'Fideos', quantity: 200, unit: 'g', notes: null }],
  nutrition: {
    calories: 500,
    proteinG: 15,
    fatG: 8,
    carbsG: 90,
    fiberG: 4,
    sugarG: 6,
    sodiumMg: 300,
  },
});

const busy = () =>
  new Error(
    '{"error":{"code":503,"message":"This model is currently experiencing high demand.","status":"UNAVAILABLE"}}',
  );
const notFound = () =>
  new Error('{"error":{"code":404,"message":"model not found"}}');

function buildProvider(env: Record<string, string | undefined>) {
  const config = { get: (k: string) => env[k] } as any;
  const provider = new GeminiProvider(config);
  const generateContent = jest.fn();
  (provider as any).client = { models: { generateContent } };
  return { provider, generateContent };
}

describe('GeminiProvider — modelos de respaldo', () => {
  beforeEach(() => {
    // las esperas entre reintentos (3 s) se resuelven al instante
    jest.spyOn(global, 'setTimeout').mockImplementation(((fn: () => void) => {
      fn();
      return 0;
    }) as any);
  });
  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('si el primer modelo está saturado, usa el siguiente', async () => {
    const { provider, generateContent } = buildProvider({
      GEMINI_API_KEY: 'x',
    });
    generateContent.mockImplementation(async ({ model }: { model: string }) => {
      if (model === 'gemini-3.8-flash') throw busy();
      return { text: RECIPE_JSON };
    });

    const recipe = await provider.generateRecipe({
      availableIngredients: ['fideos'],
      allergies: [],
    } as any);

    expect(recipe.title).toBe('Fideos con tomate');
    const models = generateContent.mock.calls.map((c) => c[0].model);
    expect(models).toEqual([
      'gemini-3.8-flash',
      'gemini-3.8-flash',
      'gemini-flash-latest',
    ]);
  });

  it('saltea los modelos a los que la key no tiene acceso (404) sin reintentar', async () => {
    const { provider, generateContent } = buildProvider({
      GEMINI_API_KEY: 'x',
    });
    generateContent.mockImplementation(async ({ model }: { model: string }) => {
      if (model !== 'gemini-flash-lite-latest') throw notFound();
      return { text: RECIPE_JSON };
    });

    await provider.generateRecipe({
      availableIngredients: [],
      allergies: [],
    } as any);
    expect(generateContent).toHaveBeenCalledTimes(4);
  });

  it('si todo Gemini está saturado y hay GROQ_API_KEY, responde Groq', async () => {
    const { provider, generateContent } = buildProvider({
      GEMINI_API_KEY: 'x',
      GROQ_API_KEY: 'g',
    });
    generateContent.mockRejectedValue(busy());
    const fetchMock = jest.spyOn(global, 'fetch').mockResolvedValue({
      ok: true,
      json: async () => ({ choices: [{ message: { content: RECIPE_JSON } }] }),
    } as any);

    const recipe = await provider.generateRecipe({
      availableIngredients: ['fideos'],
      allergies: [],
    } as any);
    expect(recipe.title).toBe('Fideos con tomate');
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('si todo falla, el mensaje al usuario es claro y en castellano (sin el JSON de Google)', async () => {
    const { provider, generateContent } = buildProvider({
      GEMINI_API_KEY: 'x',
    });
    generateContent.mockRejectedValue(busy());

    const error = await provider
      .generateRecipe({ availableIngredients: [], allergies: [] } as any)
      .catch((e) => e);
    expect(error).toBeInstanceOf(InternalServerErrorException);
    expect(error.message).toBe(
      'La IA está con mucha demanda en este momento. Probá de nuevo en un minuto.',
    );
  });

  it('las imágenes no se mandan a Groq', async () => {
    const { provider, generateContent } = buildProvider({
      GEMINI_API_KEY: 'x',
      GROQ_API_KEY: 'g',
    });
    generateContent.mockRejectedValue(busy());
    const fetchMock = jest.spyOn(global, 'fetch');

    await expect(
      provider.detectIngredients(Buffer.from('img'), 'image/jpeg'),
    ).rejects.toBeInstanceOf(InternalServerErrorException);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('reconoce los errores de saturación', () => {
    expect(isBusyError('{"code":503,"status":"UNAVAILABLE"}')).toBe(true);
    expect(isBusyError('429 RESOURCE_EXHAUSTED')).toBe(true);
    expect(isBusyError('404 model not found')).toBe(false);
  });
});

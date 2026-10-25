import { BadRequestException, NotFoundException } from '@nestjs/common';
import { MealPlansService } from './meal-plans.service';
import { MealType } from '../../common/enums';

const RECIPE_ID = '11111111-1111-4111-8111-111111111111';

function buildService() {
  const plan = {
    id: 'plan-1',
    userId: 'user-1',
    startDate: '2026-10-20',
    endDate: '2026-10-26',
    entries: [
      {
        id: 'entry-1',
        date: '2026-10-21',
        mealType: MealType.LUNCH,
        recipeId: 'old-recipe',
        recipe: { title: 'Milanesa' },
        completed: true,
      },
    ],
  };
  const mealPlansRepository = {
    findOne: jest.fn().mockResolvedValue(plan),
    create: jest.fn((x) => x),
    save: jest.fn(async (x) => ({ id: 'new-plan', ...x })),
    remove: jest.fn(),
  };
  const entriesRepository = {
    create: jest.fn((x) => x),
    save: jest.fn(async (x) => ({ id: 'new-entry', ...x })),
    update: jest.fn(),
    delete: jest.fn(),
    findOneOrFail: jest.fn(async ({ where }) => ({ id: where.id })),
    manager: { exists: jest.fn().mockResolvedValue(true) },
  };
  const inventoryService = {
    findAllForUser: jest
      .fn()
      .mockResolvedValue([{ ingredient: { name: 'Papa' } }]),
  };
  const aiService = {
    generateDailyMealPlanForUser: jest.fn().mockResolvedValue([
      {
        mealType: MealType.LUNCH,
        recipe: { id: 'ai-recipe', title: 'Guiso' },
      },
    ]),
  };
  const service = new MealPlansService(
    mealPlansRepository as any,
    entriesRepository as any,
    inventoryService as any,
    aiService as any,
  );
  return { service, plan, mealPlansRepository, entriesRepository, aiService };
}

describe('MealPlansService — plan editable', () => {
  it('el plan a mano arranca en la fecha del celular', async () => {
    const { service, mealPlansRepository } = buildService();
    await service.createEmpty('user-1', { days: 7, startDate: '2026-10-24' });
    expect(mealPlansRepository.save).toHaveBeenCalledWith(
      expect.objectContaining({
        startDate: '2026-10-24',
        endDate: '2026-10-30',
      }),
    );
  });

  it('agrega una comida dentro del plan', async () => {
    const { service, entriesRepository } = buildService();
    await service.addEntry('user-1', 'plan-1', {
      date: '2026-10-22',
      mealType: MealType.DINNER,
      recipeId: RECIPE_ID,
    });
    expect(entriesRepository.save).toHaveBeenCalledWith(
      expect.objectContaining({
        mealPlanId: 'plan-1',
        date: '2026-10-22',
        mealType: MealType.DINNER,
        recipeId: RECIPE_ID,
      }),
    );
  });

  it('sin receta, la comida nueva la propone la IA', async () => {
    const { service, entriesRepository, aiService } = buildService();
    await service.addEntry('user-1', 'plan-1', {
      date: '2026-10-22',
      mealType: MealType.DINNER,
    });
    expect(aiService.generateDailyMealPlanForUser).toHaveBeenCalledWith(
      'user-1',
      expect.objectContaining({ mealTypes: [MealType.DINNER] }),
    );
    expect(entriesRepository.save).toHaveBeenCalledWith(
      expect.objectContaining({ recipeId: 'ai-recipe' }),
    );
  });

  it('no deja agregar una comida fuera de las fechas del plan', async () => {
    const { service } = buildService();
    await expect(
      service.addEntry('user-1', 'plan-1', {
        date: '2026-11-02',
        mealType: MealType.DINNER,
        recipeId: RECIPE_ID,
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('no deja usar una receta que no existe', async () => {
    const { service, entriesRepository } = buildService();
    entriesRepository.manager.exists.mockResolvedValue(false);
    await expect(
      service.addEntry('user-1', 'plan-1', {
        date: '2026-10-22',
        mealType: MealType.DINNER,
        recipeId: RECIPE_ID,
      }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('al cambiar la receta se destilda la comida', async () => {
    const { service, entriesRepository } = buildService();
    await service.updateEntry('user-1', 'plan-1', 'entry-1', {
      recipeId: RECIPE_ID,
    });
    expect(entriesRepository.update).toHaveBeenCalledWith('entry-1', {
      date: '2026-10-21',
      mealType: MealType.LUNCH,
      recipeId: RECIPE_ID,
      completed: false,
    });
  });

  it('mover de día o de comida no destilda', async () => {
    const { service, entriesRepository } = buildService();
    await service.updateEntry('user-1', 'plan-1', 'entry-1', {
      date: '2026-10-23',
      mealType: MealType.DINNER,
    });
    expect(entriesRepository.update).toHaveBeenCalledWith('entry-1', {
      date: '2026-10-23',
      mealType: MealType.DINNER,
      recipeId: 'old-recipe',
      completed: true,
    });
  });

  it('la IA reemplaza una sola comida, del mismo tipo y sin repetir', async () => {
    const { service, entriesRepository, aiService } = buildService();
    await service.suggestEntry('user-1', 'plan-1', 'entry-1');
    expect(aiService.generateDailyMealPlanForUser).toHaveBeenCalledWith(
      'user-1',
      {
        availableIngredients: ['Papa'],
        mealTypes: [MealType.LUNCH],
        avoidTitles: ['Milanesa'],
      },
    );
    expect(entriesRepository.update).toHaveBeenCalledWith('entry-1', {
      recipeId: 'ai-recipe',
      completed: false,
    });
  });

  it('una comida de otro plan da 404', async () => {
    const { service } = buildService();
    await expect(
      service.removeEntry('user-1', 'plan-1', 'otra'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });
});

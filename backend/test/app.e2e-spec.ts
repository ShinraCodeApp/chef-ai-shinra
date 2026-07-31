import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from './../src/app.module';

describe('Chef AI backend (e2e)', () => {
  let app: INestApplication;
  let accessToken: string;
  const email = `e2e-${Date.now()}@chefai.com`;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        transform: true,
        forbidNonWhitelisted: true,
      }),
    );
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('/health (GET) responde ok', () => {
    return request(app.getHttpServer())
      .get('/health')
      .expect(200)
      .expect({ status: 'ok', service: 'chef-ai-backend' });
  });

  it('registra un usuario y devuelve tokens', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/register')
      .send({ email, password: 'password123', name: 'E2E Test' })
      .expect(201);

    expect(res.body.accessToken).toBeDefined();
    expect(res.body.refreshToken).toBeDefined();
    accessToken = res.body.accessToken;
  });

  it('rechaza rutas protegidas sin token', () => {
    return request(app.getHttpServer()).get('/users/me').expect(401);
  });

  it('permite el flujo completo: ingrediente -> inventario -> receta -> cocinar descuenta inventario', async () => {
    const ingredientRes = await request(app.getHttpServer())
      .post('/ingredients')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        name: `Ingrediente E2E ${Date.now()}`,
        category: 'verduras',
        unit: 'unidad',
      })
      .expect(201);
    const ingredientId = ingredientRes.body.id;

    await request(app.getHttpServer())
      .post('/inventory')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ ingredientId, quantity: 5, unit: 'unidad' })
      .expect(201);

    const recipeRes = await request(app.getHttpServer())
      .post('/recipes')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        title: 'Receta E2E',
        description: 'Receta de prueba',
        instructions: [{ order: 1, instruction: 'Paso único' }],
        servings: 1,
        prepTimeMinutes: 5,
        ingredients: [{ ingredientId, quantity: 2, unit: 'unidad' }],
      })
      .expect(201);
    const recipeId = recipeRes.body.id;

    await request(app.getHttpServer())
      .post(`/recipes/${recipeId}/cook`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({})
      .expect(201);

    const inventoryRes = await request(app.getHttpServer())
      .get('/inventory')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);

    const item = inventoryRes.body.find(
      (i: any) => i.ingredientId === ingredientId,
    );
    expect(item.quantity).toBe(3); // 5 - 2
  });
});

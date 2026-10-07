import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { requestLanguageMiddleware } from './common/request-language';
import { RecipeLanguageInterceptor } from './common/interceptors/recipe-language.interceptor';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const configService = app.get(ConfigService);

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );
  app.enableCors();
  // idioma de la request (Accept-Language) para que la IA responda en él
  app.use(requestLanguageMiddleware);
  // recetas del catálogo en inglés cuando la app está en inglés
  app.useGlobalInterceptors(new RecipeLanguageInterceptor());

  const port = configService.get<number>('PORT') ?? 3000;
  await app.listen(port);
}
bootstrap();

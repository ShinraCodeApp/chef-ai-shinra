import { Module } from '@nestjs/common';
import { AiService } from './ai.service';
import { AiController } from './ai.controller';
import { AI_PROVIDER } from './ai-provider.interface';
import { GeminiProvider } from './providers/gemini.provider';
import { UsersModule } from '../users/users.module';
import { RecipesModule } from '../recipes/recipes.module';
import { IngredientsModule } from '../ingredients/ingredients.module';
import { StorageModule } from '../storage/storage.module';

@Module({
  imports: [UsersModule, RecipesModule, IngredientsModule, StorageModule],
  controllers: [AiController],
  providers: [AiService, { provide: AI_PROVIDER, useClass: GeminiProvider }],
  exports: [AiService],
})
export class AiModule {}

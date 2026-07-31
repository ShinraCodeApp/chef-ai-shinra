import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { envValidationSchema } from './config/env.validation';
import { typeOrmConfigFactory } from './config/typeorm.config';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { IngredientsModule } from './modules/ingredients/ingredients.module';
import { InventoryModule } from './modules/inventory/inventory.module';
import { RecipesModule } from './modules/recipes/recipes.module';
import { StorageModule } from './modules/storage/storage.module';
import { AiModule } from './modules/ai/ai.module';
import { MealPlansModule } from './modules/meal-plans/meal-plans.module';
import { ShoppingListsModule } from './modules/shopping-lists/shopping-lists.module';
import { AdminModule } from './modules/admin/admin.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      validationSchema: envValidationSchema,
    }),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: typeOrmConfigFactory,
    }),
    ThrottlerModule.forRoot([{ name: 'default', ttl: 60_000, limit: 60 }]),
    AuthModule,
    UsersModule,
    IngredientsModule,
    InventoryModule,
    RecipesModule,
    StorageModule,
    AiModule,
    MealPlansModule,
    ShoppingListsModule,
    AdminModule,
  ],
  controllers: [AppController],
  providers: [AppService, { provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}

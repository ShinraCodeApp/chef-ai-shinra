import { MigrationInterface, QueryRunner } from 'typeorm';

export class InitialSchema1785376691120 implements MigrationInterface {
  name = 'InitialSchema1785376691120';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "public"."ingredient_prices_unit_enum" AS ENUM('g', 'kg', 'ml', 'l', 'unidad')`,
    );
    await queryRunner.query(
      `CREATE TABLE "ingredient_prices" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "ingredientId" uuid NOT NULL, "price" double precision NOT NULL, "unit" "public"."ingredient_prices_unit_enum" NOT NULL, "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_fad98abe2698c20e5a5b5ee73d9" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "favorites" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "recipeId" uuid NOT NULL, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "UQ_9d78e74219d7b9588440208b5bf" UNIQUE ("userId", "recipeId"), CONSTRAINT "PK_890818d27523748dd36a4d1bdc8" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."recipes_difficulty_enum" AS ENUM('easy', 'medium', 'hard')`,
    );
    await queryRunner.query(
      `CREATE TABLE "recipes" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "title" character varying NOT NULL, "description" text NOT NULL, "instructions" jsonb NOT NULL, "servings" integer NOT NULL, "prepTimeMinutes" integer NOT NULL, "difficulty" "public"."recipes_difficulty_enum" NOT NULL DEFAULT 'easy', "estimatedCostTotal" double precision, "imageUrl" character varying, "dietTags" text array NOT NULL DEFAULT '{}', "isAiGenerated" boolean NOT NULL DEFAULT false, "createdByUserId" uuid, "nutrition" jsonb, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_8f09680a51bf3669c1598a21682" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."recipe_ingredients_unit_enum" AS ENUM('g', 'kg', 'ml', 'l', 'unidad')`,
    );
    await queryRunner.query(
      `CREATE TABLE "recipe_ingredients" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "recipeId" uuid NOT NULL, "ingredientId" uuid NOT NULL, "quantity" double precision NOT NULL, "unit" "public"."recipe_ingredients_unit_enum" NOT NULL, "notes" character varying, CONSTRAINT "PK_8f15a314e55970414fc92ffb532" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."ingredients_category_enum" AS ENUM('carnes', 'verduras', 'frutas', 'lacteos', 'congelados', 'bebidas', 'panaderia', 'limpieza', 'condimentos', 'otros')`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."ingredients_unit_enum" AS ENUM('g', 'kg', 'ml', 'l', 'unidad')`,
    );
    await queryRunner.query(
      `CREATE TABLE "ingredients" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "name" character varying NOT NULL, "category" "public"."ingredients_category_enum" NOT NULL, "unit" "public"."ingredients_unit_enum" NOT NULL, "barcode" character varying, "caloriesPer100g" double precision, "proteinPer100g" double precision, "fatPer100g" double precision, "carbsPer100g" double precision, "fiberPer100g" double precision, "sugarPer100g" double precision, "sodiumPer100g" double precision, "imageUrl" character varying, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "UQ_6dd23ce7dc8f1d3f7246a95d993" UNIQUE ("barcode"), CONSTRAINT "PK_9240185c8a5507251c9f15e0649" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."inventory_items_unit_enum" AS ENUM('g', 'kg', 'ml', 'l', 'unidad')`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."inventory_items_state_enum" AS ENUM('fresh', 'frozen', 'opened', 'cooked', 'expired')`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."inventory_items_source_enum" AS ENUM('manual', 'photo', 'barcode')`,
    );
    await queryRunner.query(
      `CREATE TABLE "inventory_items" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "ingredientId" uuid NOT NULL, "quantity" double precision NOT NULL, "unit" "public"."inventory_items_unit_enum" NOT NULL, "state" "public"."inventory_items_state_enum" NOT NULL DEFAULT 'fresh', "expirationDate" date, "source" "public"."inventory_items_source_enum" NOT NULL DEFAULT 'manual', "addedAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_cf2f451407242e132547ac19169" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."users_role_enum" AS ENUM('user', 'admin')`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."users_sex_enum" AS ENUM('male', 'female', 'other')`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."users_goal_enum" AS ENUM('lose_weight', 'gain_muscle', 'maintain', 'eat_healthier', 'save_money')`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."users_activitylevel_enum" AS ENUM('sedentary', 'light', 'moderate', 'active', 'very_active')`,
    );
    await queryRunner.query(
      `CREATE TABLE "users" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "email" character varying NOT NULL, "passwordHash" character varying NOT NULL, "name" character varying NOT NULL, "role" "public"."users_role_enum" NOT NULL DEFAULT 'user', "age" integer, "weightKg" double precision, "heightCm" double precision, "sex" "public"."users_sex_enum", "goal" "public"."users_goal_enum", "activityLevel" "public"."users_activitylevel_enum", "monthlyBudget" double precision, "familyMembers" integer, "dietPreferences" text array NOT NULL DEFAULT '{}', "allergies" text array NOT NULL DEFAULT '{}', "createdAt" TIMESTAMP NOT NULL DEFAULT now(), "updatedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "UQ_97672ac88f789774dd47f7c8be3" UNIQUE ("email"), CONSTRAINT "PK_a3ffb1c0c8416b9fc6f907b7433" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "refresh_tokens" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "tokenHash" character varying NOT NULL, "expiresAt" TIMESTAMP WITH TIME ZONE NOT NULL, "revoked" boolean NOT NULL DEFAULT false, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_7d8bee0204106019488c4c50ffa" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "meal_plans" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "startDate" date NOT NULL, "endDate" date NOT NULL, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_6270d3206d074e2a2520f8d0a0b" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."meal_plan_entries_mealtype_enum" AS ENUM('breakfast', 'lunch', 'snack', 'dinner')`,
    );
    await queryRunner.query(
      `CREATE TABLE "meal_plan_entries" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "mealPlanId" uuid NOT NULL, "date" date NOT NULL, "mealType" "public"."meal_plan_entries_mealtype_enum" NOT NULL, "recipeId" uuid NOT NULL, CONSTRAINT "PK_8384d591c94bb96697f81749b09" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."shopping_list_items_unit_enum" AS ENUM('g', 'kg', 'ml', 'l', 'unidad')`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."shopping_list_items_category_enum" AS ENUM('carnes', 'verduras', 'frutas', 'lacteos', 'congelados', 'bebidas', 'panaderia', 'limpieza', 'condimentos', 'otros')`,
    );
    await queryRunner.query(
      `CREATE TABLE "shopping_list_items" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "shoppingListId" uuid NOT NULL, "ingredientId" uuid, "customName" character varying, "quantity" double precision NOT NULL, "unit" "public"."shopping_list_items_unit_enum" NOT NULL, "category" "public"."shopping_list_items_category_enum" NOT NULL DEFAULT 'otros', "isChecked" boolean NOT NULL DEFAULT false, CONSTRAINT "PK_043c112c02fdc1c39fbd619fadb" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "shopping_lists" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "name" character varying NOT NULL, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_9289ace7dd5e768d65290f3f9de" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `ALTER TABLE "ingredient_prices" ADD CONSTRAINT "FK_758fc3c7d8264ae60323c80e59d" FOREIGN KEY ("ingredientId") REFERENCES "ingredients"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "favorites" ADD CONSTRAINT "FK_e747534006c6e3c2f09939da60f" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "favorites" ADD CONSTRAINT "FK_13469711425f498cae5e6faa6a8" FOREIGN KEY ("recipeId") REFERENCES "recipes"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "recipes" ADD CONSTRAINT "FK_e99544bc749b5b2803a5d5454ab" FOREIGN KEY ("createdByUserId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "recipe_ingredients" ADD CONSTRAINT "FK_2d7f407ae694e91bb3da1798c61" FOREIGN KEY ("recipeId") REFERENCES "recipes"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "recipe_ingredients" ADD CONSTRAINT "FK_05a2b62604dfd9840f4cda76a93" FOREIGN KEY ("ingredientId") REFERENCES "ingredients"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_items" ADD CONSTRAINT "FK_e11f318801d41b478302f20760d" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_items" ADD CONSTRAINT "FK_668785925cd0c80dc743fcd40e8" FOREIGN KEY ("ingredientId") REFERENCES "ingredients"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "refresh_tokens" ADD CONSTRAINT "FK_610102b60fea1455310ccd299de" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "meal_plans" ADD CONSTRAINT "FK_1ce69a2fecf3cefd6a986c452c4" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "meal_plan_entries" ADD CONSTRAINT "FK_04054fc6ab06c6e4808a0f12a4e" FOREIGN KEY ("mealPlanId") REFERENCES "meal_plans"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "meal_plan_entries" ADD CONSTRAINT "FK_a87c81bcb6a3310b0648e79032f" FOREIGN KEY ("recipeId") REFERENCES "recipes"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "shopping_list_items" ADD CONSTRAINT "FK_268e82a2d60e718cbaf8354a0f8" FOREIGN KEY ("shoppingListId") REFERENCES "shopping_lists"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "shopping_list_items" ADD CONSTRAINT "FK_36de8adfa9e601fcb8c2066d9c0" FOREIGN KEY ("ingredientId") REFERENCES "ingredients"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "shopping_lists" ADD CONSTRAINT "FK_5b9bb541ecf94396d2078d96df8" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "shopping_lists" DROP CONSTRAINT "FK_5b9bb541ecf94396d2078d96df8"`,
    );
    await queryRunner.query(
      `ALTER TABLE "shopping_list_items" DROP CONSTRAINT "FK_36de8adfa9e601fcb8c2066d9c0"`,
    );
    await queryRunner.query(
      `ALTER TABLE "shopping_list_items" DROP CONSTRAINT "FK_268e82a2d60e718cbaf8354a0f8"`,
    );
    await queryRunner.query(
      `ALTER TABLE "meal_plan_entries" DROP CONSTRAINT "FK_a87c81bcb6a3310b0648e79032f"`,
    );
    await queryRunner.query(
      `ALTER TABLE "meal_plan_entries" DROP CONSTRAINT "FK_04054fc6ab06c6e4808a0f12a4e"`,
    );
    await queryRunner.query(
      `ALTER TABLE "meal_plans" DROP CONSTRAINT "FK_1ce69a2fecf3cefd6a986c452c4"`,
    );
    await queryRunner.query(
      `ALTER TABLE "refresh_tokens" DROP CONSTRAINT "FK_610102b60fea1455310ccd299de"`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_items" DROP CONSTRAINT "FK_668785925cd0c80dc743fcd40e8"`,
    );
    await queryRunner.query(
      `ALTER TABLE "inventory_items" DROP CONSTRAINT "FK_e11f318801d41b478302f20760d"`,
    );
    await queryRunner.query(
      `ALTER TABLE "recipe_ingredients" DROP CONSTRAINT "FK_05a2b62604dfd9840f4cda76a93"`,
    );
    await queryRunner.query(
      `ALTER TABLE "recipe_ingredients" DROP CONSTRAINT "FK_2d7f407ae694e91bb3da1798c61"`,
    );
    await queryRunner.query(
      `ALTER TABLE "recipes" DROP CONSTRAINT "FK_e99544bc749b5b2803a5d5454ab"`,
    );
    await queryRunner.query(
      `ALTER TABLE "favorites" DROP CONSTRAINT "FK_13469711425f498cae5e6faa6a8"`,
    );
    await queryRunner.query(
      `ALTER TABLE "favorites" DROP CONSTRAINT "FK_e747534006c6e3c2f09939da60f"`,
    );
    await queryRunner.query(
      `ALTER TABLE "ingredient_prices" DROP CONSTRAINT "FK_758fc3c7d8264ae60323c80e59d"`,
    );
    await queryRunner.query(`DROP TABLE "shopping_lists"`);
    await queryRunner.query(`DROP TABLE "shopping_list_items"`);
    await queryRunner.query(
      `DROP TYPE "public"."shopping_list_items_category_enum"`,
    );
    await queryRunner.query(
      `DROP TYPE "public"."shopping_list_items_unit_enum"`,
    );
    await queryRunner.query(`DROP TABLE "meal_plan_entries"`);
    await queryRunner.query(
      `DROP TYPE "public"."meal_plan_entries_mealtype_enum"`,
    );
    await queryRunner.query(`DROP TABLE "meal_plans"`);
    await queryRunner.query(`DROP TABLE "refresh_tokens"`);
    await queryRunner.query(`DROP TABLE "users"`);
    await queryRunner.query(`DROP TYPE "public"."users_activitylevel_enum"`);
    await queryRunner.query(`DROP TYPE "public"."users_goal_enum"`);
    await queryRunner.query(`DROP TYPE "public"."users_sex_enum"`);
    await queryRunner.query(`DROP TYPE "public"."users_role_enum"`);
    await queryRunner.query(`DROP TABLE "inventory_items"`);
    await queryRunner.query(`DROP TYPE "public"."inventory_items_source_enum"`);
    await queryRunner.query(`DROP TYPE "public"."inventory_items_state_enum"`);
    await queryRunner.query(`DROP TYPE "public"."inventory_items_unit_enum"`);
    await queryRunner.query(`DROP TABLE "ingredients"`);
    await queryRunner.query(`DROP TYPE "public"."ingredients_unit_enum"`);
    await queryRunner.query(`DROP TYPE "public"."ingredients_category_enum"`);
    await queryRunner.query(`DROP TABLE "recipe_ingredients"`);
    await queryRunner.query(
      `DROP TYPE "public"."recipe_ingredients_unit_enum"`,
    );
    await queryRunner.query(`DROP TABLE "recipes"`);
    await queryRunner.query(`DROP TYPE "public"."recipes_difficulty_enum"`);
    await queryRunner.query(`DROP TABLE "favorites"`);
    await queryRunner.query(`DROP TABLE "ingredient_prices"`);
    await queryRunner.query(`DROP TYPE "public"."ingredient_prices_unit_enum"`);
  }
}

import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddAiGenerationsToUsers1790600000000 implements MigrationInterface {
  name = 'AddAiGenerationsToUsers1790600000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "aiGenerationsUsed" integer NOT NULL DEFAULT 0`,
    );
    await queryRunner.query(
      `ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "aiGenerationsResetAt" TIMESTAMPTZ`,
    );
    await queryRunner.query(
      `ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "aiUnlimited" boolean NOT NULL DEFAULT false`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN IF EXISTS "aiUnlimited"`);
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN IF EXISTS "aiGenerationsResetAt"`);
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN IF EXISTS "aiGenerationsUsed"`);
  }
}

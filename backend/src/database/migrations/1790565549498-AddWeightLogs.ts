import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddWeightLogs1790565549498 implements MigrationInterface {
  name = 'AddWeightLogs1790565549498';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "weight_logs" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "userId" uuid NOT NULL, "weightKg" double precision NOT NULL, "recordedAt" date NOT NULL, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_weight_logs_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `ALTER TABLE "weight_logs" ADD CONSTRAINT "FK_weight_logs_userId" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "weight_logs" DROP CONSTRAINT "FK_weight_logs_userId"`,
    );
    await queryRunner.query(`DROP TABLE "weight_logs"`);
  }
}

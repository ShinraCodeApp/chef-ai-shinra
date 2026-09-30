import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateContactsTable1790610000000 implements MigrationInterface {
  name = 'CreateContactsTable1790610000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TYPE "public"."contacts_status_enum" AS ENUM('pending', 'accepted', 'rejected')
    `);
    await queryRunner.query(`
      CREATE TABLE "contacts" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "requesterId" uuid NOT NULL,
        "addresseeId" uuid NOT NULL,
        "status" "public"."contacts_status_enum" NOT NULL DEFAULT 'pending',
        "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_contacts" PRIMARY KEY ("id"),
        CONSTRAINT "FK_contacts_requester" FOREIGN KEY ("requesterId")
          REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_contacts_addressee" FOREIGN KEY ("addresseeId")
          REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "contacts"`);
    await queryRunner.query(`DROP TYPE "public"."contacts_status_enum"`);
  }
}

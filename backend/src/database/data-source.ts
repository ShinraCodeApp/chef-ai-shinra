import 'reflect-metadata';
import * as path from 'path';
import * as dotenv from 'dotenv';
import { DataSource } from 'typeorm';

dotenv.config();

/**
 * DataSource usado por el CLI de TypeORM (migration:generate / migration:run / migration:revert).
 * Separado del factory de NestJS (config/typeorm.config.ts) porque el CLI corre fuera del
 * contexto de Nest y no tiene acceso a ConfigService.
 */
export const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT ?? 5432),
  username: process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
  // los patrones glob de TypeORM esperan '/' — en Windows path.join() devuelve '\' y rompe el match
  entities: [
    path.join(__dirname, '../modules/**/*.entity.ts').replace(/\\/g, '/'),
  ],
  migrations: [path.join(__dirname, 'migrations/*.ts').replace(/\\/g, '/')],
  synchronize: false,
});

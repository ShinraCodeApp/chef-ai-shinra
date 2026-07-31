import * as path from 'path';
import { ConfigService } from '@nestjs/config';
import { TypeOrmModuleOptions } from '@nestjs/typeorm';

export const typeOrmConfigFactory = (
  configService: ConfigService,
): TypeOrmModuleOptions => ({
  type: 'postgres',
  host: configService.get<string>('DB_HOST'),
  port: configService.get<number>('DB_PORT'),
  username: configService.get<string>('DB_USERNAME'),
  password: configService.get<string>('DB_PASSWORD'),
  database: configService.get<string>('DB_NAME'),
  autoLoadEntities: true,
  synchronize: false,
  migrations: [
    path.join(__dirname, '../database/migrations/*.js').replace(/\\/g, '/'),
  ],
  // corre las migraciones pendientes al bootear la app, para no depender de un paso manual aparte
  migrationsRun: true,
});

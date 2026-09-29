import { Module } from '@nestjs/common';
import { StorageService } from './storage.service';
import { ImagesController } from './images.controller';

@Module({
  controllers: [ImagesController],
  providers: [StorageService],
  exports: [StorageService],
})
export class StorageModule {}

import { Controller, Get, Param, Res } from '@nestjs/common';
import { Response } from 'express';
import { StorageService } from './storage.service';
import { Public } from '../../common/decorators/public.decorator';

@Controller('images')
export class ImagesController {
  constructor(private readonly storageService: StorageService) {}

  @Public()
  @Get('recipe-images/:filename')
  async serveRecipeImage(
    @Param('filename') filename: string,
    @Res() res: Response,
  ) {
    const { stream, contentType } = await this.storageService.getObject(
      `recipe-images/${filename}`,
    );
    res.setHeader('Content-Type', contentType);
    res.setHeader('Cache-Control', 'public, max-age=86400');
    stream.pipe(res);
  }
}

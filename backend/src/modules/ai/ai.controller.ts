import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  AuthenticatedUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';
import { AiService } from './ai.service';
import { GenerateRecipeDto } from './dto/generate-recipe.dto';
import { ParseVoiceInventoryDto } from './dto/parse-voice-inventory.dto';

const MAX_IMAGE_SIZE_BYTES = 10 * 1024 * 1024;
const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp'];

@Controller('ai')
@UseGuards(JwtAuthGuard)
export class AiController {
  constructor(private readonly aiService: AiService) {}

  @Post('recipes/generate')
  generateRecipe(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: GenerateRecipeDto,
  ) {
    return this.aiService.generateRecipeForUser(user.userId, dto);
  }

  @Post('inventory/scan')
  @UseInterceptors(
    FileInterceptor('image', { limits: { fileSize: MAX_IMAGE_SIZE_BYTES } }),
  )
  scanInventory(@UploadedFile() image?: Express.Multer.File) {
    if (!image) {
      throw new BadRequestException(
        'Falta el archivo de imagen (campo "image")',
      );
    }
    if (!ALLOWED_MIME_TYPES.includes(image.mimetype)) {
      throw new BadRequestException(
        'Formato de imagen no soportado (usar JPEG, PNG o WEBP)',
      );
    }
    return this.aiService.scanImageForIngredients(image.buffer, image.mimetype);
  }

  @Post('receipt/scan')
  @UseInterceptors(
    FileInterceptor('image', { limits: { fileSize: MAX_IMAGE_SIZE_BYTES } }),
  )
  scanReceipt(@UploadedFile() image?: Express.Multer.File) {
    if (!image) {
      throw new BadRequestException(
        'Falta el archivo de imagen (campo "image")',
      );
    }
    if (!ALLOWED_MIME_TYPES.includes(image.mimetype)) {
      throw new BadRequestException(
        'Formato de imagen no soportado (usar JPEG, PNG o WEBP)',
      );
    }
    return this.aiService.scanReceiptForItems(image.buffer, image.mimetype);
  }

  @Post('meal/analyze')
  @UseInterceptors(
    FileInterceptor('image', { limits: { fileSize: MAX_IMAGE_SIZE_BYTES } }),
  )
  analyzeMeal(@UploadedFile() image?: Express.Multer.File) {
    if (!image) {
      throw new BadRequestException(
        'Falta el archivo de imagen (campo "image")',
      );
    }
    if (!ALLOWED_MIME_TYPES.includes(image.mimetype)) {
      throw new BadRequestException(
        'Formato de imagen no soportado (usar JPEG, PNG o WEBP)',
      );
    }
    return this.aiService.analyzeMealPhoto(image.buffer, image.mimetype);
  }

  @Post('inventory/parse-voice')
  parseVoiceInventory(@Body() dto: ParseVoiceInventoryDto) {
    return this.aiService.parseVoiceInventory(dto.text);
  }

  @Get('health-advice')
  getHealthAdvice(@CurrentUser() user: AuthenticatedUser) {
    return this.aiService.getHealthAdviceForUser(user.userId);
  }
}

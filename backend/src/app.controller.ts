import { Controller, Get, Res } from '@nestjs/common';
import { Response } from 'express';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get('health')
  getHealth() {
    return this.appService.getHealth();
  }

  @Get('delete-account')
  getDeleteAccount(@Res() res: Response) {
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.send(`<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Chef AI — Eliminar cuenta</title>
<style>
  :root { --bg: #fafaf8; --fg: #1a1a18; --muted: #6b6b60; --accent: #2d6a4f; --border: #e0e0d8; --card: #f0f0ec; }
  @media (prefers-color-scheme: dark) {
    :root { --bg: #141412; --fg: #e8e8e0; --muted: #9a9a8e; --accent: #52b788; --border: #2a2a26; --card: #1e1e1a; }
  }
  *, *::before, *::after { box-sizing: border-box; margin: 0; }
  body { background: var(--bg); color: var(--fg); font-family: system-ui, sans-serif; font-size: 1rem; line-height: 1.7; padding: 2rem 1rem; max-width: 600px; margin: 0 auto; }
  h1 { font-size: 1.6rem; font-weight: 700; margin-bottom: 0.5rem; color: var(--fg); }
  .logo { font-size: 0.9rem; color: var(--accent); font-weight: 600; margin-bottom: 1rem; letter-spacing: 0.05em; text-transform: uppercase; }
  p { margin-bottom: 1rem; color: var(--fg); }
  .card { background: var(--card); border: 1px solid var(--border); border-radius: 10px; padding: 1.5rem; margin: 1.5rem 0; }
  .card h2 { font-size: 1rem; font-weight: 600; margin-bottom: 0.75rem; }
  ol { padding-left: 1.25rem; }
  ol li { margin-bottom: 0.5rem; }
  .email-link { color: var(--accent); font-weight: 600; word-break: break-all; }
  .note { font-size: 0.875rem; color: var(--muted); border-left: 3px solid var(--border); padding-left: 0.75rem; margin-top: 1rem; }
  footer { margin-top: 2.5rem; padding-top: 1rem; border-top: 1px solid var(--border); font-size: 0.8rem; color: var(--muted); }
</style>
</head>
<body>
<div class="logo">Chef AI · ShinraCode</div>
<h1>Solicitar eliminación de cuenta</h1>
<p>Podés solicitar la eliminación de tu cuenta y todos tus datos personales de Chef AI en cualquier momento.</p>

<div class="card">
  <h2>Opción 1 — Desde la app</h2>
  <ol>
    <li>Abrí Chef AI en tu dispositivo.</li>
    <li>Andá a <strong>Perfil → Configuración</strong>.</li>
    <li>Tocá <strong>Eliminar cuenta</strong> y confirmá.</li>
  </ol>
  <p class="note">Tu cuenta y todos tus datos se eliminarán de forma permanente e inmediata.</p>
</div>

<div class="card">
  <h2>Opción 2 — Por correo electrónico</h2>
  <p>Si no tenés acceso a la app, envianos un email desde la dirección asociada a tu cuenta:</p>
  <p class="email-link">yamilrueda88@gmail.com</p>
  <p>Asunto sugerido: <em>Solicitud de eliminación de cuenta — Chef AI</em></p>
  <p class="note">Procesamos las solicitudes en un plazo de 30 días hábiles. Se eliminará tu cuenta, recetas, inventario, plan de comidas, listas de compras y datos de perfil.</p>
</div>

<footer>Chef AI · ShinraCode · © 2026</footer>
</body>
</html>`);
  }
}

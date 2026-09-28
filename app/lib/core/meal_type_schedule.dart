import 'package:flutter/material.dart';

/// Horario por defecto (no configurable por el usuario en esta versión) que se usa
/// para agendar el recordatorio de cada tipo de comida del plan semanal.
const Map<String, TimeOfDay> kMealTypeDefaultTimes = {
  'breakfast': TimeOfDay(hour: 8, minute: 0),
  'mid_morning': TimeOfDay(hour: 10, minute: 30),
  'lunch': TimeOfDay(hour: 13, minute: 0),
  'post_workout': TimeOfDay(hour: 16, minute: 30),
  'snack': TimeOfDay(hour: 17, minute: 30),
  'dinner': TimeOfDay(hour: 21, minute: 0),
};

/// Orden canónico en el que deben mostrarse/ordenarse las comidas de un mismo día.
const List<String> kMealTypeOrder = [
  'breakfast',
  'mid_morning',
  'lunch',
  'post_workout',
  'snack',
  'dinner',
];

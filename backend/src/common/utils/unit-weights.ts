/**
 * Peso promedio (en gramos) de UNA unidad de los ingredientes que se cuentan por
 * unidad. Permite comparar una receta que pide "150 g de cebolla" con un
 * inventario que tiene "3 unidades" (y al revés). Son promedios de mercado en
 * Argentina: alcanzan para saber si te falta algo y para descontar del
 * inventario, no para pesar en una balanza. Para líquidos se toma 1 ml ≈ 1 g.
 */
export const UNIT_WEIGHTS_G: Record<string, number> = {
  // verduras
  tomate: 120,
  cebolla: 150,
  morron: 150,
  lechuga: 300,
  ajo: 5, // un diente
  papa: 170,
  zanahoria: 80,
  batata: 250,
  berenjena: 250,
  zapallito: 200,
  pepino: 200,
  palta: 200,
  'cebolla de verdeo': 25,
  'chile verde': 15,
  caigua: 50,
  apio: 40, // una rama
  repollo: 1000,
  alcachofa: 200,
  hinojo: 250,
  puerro: 150,
  nabo: 120,
  choclo: 250,
  remolacha: 150,
  // frutas
  manzana: 180,
  banana: 120,
  limon: 100,
  naranja: 180,
  mandarina: 100,
  pera: 170,
  durazno: 150,
  ciruela: 60,
  mango: 300,
  granada: 250,
  maracuya: 50,
  caqui: 170,
  melon: 1200,
  kiwi: 75,
  frutilla: 15,
  pina: 1500, // ananá entero
  anana: 1500,
  sandia: 4000,
  // huevos, lácteos y panificados
  huevo: 50,
  yogur: 125, // un pote
  pan: 60, // un pan francés
  'tortilla de trigo': 40,
  'tostada de maiz': 15,
  medialuna: 40,
  'tapa de empanada': 30,
  pascualina: 400, // un paquete de tapas
  flan: 120,
  // carnes y embutidos
  chorizo: 100,
  salchichas: 50,
  salchicha: 50,
  'pechuga de pollo': 200,
  milanesa: 150,
  hamburguesa: 110,
  // latas y envases
  'lata de atun': 170,
  atun: 170,
};

function normalize(name: string): string {
  return name
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '') // saca los acentos
    .replace(/\s+/g, ' ')
    .trim();
}

// Variedades del mismo producto: "cebolla morada" pesa como "cebolla". Otras
// palabras cambian el producto ("pan rallado" no es "pan"), así que no se usan.
const VARIETY =
  /^(de campo|morada|morado|blanca|blanco|colorada|colorado|perita|cherry|negra|roja|rojo|verde|amarilla|amarillo|grande|mediana|mediano|chica|chico)$/;

/**
 * Gramos que pesa una unidad de este ingrediente, o null si no lo conocemos.
 * Prueba el nombre completo, en singular ("tomates" → "tomate") y la primera
 * palabra solo si el resto es una variedad ("huevo de campo" → "huevo").
 */
export function unitWeightFor(name: string | null | undefined): number | null {
  if (!name) return null;
  const n = normalize(name);
  const [first, ...rest] = n.split(' ');
  const candidates = [n, n.replace(/es$/, ''), n.replace(/s$/, '')];
  if (rest.length > 0 && VARIETY.test(rest.join(' '))) {
    candidates.push(first, first.replace(/es$/, ''), first.replace(/s$/, ''));
  }
  for (const c of candidates) {
    if (UNIT_WEIGHTS_G[c] !== undefined) return UNIT_WEIGHTS_G[c];
  }
  return null;
}

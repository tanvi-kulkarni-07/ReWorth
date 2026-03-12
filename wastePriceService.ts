// wastePriceService.ts
// Handles market price prediction for different waste types using
// a combination of hardcoded defaults and Firestore overrides.

import {
  getFirestore,
  collection,
  query,
  where,
  getDocs,
  serverTimestamp,
  DocumentData,
} from 'firebase/firestore';

// base prices per kilogram (rupees)
export const BASE_PRICE_MAP: Record<string, number> = {
  plastic: 20,
  paper: 12,
  metal: 40,
  electronics: 50,
  organic: 5,
  glass: 8,
};

// demand multipliers used for AI-style adjustment
export const DEMAND_FACTOR_MAP: Record<string, number> = {
  plastic: 1.2,
  metal: 1.3,
  electronics: 1.4,
  paper: 1.0,
  organic: 0.8,
  glass: 1.0, // default factor for glass
};

// Structure returned by predictWastePrice
export interface PricePrediction {
  pricePerKg: number;
  totalValue: number;
}

// Structure used by estimateWasteValue
export interface WasteEstimate {
  wasteType: string;
  weightKg: number;
  pricePerKg: number;
  totalEstimatedValue: number;
}

// Firestore collection name
const MARKET_COL = 'wasteMarketPrices';

// fetch market price configuration from Firestore if available
export async function getWasteMarketPrice(
  wasteType: string,
): Promise<{ basePrice: number; demandFactor: number }> {
  const db = getFirestore();
  const normalized = wasteType.toLowerCase();
  try {
    const colRef = collection(db, MARKET_COL);
    const q = query(colRef, where('wasteType', '==', normalized));
    const snap = await getDocs(q);
    if (!snap.empty) {
      const doc = snap.docs[0].data();
      const bp = (doc.basePrice as number) || BASE_PRICE_MAP[normalized] || 0;
      const df = (doc.demandFactor as number) || DEMAND_FACTOR_MAP[normalized] || 1;
      return { basePrice: bp, demandFactor: df };
    }
  } catch (e) {
    // log and fall through to defaults
    console.error('getWasteMarketPrice error', e);
  }

  // fallback constants
  return {
    basePrice: BASE_PRICE_MAP[normalized] ?? 0,
    demandFactor: DEMAND_FACTOR_MAP[normalized] ?? 1,
  };
}

// Predicts price given a waste type and weight.  Does not consult Firestore.
export function predictWastePrice(
  wasteType: string,
  weightKg: number,
): PricePrediction {
  const normalized = wasteType.toLowerCase();
  const base = BASE_PRICE_MAP[normalized] ?? 0;
  const factor = DEMAND_FACTOR_MAP[normalized] ?? 1;
  const pricePerKg = base * factor;
  const totalValue = pricePerKg * weightKg;
  return { pricePerKg, totalValue };
}

// Higher‑level helper combining Firestore lookup and prediction logic.
export async function estimateWasteValue(
  wasteType: string,
  weightKg: number,
): Promise<WasteEstimate> {
  if (!wasteType || weightKg <= 0) {
    throw new Error('Invalid arguments');
  }
  const { basePrice, demandFactor } = await getWasteMarketPrice(wasteType);
  const pricePerKg = basePrice * demandFactor;
  const totalEstimatedValue = pricePerKg * weightKg;
  return {
    wasteType,
    weightKg,
    pricePerKg,
    totalEstimatedValue,
  };
}

// optionally, a function to refresh or set a market price document
export async function setWasteMarketPrice(
  wasteType: string,
  basePrice: number,
  demandFactor: number,
): Promise<void> {
  const db = getFirestore();
  const colRef = collection(db, MARKET_COL);
  const normalized = wasteType.toLowerCase();
  try {
    // simplistic: add new doc; in production you'd upsert by ID
    await colRef.add({
      wasteType: normalized,
      basePrice,
      demandFactor,
      lastUpdated: serverTimestamp(),
    });
  } catch (e) {
    console.error('setWasteMarketPrice error', e);
    throw e;
  }
}

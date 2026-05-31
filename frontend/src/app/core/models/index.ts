export interface User {
  id: number;
  email: string;
  fullName: string;
  role: string;
  subscriptionStatus: string;
  pro: boolean;
}

export interface SensorReading {
  id: number;
  temperature: number;
  humidity: number;
  soilMoisture: number;
  recordedAt: string;
}

export interface ProjectInfo {
  name: string;
  tagline: string;
  description: string;
  features: string[];
  desktopApp: { name: string; sync: string; platform: string };
}

export interface PricingPlan {
  id: string;
  name: string;
  price: number;
  currency: string;
  interval?: string;
  features: string[];
}

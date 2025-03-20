import config from 'config';
import { TokensConfig } from '../typings/globals';

export const isProduction = (): boolean => {
  return process.env.NODE_ENV === 'production';
};

export const isLocalhost = (): boolean => {
  return process.env.NODE_ENV === 'localhost';
};

export const getJWTSecret = (): string => {
  const secret = config.get<TokensConfig>('tokens').jwtSecret;

  return isProduction() ? secret.prod : secret.rest;
};

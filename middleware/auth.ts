import { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { getJWTSecret, isProduction } from '../lib/env';
import UserService from '../services/user';
import { WebTokenPayload } from '../typings/globals';
import { User } from '../typings/user';
import {
  HEADER_NAME_API_AUTH,
  HEADER_NAME_API_PROD_MODE,
  HEADER_NAME_API_VERSION
} from './headers';

export const checkAccess = async (req: Request, res: Response, next: NextFunction) => {
  const token = req.header(HEADER_NAME_API_AUTH);
  if (!token) {
    return res.status(401).json({ msg: 'No token, authorization denied' });
  }

  try {
    const payload = jwt.verify(token, getJWTSecret());

    // Fetch user based on the ID decoded from the token
    const user = (await UserService.getById((payload as WebTokenPayload)._id)) as User;

    // Report API version for all the authenticated requests
    res.set(HEADER_NAME_API_VERSION, process.env.npm_package_version);

    // Also report if the API is configured to run in production mode
    res.set(HEADER_NAME_API_PROD_MODE, `${isProduction()}`);

    if (!user.userIsActive) {
      return res.status(401).json({ msg: 'User is currently inactive. Access denied' });
    }

    req.user = user;

    next();
  } catch (e) {
    res.status(400).json({ msg: 'Token is not valid', details: e.message });
  }
};

export const isRequestAuthenticated = async (req: Request) => {
  try {
    const payload =
      (req.header(HEADER_NAME_API_AUTH) &&
        jwt.verify(req.header(HEADER_NAME_API_AUTH), getJWTSecret())) ||
      null;

    return (payload && !!(await UserService.getById((payload as WebTokenPayload)._id))) || false;
  } catch {
    return false;
  }
};

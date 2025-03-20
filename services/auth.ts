import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { WebTokenPayload } from '../typings/globals';
import { getJWTSecret } from '../lib/env';
import UserService from './user';

// Password-less tokens will last 3 hours
const WEB_TOKEN_EXPIRATION_TIME = '3h';

class AuthService {
  /**
   * For password-less flow tokens will NOT last forever. They will expire
   * right after {WEB_TOKEN_EXPIRATION_TIME} seconds have elapsed
   *
   * @returns The amount of time password-less tokens will be valid for
   */
  public getWebTokenExpirationTime = (): string => WEB_TOKEN_EXPIRATION_TIME;

  public signUserIn = async ({
    userUsername,
    userPassword,
    isPasswordLess
  }: {
    userUsername: string;
    userPassword?: string;
    isPasswordLess: boolean;
  }): Promise<any> => {
    if (
      !userUsername ||
      !userUsername.trim().length ||
      (!isPasswordLess && !userPassword?.trim())
    ) {
      throw new Error('Por favor, ingrese todos los campos');
    }

    const cleanUsername = userUsername.trim();
    if (cleanUsername.includes(' ')) {
      throw new Error('El nombre de usuario no puede contener espacios');
    }

    const user = await UserService.getByUsername(cleanUsername);

    if (!user) {
      throw new Error('El usuario no existe');
    } else if (!user.userPassword || !user._id) {
      throw new Error(
        `Ocurrió un problema con los datos del usuario '${cleanUsername}'. Contacte al administrador del sistema`
      );
    }

    if (!isPasswordLess) {
      if (!(await bcrypt.compare(userPassword, user.userPassword))) {
        throw new Error('Credenciales invalidas');
      }
    }

    const payload = { _id: user?._id } as WebTokenPayload;

    const token = jwt.sign(payload, getJWTSecret(), {
      expiresIn: this.getWebTokenExpirationTime()
    });
    // Take user password away from the rest of the attributes
    const { userPassword: hashedPassword, ...rest } = user;
    return { token, user: rest };
  };
}

const authService = new AuthService();

export default authService;

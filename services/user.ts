import { SimpleObject } from '../typings/globals';
import BaseService from './base';
import ErrorWithStatus from '../lib/error';

class UserService extends BaseService {
  public getById = async (userAccountId: string): Promise<SimpleObject> => {
    const res = await this.baseSecureQueryPerformer({
      queryString: `SELECT user_account_id AS _id, * FROM user_account WHERE user_account_id = $1`,
      queryParams: [userAccountId]
    });

    if (res.length > 0) {
      return res[0];
    }

    throw new ErrorWithStatus(
      `No se ha encontrado usuario con user_account_id = '${userAccountId}'`,
      404
    );
  };

  public getByUsername = async (userUsername: string): Promise<SimpleObject> => {
    const res = await this.baseSecureQueryPerformer({
      queryString: `SELECT user_account_id AS _id, * FROM user_account WHERE user_username = $1`,
      queryParams: [userUsername]
    });

    if (res.length > 0) {
      return res[0];
    }

    throw new ErrorWithStatus(
      `No se ha encontrado usuario con user_username = '${userUsername}'`,
      404
    );
  };
}

const userService = new UserService();

export default userService;

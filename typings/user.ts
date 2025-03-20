import { BasicEntity } from './globals';

export interface User extends BasicEntity {
  userAccountId: string;
  userUsername: string;
  userPassword: string;
  userIsActive: boolean;
}

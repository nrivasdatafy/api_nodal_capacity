import { User } from "../../typings/user";

declare global {
  namespace Express {
    interface Request {
      user: User;
      rawBody: string;
    }
  }
}

import express, { Request, Response } from 'express';
import authService from '../../services/auth';
import logger from '../../lib/logger';
import userService from '../../services/user';
import { checkAccess } from '../../middleware/auth';

const router = express.Router();

// @route  POST api/auth
// @desc   Authenticate user
// @access Public
router.post('/', async (req: Request, res: Response) => {
  const { userUsername, userPassword } = req.body;

  try {
    const { user, token } = await authService.signUserIn({
      userUsername,
      userPassword,
      isPasswordLess: false
    });

    if (!user.userIsActive) {
      return res.status(401).json({ msg: 'El usuario no se encuentra habilitado en el sistema' });
    }

    res.json({ user, token });
  } catch (error) {
    logger.error(error);
    res.status(400).json({ msg: error.message });
  }
});

// @route  GET api/auth/user
// @desc   Get user data
// @access Private
router.get('/user', checkAccess, async (req: Request, res: Response) => {
  try {
    res.json(await userService.getById(req.user._id));
  } catch (error) {
    logger.error(error);
    res.status(400).json({ msg: 'No se pudo obtener el usuario' });
  }
});

export default router;

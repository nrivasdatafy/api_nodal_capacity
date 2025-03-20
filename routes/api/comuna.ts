import express, { Request, Response } from 'express';
import logger from '../../lib/logger';
import ComunaService from '../../services/comuna';
import { checkAccess } from '../../middleware/auth';

const router = express.Router();

// @route  GET api/comuna
// @desc   Get all 'comunas' by regionId
// @access Private
router.get('/', checkAccess, async (req: Request, res: Response) => {
  try {
    res.json(await ComunaService.getAll(req.query?.regionId as string));
  } catch (error) {
    logger.error(error);
    res.status(error.statusCode || 500).json({
      msg: `No se pudo obtener la lista de Comunas`,
      details: error.message
    });
  }
});

// @route  GET api/comuna/getComuna
// @desc   Get 'comuna' info by comunaId (lat, log)
// @access Private
router.get('/getComuna', checkAccess, async (req: Request, res: Response) => {
  try {
    res.json(await ComunaService.getById(req.query?.comunaId as string));
  } catch (error) {
    logger.error(error);
    res.status(error.statusCode || 500).json({
      msg: `No se pudo obtener la informacion de la comuna`,
      details: error.message
    });
  }
});

export default router;

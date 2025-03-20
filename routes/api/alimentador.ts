import express, { Request, Response } from 'express';
import logger from '../../lib/logger';
import AlimentadorService from '../../services/alimentador';
import { checkAccess } from '../../middleware/auth';

const router = express.Router();

// @route  GET api/alimentador/getAlimentadorData
// @desc   Get 'alimentador' data by alimentadorId
// @access Private
router.get('/getAlimentadorData', checkAccess, async (req: Request, res: Response) => {
  try {
    res.json(await AlimentadorService.getAlimentadorData(req.query?.alimentadorId as string));
  } catch (error) {
    logger.error(error);
    res.status(error.statusCode || 500).json({
      msg: `No se pudo obtener el alimentador`,
      details: error.message
    });
  }
});

export default router;

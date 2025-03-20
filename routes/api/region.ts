import express, { Request, Response } from 'express';
import logger from '../../lib/logger';
import RegionService from '../../services/region';
import { checkAccess } from '../../middleware/auth';

const router = express.Router();

// @route  GET api/region
// @desc   Get all 'regiones'
// @access Private
router.get('/', checkAccess, async (_: Request, res: Response) => {
  try {
    res.json(await RegionService.getAll());
  } catch (error) {
    logger.error(error);
    res.status(error.statusCode || 500).json({
      msg: `No se pudo obtener la lista de regiones`,
      details: error.message
    });
  }
});

// @route  GET api/comuna/getRegion
// @desc   Get 'region' info by regionId (lat, log)
// @access Private
router.get('/getRegion', checkAccess, async (req: Request, res: Response) => {
  try {
    res.json(await RegionService.getById(req.query?.regionId as string));
  } catch (error) {
    logger.error(error);
    res.status(error.statusCode || 500).json({
      msg: `No se pudo obtener la informacion de la comuna`,
      details: error.message
    });
  }
});

export default router;

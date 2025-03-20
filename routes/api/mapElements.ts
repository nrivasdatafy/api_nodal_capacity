import express, { Request, Response } from 'express';
import logger from '../../lib/logger';
import MapElementService from '../../services/mapElement';
import { checkAccess } from '../../middleware/auth';

const router = express.Router();

// @route  GET api/mapElements/geoJSON/all
// @desc   Get all 'mapElements' related to an alimentadorId
// @param  alimentadorId: number
// @access Private
router.get('/geoJSON/all', checkAccess, async (req: Request, res: Response) => {
  try {
    const { alimentadorId } = req.query;
    res.json(await MapElementService.getAllFeaturesByAlimentadorId(Number(alimentadorId)));
  } catch (error) {
    logger.error(error);
    res.status(error.statusCode || 500).json({
      msg: `No se pudo obtener el conjunto de elementos del mapa`,
      details: error.message
    });
  }
});

// @route  GET api/mapElements/alimentadores
// @desc   Get all 'mapElements' related to an alimentadorId
// @access Private
router.get('/alimentadores', checkAccess, async (_: Request, res: Response) => {
  try {
    res.json(await MapElementService.getAlimentadores());
  } catch (error) {
    logger.error(error);
    res.status(error.statusCode || 500).json({
      msg: `No se pudo obtener el conjunto de elementos del mapa`,
      details: error.message
    });
  }
});

// @route  GET api/mapElements/geoJSON/lines
// @desc   Get all 'lines' related to an alimentadorId
// @param  alimentadorId: number
// @access Private
router.get('/geoJSON/lines', checkAccess, async (req: Request, res: Response) => {
  try {
    const { alimentadorId } = req.query;
    res.json(await MapElementService.getLineFeaturesByAlimentadorId(Number(alimentadorId)));
  } catch (error) {
    logger.error(error);
    res.status(error.statusCode || 500).json({
      msg: `No se pudo obtener el conjunto de elementos del mapa`,
      details: error.message
    });
  }
});

// @route  GET api/mapElements/geoJSON/polygons
// @desc   Get all 'polygons' related to an alimentadorId
// @param  alimentadorId: number
// @access Public
router.get('/geoJSON/polygons', checkAccess, async (req: Request, res: Response) => {
  try {
    const { alimentadorId } = req.query;
    res.json(await MapElementService.getPolygonFeaturesByAlimentadorId(Number(alimentadorId)));
  } catch (error) {
    logger.error(error);
    res.status(error.statusCode || 500).json({
      msg: `No se pudo obtener el conjunto de elementos del mapa`,
      details: error.message
    });
  }
});

// @route  GET api/mapElements/geoJSON/points
// @desc   Get all 'points' related to an alimentadorId
// @param  alimentadorId: number
// @access Private
router.get('/geoJSON/points', checkAccess, async (req: Request, res: Response) => {
  try {
    const { alimentadorId } = req.query;
    res.json(await MapElementService.getPointFeaturesByAlimentadorId(Number(alimentadorId)));
  } catch (error) {
    logger.error(error);
    res.status(error.statusCode || 500).json({
      msg: `No se pudo obtener el conjunto de elementos del mapa`,
      details: error.message
    });
  }
});

// @route  PATCH api/mapElements/regenerateMapElements
// @desc   regenerate all the elements of map (Lines, Points, Polygons, etc..)
// @access Private
router.patch('/regenerateMapElements', checkAccess, async (_: Request, res: Response) => {
  try {
    res.json(await MapElementService.regenerateMapElements());
  } catch (error) {
    logger.error(error);
    res.status(error.statusCode || 500).json({
      msg: `No se pudo re-generar los polygonos`,
      details: error.message
    });
  }
});

// @route  GET api/mapElements/missingLines
// @desc   Get all 'lines' that are missing in the database
// @access Private
router.get('/missingLines', checkAccess, async (_: Request, res: Response) => {
  try {
    res.json(await MapElementService.missingLines());
  } catch (error) {
    logger.error(error);
    res.status(error.statusCode || 500).json({
      msg: `No se pudieron obtener las líneas faltantes`,
      details: error.message
    });
  }
});

export default router;

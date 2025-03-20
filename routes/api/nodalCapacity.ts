import express, { Request, Response } from 'express';
import logger from '../../lib/logger';
import { checkAccess } from '../../middleware/auth';
import { spawn } from 'child_process';
import path from 'path';

const router = express.Router();

// @route   POST api/nodalCapacity
// @desc    execute nodalCapacitys scripts
// @body
//          functionName: string
//          params?: Array<any>
// @access  Private
router.post('/', checkAccess, async (req: Request, res: Response) => {
  const basePath = '../../NodalCapacity/src/api';
  const script = 'main.jl';
  try {
    const { functionName, params } = req.body;

    if (!functionName) {
      throw Error('functionName is required');
    }

    const juliaScriptPath = path.join(__dirname, `${basePath}/${script}`);

    const julia = spawn('julia', [
      `--project=${path.join(__dirname, '../../NodalCapacity')}`,
      juliaScriptPath,
      functionName as string,
      ...(params ? params.map((value) => `${value}`) : [])
    ]);

    let output = '';
    let errorOutput = '';

    // capture output
    julia.stdout.on('data', (data) => {
      output += data.toString();
    });

    // capture error
    julia.stderr.on('data', (data) => {
      errorOutput += data.toString();
    });

    // handles process closure
    julia.on('close', (code) => {
      if (code === 0) {
        try {
          const lines = output.trim().split('\n');
          try {
            const jsonResponse = JSON.parse(lines[lines.length - 1]); // Last line is the JSON

            res.status(200).json({
              msg: 'Se completó la solicitud',
              logs: lines.slice(0, -1).join('\n'), // All lines except the JSON
              result: jsonResponse
            });
          } catch {
            res.status(200).json({
              msg: 'Se completó la solicitud',
              logs: lines.slice(0, -1).join('\n'), // All lines except the JSON
              result: lines[lines.length - 1]
            });
          }
        } catch (err) {
          res.status(500).json({
            msg: 'Error procesando la respuesta de Julia',
            details: err.message
          });
        }
      } else {
        // return errors
        res.status(500).json({
          msg: `Error al ejecutar el script ${script}`,
          details: errorOutput.trim()
        });
      }
    });
  } catch (error) {
    logger.error(error);
    res.status(error.statusCode || 500).json({
      msg: `Error al ejecutar el script ${script}`,
      details: error.message
    });
  }
});

export default router;

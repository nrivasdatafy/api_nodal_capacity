import ErrorWithStatus from '../lib/error';
import BaseService from './base';

class ComunaService extends BaseService {
  public async getAll(regionId: string): Promise<any[]> {
    if (!regionId) {
      throw new ErrorWithStatus('No se recibió el regionId', 400);
    }
    return await this.baseSecureQueryPerformer({
      queryString: `
SELECT comuna_id, comuna_nombre
FROM comuna
WHERE region_id = $1
ORDER BY comuna_nombre ASC`,
      queryParams: [regionId]
    });
  }

  public async getById(comunaId: string): Promise<any[]> {
    if (!comunaId) {
      throw new ErrorWithStatus('No se recibió el comunaId', 400);
    }
    return await this.baseSecureQueryPerformer({
      queryString: `
SELECT comuna_id, comuna_nombre, latitud, longitud
FROM comuna
WHERE comuna_id = $1`,
      queryParams: [comunaId]
    });
  }
}

const comunaService = new ComunaService();

export default comunaService;

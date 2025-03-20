import ErrorWithStatus from '../lib/error';
import BaseService from './base';

class RegionService extends BaseService {
  public async getAll(): Promise<any[]> {
    return await this.baseSimpleQueryPerformer({
      queryString: `
SELECT region_id, region_nombre
FROM region
ORDER BY region_nombre ASC`
    });
  }

  public async getById(regionId: string): Promise<any[]> {
    if (!regionId) {
      throw new ErrorWithStatus('No se recibió el regionId', 400);
    }
    return await this.baseSecureQueryPerformer({
      queryString: `
SELECT region_id, region_nombre, latitud, longitud
FROM region
WHERE region_id = $1`,
      queryParams: [regionId]
    });
  }
}

const regionService = new RegionService();

export default regionService;

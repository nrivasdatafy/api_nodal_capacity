import { SimpleObject } from '../typings/globals';
import BaseService from './base';
import ErrorWithStatus from '../lib/error';

class AlimentadorService extends BaseService {
  public async getAlimentadorData(alimentadorId: string): Promise<SimpleObject> {
    if (!alimentadorId) {
      throw new ErrorWithStatus('No se recibió el alimentadorId', 400);
    }

    const res = await this.baseSecureQueryPerformer({
      queryString: `
WITH clientes_bt AS (
    SELECT
      alimentador.alimentador_id,
      COUNT(1) qty
    FROM alimentador
    INNER JOIN nodo
      ON alimentador.alimentador_id = nodo.alimentador_id
    INNER JOIN poste
      ON nodo.poste_id = poste.poste_id
    INNER JOIN cliente_postes
      ON poste.poste_id = cliente_postes.poste_id
    WHERE
      cliente_postes.orden_cercania = 1
      AND alimentador.alimentador_id = $1
    GROUP BY
      alimentador.alimentador_id
), kilometros_tramo AS (
    SELECT
        tramo.alimentador_id,
        SUM(CASE WHEN tension = 0.32 THEN tramo.largo ELSE 0 END)/1000 AS kilometros_tramo_bt,
        SUM(CASE WHEN tension IN (23, 13.2) THEN tramo.largo ELSE 0 END)/1000 AS kilometros_tramo_mt,
        SUM(CASE WHEN tension IS NULL THEN tramo.largo ELSE 0 END)/1000 AS kilometros_tramo_null
    FROM tramo
    WHERE tramo.alimentador_id = $1
    GROUP BY tramo.alimentador_id
    )
SELECT
    empresa.empresa_id_origen empresa_id,
    empresa.empresa_nombre,
    ssee_poder.ssee_poder_nombre AS subestacion_nombre,
    alimentador.alimentador_nombre,
    alimentador.dda_max_kw AS demanda_maxima,
    alimentador.dda_min_kw AS demanda_minima,
    clientes_bt.qty AS cantidad_clientes_bt,
    SUM(CASE WHEN transformador_dx.propiedad_id IN (3, 4) THEN 1 ELSE 0 END) AS cantidad_clientes_mt,
    kilometros_tramo.kilometros_tramo_bt + kilometros_tramo_null AS kilometros_tramo_bt,
    kilometros_tramo.kilometros_tramo_mt,
    COUNT(1) AS cantidad_transformadores
FROM alimentador
INNER JOIN ssee_poder
    ON ssee_poder.subestacion_id = alimentador.subestacion_id
    AND ssee_poder.empresa_id = alimentador.subestacion_empresa_id
INNER JOIN empresa
    ON alimentador.empresa_id = empresa.empresa_id
INNER JOIN transformador_dx
    ON alimentador.alimentador_id = transformador_dx.alimentador_id
INNER JOIN clientes_bt
    ON alimentador.alimentador_id = clientes_bt.alimentador_id
INNER JOIN kilometros_tramo
    ON alimentador.alimentador_id = kilometros_tramo.alimentador_id
WHERE alimentador.alimentador_id = $1
GROUP BY
    empresa.empresa_id_origen,
    empresa.empresa_nombre,
    ssee_poder.ssee_poder_nombre,
    alimentador.alimentador_nombre,
    alimentador.dda_max_kw,
    alimentador.dda_min_kw,
    clientes_bt.qty,
    kilometros_tramo.kilometros_tramo_bt,
    kilometros_tramo_null,
    kilometros_tramo.kilometros_tramo_mt;`,
      queryParams: [alimentadorId]
    });

    if (res.length > 0) {
      return res[0];
    }

    throw new ErrorWithStatus(
      `No se ha encontrado informacion para el alimentador de ID = '${alimentadorId}'`,
      404
    );
  }
}

const alimentadorService = new AlimentadorService();

export default alimentadorService;

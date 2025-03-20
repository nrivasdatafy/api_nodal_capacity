import * as wkx from 'wkx';
import { PostgisGeometryValues, PostgisGeometryType } from '../typings/postgisGeometryType';
import BaseService from './base';
import { queries } from '../lib/queries';
import { allElementsDataToLngLat } from '../utils/mapDataParser';
import {
  createPolygonFeaturesByHullPoints,
  generateFeaturesFromMapLines,
  generateFeaturesFromMapPoints
} from '../utils/mapFeatureUtils';
import { SimpleObject } from '../typings/globals';

class MapElementService extends BaseService {
  public async getAlimentadores(): Promise<any[]> {
    const res = await this.baseSimpleQueryPerformer({
      queryString: queries.alimentadores()
    });
    return res;
  }

  public async getGeometryFeatureByAlimentadorId(
    geometries: PostgisGeometryType[],
    alimentadorId?: number
  ): Promise<any[]> {
    const queryParams: any[] = [];

    const geometryPlaceholders = geometries.map((_, index) => `$${index + 1}`);
    queryParams.push(...geometries);

    let alimentadorFilter = '';
    if (alimentadorId) {
      alimentadorFilter = `AND alimentador_id = $${queryParams.length + 1}`;
      queryParams.push(alimentadorId);
    }

    const queryString = `
  SELECT * 
  FROM features 
  WHERE ST_GeometryType(geometry) IN (${geometryPlaceholders.join(', ')}) 
  ${alimentadorFilter};`;

    const featuresDB = await this.baseSecureQueryPerformer({
      queryString,
      queryParams
    });

    const features = featuresDB.map((row) => {
      // Convertir la cadena hexadecimal a un Buffer
      const wkbBuffer = Buffer.from(row.geometry, 'hex');
      // Parsear el WKB a una geometría
      const geometry = wkx.Geometry.parse(wkbBuffer);
      // Convertir la geometría a GeoJSON
      const geoJSON = geometry.toGeoJSON();
      return {
        type: 'Feature',
        geometry: geoJSON,
        properties: row.properties
      };
    });

    return features;
  }

  public async getPolygonFeaturesByAlimentadorId(alimentadorId?: number): Promise<SimpleObject> {
    return await this.getGeometryFeatureByAlimentadorId(
      [PostgisGeometryValues.ST_MultiPolygon, PostgisGeometryValues.ST_Polygon],
      alimentadorId
    );
  }

  public async getLineFeaturesByAlimentadorId(alimentadorId?: number): Promise<SimpleObject> {
    return await this.getGeometryFeatureByAlimentadorId(
      [PostgisGeometryValues.ST_LineString],
      alimentadorId
    );
  }

  public async getPointFeaturesByAlimentadorId(alimentadorId?: number): Promise<SimpleObject> {
    return await this.getGeometryFeatureByAlimentadorId(
      [PostgisGeometryValues.ST_Point],
      alimentadorId
    );
  }

  public async getAllFeaturesByAlimentadorId(alimentadorId?: number): Promise<SimpleObject> {
    const polygonFeatures = await this.getPolygonFeaturesByAlimentadorId(alimentadorId);
    const lineFeatures = await this.getLineFeaturesByAlimentadorId(alimentadorId);
    const pointFeatures = await this.getPointFeaturesByAlimentadorId(alimentadorId);
    const alimentadores = await this.getAlimentadores();

    return {
      polygonFeatures,
      lineFeatures,
      pointFeatures,
      alimentadores
    };
  }

  public async regenerateMapElements(): Promise<any> {
    const EPSG_CODE_FOR_WGS84 = '4326';
    const res = await this.baseSimpleQueryPerformer({
      queryString: queries.allArtifactsByAlimentadorId()
    });

    const allElements = allElementsDataToLngLat(res);
    const { ElectricLinePointsByAlimentador, Linea, Alimentador, ...OtherArtefacts } = allElements;

    const polygonFeatureCollection = createPolygonFeaturesByHullPoints(
      ElectricLinePointsByAlimentador
    );
    const lineFeatureCollection = generateFeaturesFromMapLines(Linea);
    const otherArtefactsArray = Object.keys(OtherArtefacts)
      .map((k) => OtherArtefacts[k])
      .flat();
    const pointFeatureCollection = generateFeaturesFromMapPoints(otherArtefactsArray);

    let insertQuery = '';

    // INSERT FOR POLYGON, LINE AND POINTS
    for (const feature of [
      ...polygonFeatureCollection,
      ...lineFeatureCollection,
      ...pointFeatureCollection
    ]) {
      const { properties } = feature;
      const geometry = feature.geometry;

      insertQuery += `INSERT INTO features (alimentador_id, geometry, properties)
VALUES (${properties.alimentadorId}, ST_SetSRID(ST_GeomFromGeoJSON('${JSON.stringify(
        geometry
      )}'), ${EPSG_CODE_FOR_WGS84}), '${JSON.stringify(properties)}');
`;
    }

    if (!insertQuery) {
      return { done: true, details: 'features not found' };
    }

    // Remove everything before to create again
    await this.baseSimpleQueryPerformer({
      queryString: 'DELETE FROM features'
    });

    // Insert the new features
    await this.baseSimpleQueryPerformer({
      inhibitLog: true,
      queryString: insertQuery
    });

    return { done: true };
  }

  public async missingLines(): Promise<SimpleObject[]> {
    return await this.baseSimpleQueryPerformer({
      queryString: `
SELECT
    'Linea DUMMY V2' AS tramo_id_origen,
    tramo.empresa_id,
    cercanos.nodo_cercano_id,
    cercanos.nodo_base_id as nodo_dos_id,
    tramo.catalogo_conductor_id,
    tramo.alimentador_id,
    tramo.fases_id,
    tramo.zona_id,
    tramo.tipo_dispositivo_id,
    CASE WHEN cercanos.distancia <= 0 THEN 1 ELSE cercanos.distancia END AS largo,
    tramo.numero_fases,
    tramo.tension,
    tramo.datum,
    tramo.propiedad_id
FROM tramo
JOIN cercanos
    ON tramo.nodo_uno_id = cercanos.nodo_base_id
    AND cercania = 1
LEFT JOIN tramo AS tramo_existente
    ON tramo_existente.nodo_uno_id = cercanos.nodo_cercano_id
    AND tramo_existente.nodo_dos_id = cercanos.nodo_base_id
WHERE tramo_existente.tramo_id IS NULL;`
    });
  }
}

const mapElementService = new MapElementService();

export default mapElementService;
